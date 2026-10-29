#!/bin/bash
# Toggle the iMessage Agent on/off
# When turning ON:
#   - Captures the current Terminal window/tab as the target
#   - Spawns imessage-listener.sh as a background daemon
# When turning OFF:
#   - Kills the listener daemon
#   - Cleans up state files
DIR="$(cd "$(dirname "$0")" && pwd)"
FLAG_FILE="$DIR/imessage-agent-on"
TARGET_FILE="$DIR/imessage-mobile-target"
PID_FILE="$DIR/imessage-listener.pid"
LOG_FILE="/tmp/imessage-listener.log"

if [ -f "$FLAG_FILE" ]; then
    # Turn OFF
    rm -f "$FLAG_FILE"
    if [ -f "$PID_FILE" ]; then
        LISTENER_PID=$(cat "$PID_FILE" 2>/dev/null)
        if [ -n "$LISTENER_PID" ]; then
            kill "$LISTENER_PID" 2>/dev/null
        fi
        rm -f "$PID_FILE"
    fi
    rm -f "$TARGET_FILE"
    bash "$DIR/imessage-send.sh" "iMessage Agent is OFF. Back to keyboard mode."
    echo "OFF"
else
    # Turn ON — Mobile mode is allowed in any Claude Code session.
    # (The mic dictation listener has its own separate whitelist enforced
    # inside the dictation tool via NARRATE_DICTATION_LAUNCHER. iMessage
    # mobile mode is intentionally open to any session.)

    # Find the controlling tty of OUR caller (Claude Code or shell).
    # This is more reliable than asking Terminal for "front window", which can
    # grab the wrong window if the user has multiple Claude Code sessions or
    # the bash subprocess isn't visually frontmost.
    PID=$PPID
    TARGET_TTY_NAME=""
    while [ -n "$PID" ] && [ "$PID" != "1" ] && [ "$PID" != "0" ]; do
        T=$(ps -p "$PID" -o tty= 2>/dev/null | xargs)
        if [ -n "$T" ] && [ "$T" != "??" ]; then
            TARGET_TTY_NAME="$T"
            break
        fi
        PID=$(ps -p "$PID" -o ppid= 2>/dev/null | xargs)
    done

    if [ -z "$TARGET_TTY_NAME" ]; then
        echo "ERROR: couldn't find a controlling tty by walking parent process chain" >&2
        exit 1
    fi

    TARGET_TTY="/dev/$TARGET_TTY_NAME"

    cat > "$TARGET_FILE" <<EOF
TARGET_TTY=$TARGET_TTY
EOF

    touch "$FLAG_FILE"

    # Start the background listener
    nohup bash "$DIR/imessage-listener.sh" > "$LOG_FILE" 2>&1 &
    LISTENER_PID=$!
    echo "$LISTENER_PID" > "$PID_FILE"
    disown "$LISTENER_PID" 2>/dev/null || true

    bash "$DIR/imessage-send.sh" "iMessage Agent is ON. I'm listening — text me anything from your phone and it'll go straight into the Mac. Say 'stop' to turn off."
    echo "ON (listener PID $LISTENER_PID, target $TARGET_TTY)"
fi
