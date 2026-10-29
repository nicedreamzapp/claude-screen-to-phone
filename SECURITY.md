# Security policy

## Reporting a vulnerability

Please do not open a public issue for security problems.

Report them privately through GitHub: go to the **Security** tab of this repo and click **Report a vulnerability** ([direct link](https://github.com/nicedreamzapp/claude-screen-to-phone/security/advisories/new)). Only the maintainer sees the report.

Helpful details: what you found, how to reproduce it, which commit, your Mac and macOS version, and which script was involved.

I aim to reply within 3 days and to ship a fix or a clear plan within 30 days, depending on severity. You will be credited in the advisory unless you ask not to be.

## Supported versions

Fixes go into the latest code on `main`. Please update before reporting if you are on an older version.

## What matters most here

Mobile Mode turns text messages into keystrokes on your Mac, so the parts where a mistake could hurt someone:

- `scripts/imessage-listener.sh`, which reads `~/Library/Messages/chat.db` and pastes texts from the matched conversation into a Terminal tab running an agent
- `scripts/imessage-receive.sh`, `scripts/imessage-ask.sh` and `scripts/imessage-agent.sh`, which read replies from the Messages database and decide which chat counts as you (including the "Yes to All" flag file)
- Studio Record's HTTP API in `studio-record/studio_record.py`, on `127.0.0.1` port 17494, which starts and stops screen and webcam recording
- `~/.claude/screen-to-phone-config.sh`, created by the installer, which holds your phone number and Apple ID
- `install.sh`, `setup.sh` and `uninstall.sh`, which write into `~/.claude/` and edit `~/.claude/settings.json`
