#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

property() {
  sed -n "s/^$1=//p" "$project_dir/template.properties"
}

module_id="$(property moduleId)"
module_name="$(property moduleName)"
version_name="$(property versionName)"
version_code="$(property versionCode)"
required_env="$(property requiredEnv)"

for target in \
  aarch64-linux-android \
  armv7-linux-androideabi \
  x86_64-linux-android \
  i686-linux-android; do
  mkdir -p "$test_root/$target/release"
  cp "$project_dir/tests/fake_oxidebot.sh" "$test_root/$target/release/oxidebot_app"
done

GITHUB_REPOSITORY=octocat/custom-oxidebot BINARY_DIR="$test_root" \
  bash "$project_dir/build.sh" >/dev/null

module_zip="$project_dir/build/${module_id}-v${version_name}.zip"
test -f "$module_zip"
unzip -t "$module_zip" >/dev/null

module_prop="$(unzip -p "$module_zip" module.prop)"
grep -Fqx "id=$module_id" <<<"$module_prop"
grep -Fqx "name=$module_name" <<<"$module_prop"
grep -Fqx "version=v$version_name" <<<"$module_prop"
grep -Fqx 'updateJson=https://github.com/octocat/custom-oxidebot/releases/latest/download/update.json' <<<"$module_prop"

controller="$(unzip -p "$module_zip" scripts/oxidebotctl)"
grep -Fq "/data/adb/$module_id" <<<"$controller"
grep -Fq "OXIDEBOT_REQUIRED_ENV:-$required_env" <<<"$controller"
if grep -q '__MODULE_ID__' <<<"$controller"; then
  echo 'unrendered module ID in controller' >&2
  exit 1
fi

webui="$(unzip -p "$module_zip" webroot/index.html)"
grep -Fq "/data/adb/modules/$module_id/scripts/oxidebotctl" <<<"$webui"
grep -Fq 'setInterval(refreshHomeStatus, AUTO_REFRESH_MS)' <<<"$webui"
grep -Fq 'window.oxideRefreshStatus = refreshHomeStatus' <<<"$webui"
if grep -Fq "document.visibilityState === 'visible'" <<<"$webui"; then
  echo 'auto refresh still depends on unreliable WebView visibility state' >&2
  exit 1
fi
sed -n '/^  <script>$/,/^  <\/script>$/p' "$project_dir/webroot/index.html" \
  | sed '1d;$d' \
  | node --check

jq -e \
  --arg version "v$version_name" \
  --argjson version_code "$version_code" \
  --arg zip_url "https://github.com/octocat/custom-oxidebot/releases/download/v${version_name}/${module_id}-v${version_name}.zip" '
  .version == $version
  and .versionCode == $version_code
  and .zipUrl == $zip_url
' "$project_dir/build/update.json" >/dev/null

echo 'template rendering tests passed'
