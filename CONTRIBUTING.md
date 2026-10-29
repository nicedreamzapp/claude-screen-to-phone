# Contributing

Thanks for taking a look. These scripts lean on macOS, Messages and AppleScript, which change
between macOS versions, so a clear bug report is useful even if you never send code.

## Reporting a problem

Open an [issue](https://github.com/nicedreamzapp/claude-screen-to-phone/issues/new/choose). The
things that make it quick to fix:

- your Mac and macOS version, and your iPhone's iOS version
- which script you ran, and the exact command
- which permissions you granted (Full Disk Access, Accessibility, Screen Recording)
- for Mobile Mode, the last lines of `/tmp/imessage-listener.log`
- what arrived on the phone, if anything

Please remove your phone number, Apple ID and message text before posting.

## Running it locally

```bash
git clone https://github.com/nicedreamzapp/claude-screen-to-phone
cd claude-screen-to-phone
bash install.sh        # uses this checkout, installs every script into ~/.claude/
nano ~/.claude/screen-to-phone-config.sh   # set BUDDY, APPLE_ID_EMAIL and FFMPEG
~/.claude/imessage-send.sh "Hello"
bash uninstall.sh      # removes what install.sh put in ~/.claude/ (config kept)
```

Run `bash install.sh` again after editing a script so the copy in `~/.claude/` updates.

Studio Record: `cd studio-record && pip install -r requirements.txt`, then
`python studio-record/studio_record.py` from the repo root. The browser agent lives in
[browser-agent](https://github.com/nicedreamzapp/browser-agent).

## Tests

There is no test suite. Before sending a change, check by hand on a Mac: send a text, an image
and a video with the `imessage-send*.sh` scripts, reply to `imessage-ask.sh` from the phone, and
if you touched Mobile Mode, turn it on with `imessage-toggle.sh`, text a command, then text "stop".

## Pull requests

Small and focused is easiest to review. For big changes, open an issue first so we can talk it
through. Say which macOS version you tested on, and never commit your `config.sh`.

Please follow the [code of conduct](CODE_OF_CONDUCT.md).
