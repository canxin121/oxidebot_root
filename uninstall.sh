#!/system/bin/sh

MODDIR=${0%/*}
CTL="$MODDIR/scripts/oxidebotctl"
DATA_DIR=/data/adb/__MODULE_ID__

if [ -x "$CTL" ]; then
  "$CTL" disable >/dev/null 2>&1
fi
if [ -f "$DATA_DIR/run/supervisor.pid" ]; then
  supervisor_pid=$(sed -n '1p' "$DATA_DIR/run/supervisor.pid" 2>/dev/null)
  case "$supervisor_pid" in
    *[!0-9]*|'') ;;
    *) kill "$supervisor_pid" 2>/dev/null ;;
  esac
  rm -f "$DATA_DIR/run/supervisor.pid"
fi

# 默认保留配置、日志和数据库，方便重装恢复。用户可在 env.conf 中明确选择清除。
if grep -q '^REMOVE_DATA_ON_UNINSTALL=1$' "$DATA_DIR/env.conf" 2>/dev/null; then
  rm -rf "$DATA_DIR"
else
  # 重装时恢复默认的自动启动选择。
  rm -f "$DATA_DIR/enabled" "$DATA_DIR/disabled"
fi
