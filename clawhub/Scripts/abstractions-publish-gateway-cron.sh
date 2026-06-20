#!/usr/bin/env bash
# Wrapper für Linux-crontab - setzt sauberes Environment
export HOME=/home/openclaw
export PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

LOG_DIR="/home/openclaw/.openclaw/logs/abstractions-publish-gateway"
mkdir -p "$LOG_DIR"
CRON_LOG="$LOG_DIR/linux-cron.log"

{
  echo ""
  echo "===== CRON START $(date '+%Y-%m-%d %H:%M:%S') ====="
  /home/openclaw/.openclaw/scripts/abstractions-publish-gateway.sh
  echo "===== CRON END (exit $?) ====="
} >> "$CRON_LOG" 2>&1
