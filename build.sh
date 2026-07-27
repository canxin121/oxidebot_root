#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")" && pwd)"
config_file="$project_dir/template.properties"
binary_root="${BINARY_DIR:-$project_dir/runner/target}"
build_dir="$project_dir/build"
stage_dir="$build_dir/staging"

config_value() {
  local key=$1 value
  value="$(sed -n "s/^${key}=//p" "$config_file" | tail -n 1)"
  if [[ -z "$value" ]]; then
    printf 'Missing %s in %s\n' "$key" "$config_file" >&2
    exit 1
  fi
  printf '%s\n' "$value"
}

config_optional_value() {
  local key=$1
  sed -n "s/^${key}=//p" "$config_file" | tail -n 1
}

module_id="$(config_value moduleId)"
module_name="$(config_value moduleName)"
module_author="$(config_value moduleAuthor)"
module_description="$(config_value moduleDescription)"
version="$(config_value versionName)"
version_code="$(config_value versionCode)"
required_env="$(config_optional_value requiredEnv)"
repository="${GITHUB_REPOSITORY:-$(config_value repository)}"

[[ "$module_id" =~ ^[A-Za-z][A-Za-z0-9._-]*$ ]] || {
  printf 'Invalid moduleId: %s\n' "$module_id" >&2
  exit 1
}
[[ "$version" =~ ^[0-9A-Za-z][0-9A-Za-z._-]*$ ]] || {
  printf 'Invalid versionName: %s\n' "$version" >&2
  exit 1
}
[[ "$version_code" =~ ^[0-9]+$ ]] || {
  printf 'versionCode must be an integer\n' >&2
  exit 1
}
[[ "$repository" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]] || {
  printf 'Invalid repository: %s\n' "$repository" >&2
  exit 1
}
if [[ -n "$required_env" ]] && ! [[ "$required_env" =~ ^[A-Za-z_][A-Za-z0-9_]*(,[A-Za-z_][A-Za-z0-9_]*)*$ ]]; then
  printf 'requiredEnv must be empty or a comma-separated list of environment variable names\n' >&2
  exit 1
fi

output_zip="$build_dir/${module_id}-v${version}.zip"
update_json="$build_dir/update.json"

find_binary() {
  local target=$1
  local candidate
  for candidate in \
    "$binary_root/$target/release/oxidebot_app" \
    "$binary_root/target/$target/release/oxidebot_app" \
    "$binary_root/oxidebot_app-$target"; do
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
    printf 'Missing %s binary. Build runner first or set BINARY_DIR.\n' "$target" >&2
    exit 1
  fi
  install -m 0755 "$source" "$stage_dir/bin/$abi/oxidebot"
}

mkdir -p "$stage_dir/bin/arm64-v8a" "$stage_dir/bin/armeabi-v7a" "$stage_dir/bin/x86_64" "$stage_dir/bin/x86"
find "$stage_dir" -mindepth 1 -maxdepth 1 ! -name bin -exec rm -rf {} +
find "$stage_dir/bin" -type f -name oxidebot -delete

cp "$project_dir/customize.sh" "$project_dir/service.sh" "$project_dir/action.sh" \
  "$project_dir/uninstall.sh" "$project_dir/env.example" "$project_dir/CHANGELOG.md" "$stage_dir/"
cp -R "$project_dir/scripts" "$project_dir/webroot" "$project_dir/META-INF" "$stage_dir/"

printf '%s\n' \
  "id=$module_id" \
  "name=$module_name" \
  "version=v$version" \
  "versionCode=$version_code" \
  "author=$module_author" \
  "description=$module_description" \
  "updateJson=https://github.com/$repository/releases/latest/download/update.json" \
  > "$stage_dir/module.prop"

for template_target in \
  "$stage_dir/customize.sh" \
  "$stage_dir/uninstall.sh" \
  "$stage_dir/scripts/oxidebotctl" \
  "$stage_dir/scripts/supervisor.sh" \
  "$stage_dir/webroot/index.html"; do
  sed "s/__MODULE_ID__/$module_id/g" "$template_target" > "$template_target.rendered"
  mv -f "$template_target.rendered" "$template_target"
done

sed "s/__REQUIRED_ENV__/$required_env/g" "$stage_dir/scripts/oxidebotctl" \
  > "$stage_dir/scripts/oxidebotctl.rendered"
mv -f "$stage_dir/scripts/oxidebotctl.rendered" "$stage_dir/scripts/oxidebotctl"

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

printf '%s\n' \
  '{' \
  "  \"version\": \"v$version\"," \
  "  \"versionCode\": $version_code," \
  "  \"zipUrl\": \"https://github.com/$repository/releases/download/v$version/${module_id}-v${version}.zip\"," \
  "  \"changelog\": \"https://github.com/$repository/releases/tag/v$version\"" \
  '}' \
  > "$update_json"

printf 'Built %s\n' "$output_zip"
printf 'Built %s\n' "$update_json"
