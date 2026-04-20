#!/bin/bash
# Ask Matt a yes/no question via iMessage — short, clean, phone-friendly
# Usage: imessage-ask.sh "what" "why" [timeout]
# Example: imessage-ask.sh "Rebalance crypto" "BTC is 90%, should be 70%"
#
# Sends:
#   🔔 Rebalance crypto
#   BTC is 90%, should be 70%
#   → Yes / Yes to All / No

DIR="$(cd "$(dirname "$0")" && pwd)"
WHAT="$1"
WHY="$2"
TIMEOUT=${3:-600}
# Source config
CONFIG="$(dirname "$0")/../config.sh"
[ ! -f "$CONFIG" ] && CONFIG="$HOME/.claude/screen-to-phone-config.sh"
if [ ! -f "$CONFIG" ]; then echo "❌ config.sh not found. Run setup.sh first."; exit 1; fi
source "$CONFIG"
YESALL_FILE="$DIR/imessage-yesall"
ASK_LOCK="$DIR/imessage-ask-active"
DB="$HOME/Library/Messages/chat.db"
BUDDY_MATCH="%${APPLE_ID_EMAIL:-$BUDDY}%"
PHONE_MATCH="%$(echo "$BUDDY" | tr -d '+')%"

# Auto mode — skip asking
if [ -f "$YESALL_FILE" ]; then
    echo "YES"
    exit 0
fi

# Build short message
if [ -n "$WHY" ]; then
    MSG=$(printf "🔔 %s\n%s\n→ Yes / Yes to All / No" "$WHAT" "$WHY")
else
    MSG=$(printf "🔔 %s\n→ Yes / Yes to All / No" "$WHAT")
fi

# Get current latest ROWID
BEFORE_ROWID=$(sqlite3 "$DB" "
    SELECT COALESCE(MAX(m.ROWID), 0)
    FROM message m
    JOIN chat_message_join cmj ON m.ROWID = cmj.message_id
    JOIN chat c ON cmj.chat_id = c.ROWID
    WHERE (c.chat_identifier LIKE '$BUDDY_MATCH' OR c.chat_identifier LIKE '$PHONE_MATCH')
" 2>/dev/null || echo "0")

# Send
osascript <<ENDSCRIPT
tell application "Messages"
    set targetService to 1st service whose service type = iMessage
    set targetBuddy to buddy "$BUDDY" of targetService
    send "$MSG" to targetBuddy
end tell
ENDSCRIPT

# Tell the listener daemon to back off — this question owns the next reply
touch "$ASK_LOCK"

# Wait for reply
REPLY=$(bash "$DIR/imessage-receive.sh" "$TIMEOUT" "$BEFORE_ROWID" "$MSG")

rm -f "$ASK_LOCK"

if [ $? -ne 0 ] || [ "$REPLY" = "TIMEOUT" ]; then
    echo "TIMEOUT"
    exit 1
fi

# Normalize
LOWER=$(echo "$REPLY" | tr '[:upper:]' '[:lower:]' | xargs)

case "$LOWER" in
    "yes"|"y"|"ok"|"do it"|"go"|"go ahead"|"yes 👍"|"👍"|"yep"|"yeah"|"sure"|"approved")
        echo "YES"
        ;;
    "yes to all"|"yta"|"yes all"|"approve all"|"do everything")
        touch "$YESALL_FILE"
        echo "YES_TO_ALL"
        ;;
    "no"|"n"|"stop"|"dont"|"don't"|"cancel"|"reject"|"nope"|"👎")
        echo "NO"
        ;;
    *)
        echo "$REPLY"
        ;;
esac
