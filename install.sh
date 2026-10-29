#!/bin/bash
# Claude Screen to Phone installer.
#   curl -fsSL https://raw.githubusercontent.com/nicedreamzapp/claude-screen-to-phone/main/install.sh | bash
# or, from a clone:  bash install.sh
#
# Env: STP_REPO (git URL or local path to clone from), STP_DIR (clone location,
# default ~/claude-screen-to-phone). Runs setup.sh from the checkout, which
# installs the scripts into ~/.claude/. Non-interactive; safe to run again.

set -euo pipefail

STP_REPO="${STP_REPO:-https://github.com/nicedreamzapp/claude-screen-to-phone}"
STP_DIR="${STP_DIR:-$HOME/claude-screen-to-phone}"

is_our_checkout() {
    [ -d "$1/.git" ] && [ -f "$1/setup.sh" ] && [ -f "$1/scripts/imessage-toggle.sh" ]
}

# Running from inside a checkout? Use it in place.
SRC=""
if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
    HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    if is_our_checkout "$HERE"; then
        SRC="$HERE"
    fi
fi

if [ -z "$SRC" ]; then
    command -v git >/dev/null 2>&1 || { echo "git is required (xcode-select --install)" >&2; exit 1; }
    if is_our_checkout "$STP_DIR"; then
        if [ -n "$(git -C "$STP_DIR" status --porcelain --untracked-files=no 2>/dev/null)" ]; then
            echo "Local edits in $STP_DIR, keeping them (skipped git pull)"
        else
            git -C "$STP_DIR" pull --ff-only --quiet || echo "git pull failed in $STP_DIR, using it as is"
        fi
    elif [ -e "$STP_DIR" ]; then
        echo "$STP_DIR exists but is not a claude-screen-to-phone checkout. Set STP_DIR to another path." >&2
        exit 1
    else
        git clone --quiet "$STP_REPO" "$STP_DIR"
    fi
    SRC="$STP_DIR"
fi

bash "$SRC/setup.sh"

echo ""
echo "Done: Claude Screen to Phone installed into ~/.claude/ (source: $SRC)"
echo "Uninstall: curl -fsSL https://raw.githubusercontent.com/nicedreamzapp/claude-screen-to-phone/main/uninstall.sh | bash"
