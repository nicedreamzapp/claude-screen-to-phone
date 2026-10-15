---
title: Troubleshooting iMessage sends, chat.db access and Mobile Mode
description: Fixes for Claude Screen to Phone error messages - config.sh not found, messages not sending, chat.db permission denied, TIMEOUT replies, Mobile Mode not forwarding, video compression failures.
---

# Troubleshooting

The repo has no GitHub issues filed yet (checked October 2026), so this page is built from the error messages in the code and the troubleshooting notes in the README.

## `❌ config.sh not found. Run setup.sh first.`

Printed by `imessage-send.sh`, `-send-image.sh`, `-send-video.sh`, `-ask.sh` and the listener when neither `../config.sh` nor `~/.claude/screen-to-phone-config.sh` exists. Run `bash setup.sh` twice: once to create `config.sh`, then again after filling it in.

## Messages won't send

- Allow **Accessibility** for Terminal (or the app running Claude Code). The scripts press Cmd+V and Return through System Events, which fails silently or with an `osascript` error without it.
- Check `BUDDY` includes the country code, e.g. `+15551234567`.
- A message containing a double quote `"` or a backslash can break the send. `imessage-send.sh` and `imessage-ask.sh` put the text inside an AppleScript string literal without escaping it, so `osascript` reports a syntax error. TODO-VERIFY: not escaped in code; avoid `"` in messages until fixed.

## `chat.db` permission denied, or replies always `TIMEOUT`

- Grant **Full Disk Access** to Terminal (or your Claude Code app). Without it `sqlite3` can't open `~/Library/Messages/chat.db`; the scripts send errors to `/dev/null`, so this shows up as a `0` baseline and then `TIMEOUT`.
- `imessage-receive.sh` and `imessage-agent.sh` don't load `config.sh`. Run on their own, they watch every conversation unless `BUDDY` and `APPLE_ID_EMAIL` are exported in your shell. `imessage-ask.sh` and the listener do load it.
- Check that `BUDDY` or `APPLE_ID_EMAIL` actually appears in the chat identifier for your thread in Messages.

## Reply picked up from the wrong chat

Same cause as above. With empty `BUDDY` and `APPLE_ID_EMAIL` the filter becomes `LIKE '%%'`, which matches every chat. Export both, or call `imessage-ask.sh`, which sources config.

## `File not found: …` / `Usage: …`

Printed by the image and video senders when the path is missing or wrong. They resolve the path with `realpath`, so relative paths work from the current directory.

## `Compression failed`

`imessage-send-video.sh` printed this because `ffmpeg` exited non-zero. Check:

- `FFMPEG` in `config.sh` points at a real binary (`which ffmpeg`), then re-run `setup.sh` to copy the config.
- `ffprobe` is on `PATH`. The duration comes from `ffprobe`; if it's missing, the bitrate math divides by an empty value.
- Your ffmpeg build includes `h264_videotoolbox` (Homebrew's macOS build does).

## `Send failed — check Messages app permissions`

The video AppleScript returned an error. Allow Accessibility, and Automation for Finder, Messages and System Events if macOS asks. The video path also activates **Brave Browser** at the end; if Brave isn't installed, that line can fail the script. TODO-VERIFY on a Mac without Brave.

## Video arrives as nothing

The Finder copy method is needed because AppleScript's `send file` returns success without delivering on macOS Sequoia (per the README). Don't replace `imessage-send-video.sh` with a `send file` call.

## Mobile Mode says ON but nothing gets forwarded

Look at `/tmp/imessage-listener.log`.

| Log line | Cause | Fix |
|---|---|---|
| `No such file` for `imessage-listener.sh` | `setup.sh` does not copy the listener | `cp scripts/imessage-listener.sh ~/.claude/` |
| `no target window saved, exiting` | `imessage-mobile-target` missing | Run the toggle again from the Terminal tab you want |
| `target file missing TARGET_TTY, exiting` | Target file is empty | Toggle off, then on |
| `[applescript: ERROR: no Terminal tab with tty …]` | That tab was closed, or you're in iTerm/another terminal | Re-toggle from a Terminal.app tab |
| nothing after `listener started` | Full Disk Access, or `imessage-startup-lock` left behind | Grant access; `rm ~/.claude/imessage-startup-lock` |

Toggle itself can fail with `ERROR: couldn't find a controlling tty by walking parent process chain` when run from something with no TTY (a GUI app or a background job). Run it from a Terminal tab.

## Statusline says OFF when the flag exists

That's intended. It only shows ON when `imessage-listener.pid` exists and that process is alive, so a stale flag from a crashed session reads OFF. Toggle off and on again to restart the listener.

## Every question returns `YES` without asking

`~/.claude/imessage-yesall` exists because someone replied "yes to all". Delete it.

## Browser agent

| Message | Cause |
|---|---|
| `No browser pages` | Brave not running with `--remote-debugging-port=9222`, or no open tab. `CDP_URL` overrides the address |
| `Task failed: URLError …` | Nothing listening at `MLX_URL` (default `http://localhost:4000`) |
| `Step N (no tool)` | The model reply had no parsable `{"tool": …}` JSON; the agent asks again |
| `Reached max steps (30)` | Raise `MAX_STEPS` or narrow the task |
| `mobile mode is off` | Media tools only send when `~/.claude/imessage-agent-on` exists |
| `refused: that's a Google Images thumbnail` | URL is from `encrypted-tbn*.gstatic.com` |
| `failed: download too small` | Downloaded file under 5000 bytes, usually an HTML error page |
| `studio not reachable` / `start failed` | Studio Record isn't running. The agent only auto-starts it if `~/Desktop/Screen Recordings/studio_record.py` and `.venv/bin/python` exist there |

Pointing `MLX_URL` at Anthropic's hosted API does not work as-is: the agent sends no API key or version header.

## Studio Record

- `Camera unavailable — check Privacy settings`: grant Camera access to Terminal/Python.
- Black or empty screen recordings: grant Screen Recording.
- No backgrounds in the picker: copy images into `~/Desktop/Screen Recordings/backgrounds/`. The repo folder isn't read.
- ffmpeg not found on an Intel Mac: the path is hard-coded to `/opt/homebrew/bin/ffmpeg`.
