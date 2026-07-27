#!/bin/sh

[ -n "${TELEGRAM_BOT_TOKEN:-}" ] || exit 2
echo "fake oxidebot started"
trap 'exit 0' TERM INT
while true; do sleep 1; done
