#!/bin/bash
# Wait for a new iMessage reply from Matt
# Since phone and Mac share the same Apple ID, ALL messages show as is_from_me=1
# So we just look for any NEW message after our sent ROWID that isn't our exact sent text

TIMEOUT=${1:-300}
SINCE_ROWID=${2:-0}
SENT_TEXT=${3:-""}  # the text WE sent, so we can skip it
DB="$HOME/Library/Messages/chat.db"
BUDDY_MATCH="%${APPLE_ID_EMAIL:-$BUDDY}%"
PHONE_MATCH="%$(echo "$BUDDY" | tr -d '+')%"

# If no since_rowid given, get the current latest
if [ "$SINCE_ROWID" = "0" ]; then
    SINCE_ROWID=$(sqlite3 "$DB" "
        SELECT COALESCE(MAX(m.ROWID), 0)
        FROM message m
        JOIN chat_message_join cmj ON m.ROWID = cmj.message_id
        JOIN chat c ON cmj.chat_id = c.ROWID
        WHERE (c.chat_identifier LIKE '$BUDDY_MATCH' OR c.chat_identifier LIKE '$PHONE_MATCH')
    " 2>/dev/null || echo "0")
fi

# Poll for new message (any new message that isn't our sent text)
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
    REPLY=$(sqlite3 "$DB" "
        SELECT m.text
        FROM message m
        JOIN chat_message_join cmj ON m.ROWID = cmj.message_id
        JOIN chat c ON cmj.chat_id = c.ROWID
        WHERE (c.chat_identifier LIKE '$BUDDY_MATCH' OR c.chat_identifier LIKE '$PHONE_MATCH')
          AND m.ROWID > $SINCE_ROWID
          AND m.text IS NOT NULL
          AND m.text != ''
        ORDER BY m.ROWID DESC
        LIMIT 1;
    " 2>/dev/null)

    # Skip if the reply is exactly what we sent
    if [ -n "$REPLY" ] && [ "$REPLY" != "$SENT_TEXT" ]; then
        echo "$REPLY"
        exit 0
    fi

    sleep 3
    ELAPSED=$((ELAPSED + 3))
done

echo "TIMEOUT"
exit 1
