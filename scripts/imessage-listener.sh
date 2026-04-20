#!/bin/bash
# imessage-listener.sh — background daemon that forwards the user's phone messages
# straight into the target Terminal tab as if he typed them. Runs as long as
# the mobile-mode flag file exists.
#
# Started by imessage-toggle.sh when mobile mode is turned ON.
# Stopped (killed by PID) by imessage-toggle.sh when mobile mode is turned OFF.

DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$(dirname "$0")/../config.sh"
[ ! -f "$CONFIG" ] && CONFIG="$HOME/.claude/screen-to-phone-config.sh"
if [ ! -f "$CONFIG" ]; then echo "❌ config.sh not found. Run setup.sh first." >&2; exit 1; fi
source "$CONFIG"
FLAG_FILE="$DIR/imessage-agent-on"
TARGET_FILE="$DIR/imessage-mobile-target"
SENT_LOG="$DIR/imessage-sent-recent"
ASK_LOCK="$DIR/imessage-ask-active"
STARTUP_LOCK="$DIR/imessage-startup-lock"
DB="$HOME/Library/Messages/chat.db"
BUDDY_MATCH="%${APPLE_ID_EMAIL:-$BUDDY}%"
PHONE_MATCH="%$(echo "$BUDDY" | tr -d '+')%"

# Need a target window saved by the toggle script
if [ ! -f "$TARGET_FILE" ]; then
    echo "$(date) — no target window saved, exiting" >&2
    exit 1
fi
# shellcheck disable=SC1090
source "$TARGET_FILE"  # exports TARGET_TTY

if [ -z "$TARGET_TTY" ]; then
    echo "$(date) — target file missing TARGET_TTY, exiting" >&2
    exit 1
fi

get_max_rowid() {
    sqlite3 "$DB" "
        SELECT COALESCE(MAX(m.ROWID), 0)
        FROM message m
        JOIN chat_message_join cmj ON m.ROWID = cmj.message_id
        JOIN chat c ON cmj.chat_id = c.ROWID
        WHERE (c.chat_identifier LIKE '$BUDDY_MATCH' OR c.chat_identifier LIKE '$PHONE_MATCH')
    " 2>/dev/null || echo "0"
}

# Start from the current latest message — anything that arrives AFTER we
# turned on mobile mode is what we care about.
LAST_ROWID=$(get_max_rowid)
echo "$(date) — listener started, baseline ROWID=$LAST_ROWID, target=$TARGET_TTY"

while [ -f "$FLAG_FILE" ]; do
    # If the launcher is still bringing the app up, buffer — don't advance the
    # pointer, just wait. Messages that arrive during startup will get forwarded
    # once the lock lifts and the app is actually listening.
    if [ -f "$STARTUP_LOCK" ]; then
        sleep 2
        continue
    fi

    # If imessage-ask.sh / imessage-agent.sh is actively waiting for a yes/no
    # reply, let it consume the next message — don't double-fire it into the
    # terminal. Just advance our pointer past anything that arrived during the
    # ask so we don't replay it later.
    if [ -f "$ASK_LOCK" ]; then
        sleep 2
        LAST_ROWID=$(get_max_rowid)
        continue
    fi

    # Pull any new messages since the last one we forwarded
    NEW_MSGS=$(sqlite3 -separator $'\t' "$DB" "
        SELECT m.ROWID, m.text
        FROM message m
        JOIN chat_message_join cmj ON m.ROWID = cmj.message_id
        JOIN chat c ON cmj.chat_id = c.ROWID
        WHERE (c.chat_identifier LIKE '$BUDDY_MATCH' OR c.chat_identifier LIKE '$PHONE_MATCH')
          AND m.ROWID > $LAST_ROWID
          AND m.text IS NOT NULL
          AND m.text != ''
        ORDER BY m.ROWID ASC;
    " 2>/dev/null)

    if [ -n "$NEW_MSGS" ]; then
        while IFS=$'\t' read -r ROWID TEXT; do
            [ -z "$ROWID" ] && continue
            LAST_ROWID="$ROWID"

            # Skip echoes of messages WE sent via imessage-send.sh in the last 60s.
            # iCloud-syncs Apple ID, so our outbound messages would otherwise look
            # like they came from the phone.
            if [ -f "$SENT_LOG" ]; then
                NOW=$(date +%s)
                if awk -F'\t' -v now="$NOW" -v target="$TEXT" '
                    { if ((now - $1) < 60 && $2 == target) { found=1 } }
                    END { exit !found }
                ' "$SENT_LOG"; then
                    continue
                fi
            fi

            # "stop" from the phone turns mobile mode off
            LOWER_TEXT=$(echo "$TEXT" | tr '[:upper:]' '[:lower:]' | xargs)
            if [ "$LOWER_TEXT" = "stop" ]; then
                bash "$DIR/imessage-toggle.sh" >/dev/null 2>&1
                exit 0
            fi

            # Strip newlines so we don't accidentally submit half a message
            CLEAN_TEXT=$(printf '%s' "$TEXT" | tr '\n\r' '  ')

            # Use clipboard so special characters survive (no AppleScript escaping nightmare)
            printf '%s' "$CLEAN_TEXT" | pbcopy

            ACTIVATED=$(osascript <<APPLESCRIPT 2>&1
tell application "Terminal"
    set targetWin to missing value
    set targetTab to missing value
    repeat with w in windows
        repeat with t in tabs of w
            if tty of t is "$TARGET_TTY" then
                set targetWin to w
                set targetTab to t
                exit repeat
            end if
        end repeat
        if targetWin is not missing value then exit repeat
    end repeat
    if targetWin is missing value then
        return "ERROR: no Terminal tab with tty $TARGET_TTY"
    end if
    set selected tab of targetWin to targetTab
    set index of targetWin to 1
    activate
end tell
delay 0.3
tell application "System Events"
    set frontmost of (first process whose name is "Terminal") to true
end tell
delay 0.2
tell application "System Events"
    tell process "Terminal"
        keystroke "v" using command down
        delay 0.3
        key code 36
    end tell
end tell
return "OK"
APPLESCRIPT
)
            echo "$(date) — forwarded ROWID=$ROWID: $CLEAN_TEXT [applescript: $ACTIVATED]"

            # Small breather between messages so Claude Code can register them in order
            sleep 0.5
        done <<< "$NEW_MSGS"
    fi

    sleep 2
done

echo "$(date) — flag file gone, listener exiting"
