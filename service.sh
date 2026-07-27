#!/system/bin/sh

MODDIR=${0%/*}

# 由 supervisor 自己持有生命周期；Root 管理器无需等待这个脚本。
"$MODDIR/scripts/supervisor.sh" >/dev/null 2>&1 &
