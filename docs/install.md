---
title: Install Claude Screen to Phone on macOS
description: Requirements, macOS permissions and the one-line installer for the Claude Screen to Phone iMessage scripts into ~/.claude/.
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
| `git` | The installer clones the repo | `xcode-select --install` |
| `jq` (optional) | `statusline.sh` uses it to read context usage. The installer uses it to edit `~/.claude/settings.json` and falls back to macOS `plutil` without it | `brew install jq` |
| Terminal.app | Mobile Mode finds the target tab by TTY through Terminal's AppleScript dictionary | iTerm and other terminals are not supported |
| Python 3 + Studio Record deps | Studio Record only | `pip install -r studio-record/requirements.txt` |
| Brave Browser | Not needed here | `imessage-send-video.sh` activates Brave when it finishes. The browser agent is a separate repo, see below |

## Steps

```bash
# 1. Install (clones to ~/claude-screen-to-phone and installs into ~/.claude/)
curl -fsSL https://raw.githubusercontent.com/nicedreamzapp/claude-screen-to-phone/main/install.sh | bash

# 2. Fill in BUDDY, APPLE_ID_EMAIL and FFMPEG
nano ~/.claude/screen-to-phone-config.sh

# 3. Test it
~/.claude/imessage-send.sh "Hello from Claude!"
```

Already have a clone? `bash install.sh` from inside it uses that checkout in place. `STP_DIR` changes where the installer clones to, and `STP_REPO` where it clones from.

### What the installer does

[`install.sh`](https://github.com/nicedreamzapp/claude-screen-to-phone/blob/main/install.sh) clones the repo (or runs `git pull --ff-only` on an existing clone, skipped if you have local edits), then runs [`setup.sh`](https://github.com/nicedreamzapp/claude-screen-to-phone/blob/main/setup.sh), which:

1. Creates `~/.claude/` if needed and copies these nine scripts into it, executable: `imessage-send.sh`, `imessage-send-image.sh`, `imessage-send-video.sh`, `imessage-toggle.sh`, `imessage-receive.sh`, `imessage-listener.sh`, `imessage-ask.sh`, `imessage-agent.sh`, `statusline.sh`.
2. Writes the list of installed files to `~/.claude/.screen-to-phone-installed`, so the uninstaller removes exactly those.
3. Creates `~/.claude/screen-to-phone-config.sh` from `config.example.sh` (or from the clone's `config.sh` if you made one) only if it does not exist yet. A filled-in config is never overwritten.
4. Sets `statusLine` in `~/.claude/settings.json` to `{"type":"command","command":"bash ~/.claude/statusline.sh"}` only if no `statusLine` is set. An existing one is left alone, and other keys are kept.

It asks no questions and is safe to run again. Studio Record is not installed; see below.

### Uninstall

```bash
curl -fsSL https://raw.githubusercontent.com/nicedreamzapp/claude-screen-to-phone/main/uninstall.sh | bash
```

It stops the Mobile Mode listener through `~/.claude/imessage-listener.pid` (only if that process is our listener), removes the installed scripts, and removes the `statusLine` only if it is exactly the one above. Your config stays. Add `-s -- --purge` (or run `bash ~/claude-screen-to-phone/uninstall.sh --purge`) to also delete the config, the Mobile Mode state files and the clone.

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

The browser and shell agent lives in its own repo, [browser-agent](https://github.com/nicedreamzapp/browser-agent). Its broker owns port 9222 as a proxy in front of your real browser, so you don't launch Brave with a debug port yourself:

```bash
curl -fsSL https://raw.githubusercontent.com/nicedreamzapp/browser-agent/main/broker/get.sh | bash
cd ~/.browser-agent
pip install websockets
python agent.py "Find an article about X and screenshot it"
```

The agent leases its own background tab from the broker and talks to it on 9222. It needs the local MLX server from [claude-code-local](https://github.com/nicedreamzapp/claude-code-local). In Mobile Mode it texts screenshots, media and task updates through the `~/.claude/imessage-send*.sh` scripts installed here.
