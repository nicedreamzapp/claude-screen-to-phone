#!/bin/bash
# Send an arbitrary question via iMessage and wait for the reply.
# Like imessage-ask.sh but without the Yes/No/YesToAll structure — for free-form Q&A.
# Usage: imessage-agent.sh "Your question" [timeout_seconds]
# ─────────────────────────────────────────────
DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG="$DIR/../config.sh"
[ ! -f "$CONFIG" ] && CONFIG="$HOME/.claude/screen-to-phone-config.sh"
if [ ! -f "$CONFIG" ]; then echo "❌ config.sh not found. Run setup.sh first."; exit 1; fi
source "$CONFIG"

QUESTION="$1"
TIMEOUT=${2:-600}
YESALL_FILE="$HOME/.claude/imessage-yesall"

if [ -z "$QUESTION" ]; then
    echo "Usage: imessage-agent.sh 'question' [timeout_seconds]"
    exit 1
fi

# Auto-approve mode short-circuits everything
if [ -f "$YESALL_FILE" ]; then
    echo "YES"
    exit 0
fi

bash "$DIR/imessage-send.sh" "$QUESTION"
REPLY=$(bash "$DIR/imessage-receive.sh" "$TIMEOUT")

if [ -z "$REPLY" ] || [ "$REPLY" = "TIMEOUT" ]; then
    echo "TIMEOUT"
    exit 1
fi

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
