#!/bin/bash
# Wait for a new iMessage reply from your phone
# ─────────────────────────────────────────────
CONFIG="$(dirname "$0")/../config.sh"
[ ! -f "$CONFIG" ] && CONFIG="$HOME/.claude/screen-to-phone-config.sh"
if [ ! -f "$CONFIG" ]; then echo "❌ config.sh not found. Run setup.sh first."; exit 1; fi
source "$CONFIG"

TIMEOUT=${1:-300}
DB="$HOME/Library/Messages/chat.db"

# Get ROWID of the most recent incoming message (baseline)
PHONE_STRIPPED=$(echo "$BUDDY" | tr -d '+')
SINCE_ROWID=$(sqlite3 "$DB" "
    SELECT COALESCE(MAX(m.ROWID), 0)
    FROM message m
    JOIN chat_message_join cmj ON m.ROWID = cmj.message_id
    JOIN chat c ON cmj.chat_id = c.ROWID
    WHERE (c.chat_identifier LIKE '%$APPLE_ID_EMAIL%'
        OR c.chat_identifier LIKE '%$PHONE_STRIPPED%')
      AND m.is_from_me = 0
" 2>/dev/null || echo "0")

# Poll for new incoming message
ELAPSED=0
while [ $ELAPSED -lt $TIMEOUT ]; do
    sleep 3
    ELAPSED=$((ELAPSED + 3))

    REPLY=$(sqlite3 "$DB" "
        SELECT m.text
        FROM message m
        JOIN chat_message_join cmj ON m.ROWID = cmj.message_id
        JOIN chat c ON cmj.chat_id = c.ROWID
        WHERE (c.chat_identifier LIKE '%$APPLE_ID_EMAIL%'
            OR c.chat_identifier LIKE '%$PHONE_STRIPPED%')
          AND m.ROWID > $SINCE_ROWID
          AND m.is_from_me = 0
          AND m.text IS NOT NULL
          AND m.text != ''
        ORDER BY m.ROWID DESC
        LIMIT 1;
    " 2>/dev/null)

    if [ -n "$REPLY" ]; then
        echo "$REPLY"
        exit 0
    fi
done

echo "TIMEOUT"
exit 1
