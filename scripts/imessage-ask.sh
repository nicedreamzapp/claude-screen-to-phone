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
CONFIG="${STP_CONFIG:-$HOME/.claude/screen-to-phone-config.sh}"
[ ! -f "$CONFIG" ] && CONFIG="$(dirname "$0")/../config.sh"
if [ ! -f "$CONFIG" ]; then echo "❌ config.sh not found. Run setup.sh first."; exit 1; fi
# shellcheck disable=SC1090
source "$CONFIG"
YESALL_FILE="$DIR/imessage-yesall"
ASK_LOCK="$DIR/imessage-ask-active"
DB="$HOME/Library/Messages/chat.db"
# Owner identifiers, matched EXACTLY. A LIKE '%...%' here would also match any
# other sender whose chat identifier merely contains the address, and that
# sender's texts would be treated as the owner's.
# Single quotes are doubled so a value can never close the SQL string literal.
sql_quote() { printf '%s' "${1//\'/\'\'}"; }
BUDDY_ID="$(sql_quote "${APPLE_ID_EMAIL:-$BUDDY}")"
BUDDY_PHONE="$(sql_quote "$(printf '%s' "$BUDDY" | tr -d '+')")"
OWNER_SQL="(lower(c.chat_identifier) = lower('$BUDDY_ID') OR replace(c.chat_identifier, '+', '') = '$BUDDY_PHONE')"

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
    WHERE $OWNER_SQL
" 2>/dev/null || echo "0")

# Send. Message and buddy go in as ARGUMENTS and the heredoc is quoted, so a
# double quote in the text can't close the AppleScript string and run code.
osascript - "$MSG" "$BUDDY" <<'ENDSCRIPT'
on run argv
    set msgText to item 1 of argv
    set buddyID to item 2 of argv
    tell application "Messages"
        set targetService to 1st service whose service type = iMessage
        set targetBuddy to buddy buddyID of targetService
        send msgText to targetBuddy
    end tell
end run
ENDSCRIPT

# Tell the listener daemon to back off — this question owns the next reply
touch "$ASK_LOCK"

# Wait for reply
REPLY=$(bash "$DIR/imessage-receive.sh" "$TIMEOUT" "$BEFORE_ROWID" "$MSG")
RC=$?

rm -f "$ASK_LOCK"

if [ $RC -ne 0 ] || [ "$REPLY" = "TIMEOUT" ]; then
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
