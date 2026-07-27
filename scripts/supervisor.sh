#!/system/bin/sh

MODDIR=${0%/*}/..
CTL="$MODDIR/scripts/oxidebotctl"
DATA_DIR=/data/adb/__MODULE_ID__
RUN_DIR="$DATA_DIR/run"
SUPERVISOR_PID="$RUN_DIR/supervisor.pid"

mkdir -p "$RUN_DIR"

if [ -f "$SUPERVISOR_PID" ]; then
  old_pid=$(sed -n '1p' "$SUPERVISOR_PID" 2>/dev/null)
  case "$old_pid" in
    *[!0-9]*|'') ;;
    *) kill -0 "$old_pid" 2>/dev/null && exit 0 ;;
  esac
fi
echo $$ > "$SUPERVISOR_PID"
trap 'rm -f "$SUPERVISOR_PID"' EXIT INT TERM

# Android 完全启动并解锁数据分区后再启动网络 Bot。
waited=0
while [ "$(getprop sys.boot_completed 2>/dev/null)" != "1" ] && [ "$waited" -lt 180 ]; do
  sleep 2
  waited=$((waited + 2))
done

failures=0
while true; do
  if [ -f "$DATA_DIR/enabled" ] && [ ! -f "$DATA_DIR/disabled" ]; then
    if ! "$CTL" is-running >/dev/null 2>&1; then
      if "$CTL" start >/dev/null 2>&1; then
        failures=0
      else
        failures=$((failures + 1))
      fi
    else
      failures=0
    fi
  fi

  # 连续失败时逐步降频，最高每五分钟重试一次。
  if [ "$failures" -ge 5 ]; then
    sleep 300
  elif [ "$failures" -ge 2 ]; then
    sleep 60
  else
    sleep 20
  fi
done
