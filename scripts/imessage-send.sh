#!/bin/bash
# Send a text iMessage to your phone
# ─────────────────────────────────────────────
CONFIG="$(dirname "$0")/../config.sh"
[ ! -f "$CONFIG" ] && CONFIG="$HOME/.claude/screen-to-phone-config.sh"
if [ ! -f "$CONFIG" ]; then echo "❌ config.sh not found. Run setup.sh first."; exit 1; fi
source "$CONFIG"

MSG="$1"
MAX_LEN=200

if [ -z "$MSG" ]; then echo "Usage: imessage-send.sh 'message'"; exit 1; fi
if [ ${#MSG} -gt $MAX_LEN ]; then MSG="${MSG:0:$MAX_LEN}..."; fi

MSG_ESCAPED=$(echo "$MSG" | sed 's/"/\\"/g')

osascript -e "tell application \"Messages\"" \
          -e "set targetService to 1st service whose service type = iMessage" \
          -e "set targetBuddy to buddy \"$BUDDY\" of targetService" \
          -e "send \"$MSG_ESCAPED\" to targetBuddy" \
          -e "end tell" 2>&1
