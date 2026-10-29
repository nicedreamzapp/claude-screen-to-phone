---
title: Control Claude Code from your iPhone over iMessage
description: Claude Screen to Phone is a set of macOS scripts that let you text commands from your iPhone into a Claude Code session on your Mac and get text, images and video back in iMessage.
---

# Claude Screen to Phone

Text your Mac from your iPhone and have Claude Code do the work while you're away from the desk. Results come back in the same iMessage thread as text, screenshots or video.

It is a set of macOS bash, AppleScript and Python scripts. There is no server and no extra app on the phone. The Mac reads incoming texts from the local Messages database (`~/Library/Messages/chat.db`) and sends replies by driving the Messages app.

[Install](install.md){ .md-button .md-button--primary } [Quickstart](quickstart.md){ .md-button }

## Who it's for

People who already run [Claude Code](https://claude.ai/code) (Anthropic's coding agent) in Terminal on a Mac and want to:

- send a task from the phone and have it typed into the running session
- get a short reply, a screenshot, or a screen recording back in Messages
- answer yes/no prompts from the agent without walking back to the keyboard

You need a Mac signed into Messages, an iPhone on the same Apple ID, and Apple's Terminal.app for Mobile Mode. See [Install](install.md) for the full list.

## What's in the repo

| Piece | File | What it does |
|---|---|---|
| Send text | [`scripts/imessage-send.sh`][send] | Pastes a message into the configured iMessage thread and sends it |
| Send image | [`scripts/imessage-send-image.sh`][img] | Loads a PNG, JPEG or GIF onto the clipboard and pastes it into the thread |
| Send video | [`scripts/imessage-send-video.sh`][vid] | Copies the file via Finder and pastes it; re-encodes anything over 95 MB first |
| Wait for a reply | [`scripts/imessage-receive.sh`][recv] | Polls `chat.db` every 3 seconds until a new message arrives or it times out |
| Yes / No prompts | [`scripts/imessage-ask.sh`][ask], [`scripts/imessage-agent.sh`][agent] | Sends a question, waits, returns `YES`, `NO`, `YES_TO_ALL`, `TIMEOUT` or the raw reply |
| Mobile Mode | [`scripts/imessage-toggle.sh`][toggle], [`scripts/imessage-listener.sh`][listen] | Background daemon that pastes each new phone text into a chosen Terminal tab |
| Statusline | [`scripts/statusline.sh`][status] | Claude Code statusline with a context bar and a Mobile Mode ON/OFF flag |
| Browser + shell agent | separate repo, [browser-agent][ba] | Its agent texts results through these scripts; its broker owns port 9222 |
| Studio Record | [`studio-record/studio_record.py`][sr] | Screen and webcam recorder with an HTTP API on `127.0.0.1:17494` |
| Video template | [`scripts/build_production_video.py`][bpv] | Hard-coded template: title card, cut, subtitles, end card |
| Installer | [`install.sh`][install], [`setup.sh`][setup], [`uninstall.sh`][uninstall], [`config.example.sh`][cfg] | One-line install of every script into `~/.claude/`, creates the config once, clean uninstall |

## Screenshots

There is no screenshot, GIF or demo video of the iMessage flow checked into the repo yet. TODO-VERIFY: add one under `docs/assets/` and reference it here.

The only images in the repo are the 32 virtual backgrounds that ship with Studio Record in [`studio-record/backgrounds/`][bgs], for example:

![Studio Record background "golden-hour"](https://raw.githubusercontent.com/nicedreamzapp/claude-screen-to-phone/main/studio-record/backgrounds/golden-hour.jpg){ width="240" loading=lazy }
![Studio Record background "neon-city"](https://raw.githubusercontent.com/nicedreamzapp/claude-screen-to-phone/main/studio-record/backgrounds/neon-city.jpg){ width="240" loading=lazy }

## What it is not

- Not cross-platform. Everything drives macOS apps through AppleScript.
- Not fully offline. The bridge runs on your Mac, but iMessage goes through Apple, and stock Claude Code sends prompts to Anthropic's API. The README points to the sibling repo [`claude-code-local`](https://github.com/nicedreamzapp/claude-code-local) for running the model on the Mac instead.
- Not tested by a test suite. There are no automated tests in the repo; the scripts drive real apps and were tested by hand.

[send]: https://github.com/nicedreamzapp/claude-screen-to-phone/blob/main/scripts/imessage-send.sh
[img]: https://github.com/nicedreamzapp/claude-screen-to-phone/blob/main/scripts/imessage-send-image.sh
[vid]: https://github.com/nicedreamzapp/claude-screen-to-phone/blob/main/scripts/imessage-send-video.sh
[recv]: https://github.com/nicedreamzapp/claude-screen-to-phone/blob/main/scripts/imessage-receive.sh
[ask]: https://github.com/nicedreamzapp/claude-screen-to-phone/blob/main/scripts/imessage-ask.sh
[agent]: https://github.com/nicedreamzapp/claude-screen-to-phone/blob/main/scripts/imessage-agent.sh
[toggle]: https://github.com/nicedreamzapp/claude-screen-to-phone/blob/main/scripts/imessage-toggle.sh
[listen]: https://github.com/nicedreamzapp/claude-screen-to-phone/blob/main/scripts/imessage-listener.sh
[status]: https://github.com/nicedreamzapp/claude-screen-to-phone/blob/main/scripts/statusline.sh
[ba]: https://github.com/nicedreamzapp/browser-agent
[sr]: https://github.com/nicedreamzapp/claude-screen-to-phone/blob/main/studio-record/studio_record.py
[bpv]: https://github.com/nicedreamzapp/claude-screen-to-phone/blob/main/scripts/build_production_video.py
[install]: https://github.com/nicedreamzapp/claude-screen-to-phone/blob/main/install.sh
[setup]: https://github.com/nicedreamzapp/claude-screen-to-phone/blob/main/setup.sh
[uninstall]: https://github.com/nicedreamzapp/claude-screen-to-phone/blob/main/uninstall.sh
[cfg]: https://github.com/nicedreamzapp/claude-screen-to-phone/blob/main/config.example.sh
[bgs]: https://github.com/nicedreamzapp/claude-screen-to-phone/tree/main/studio-record/backgrounds
