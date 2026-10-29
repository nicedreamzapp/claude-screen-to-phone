---
title: Changelog
description: History of Claude Screen to Phone built from the git log, from the first release in April 2026 to the latest README updates.
---

# Changelog

The repo has no tags or GitHub releases. This list is built from `git log` on `main`, grouped by date. Commit hashes link to GitHub.

## 2026-10-29

- One-line `install.sh` and `uninstall.sh`; `setup.sh` now installs every script including `imessage-listener.sh`, creates the config once and never overwrites it, and only sets `statusLine` when none is set.
- All iMessage scripts read `~/.claude/screen-to-phone-config.sh` first; `imessage-receive.sh` and `imessage-agent.sh` now load it too.
- The browser agent moved to [browser-agent](https://github.com/nicedreamzapp/browser-agent); `browser-agent.py` is removed from this repo.

## 2026-10-09

- README: add a plain opening and list browser agent requirements ([`edcc5b8`](https://github.com/nicedreamzapp/claude-screen-to-phone/commit/edcc5b8)).

## 2026-10-08

- README: location line updated ([`778f969`](https://github.com/nicedreamzapp/claude-screen-to-phone/commit/778f969)).

## 2026-09-27

- README: add "What I Built", a Known Limits section, and fix claims that didn't match the code ([`7c73a4a`](https://github.com/nicedreamzapp/claude-screen-to-phone/commit/7c73a4a)).

## 2026-09-07

- Remove the example output video from the repo ([`3b5f3c6`](https://github.com/nicedreamzapp/claude-screen-to-phone/commit/3b5f3c6)).

## 2026-08-06

- Add `CREDITS.md` naming upstream work ([`982f110`](https://github.com/nicedreamzapp/claude-screen-to-phone/commit/982f110)).
- Add MIT license ([`1f64ec4`](https://github.com/nicedreamzapp/claude-screen-to-phone/commit/1f64ec4)).

## 2026-04-20

- Enable the GitHub Sponsors button ([`9b39bc2`](https://github.com/nicedreamzapp/claude-screen-to-phone/commit/9b39bc2)).

## 2026-04-19

- **Mobile Mode**: `imessage-listener.sh` daemon that forwards phone texts into a Terminal tab, and general-purpose `shell` / `read_file` / `write_file` and media tools in the browser agent ([`7dcfd0f`](https://github.com/nicedreamzapp/claude-screen-to-phone/commit/7dcfd0f)).
- README rewrite and link to `claude-code-local` ([`1926b75`](https://github.com/nicedreamzapp/claude-screen-to-phone/commit/1926b75), [`66a8c99`](https://github.com/nicedreamzapp/claude-screen-to-phone/commit/66a8c99)).

## 2026-04-07

- Add `statusline.sh`, `imessage-ask.sh` and `imessage-agent.sh`; `setup.sh` now wires the statusline into `~/.claude/settings.json` ([`3321b01`](https://github.com/nicedreamzapp/claude-screen-to-phone/commit/3321b01)).

## 2026-04-02

- First release of the pipeline: send text, image and video, receive replies ([`01f7516`](https://github.com/nicedreamzapp/claude-screen-to-phone/commit/01f7516)).
- Add Studio Record with 32 virtual backgrounds ([`e5578aa`](https://github.com/nicedreamzapp/claude-screen-to-phone/commit/e5578aa)).
- Add the CDP browser agent ([`8e32405`](https://github.com/nicedreamzapp/claude-screen-to-phone/commit/8e32405)).
- Add `CLAUDE.md` for Claude Code integration ([`a405bff`](https://github.com/nicedreamzapp/claude-screen-to-phone/commit/a405bff)).
- README: iMessage method write-up ([`62f9475`](https://github.com/nicedreamzapp/claude-screen-to-phone/commit/62f9475), [`6ae0735`](https://github.com/nicedreamzapp/claude-screen-to-phone/commit/6ae0735)).
- Senders hide Messages after sending and restore the previous app ([`9756a48`](https://github.com/nicedreamzapp/claude-screen-to-phone/commit/9756a48)).
