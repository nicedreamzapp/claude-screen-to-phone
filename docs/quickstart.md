---
title: Quickstart - send your first iMessage from Claude Code
description: Send a text, image and video to your iPhone, ask a yes/no question, and turn on Mobile Mode so phone texts are typed into your Claude Code session.
---

# Quickstart

This assumes you finished [Install](install.md) and granted Accessibility and Full Disk Access.

## 1. Send a text

```bash
bash ~/.claude/imessage-send.sh "Hello from the Mac"
```

The script briefly opens Messages off-screen, pastes the text into the thread for `BUDDY`, presses Return, hides Messages and returns focus to the app you were in.

## 2. Send an image and a video

```bash
bash ~/.claude/imessage-send-image.sh ~/Desktop/screenshot.png
bash ~/.claude/imessage-send-video.sh ~/Desktop/clip.mp4
```

Images: `.png`, `.jpg`/`.jpeg` and `.gif` are recognised; anything else is loaded as PNG data. Videos larger than 95 MB are re-encoded to `/tmp/imessage-video-compressed.mp4` first.

## 3. Ask a yes/no question

```bash
bash ~/.claude/imessage-ask.sh "Deploy to prod" "All tests pass"
```

Your phone gets:

```
🔔 Deploy to prod
All tests pass
→ Yes / Yes to All / No
```

The script waits up to 600 seconds and prints one of `YES`, `NO`, `YES_TO_ALL`, `TIMEOUT`, or your reply text as-is. Replying "yes to all" creates `~/.claude/imessage-yesall`; after that every ask returns `YES` immediately until you delete the file.

## 4. Tell Claude Code about the scripts

Claude Code reads `CLAUDE.md`. Add something like this to `~/.claude/CLAUDE.md` (the repo's own [`CLAUDE.md`](https://github.com/nicedreamzapp/claude-screen-to-phone/blob/main/CLAUDE.md) is a longer version):

```markdown
## iMessage Agent
bash ~/.claude/imessage-send.sh "msg"
bash ~/.claude/imessage-send-image.sh /path/to/image.png
bash ~/.claude/imessage-send-video.sh /path/to/video.mp4
bash ~/.claude/imessage-ask.sh "what" "why"
bash ~/.claude/imessage-toggle.sh   # Mobile Mode on/off
```

## 5. Turn on Mobile Mode

From inside a Claude Code session running in Terminal.app, run (or ask Claude to run):

```bash
bash ~/.claude/imessage-toggle.sh
```

It prints `ON (listener PID …, target /dev/ttys…)` and texts you a confirmation. From then on, any new text you send in that thread is pasted into that Terminal tab and submitted with Return. Text `stop` to turn it off, or run the toggle again.

!!! warning "Permission prompts"
    Mobile Mode types into the session. It cannot answer Claude Code's own permission dialogs for you unless you reply with the keys they expect. The README notes that the author's launchers start Claude Code with `--dangerously-skip-permissions` for remote use. That flag lets the agent run any tool without asking, so decide for yourself whether that is acceptable on your machine.

## 6. Watch the statusline

If `jq` was installed during setup, the bottom of each Claude Code session shows something like:

```
[CLAUDE CODE] █████░░░░░ 47%  📱 Mobile Mode OFF
```

It only says ON when the flag file exists and the listener process is alive.
