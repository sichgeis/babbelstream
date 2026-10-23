# BabbelStream

Speak a draft. Keep your own words. Send it when you're ready.

BabbelStream is a native macOS menu-bar app for dictating into Slack and other
focused text fields. It supports German, English and mixed technical speech,
with optional cleanup for punctuation and filler words. **It never presses Enter
or sends your message.**

## Try the pilot

**Version 0.5.1 · Apple Silicon · Non-notarized Homebrew pilot**

The [0.5.1 release](https://github.com/sichgeis/babbelstream/releases/tag/v0.5.1)
is public and the tap is active. Public Homebrew installation passed on the
macOS 27.0.1 pilot Mac after moving its manual app aside; post-install dictation
and restart confirmation is pending. This remains a limited colleague pilot.

| Requirement | What to expect |
| --- | --- |
| Mac | Apple Silicon; Intel is not supported by this build |
| macOS | Declared minimum 13.0; native evidence on 26.7.1 and pilot smoke on 27.0.1; other versions pending |
| Installation | Ad-hoc signed, not notarized by Apple; macOS may require explicit approval |
| Dictation provider | Your own approved OpenAI-compatible endpoint and API key; provider charges may apply |
| Permissions | Microphone for recording; Accessibility for automatic paste |

**Testing the pilot?** Follow the [download/launch checklist](docs/homebrew-pilot-smoke-test.md).
Downloads are public and do not require GitHub sign-in. See
[project status](docs/project-status.md) for current evidence and remaining gates.

### Install with Homebrew

```sh
brew install --cask sichgeis/tap/babbelstream
open /Applications/BabbelStream.app
```

This uses [our own tap](https://github.com/sichgeis/homebrew-tap), independently of
Homebrew's official catalogue. Homebrew must already be installed. If you have a
manual BabbelStream installation, quit it and preserve a backup before migrating;
see [installation guidance](docs/getting-started.md).

You can also use the versioned DMG and checksum from GitHub Releases.
The app is **not Apple-notarized**. If macOS blocks first launch, use
[Apple's per-app approval instructions](https://support.apple.com/en-gb/102445)
where device policy permits. On a managed Mac, ask IT if approval is unavailable.

## Set up once

1. Open BabbelStream from Applications. Its setup dialog can be postponed and
   reopened through **Set Up BabbelStream…**.
2. Deliberately allow Microphone and Accessibility access. Without Accessibility,
   completed drafts can still be copied for manual paste.
3. Confirm your approved provider destination, enter your own key, and choose
   **Apply Settings**. No provider key is bundled with the app.
4. Try the optional local paste test, then dictate a harmless sample into an
   unsent draft. The local test uses no microphone or provider, and replaces the
   clipboard with its sample.

[Setup and troubleshooting →](docs/getting-started.md)

## Dictate where you write

| Action | Result |
| --- | --- |
| Tap `Control + Option + Space` | Start hands-free recording; tap again to stop and process |
| Hold the shortcut for at least 0.5 seconds | Record while held; release to process |
| Press Escape while active | Cancel recording or processing |
| Switch to another app before delivery | Keep the draft available for copying instead of pasting into that app |

Automatic delivery puts the draft on the clipboard and posts `Command + V` to the
currently focused field in the original app. Review the result before sending.
Use **Copy Last Draft** for manual recovery, **Failed Recordings…** to recover a
failed attempt, and **Teach Correction…** to add vocabulary hints. Leave the
language hint blank for mixed German-English dictation.

## Update when you're ready

Finish or cancel active work and quit BabbelStream
normally before upgrading. Copy Last Draft is session-only and is lost on quit.

```sh
brew update
brew upgrade --cask sichgeis/tap/babbelstream
open /Applications/BabbelStream.app
```

Confirm the version/commit in Diagnostics. macOS or Keychain may request approval
again after an update. Settings, dictionary and retained recordings should remain;
the first real Homebrew upgrade is still awaiting pilot validation. There is no
in-app updater or automatic background update check.

[Upgrade and rollback guidance →](docs/homebrew-release.md#bad-release-and-rollback)

## Troubleshooting

### Keychain asks for your password after every restart

**Symptom:** dictation works, but the first transcription after quitting and
reopening BabbelStream asks for your login Keychain password again, even after
choosing **Always Allow**.

This occurred on macOS 27.0.1 when upgrading a manual 0.4.5 installation to the
ad-hoc-signed 0.5.1 pilot. The saved key remained, but repeated approval did not
resolve access. A signing/trust mismatch is suspected; the root cause is not
confirmed. The following per-item repair resolved the reported restart test:

1. Open **Keychain Access** (choose it rather than Passwords if macOS offers both).
2. Select the **login** keychain and search for `com.sichgeis.babbelstream`.
3. Open the application-password item with account **provider-api-key**, then
   select **Access Control**. Leave **Show password** unchecked.
4. Keep **Confirm before allowing access** selected. Under **Always allow access
   by these applications**, click **+** and add `/Applications/BabbelStream.app`.
   Existing BabbelStream entries may refer to older builds; in the reported case,
   adding the current Applications copy worked without removing those entries.
5. Choose **Save Changes** and authenticate in the macOS dialog if requested.
6. Quit and reopen BabbelStream, then dictate harmless text into an unsent draft.
   Confirm the text appears once without a Keychain prompt; repeat the restart
   test to check that access persists.

Do not enable **Allow all applications to access this item**, reveal/share the
key, or delete the Keychain item as a repair. If saving is blocked or the prompt
returns, report the macOS version, BabbelStream version/commit and reproduction
steps without including passwords or private dictation.

This repair was confirmed for the installed 0.5.1 build; it does not establish
that trust survives a future Homebrew upgrade. Ad-hoc builds can change identity
between versions. See [Apple's Keychain access guidance](https://support.apple.com/en-gb/guide/mac-help/kychn002/mac).

## Privacy by default

- Recording starts only when you request it. Audio goes to the configured provider;
  optional cleanup sends transcript text and dictionary hints to that provider.
- Successful audio is deleted. Failed or interrupted stopped recordings stay
  locally in **Failed Recordings** until recovery succeeds or you delete them.
- Draft text stays in session memory and the clipboard unless you explicitly enable
  the local archive. Other apps and clipboard managers may read clipboard text.
- API keys stay in macOS Keychain. Personal OpenAI fallback is off by default and
  requires separate consent, a separate key and possible personal charges.
- No telemetry, cloud sync, Slack API integration or auto-send.

For work dictation, use only content and provider destinations your company
allows. [Privacy contract →](docs/security-privacy.md)

## Remove the app

For a Homebrew-managed installation, disable launch at login if enabled, quit the
app, then run `brew uninstall --cask sichgeis/tap/babbelstream`. For a manual
installation, remove the Applications bundle after quitting.

Removing the app retains keys, settings, dictionary, failed recordings and any
optional archive. Complete data removal is a separate deliberate choice; see
[removal and local data](docs/getting-started.md#remove-local-data-deliberately).

## Build or contribute

```sh
task check
scripts/build-app.sh
```

Swift, SwiftUI and AppKit; no third-party runtime dependencies. The canonical
checks use executable fixtures rather than an unavailable XCTest runner in this
Command Line Tools environment. [Development guide →](docs/development.md)

[Documentation](docs/README.md) · [Changelog](CHANGELOG.md) ·
[Release operations](docs/homebrew-release.md) · [Project status](docs/project-status.md)
