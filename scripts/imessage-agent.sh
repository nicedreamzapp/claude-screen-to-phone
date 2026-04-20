#!/bin/bash
# AiMessageAgent — send a question via iMessage, wait for reply
# Usage: imessage-agent.sh "Your question here" [timeout_seconds]

DIR="$(cd "$(dirname "$0")" && pwd)"
FLAG_FILE="$DIR/imessage-agent-on"
YESALL_FILE="$DIR/imessage-yesall"
ASK_LOCK="$DIR/imessage-ask-active"
DB="$HOME/Library/Messages/chat.db"
BUDDY_MATCH="%${APPLE_ID_EMAIL:-$BUDDY}%"
PHONE_MATCH="%$(echo "$BUDDY" | tr -d '+')%"

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
    WHERE (c.chat_identifier LIKE '$BUDDY_MATCH' OR c.chat_identifier LIKE '$PHONE_MATCH')
" 2>/dev/null || echo "0")

# Send the question
bash "$DIR/imessage-send.sh" "$QUESTION"

# Tell the listener daemon to back off — this question owns the next reply
touch "$ASK_LOCK"

# Wait for reply (pass our sent text so it gets skipped)
REPLY=$(bash "$DIR/imessage-receive.sh" "$TIMEOUT" "$BEFORE_ROWID" "$QUESTION")

rm -f "$ASK_LOCK"

if [ $? -ne 0 ] || [ "$REPLY" = "TIMEOUT" ]; then
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
