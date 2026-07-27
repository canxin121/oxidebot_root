#!/system/bin/sh

MODDIR=${0%/*}
CTL="$MODDIR/scripts/oxidebotctl"

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  OxideBot 服务开关"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if "$CTL" is-running >/dev/null 2>&1; then
  echo "- 当前状态：运行中"
  echo "- 正在停止，并关闭自动启动…"
  "$CTL" disable
else
  echo "- 当前状态：已停止"
  echo "- 正在启用，并立即启动…"
  "$CTL" enable
fi

echo
"$CTL" status
