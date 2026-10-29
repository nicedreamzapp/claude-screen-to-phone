---
title: How it works - reading chat.db and driving Messages with AppleScript
description: Architecture of Claude Screen to Phone - how replies are read from the macOS Messages SQLite database, how sends use the clipboard, how Mobile Mode types into Terminal, and how Studio Record and the separate browser agent fit in.
---

# How it works

```
iPhone ──iMessage (Apple)──► Mac: ~/Library/Messages/chat.db
                                   │
                    sqlite3 poll   │  (receive: every 3 s, listener: every 2 s)
                                   ▼
             imessage-listener.sh ──pbcopy + Cmd+V + Return──► Terminal tab (Claude Code)
                                                                    │
                                                     runs tools, then calls
                                                                    ▼
             imessage-send*.sh ──clipboard + imessage://BUDDY + Cmd+V──► Messages ──► iPhone
```

There is no server process of its own apart from the optional listener daemon and Studio Record. Every step is a shell script calling `sqlite3`, `osascript` or `ffmpeg`.

## Reading replies

All readers run the same query shape against `~/Library/Messages/chat.db`:

```sql
SELECT m.ROWID, m.text
FROM message m
JOIN chat_message_join cmj ON m.ROWID = cmj.message_id
JOIN chat c ON cmj.chat_id = c.ROWID
WHERE (c.chat_identifier LIKE '%<APPLE_ID_EMAIL or BUDDY>%'
    OR c.chat_identifier LIKE '%<BUDDY without +>%')
  AND m.ROWID > <last seen>
  AND m.text IS NOT NULL AND m.text != ''
```

The comment in `imessage-receive.sh` explains the design choice: because the phone and Mac share one Apple ID, messages can show `is_from_me = 1` either way, so the scripts don't filter on sender. They take "anything new after the row I started from" and skip text that matches what they just sent.

- `imessage-receive.sh` returns the newest new row (`ORDER BY ROWID DESC LIMIT 1`). If several texts arrive between polls, only the last is returned.
- The listener walks all new rows in order (`ORDER BY ROWID ASC`).

Only the `text` column is read. TODO-VERIFY: messages whose body lives only in `attributedBody` (which newer macOS versions use for some messages) would have `text` NULL and be ignored.

## Sending

### Text

`imessage-send.sh` appends the message to `imessage-sent-recent`, then one AppleScript:

1. Saves the frontmost app and puts the text on the clipboard.
2. Launches Messages and moves its windows to `{-9999, -9999}` so nothing flashes on screen.
3. `open 'imessage://$BUDDY'` to focus the right thread.
4. Cmd+V, Return.
5. Hides Messages and reactivates the previous app.

Routing every send through `imessage://BUDDY` keeps text and media in the same thread (the script comment says this avoids splitting between email-handle and phone-number threads).

`imessage-ask.sh` is the exception: it sends with `send "$MSG" to buddy "$BUDDY" of (1st service whose service type = iMessage)` instead of the clipboard path.

### Images

`imessage-send-image.sh` reads the file straight onto the clipboard as `«class PNGf»`, `JPEG picture` or `«class GIFf»`, then pastes it the same way.

### Video

The README explains why video is different: on macOS Sequoia, `send file to buddy` reports success but the attachment never arrives. `imessage-send-video.sh` instead selects the file in Finder, presses Cmd+C (which puts a file reference on the clipboard that Messages accepts), opens the thread, pastes, waits 2 s, presses Return, then Cmd+M to minimize Messages and activates Brave Browser.

## Mobile Mode

`imessage-toggle.sh` (ON):

1. Walks up from its parent PID with `ps -o tty=` until it finds a controlling TTY. This picks the Terminal tab that actually ran the command, not just the front window.
2. Writes `TARGET_TTY=/dev/ttys…` to `imessage-mobile-target`, creates `imessage-agent-on`.
3. Starts `imessage-listener.sh` with `nohup`, saves its PID, texts a confirmation.

`imessage-listener.sh` loop, every 2 s while the flag exists:

- If `imessage-startup-lock` exists: wait, don't advance.
- If `imessage-ask-active` exists: advance the pointer to the latest row so the ask script owns that reply.
- Otherwise, for each new row:
    - skip if the same text was sent by `imessage-send.sh` within 60 s (iCloud echo)
    - if the text is `stop` (any case), run the toggle to turn off and exit
    - replace newlines with spaces, `pbcopy`, then AppleScript finds the Terminal tab whose `tty` matches, selects it, brings Terminal to the front, Cmd+V, Return
    - log `forwarded ROWID=…` to `/tmp/imessage-listener.log`, sleep 0.5 s

OFF removes the flag, kills the PID, deletes the target file and texts "iMessage Agent is OFF".

Because the listener uses the clipboard, anything you had copied on the Mac is overwritten by each forwarded text.

## Browser agent

The browser and shell agent lives in [browser-agent](https://github.com/nicedreamzapp/browser-agent). Its broker owns the browser's debug port 9222 as a proxy and leases each agent its own background tab, so nothing here launches Brave with a debug port. The agent (`python ~/.browser-agent/agent.py "task"`) reaches the phone through this repo: when `~/.claude/imessage-agent-on` exists it texts results, screenshots and media with `~/.claude/imessage-send.sh`, `-send-image.sh` and `-send-video.sh`.

## Studio Record

A [CustomTkinter](https://github.com/TomSchimansky/CustomTkinter) window with a [Flask](https://flask.palletsprojects.com/) API in a background thread.

- **Screen mode:** `ffmpeg -f avfoundation -i "<screen index>:none"` captures the display; the mic is recorded separately with `sounddevice`, and the two are muxed on stop. The screen index is found by parsing `ffmpeg -list_devices` for "capture screen".
- **Face mode:** OpenCV reads camera 0 at 1280×720; each frame is optionally composited onto a background, resized to 1920×1080 and piped into ffmpeg.
- **Screen + face:** screen recording plus a floating picture-in-picture camera window.
- **Background removal:** Apple Vision `VNGeneratePersonSegmentationRequest` at Balanced quality, run every 3rd frame and cached. The code comment cites 14 ms per frame on M-series. TODO-VERIFY: that number is from a code comment, not a benchmark in the repo.

!!! note "About the MediaPipe model"
    The code defines `MODEL_PATH` for MediaPipe's `selfie_segmenter.tflite` and has a MediaPipe fallback branch, but `self.segmentor` is never assigned anywhere in the file. As written, only Apple Vision does segmentation, and the downloaded model file is not loaded. TODO-VERIFY with the author whether the fallback was meant to be wired up.

The sound toggle, when off, lowers the system input volume to 0 via AppleScript and restores the previous value afterwards.

## Video template

`build_production_video.py` runs seven printed steps: TTS intro voice-over via `curl`, a Pillow-rendered title card, a cut of fixed keep-segments, subtitle overlays from a fixed list, an end card, concatenation, and a final report. It does not detect silence or transcribe; the segment times and captions are typed in by hand.
