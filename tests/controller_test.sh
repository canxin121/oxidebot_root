#!/usr/bin/env bash
set -euo pipefail

project_dir="$(cd "$(dirname "$0")/.." && pwd)"
test_root="$(mktemp -d)"
module_dir="$test_root/module"
data_dir="$test_root/data"
cleanup() {
  if [[ -f "$module_dir/scripts/oxidebotctl" ]]; then
    env OXIDEBOT_MODDIR="$module_dir" OXIDEBOT_DATA_DIR="$data_dir" OXIDEBOT_ABI=arm64-v8a \
      OXIDEBOT_REQUIRED_ENV=TELEGRAM_BOT_TOKEN,TELEGRAM_BOT_ID \
      sh "$module_dir/scripts/oxidebotctl" disable >/dev/null 2>&1 || true
  fi
  rm -rf "$test_root"
}
trap cleanup EXIT

mkdir -p "$module_dir/scripts" "$module_dir/bin/arm64-v8a" "$data_dir"
cp "$project_dir/scripts/oxidebotctl" "$module_dir/scripts/oxidebotctl"
cp "$project_dir/module.prop" "$module_dir/module.prop"
cp "$project_dir/env.example" "$module_dir/env.example"

cp "$project_dir/tests/fake_oxidebot.sh" "$module_dir/bin/arm64-v8a/oxidebot"
chmod 0755 "$module_dir/scripts/oxidebotctl" "$module_dir/bin/arm64-v8a/oxidebot"

ctl=(env OXIDEBOT_MODDIR="$module_dir" OXIDEBOT_DATA_DIR="$data_dir" OXIDEBOT_ABI=arm64-v8a OXIDEBOT_REQUIRED_ENV=TELEGRAM_BOT_TOKEN,TELEGRAM_BOT_ID sh "$module_dir/scripts/oxidebotctl")

config='TELEGRAM_BOT_TOKEN=test-token
TELEGRAM_BOT_ID=123456789
RUST_LOG=debug
LITERAL=$(must-not-run)'
encoded="$(printf '%s\n' "$config" | base64 | tr -d '\n')"
output="$("${ctl[@]}" config-import "$encoded")"
grep -q '配置已安全保存' <<<"$output"
output="$("${ctl[@]}" enable)"
grep -q '启动成功' <<<"$output"
"${ctl[@]}" is-running
status="$("${ctl[@]}" status --properties)"
grep -q '^status=running$' <<<"$status"
grep -q '^configured=true$' <<<"$status"
logs="$("${ctl[@]}" logs 20)"
grep -q 'fake oxidebot started' <<<"$logs"
output="$("${ctl[@]}" restart)"
grep -q '启动成功' <<<"$output"
output="$("${ctl[@]}" disable)"
grep -q '已停止' <<<"$output"
if "${ctl[@]}" is-running; then
  echo 'controller failed to stop the process' >&2
  exit 1
fi
status="$("${ctl[@]}" status --properties)"
grep -q '^autostart=false$' <<<"$status"
echo 'controller tests passed'
