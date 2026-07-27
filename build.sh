#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")" && pwd)"
binary_root="${BINARY_DIR:-$project_dir/../my_oxidebot/target}"
build_dir="$project_dir/build"
stage_dir="$build_dir/staging"

version="$(sed -n 's/^version=//p' "$project_dir/module.prop")"
version="${version#v}"
output_zip="$build_dir/oxidebot-root-v${version}.zip"

find_binary() {
  local target=$1
  local candidate
  for candidate in \
    "$binary_root/$target/release/my_oxidebot" \
    "$binary_root/target/$target/release/my_oxidebot" \
    "$binary_root/my_oxidebot-$target"; do
    if [[ -f "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done
  return 1
}

prepare_binary() {
  local abi=$1 target=$2 source
  if ! source="$(find_binary "$target")"; then
    printf 'Missing %s binary. Build my_oxidebot first or set BINARY_DIR.\n' "$target" >&2
    exit 1
  fi
  install -m 0755 "$source" "$stage_dir/bin/$abi/oxidebot"
}

mkdir -p "$stage_dir/bin/arm64-v8a" "$stage_dir/bin/armeabi-v7a" "$stage_dir/bin/x86_64" "$stage_dir/bin/x86"
find "$stage_dir" -mindepth 1 -maxdepth 1 ! -name bin -exec rm -rf {} +
find "$stage_dir/bin" -type f -name oxidebot -delete

cp "$project_dir/module.prop" "$project_dir/customize.sh" "$project_dir/service.sh" \
  "$project_dir/action.sh" "$project_dir/uninstall.sh" "$project_dir/env.example" \
  "$project_dir/update.json" "$project_dir/CHANGELOG.md" "$stage_dir/"
cp -R "$project_dir/scripts" "$project_dir/webroot" "$project_dir/META-INF" "$stage_dir/"

prepare_binary arm64-v8a aarch64-linux-android
prepare_binary armeabi-v7a armv7-linux-androideabi
prepare_binary x86_64 x86_64-linux-android
prepare_binary x86 i686-linux-android

chmod 0755 "$stage_dir/customize.sh" "$stage_dir/service.sh" "$stage_dir/action.sh" \
  "$stage_dir/uninstall.sh" "$stage_dir/scripts/oxidebotctl" "$stage_dir/scripts/supervisor.sh" \
  "$stage_dir/META-INF/com/google/android/update-binary"

mkdir -p "$build_dir"
rm -f "$output_zip"
(
  cd "$stage_dir"
  zip -9 -r "$output_zip" . -x '*.DS_Store'
)

printf 'Built %s\n' "$output_zip"
