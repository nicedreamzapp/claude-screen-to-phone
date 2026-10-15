---
title: Configuration reference - config.sh, script arguments and env vars
description: Every option in Claude Screen to Phone read from the source code - config.sh variables, script arguments, state files, statusline labels, browser agent environment variables and Studio Record API.
---

# Configuration

Everything on this page was read from the source. Where the code does something that looks unintended, the page says what the code does and marks it TODO-VERIFY.

## config.sh

Created from [`config.example.sh`](https://github.com/nicedreamzapp/claude-screen-to-phone/blob/main/config.example.sh) by `setup.sh`, then copied to `~/.claude/screen-to-phone-config.sh`. It is gitignored.

| Variable | Example default | Used by | What the code does with it |
|---|---|---|---|
| `BUDDY` | `+1XXXXXXXXXX` | send, send-image, send-video, ask, listener (and receive/agent via env) | Opens `imessage://$BUDDY` to pick the thread. `imessage-ask.sh` uses it as the AppleScript buddy. With the `+` removed it is also matched against `chat.chat_identifier` when reading replies |
| `APPLE_ID_EMAIL` | `you@example.com` | ask, listener, receive, agent | If set, the reply readers match chats whose identifier contains this value; if empty they fall back to `BUDDY`. The phone-number match is always added too |
| `FFMPEG` | `/opt/homebrew/bin/ffmpeg` | `imessage-send-video.sh` | Path to the encoder used to compress videos over 95 MB. `ffprobe` is called from `PATH`, not from this variable |
| `RECORDINGS_DIR` | `$HOME/Desktop/Screen Recordings` | nothing | Not read by any script. Studio Record and the browser agent hard-code `~/Desktop/Screen Recordings` |
| `TTS_URL` | `http://localhost:8000/tts` | nothing | Not read by any script. `build_production_video.py` has its own `TTS_URL` constant with the same value |

### How scripts find config

Each script that loads config tries, in order:

1. `$(dirname "$0")/../config.sh`
2. `~/.claude/screen-to-phone-config.sh`

When run from the repo (`scripts/…`), step 1 is the repo's `config.sh`. When run from `~/.claude/`, step 1 resolves to `~/config.sh` in your home directory. TODO-VERIFY: if a file named `~/config.sh` exists for some other reason, the installed scripts will source it instead of the installed copy.

`imessage-receive.sh` and `imessage-agent.sh` do **not** load config. Run on their own they only see `BUDDY` and `APPLE_ID_EMAIL` if exported in the environment. When both are empty, the `LIKE '%%'` filter matches every conversation. (`imessage-agent.sh` still sends through `imessage-send.sh`, which does load config.)

## Script arguments

| Script | Arguments | Defaults | Output |
|---|---|---|---|
| `imessage-send.sh` | `"message"` | none | none on success |
| `imessage-send-image.sh` | `/path/to/image` | none | `Sent: <path>` |
| `imessage-send-video.sh` | `/path/to/video` | none | `Video: …`, optional `Compressed to …MB`, `Sent: …` |
| `imessage-receive.sh` | `[timeout_s] [since_rowid] [sent_text]` | `300`, `0` (= latest row now), empty | The newest message text after `since_rowid`, or `TIMEOUT` (exit 1). Polls every 3 s |
| `imessage-ask.sh` | `"what" ["why"] [timeout_s]` | timeout `600` | `YES`, `NO`, `YES_TO_ALL`, `TIMEOUT`, or the raw reply |
| `imessage-agent.sh` | `"question" [timeout_s]` | timeout `600` | same as ask |
| `imessage-toggle.sh` | none | | `ON (listener PID …, target …)` or `OFF` |

### Reply keywords (ask and agent)

The reply is lower-cased and trimmed, then matched exactly:

| Returns | Replies that match |
|---|---|
| `YES` | yes, y, ok, do it, go, go ahead, yes 👍, 👍, yep, yeah, sure, approved |
| `YES_TO_ALL` | yes to all, yta, yes all, approve all, do everything (also creates `imessage-yesall`) |
| `NO` | no, n, stop, dont, don't, cancel, reject, nope, 👎 |
| raw text | anything else |

### Video compression

`imessage-send-video.sh` compresses when `du -m` reports more than `MAX_MB=95`. Target video bitrate in kbit/s is `(95 × 8192) / duration × 0.85`, encoded with `h264_videotoolbox`, AAC audio at 128k, `+faststart`. Output goes to `/tmp/imessage-video-compressed.mp4` (overwritten each time).

## State files

All live next to the scripts, so `~/.claude/` after install. The statusline and browser agent hard-code `~/.claude/`.

| File | Written by | Meaning |
|---|---|---|
| `imessage-agent-on` | toggle | Mobile Mode flag. The listener loops while it exists; the browser agent texts updates only when it exists |
| `imessage-mobile-target` | toggle | `TARGET_TTY=/dev/ttysNNN` for the listener |
| `imessage-listener.pid` | toggle | PID of the background listener |
| `imessage-sent-recent` | send | `epoch<TAB>text` of recent sends, trimmed to 50 lines. The listener skips an incoming text that matches one sent in the last 60 s |
| `imessage-ask-active` | ask, agent | While present the listener does not forward and moves its pointer past new messages |
| `imessage-startup-lock` | your launcher (not in repo) | While present the listener waits and does not advance its pointer, so texts are forwarded after startup |
| `imessage-yesall` | ask, agent | Every later ask returns `YES` without sending. Delete it to turn this off |
| `/tmp/imessage-listener.log` | toggle | Listener stdout/stderr |

## Statusline

[`scripts/statusline.sh`](https://github.com/nicedreamzapp/claude-screen-to-phone/blob/main/scripts/statusline.sh) reads Claude Code's statusline JSON on stdin and uses `.context_window.used_percentage` (needs `jq`; falls back to 0).

- Bar: 10 cells. Color red at 90% and up, yellow 70 to 89, cyan 40 to 69, green below 40.
- Mobile flag: ON only if `~/.claude/imessage-agent-on` and `~/.claude/imessage-listener.pid` both exist and that PID is alive.
- Agent tag from `CLAUDE_SESSION_LABEL` (matched by prefix):

| `CLAUDE_SESSION_LABEL` starts with | Tag |
|---|---|
| `Llama 70B` | `LLAMA 70B` |
| `Gemma 4 Browser` | `GEMMA BROWSER` |
| `Gemma 4` | `GEMMA CODE` |
| `Browser Agent` | `BROWSER AGENT` |
| `Claude Code` | `CLAUDE CODE` |
| `NarrativeClaude` | `NARRATE` |
| empty | no tag |
| anything else | the label as-is |

The script defines a `YESALL_FLAG` path but does not display it.

## Browser agent environment variables

From [`browser-agent.py`](https://github.com/nicedreamzapp/claude-screen-to-phone/blob/main/browser-agent.py):

| Env var | Default | Effect |
|---|---|---|
| `MLX_URL` | `http://localhost:4000` | Base URL; the agent POSTs to `$MLX_URL/v1/messages` with only a `Content-Type` header (no API key) |
| `MLX_MODEL_NAME` | `claude-sonnet-4-6` | Sent as `model` in each request. The server decides what this means |
| `CDP_URL` | `http://127.0.0.1:9222` | Chrome DevTools endpoint. The agent attaches to the first `page` target |
| `MAX_STEPS` | `30` | Tool calls per task before giving up |

Command line: `python browser-agent.py "task"` runs one task and exits. With no arguments it loops on a `What should I do?` prompt; `quit`, `exit` or `q` leaves.

Fixed values in the code:

| Setting | Value |
|---|---|
| Request | `max_tokens` 1024, `temperature` 0.3, 120 s timeout |
| History | first message plus last 8 kept once over 10 |
| Tool result | cut at 4000 chars |
| `shell` | `/bin/bash -lc` in `$HOME`, default timeout 60 s, output cut at 3500 chars |
| `read_file` | first 8000 bytes; directories list up to 200 entries |
| Downloads | `~/Downloads/gemma-agent/` |
| Media send | refuses files under 5000 bytes, `encrypted-tbn0..3.gstatic.com` image URLs, and repeats in the same process |
| Phone summary | trimmed to 500 chars, sent only when Mobile Mode is on |

Tools the model can call: `navigate`, `snapshot`, `click`, `type_text`, `scroll`, `js`, `shell`, `read_file`, `write_file`, `screenshot`, `fullscreen_shot`, `send_image`, `send_video`, `record_start`, `record_stop`, `record_status`, `done`. The dispatcher also handles a `comment` tool that drafts (does not submit) a comment in a page's comment widget. It is not listed in the system prompt. A `generate_comment()` helper exists but nothing calls it.

!!! danger "The shell tool runs anything"
    `shell` and `write_file` run with your user's permissions and no confirmation step. Whatever the model returns gets executed.

## Studio Record

From [`studio-record/studio_record.py`](https://github.com/nicedreamzapp/claude-screen-to-phone/blob/main/studio-record/studio_record.py). There are no flags or env vars; these are constants at the top of the file.

| Constant | Value |
|---|---|
| `FFMPEG` | `/opt/homebrew/bin/ffmpeg` |
| `OUT_DIR` | `~/Desktop/Screen Recordings` |
| `BG_DIR` | `~/Desktop/Screen Recordings/backgrounds` (`.jpg .jpeg .png .webp .bmp`) |
| `MODEL_PATH` | `~/Desktop/Screen Recordings/selfie_segmenter.tflite` |

HTTP API on `127.0.0.1:17494`:

| Method + path | Query | Returns |
|---|---|---|
| `POST /start` | `mode=screen` (default), `face`, `screen_face`; unknown values become `screen` | `{"status":"recording","outpath":…,"mode":…}` |
| `POST /stop` | | `{"status":"stopped","outpath":…}`; waits up to 30 s for the file to appear |
| `GET /status` | | `{"recording":bool,"outpath":…,"mode":…,"duration":seconds}` |

Output names: `screen-YYYYmmdd-HHMMSS.mp4`, `facecam-…`, `facecam-bg-…`, `screen-facecam-…`, `screen-facecam-bg-…`. Video is 30 fps `h264_videotoolbox` at 10 Mbit/s; audio is 48 kHz mono 16-bit from `sounddevice`. Microphones whose names contain usb, rode, yeti or shure are preferred, then a MacBook mic, then the system default.

## build_production_video.py

A template, not a tool. The paths, voice-over text, keep-segments and subtitle lines are hard-coded constants at the top and in the body. It has no arguments. Edit `INPUT`, `LOGO`, `OUTPUT`, `TTS_URL`, the `segs` list and `subtitle_data` before running. It expects macOS system fonts in `/System/Library/Fonts/` and a TTS server that accepts `POST` with a `text` form field.
