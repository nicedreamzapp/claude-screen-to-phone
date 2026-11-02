#!/bin/bash
# AiMessageAgent — send a question via iMessage, wait for reply
# Usage: imessage-agent.sh "Your question here" [timeout_seconds]

DIR="$(cd "$(dirname "$0")" && pwd)"
YESALL_FILE="$DIR/imessage-yesall"
ASK_LOCK="$DIR/imessage-ask-active"
# Load BUDDY / APPLE_ID_EMAIL from the config if there is one (env still works)
CONFIG="${STP_CONFIG:-$HOME/.claude/screen-to-phone-config.sh}"
[ ! -f "$CONFIG" ] && CONFIG="$(dirname "$0")/../config.sh"
# shellcheck disable=SC1090
[ -f "$CONFIG" ] && source "$CONFIG"
DB="$HOME/Library/Messages/chat.db"
# Owner identifiers, matched EXACTLY. A LIKE '%...%' would also match any other
# sender whose chat identifier merely contains the address, and that sender's
# messages would be accepted as the owner's.
# Single quotes are doubled so a value can never close the SQL string literal.
sql_quote() { printf '%s' "${1//\'/\'\'}"; }
BUDDY_ID="$(sql_quote "${APPLE_ID_EMAIL:-$BUDDY}")"
BUDDY_PHONE="$(sql_quote "$(printf '%s' "$BUDDY" | tr -d '+')")"
OWNER_SQL="(lower(c.chat_identifier) = lower('$BUDDY_ID') OR replace(c.chat_identifier, '+', '') = '$BUDDY_PHONE')"

QUESTION="$1"
TIMEOUT=${2:-600}

# Check if yes-to-all is active
if [ -f "$YESALL_FILE" ]; then
    echo "YES"
    exit 0
fi

# Get current latest message ROWID before sending
BEFORE_ROWID=$(sqlite3 "$DB" "
    SELECT COALESCE(MAX(m.ROWID), 0)
    FROM message m
    JOIN chat_message_join cmj ON m.ROWID = cmj.message_id
    JOIN chat c ON cmj.chat_id = c.ROWID
    WHERE $OWNER_SQL
" 2>/dev/null || echo "0")

# Send the question
bash "$DIR/imessage-send.sh" "$QUESTION"

# Tell the listener daemon to back off — this question owns the next reply
touch "$ASK_LOCK"

# Wait for reply (pass our sent text so it gets skipped)
REPLY=$(bash "$DIR/imessage-receive.sh" "$TIMEOUT" "$BEFORE_ROWID" "$QUESTION")
RC=$?

rm -f "$ASK_LOCK"

if [ $RC -ne 0 ] || [ "$REPLY" = "TIMEOUT" ]; then
    echo "TIMEOUT"
    exit 1
fi

# Normalize reply
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
