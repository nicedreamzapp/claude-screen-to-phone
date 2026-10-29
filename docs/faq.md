---
title: FAQ - Claude Code over iMessage on Mac
description: Common questions about Claude Screen to Phone - does it need a server, is it private, does it work with iTerm or Windows, can it use a local model, does it cost anything.
---

# FAQ

## Do I need to install anything on the iPhone?

No. You text the Mac from the normal Messages app. The Mac side reads the Messages database and drives the Messages app.

## Is there a server or cloud service?

No server of its own. Two things still leave the Mac: iMessage traffic goes through Apple, and stock Claude Code sends your prompts to Anthropic's API. The README points to [`claude-code-local`](https://github.com/nicedreamzapp/claude-code-local) for running Claude Code against a local model instead.

## Does it work on Windows or Linux?

No. It uses AppleScript, the Messages app, `pbcopy`, `screencapture` and `h264_videotoolbox`, all macOS-only.

## Does Mobile Mode work with iTerm2, Warp or the VS Code terminal?

No. The listener finds the target tab by asking Terminal.app for a tab whose `tty` matches. Other terminals aren't supported by the code.

## Why iMessage and not Telegram or Discord?

iMessage is already on the Mac and phone, so there's no bot account, extra app or third-party service to set up. The trade-off is that it only works on Apple devices.

## Why does sending use the clipboard?

Pasting into the thread opened by `imessage://BUDDY` keeps text, images and video in the same conversation. For video, AppleScript's `send file` reports success without delivering on macOS Sequoia (per the README), so the script copies the file from Finder instead. See [How it works](how-it-works.md#sending).

## Will it overwrite what I copied?

Yes. Every send and every forwarded Mobile Mode text replaces the clipboard.

## Can I use a local model instead of Claude?

Mobile Mode doesn't care what runs in the Terminal tab; it just types into it. The separate [browser-agent](https://github.com/nicedreamzapp/browser-agent) runs on a local model through the MLX server from [claude-code-local](https://github.com/nicedreamzapp/claude-code-local).

## Can it approve Claude Code's permission prompts from the phone?

Phone texts are typed into the tab and followed by Return, so in principle a reply can answer a prompt that's waiting for typed input. TODO-VERIFY: Claude Code's permission dialogs are menu-driven and may not accept pasted text. The README says the author's launchers start Claude Code with `--dangerously-skip-permissions` for remote use, which removes those prompts and all their safety checks.

## How do I stop it from the phone?

Text `stop`. The listener turns Mobile Mode off and exits.

## Is my phone number committed to git?

`config.sh` is in `.gitignore`. Your number lives in `config.sh` and `~/.claude/screen-to-phone-config.sh` only.

## How long does setup take?

The README badge says 60 seconds. That covers `setup.sh`; granting macOS permissions and installing `ffmpeg`/`jq` take longer depending on your machine. TODO-VERIFY.

## Does it cost anything?

The scripts are MIT licensed and free. Claude Code itself needs whatever Anthropic plan or API access you normally use.

## Are there tests?

No automated tests are in the repo. Everything drives live macOS apps and was tested by hand.
