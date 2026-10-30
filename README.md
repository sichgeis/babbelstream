# BabbelStream

**Speak a draft. Keep your own words. Send it when you’re ready.**

A native macOS menu-bar app for dictating into Slack and other text fields.
German, English, and mixed technical speech, with optional cleanup for punctuation
and filler words. **BabbelStream never presses Enter or sends your message.**

## Install

**0.6.0 · Apple Silicon · macOS 13+ · Non-notarized pilot**

Remote dictation needs an approved OpenAI-compatible provider and your own API
key; provider charges may apply. Optional local models need macOS 14+ and no API
key. Microphone access enables recording; Accessibility enables automatic paste.

This pilot is ad-hoc signed, not notarized by Apple. Use **Privacy & Security →
Open Anyway** where permitted. Managed Macs may require IT approval.
[Tested versions and pilot status →](docs/project-status.md)

### Homebrew

```sh
brew install --cask sichgeis/tap/babbelstream
open /Applications/BabbelStream.app
```

Uses [our own tap](https://github.com/sichgeis/homebrew-tap); Homebrew must already
be installed. Switching from a manual installation? Quit the app and preserve a
backup first. [Installation guidance →](docs/getting-started.md)

### DMG

Download the [DMG](https://github.com/sichgeis/babbelstream/releases/download/v0.6.0/BabbelStream-0.6.0.dmg)
and [checksum](https://github.com/sichgeis/babbelstream/releases/download/v0.6.0/BabbelStream-0.6.0.dmg.sha256).
In their download folder, verify:

```sh
shasum -a 256 -c BabbelStream-0.6.0.dmg.sha256
```

Quit the old app, open the DMG, drag BabbelStream into Applications, and launch
that copy. Eject the image afterward. Source ZIP/tar archives are not installers.

### Optional manual installation helper (pilot)

The helper prepares the latest verified public release, currently 0.6.0. If a newer
release appears before its verified pins are refreshed, it stops instead of
installing an older version. Try the same command again after the maintainer updates it.

**Notice:** This helper removes quarantine from a verified temporary app copy
only after your consent, bypassing its quarantine-based first-open check. It
provides no Apple or malware verification. Follow device policy; if blocked,
contact IT.

[Review the helper](https://github.com/sichgeis/babbelstream/blob/main/scripts/prepare-downloaded-install.sh),
then copy this command into Terminal. Use the same command for installation and
future updates. Quit BabbelStream first; no developer tools or Homebrew are needed.

```sh
/bin/bash -c 'set -e; babbelstream_helper="$(/usr/bin/mktemp -t babbelstream-helper)"; cleanup() { /bin/rm -f "$babbelstream_helper"; }; trap cleanup EXIT; /usr/bin/curl --fail --location --proto "=https" --proto-redir "=https" --tlsv1.2 --connect-timeout 20 --max-time 60 --output "$babbelstream_helper" https://raw.githubusercontent.com/sichgeis/babbelstream/main/scripts/prepare-downloaded-install.sh; /bin/bash "$babbelstream_helper" "$@"' babbelstream --update
```

1. The helper checks your installed version, then downloads and verifies its
   current supported release. If that exact release is installed, it stops there.
2. Read the notice and type **prepare** (any letter case), or press Return to cancel.
3. The illustrated installer window opens. Preserve your previous app as a
   rollback copy, then drag BabbelStream onto its Applications folder. Launch
   the installed copy yourself.
4. Check Diagnostics against the version/build/source printed in Terminal. Eject the installer
   with Command-E, then delete the temporary folder printed in Terminal.

The helper refuses Homebrew-managed installations. Ordinary Homebrew and DMG
installation preserve quarantine.

<details>
<summary>Helper options and verification</summary>

Each run downloads the current helper from `main` and deletes it on exit. You
are trusting the current code in this repository. The helper carries the expected
release version, checksum and app signature, and verifies them before asking for
consent. These checks confirm the expected artifact, not a trusted publisher.

The same command handles first installation and updates, and refuses downgrades.
Release maintainers refresh the helper’s release pins for each supported version;
your saved command stays the same. It does not run in the background or replace
the installed app automatically: you still consent and drag it in Finder.

From a checkout, run `bash scripts/prepare-downloaded-install.sh --download` or
`bash scripts/prepare-downloaded-install.sh --update`. Pass a downloaded DMG’s
path instead of `--download` to use a local file. Add `--verify-only` before the
mode to verify without changing quarantine or opening Finder.

Without provider options, only quarantine on the prepared app copy changes. The original DMG, installed
app, other metadata, global security settings, permissions, Keychain, and provider
settings stay untouched. Device policy may also block the script itself.

For a prefilled connection, append all four options to the command:
`--provider-url HTTPS_ORIGIN --model-routing ROUTING --transcription-model MODEL --cleanup-model MODEL`.
Routing is `standard-openai` or `litellm-openai-namespace`. The helper previews the
settings before the same consent prompt, disables personal fallback/direct mode,
and requires your own API key in the app afterward. Existing connection fields
are replaced only when these options are supplied. No API keys in shell commands.

[Helper contract and validation →](docs/features/manual-install-helper/spec.md)

</details>

## Set up once

1. Open **Set Up BabbelStream…** from the app’s menu.
2. Allow **Microphone** and **Accessibility**. Without Accessibility, copy the
   completed draft and paste it manually.
3. Enter your approved provider URL and personal API key, then click **Apply
   Settings**. No key is bundled.
4. Try the local paste test, then dictate harmless sample text into an unsent
   draft. The paste test replaces the clipboard; it uses no microphone or provider.

Leave the language hint empty for mixed German-English speech. For a LiteLLM
proxy using `openai/*`, select **LiteLLM (openai/ model prefix)** in Provider settings.
[Full setup guide →](docs/getting-started.md)

## Dictate where you write

| Action | Result |
| --- | --- |
| Tap `Control + Option + Space` | Start hands-free; tap again to stop |
| Hold the shortcut for at least 0.5 seconds | Push-to-talk; release to stop |
| Press Escape while active | Cancel recording or processing |
| Switch to another app | Keep the draft available for copying instead of pasting there |

Delivery copies the draft to the clipboard and posts `Command + V` in the original
app. Review it before sending. **Copy Last Draft** recovers the session’s draft;
**Failed Recordings…** handles failed attempts; **Teach Correction…** adds vocabulary.

## Update

Finish active work and quit normally first. **Copy Last Draft** is session-only
and is lost on quit.

```sh
brew update
brew upgrade --cask sichgeis/tap/babbelstream
open /Applications/BabbelStream.app
```

For manual installations, use a newer DMG or the current helper’s `--update` mode.
Check Diagnostics afterward. macOS or Keychain may require approval again.
Settings, dictionary, and retained recordings should remain; genuine Homebrew
upgrade validation is still pending. There is no automatic background updater.
[Upgrade and rollback →](docs/homebrew-release.md#bad-release-and-rollback)

## Troubleshooting

### Dictation copies the draft but does not paste into Codex or another app

Check Accessibility and keep the original app focused.
[Paste and permission repair →](docs/troubleshooting.md#dictation-copies-the-draft-but-does-not-paste-into-codex-or-another-app)

### Homebrew says installed, but the app is missing

[Restore the app without deleting settings or keys →](docs/troubleshooting.md#homebrew-says-installed-but-the-app-is-missing)

### Keychain asks for your password after every restart

[Repair access for the current app →](docs/troubleshooting.md#keychain-asks-for-your-password-after-every-restart)

## Privacy by default

- Recording starts only when requested. Audio goes to your configured provider;
  optional cleanup sends transcript text and dictionary hints there too.
- Successful audio is deleted. Failed or interrupted stopped recordings remain
  locally until recovery succeeds or you delete them.
- Drafts stay in session memory and the clipboard unless you enable the local
  archive. Other apps and clipboard managers may read clipboard text.
- Keys stay in macOS Keychain. Personal OpenAI fallback is off by default and
  requires separate consent, a key, and possible personal charges.
- No telemetry, cloud sync, Slack API integration, or auto-send.

Use only content and provider destinations your organization permits.
[Privacy contract →](docs/security-privacy.md)

## Uninstall

Disable launch at login if enabled, then quit. For Homebrew installations, run
`brew uninstall --cask sichgeis/tap/babbelstream`; otherwise remove the Applications
bundle. Keys, settings, dictionary, failed recordings, and optional archives remain.
[Remove local data deliberately →](docs/getting-started.md#remove-local-data-deliberately)

## Build or contribute

```sh
task check
scripts/build-app.sh
```

Swift, SwiftUI, and AppKit, with pinned FluidAudio and llama.cpp native helpers
for optional local inference. Checks use
executable fixtures because this Command Line Tools environment cannot run XCTest.
[Development guide →](docs/development.md)

[Documentation](docs/README.md) · [Changelog](CHANGELOG.md) ·
[Project status](docs/project-status.md) · [Pilot checklist](docs/homebrew-pilot-smoke-test.md)

### Local dictation (0.6.0)

On Apple Silicon with macOS 14 or later, choose **Provider → On this Mac**,
select **Parakeet Ultra**, confirm **Download Model**, then **Apply Settings**
after preparation. The approximately 632 MB download is separate from the app.
Subsequent dictation runs locally without an API key, cloud cleanup or fallback.
Optional Qwen3.5-4B cleanup is available in Provider Settings: download its 2.74 GB
model, enable local cleanup, and Apply. It runs on Apple Silicon/macOS 14+ without
Ollama or Xcode and uses your personal dictionary. Local cleanup defaults off;
failure returns raw text with a warning and preserves audio for retry.
Remote settings remain available when switching back. Remove Model deletes only
that model; Failed Recordings and other app data are preserved.

The public 0.6.0 release includes accepted on-device dictation and cleanup,
available through the DMG and Homebrew tap. Qwen-ASR and Granite
are listed as deferred choices with downloads disabled in this pilot. Building
the default helper requires Swift 6.2+; building deferred MLX support additionally
requires Xcode's Metal toolchain and separate validation.
