#!/bin/bash
# Ask a yes/no question via iMessage — short, clean, phone-friendly
# Usage: imessage-ask.sh "what" "why" [timeout]
# Example: imessage-ask.sh "Deploy to prod" "All tests pass"
#
# Sends:
#   🔔 Deploy to prod
#   All tests pass
#   → Yes / Yes to All / No
#
# Returns one of: YES, NO, YES_TO_ALL, TIMEOUT, or the user's custom text reply.
# ─────────────────────────────────────────────
DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$DIR/../config.sh"
[ ! -f "$CONFIG" ] && CONFIG="$HOME/.claude/screen-to-phone-config.sh"
if [ ! -f "$CONFIG" ]; then echo "❌ config.sh not found. Run setup.sh first."; exit 1; fi
source "$CONFIG"

WHAT="$1"
WHY="$2"
TIMEOUT=${3:-600}
YESALL_FILE="$HOME/.claude/imessage-yesall"

# Auto-approve mode
if [ -f "$YESALL_FILE" ]; then
    echo "YES"
    exit 0
fi

# Build the short message
if [ -n "$WHY" ]; then
    MSG=$(printf "🔔 %s\n%s\n→ Yes / Yes to All / No" "$WHAT" "$WHY")
else
    MSG=$(printf "🔔 %s\n→ Yes / Yes to All / No" "$WHAT")
fi

# Send it (delegates to imessage-send.sh which handles BUDDY)
bash "$DIR/imessage-send.sh" "$MSG"

# Wait for reply
REPLY=$(bash "$DIR/imessage-receive.sh" "$TIMEOUT")

if [ -z "$REPLY" ] || [ "$REPLY" = "TIMEOUT" ]; then
    echo "TIMEOUT"
    exit 1
fi

# Normalize and classify
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
