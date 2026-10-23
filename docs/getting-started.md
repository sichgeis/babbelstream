# Get Started With BabbelStream

BabbelStream 0.5.1 is available locally; its non-notarized GitHub/Homebrew colleague
channel is staged; the [download/launch quality test](homebrew-pilot-smoke-test.md)
has other-Mac results recorded, including the Keychain repair linked below.
The normal Homebrew commands become usable only after publication and activation.
Check [current status](project-status.md) before sharing installation instructions.

## Install the Applications copy

The current build requires Apple Silicon. It declares macOS 13.0 as its minimum;
native evidence is on 26.7.1, with pilot smoke also reported on 27.0.1.

After tap activation, use `brew install --cask sichgeis/tap/babbelstream`. For a DMG,
download both release assets, verify the checksum from their download directory,
then copy the app to Applications and eject the image:

```sh
shasum -a 256 -c BabbelStream-0.5.1.dmg.sha256
open /Applications/BabbelStream.app
```

For an existing manual installation, finish or cancel active work, quit normally,
and preserve its app bundle before moving it aside. Keep Application Support and
Keychain intact. Homebrew adoption of an identical manual app is not yet tested;
do not force an overwrite or run two copies to work around a conflict.

This pilot is ad-hoc signed, not notarized by Apple. If launch is blocked, follow
[Apple's Open Anyway instructions](https://support.apple.com/en-gb/102445) where
allowed. On managed Macs, IT may need to approve installation. Do not disable
Gatekeeper, remove quarantine or reset macOS permissions.

## Use the setup dialog

Open **Set Up BabbelStream…** from the menu or General Settings to return to setup.

1. **Permissions:** allow Microphone when you want to record and Accessibility
   when you want automatic paste. These are separate OS grants; setup completion
   alone is not evidence of permission. Without Accessibility, use manual paste.
2. **Provider:** confirm your authorized destination and enter your own API key.
   Choose the official OpenAI preset or your approved compatible service. No
   shared key or guessed company endpoint is supplied. Provider use may cost money.
3. **Apply:** choose Apply Settings to make edits active. A saved key is not proof
   that the connection works. Changing provider origin requires approving a key
   for that destination by entering it explicitly again.
4. **Local paste:** optionally run the app-owned sample test. It replaces the
   clipboard without using your microphone, provider, existing field contents or
   keys. A pass proves this local field accepted the sample, not every editor.
5. **First dictation:** with an authorized provider, focus an unsent TextEdit or
   Slack draft and use harmless sample speech. Check that the draft appears once
   and remains unsent.

## Choose provider and language settings

The official OpenAI API uses **OpenAI (standard model IDs)**. A LiteLLM proxy that
exposes OpenAI models through `openai/*` uses **LiteLLM (openai/ model prefix)**.
Provider Settings shows the effective primary and fallback model IDs; select the
models your endpoint supports. Primary choices are `gpt-transcribe`,
`gpt-4o-transcribe` and `gpt-4o-mini-transcribe`; cleanup has its own configured
model. Advanced settings contain routing, endpoint paths and timeout controls.

Leave the transcription language hint empty for mixed German-English speech.
Use a specific hint such as `de` or `en` only when you want it. Transcription hints
are distinct from cleanup instructions. Cleanup should preserve your language
and wording while removing filler and adding light punctuation.

A slow primary request may start a Mini hedge after 10 seconds; the first valid
result wins within one 75-second overall deadline. A zero-byte connection stall
is detected after 15 seconds. Rare hedged attempts can incur two transcription
charges. These requests use your applied provider configuration.

Personal OpenAI fallback is off by default. It has a separate key and explicitly
sends eligible outage recovery to `api.openai.com`, potentially with personal
charges. **Use personal OpenAI now (skip primary)** instead routes new dictations
directly to that personal account until you turn it off. Review destination,
work-data authorization and charges before applying either option. The purple
recording/processing HUD identifies direct-personal mode.

**Test Saved Connection** is optional. Its confirmation describes one short silent
WAV request to the saved primary transcription endpoint; the provider may bill it.
It does not record your microphone or test real speech, cleanup or editor delivery.
See [pilot support](pilot-support.md) for connection-state and credential details.

## Recover without losing work

| Symptom | What to do |
| --- | --- |
| Draft copied but not pasted | Use Command-V, check Accessibility in setup, and ensure the original app is frontmost |
| Clipboard changed during delivery | Use Copy Last Draft; BabbelStream preserves the newer clipboard |
| Processing failed | Open Failed Recordings… to retry and copy, export audio, or explicitly delete it |
| OS toggle says allowed but paste still fails | Recheck setup's actual trust; follow its repair guidance for the exact Applications copy |
| Permission or key access changes after an update | Reapprove through macOS/Keychain when appropriate; preserve app data and keys |
| Keychain password requested after every restart despite Always Allow | Follow the [targeted Keychain access repair](../README.md#keychain-asks-for-your-password-after-every-restart); add the current Applications copy without deleting the key or allowing all apps |
| Need to report a problem | Share version/commit, macOS version and harmless reproduction steps; omit keys, work text, clipboard, audio and archives |

Retrying a failed recording copies the recovered draft; it does not paste into a
historical target. Canceling while recording discards that partial recording;
canceling processing after stop retains stopped audio for recovery.

## Personalize deliberately

Use **Teach Correction…** for a wrong-to-right vocabulary hint and **Personal
Dictionary…** for bulk edits. Hints are explicit local data included in enabled
cleanup requests; they are not automatic transcript learning.

**Launch at login** is optional. **Archive completed dictations** is also optional
and stores local text; raw transcript storage requires a separate opt-in. Review
or export it through **Dictation Archive…**. Nothing enables the archive silently.

## Remove local data deliberately

Ordinary app or cask removal retains local data and Keychain items for reinstall
or rollback. If you intend permanent removal:

1. Disable launch at login. If desired, delete provider keys through Settings
   before removing the app; never send them to support.
2. Review/export or explicitly delete Failed Recordings and optional archive data
   you want to remove. Successful recordings are already deleted automatically.
3. Quit normally and remove the app bundle, or uninstall its Homebrew cask.
4. Only if you want to discard the local dictionary, recovery store and optional
   archive, review and remove `~/Library/Application Support/BabbelStream`.
   App preferences may remain in macOS preferences separately.
5. Review remaining permission/login entries in System Settings. Very old builds
   may leave `~/Library/LaunchAgents/com.sichgeis.babbelstream.loginitem.plist`;
   current builds migrate that legacy launch item after successful registration.

Do not use data deletion as a permission, install or upgrade repair step. The tap
has no zap recipe. Developers can remove an unused local signing identity through
Keychain Access separately; ordinary pilot users do not need one.
