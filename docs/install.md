---
title: Install Claude Screen to Phone on macOS
description: Requirements, macOS permissions and the setup.sh steps for installing the Claude Screen to Phone iMessage scripts into ~/.claude/.
---

# Install

## Requirements

| Need | Why | Notes |
|---|---|---|
| A Mac | All scripts use AppleScript, `osascript`, `pbcopy` and `screencapture` | README lists macOS 12+. TODO-VERIFY: not checked against older versions in code |
| Messages signed into your Apple ID | Sending and reading texts | The phone and the Mac must share the same iMessage account |
| `sqlite3` | Reading `~/Library/Messages/chat.db` | Ships with macOS |
| [Claude Code](https://claude.ai/code) | The agent the scripts are built for | By Anthropic |
| `ffmpeg` and `ffprobe` | Video compression in `imessage-send-video.sh`, and Studio Record | `brew install ffmpeg` |
| `jq` (optional) | Lets `setup.sh` add the statusline to `~/.claude/settings.json`; `statusline.sh` also uses it to read context usage | `brew install jq` |
| Terminal.app | Mobile Mode finds the target tab by TTY through Terminal's AppleScript dictionary | iTerm and other terminals are not supported |
| Python 3 + `websockets` | Browser agent only | `pip install websockets` |
| Python 3 + Studio Record deps | Studio Record only | `pip install -r studio-record/requirements.txt` |
| Brave Browser | Browser agent only | `imessage-send-video.sh` also activates Brave when it finishes |

## Steps

```bash
# 1. Clone
git clone https://github.com/nicedreamzapp/claude-screen-to-phone
cd claude-screen-to-phone

# 2. First run creates config.sh from config.example.sh, then exits
bash setup.sh

# 3. Fill in BUDDY, APPLE_ID_EMAIL and FFMPEG
nano config.sh

# 4. Second run installs everything into ~/.claude/
bash setup.sh

# 5. Mobile Mode only: setup.sh does not copy the listener, so copy it yourself
cp scripts/imessage-listener.sh ~/.claude/
```

### What `setup.sh` does on the second run

Read from [`setup.sh`](https://github.com/nicedreamzapp/claude-screen-to-phone/blob/main/setup.sh):

1. `chmod +x scripts/*.sh`
2. Creates `~/.claude/` if needed and copies these eight scripts into it: `imessage-send.sh`, `imessage-send-image.sh`, `imessage-send-video.sh`, `imessage-toggle.sh`, `imessage-receive.sh`, `imessage-ask.sh`, `imessage-agent.sh`, `statusline.sh`.
3. If `jq` is installed, sets `statusLine` in `~/.claude/settings.json` to `{"type":"command","command":"bash ~/.claude/statusline.sh"}`. Other keys in the file are kept. Without `jq` it prints a warning and skips this.
4. Copies `config.sh` to `~/.claude/screen-to-phone-config.sh`.

It does not copy `imessage-listener.sh`, `browser-agent.py` or Studio Record. The script uses `set -e`, so any failed copy stops it.

!!! note "Re-run after editing config.sh"
    The installed scripts read `~/.claude/screen-to-phone-config.sh`, which is a copy. If you change `config.sh` later, run `bash setup.sh` again.

## macOS permissions

Grant these in **System Settings → Privacy & Security** to the app that runs the scripts (Terminal, or whatever launches Claude Code):

| Permission | Needed for |
|---|---|
| Full Disk Access | Reading `~/Library/Messages/chat.db` |
| Accessibility | `System Events` keystrokes (Cmd+V, Return) into Messages and Terminal |
| Screen Recording | `screencapture` in the browser agent, and Studio Record screen mode |
| Camera / Microphone | Studio Record face mode and audio |

The first send will fail until Accessibility is allowed.

## Optional: Studio Record

The app reads and writes everything under `~/Desktop/Screen Recordings/` (hard-coded in `studio_record.py`):

```bash
pip install -r studio-record/requirements.txt
mkdir -p ~/Desktop/Screen\ Recordings/backgrounds
cp studio-record/backgrounds/* ~/Desktop/Screen\ Recordings/backgrounds/
python studio-record/studio_record.py
```

The code uses `/opt/homebrew/bin/ffmpeg` (hard-coded), so on an Intel Mac with Homebrew in `/usr/local` you would need to edit `FFMPEG` at the top of `studio_record.py`.

For background removal the code first tries Apple's Vision framework through PyObjC (`import Vision`, `Foundation`, `objc`). Those packages are not in `requirements.txt`. TODO-VERIFY: whether `pyobjc-framework-Vision` needs to be installed separately on a clean machine. See [How it works](how-it-works.md#studio-record) for the MediaPipe model note.

## Optional: browser agent

```bash
pip install websockets
open -a "Brave Browser" --args --remote-debugging-port=9222
python browser-agent.py "Find an article about X and screenshot it"
```

It needs a model server speaking the Anthropic Messages API at `$MLX_URL/v1/messages` (default `http://localhost:4000`). That server is not part of this repo. See [Configuration](configuration.md#browser-agent-environment-variables).
