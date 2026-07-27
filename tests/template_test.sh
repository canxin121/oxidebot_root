#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

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

module_zip="$project_dir/build/my_oxidebot-v0.1.0.zip"
test -f "$module_zip"
unzip -t "$module_zip" >/dev/null

module_prop="$(unzip -p "$module_zip" module.prop)"
grep -q '^id=my_oxidebot$' <<<"$module_prop"
grep -q '^name=My OxideBot$' <<<"$module_prop"
grep -q '^version=v0.1.0$' <<<"$module_prop"
grep -q '^updateJson=https://github.com/octocat/custom-oxidebot/releases/latest/download/update.json$' <<<"$module_prop"

controller="$(unzip -p "$module_zip" scripts/oxidebotctl)"
grep -q '/data/adb/my_oxidebot' <<<"$controller"
grep -q 'OXIDEBOT_REQUIRED_ENV:-TELEGRAM_BOT_TOKEN' <<<"$controller"
if grep -q '__MODULE_ID__' <<<"$controller"; then
  echo 'unrendered module ID in controller' >&2
  exit 1
fi

webui="$(unzip -p "$module_zip" webroot/index.html)"
grep -q '/data/adb/modules/my_oxidebot/scripts/oxidebotctl' <<<"$webui"

jq -e '
  .version == "v0.1.0"
  and .versionCode == 1
  and .zipUrl == "https://github.com/octocat/custom-oxidebot/releases/download/v0.1.0/my_oxidebot-v0.1.0.zip"
' "$project_dir/build/update.json" >/dev/null

echo 'template rendering tests passed'
