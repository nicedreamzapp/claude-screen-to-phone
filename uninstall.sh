#!/bin/bash
# Claude Screen to Phone uninstaller.
#   curl -fsSL https://raw.githubusercontent.com/nicedreamzapp/claude-screen-to-phone/main/uninstall.sh | bash
#   ... | bash -s -- --purge      also deletes your config, the Mobile Mode state and the clone
# or, from a clone:  bash uninstall.sh [--purge]
#
# Stops the Mobile Mode listener only through its pid file, removes the scripts
# setup.sh installed (from its manifest), and removes the statusLine from
# ~/.claude/settings.json only if it is exactly ours. Safe to run twice.
# --purge deletes the clone at STP_DIR (default ~/claude-screen-to-phone) only.

set -uo pipefail

PURGE=0
for arg in "$@"; do
    case "$arg" in
        --purge) PURGE=1 ;;
        *) echo "Unknown option: $arg (use --purge)" >&2; exit 2 ;;
    esac
done

STP_DIR="${STP_DIR:-$HOME/claude-screen-to-phone}"
CLAUDE_DIR="$HOME/.claude"
MANIFEST="$CLAUDE_DIR/.screen-to-phone-installed"
SETTINGS="$CLAUDE_DIR/settings.json"
PID_FILE="$CLAUDE_DIR/imessage-listener.pid"
STATUSLINE_CMD='bash ~/.claude/statusline.sh'
KNOWN=(
    imessage-send.sh imessage-send-image.sh imessage-send-video.sh
    imessage-toggle.sh imessage-receive.sh imessage-listener.sh
    imessage-ask.sh imessage-agent.sh statusline.sh
)

is_our_checkout() {
    [ -d "$1/.git" ] && [ -f "$1/setup.sh" ] && [ -f "$1/scripts/imessage-toggle.sh" ]
}

# Where to compare files from when there is no manifest: this checkout, else STP_DIR
SRC=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
    HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    is_our_checkout "$HERE" && SRC="$HERE"
fi
[ -z "$SRC" ] && is_our_checkout "$STP_DIR" && SRC="$STP_DIR"

removed=0

# 1. Stop the listener, only if the pid file points at our live listener
if [ -f "$PID_FILE" ]; then
    PID=$(tr -dc '0-9' < "$PID_FILE")
    if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null \
        && ps -p "$PID" -o command= 2>/dev/null | grep -q "imessage-listener\.sh"; then
        kill "$PID" 2>/dev/null && echo "Stopped the Mobile Mode listener (pid $PID)"
    fi
    rm -f "$PID_FILE" "$CLAUDE_DIR/imessage-mobile-target"
fi

# 2. Remove the installed scripts
SETTINGS_CREATED=0
if [ -f "$MANIFEST" ]; then
    grep -qx '#settings-created' "$MANIFEST" && SETTINGS_CREATED=1
    while IFS= read -r name; do
        case "$name" in ''|*/*|.*|'#'*) continue ;; esac
        if [ -f "$CLAUDE_DIR/$name" ]; then
            rm -f "$CLAUDE_DIR/$name"
            removed=$((removed + 1))
        fi
    done < "$MANIFEST"
    rm -f "$MANIFEST"
elif [ -n "$SRC" ]; then
    # No manifest (an older manual install): remove only files identical to ours
    for name in "${KNOWN[@]}"; do
        if [ -f "$CLAUDE_DIR/$name" ] && cmp -s "$CLAUDE_DIR/$name" "$SRC/scripts/$name"; then
            rm -f "$CLAUDE_DIR/$name"
            removed=$((removed + 1))
        fi
    done
fi
[ "$removed" -gt 0 ] && echo "Removed $removed scripts from ~/.claude/"

# 3. Remove our statusLine, only if it is exactly ours (jq if present, else plutil)
if [ -f "$SETTINGS" ]; then
    TMP=$(mktemp)
    if command -v jq >/dev/null 2>&1; then
        if jq -e --arg c "$STATUSLINE_CMD" '.statusLine == {"type":"command","command":$c}' "$SETTINGS" >/dev/null 2>&1 \
            && jq 'del(.statusLine)' "$SETTINGS" > "$TMP" 2>/dev/null; then
            cat "$TMP" > "$SETTINGS"
            echo "Removed our statusLine from ~/.claude/settings.json"
        fi
    else
        CUR_CMD=$(plutil -extract statusLine.command raw -o - "$SETTINGS" 2>/dev/null || true)
        CUR_TYPE=$(plutil -extract statusLine.type raw -o - "$SETTINGS" 2>/dev/null || true)
        KEYS=$(plutil -extract statusLine json -o - "$SETTINGS" 2>/dev/null | tr -cd ',' | wc -c | tr -d ' ')
        if [ "$CUR_CMD" = "$STATUSLINE_CMD" ] && [ "$CUR_TYPE" = "command" ] && [ "$KEYS" = "1" ]; then
            cp "$SETTINGS" "$TMP" && plutil -remove statusLine "$TMP" 2>/dev/null && cat "$TMP" > "$SETTINGS" \
                && echo "Removed our statusLine from ~/.claude/settings.json"
        fi
    fi
    rm -f "$TMP"
    # We created settings.json and nothing else is in it now: remove it
    if [ "$SETTINGS_CREATED" = "1" ] && [ "$(tr -d ' \n\t' < "$SETTINGS")" = "{}" ]; then
        rm -f "$SETTINGS"
    fi
fi

# 4. --purge: config, Mobile Mode state, and the clone at STP_DIR
if [ "$PURGE" = "1" ]; then
    for f in screen-to-phone-config.sh imessage-agent-on imessage-yesall imessage-ask-active \
             imessage-startup-lock imessage-sent-recent imessage-sent-recent.tmp imessage-mobile-target; do
        rm -f "${CLAUDE_DIR:?}/$f"
    done
    echo "Removed ~/.claude/screen-to-phone-config.sh and Mobile Mode state"
    if is_our_checkout "$STP_DIR" && [ "$STP_DIR" != "$HOME" ] && [ "$STP_DIR" != "/" ]; then
        rm -rf "$STP_DIR"
        echo "Removed the clone at $STP_DIR"
    fi
else
    [ -f "$CLAUDE_DIR/screen-to-phone-config.sh" ] && echo "Kept ~/.claude/screen-to-phone-config.sh (use --purge to delete it)"
fi

echo "Claude Screen to Phone uninstalled."
exit 0
