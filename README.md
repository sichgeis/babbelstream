# BabbelStream

BabbelStream is a native macOS menu-bar push-to-talk dictation helper for Slack and other focused text fields.

Hold `Control + Option + Space`, speak, release, and BabbelStream transcribes through an OpenAI-compatible endpoint, optionally cleans the draft for Slack, and inserts it into the focused field. It never auto-sends messages.

## Current MVP

- Native macOS menu-bar app.
- Global push-to-talk hotkey: `Control + Option + Space`.
- Compact non-activating status HUD for recording, processing, cancellation, and paste recovery.
- Escape cancels only while a recording or provider operation is active; the HUD/menu Cancel action remains available as a fallback.
- AVFoundation microphone recording with configurable max duration, defaulting to 10 minutes.
- OpenAI-compatible transcription endpoint, default path `/v1/audio/transcriptions`.
- OpenAI-compatible cleanup endpoint, default path `/v1/chat/completions`.
- One bounded retry for transient transcription transport, throttling, and server failures; a zero-byte connection stall is canceled after 15 seconds instead of waiting for the longer provider request timeout.
- The HUD shows transcription attempt count, timeout guidance, and the privacy-safe reason for a retry.
- Cleanup preserves German, English, and mixed German-English speech without translating.
- Local personal dictionary injects preferred vocabulary and correction hints into cleanup.
- Local usage counters show dictations, recorded minutes, cleanup requests, and safe failure counts.
- Optional local dictation archive writes daily JSONL text files and provides monthly word-count review/export.
- Copyable diagnostics summarize state and provider settings without transcripts, audio paths, or API keys.
- Direct Accessibility insertion first, clipboard plus `Cmd+V` fallback.
- Automatic insertion only while the originally captured app and logical field still match, including safely recognized replacement wrappers in VS Code, Codex, and other reactive editors.
- One trailing space after inserted dictation chunks so repeated dictations do not run together.
- In-app launch-at-login toggle backed by a user LaunchAgent.
- API key stored in macOS Keychain; no transcript or audio history by default.

## Build Locally

```bash
task check
scripts/build-app.sh
```

`task check` builds the app and runs `BabbelStreamChecks`, the dependency-free behavior-check executable. This CLT-only environment does not expose XCTest or Swift Testing through SwiftPM, so the repository intentionally has no misleading empty `swift test` target.

The app bundle is written to:

```text
dist/BabbelStream.app
```

For stable local permissions, create a local signing identity once, then install the app from a stable path:

```bash
scripts/create-local-codesign-identity.sh
scripts/install-dev-app.sh
```

`scripts/install-dev-app.sh` is the daily development install loop. It builds the app, packages the local DMG, opens the Finder drag-to-Applications window, and stops any running BabbelStream copy so Finder can replace it cleanly. The script does not use `sudo`; if `/Applications` needs authorization, Finder shows the standard macOS prompt during the drag copy. After copying, restart the installed app with:

```bash
RESTART_ONLY=1 scripts/install-dev-app.sh
```

Set `WAIT_FOR_INSTALL=1` if you want the script to wait for the drag copy and launch `/Applications/BabbelStream.app` after it appears.

Equivalent Taskfile shortcuts are available as `task app:build`, `task app:install-dev`, `task app:restart`, and `task app:package-dmg`.

## Package A DMG

```bash
scripts/package-dmg.sh
```

The DMG is written to:

```text
dist/BabbelStream-0.1.0.dmg
```

This local DMG is suitable for personal testing. Public distribution should use a Developer ID Application certificate and Apple notarization; see [docs/release.md](docs/release.md).

## First-Run Setup

1. Run `scripts/install-dev-app.sh`, then drag `BabbelStream.app` onto the Applications link in Finder.
2. Grant Microphone permission when prompted.
3. Open Settings from the menu-bar icon.
4. Configure provider base URL, model names, overall request timeout, and API key, then click `Apply Settings` in the persistent Settings footer. Connection establishment has a separate fixed 15-second timeout; the Provider pane shows the maximum attempt count and explains that a retry resends the same temporary audio.
5. Request Accessibility permission so BabbelStream can insert text automatically.
6. Optionally enable `Launch at login` in Settings.
7. Optionally enable `Archive completed dictations` if you want local daily text files and monthly word-count review.
8. Focus Slack or another text field, hold `Control + Option + Space`, speak, and release. Use Escape or the HUD Cancel button to stop without pasting.

For mixed German-English dictation, leave the language field blank. Use the optional transcription prompt only for transcription hints, not cleanup instructions.

Open `Teach Correction...` from the menu-bar icon or Settings to quickly add a wrong-to-right hint such as `David => Dawid`. Open `Personal Dictionary...` for bulk vocabulary and correction editing. BabbelStream stores these local hints at `~/Library/Application Support/BabbelStream/personal-dictionary.json`.

Open `Dictation Archive...` from the menu-bar icon to review monthly local word counts, copy a Markdown export, reveal the archive folder, or clear archive data. When enabled, archive files are stored under `~/Library/Application Support/BabbelStream/Archive/YYYY-MM/YYYY-MM-DD.jsonl`.

An optional local Codex skill can edit the same file from `~/.codex/skills/babbelstream-dictionary`.

## Privacy Defaults

- Temporary audio is deleted after processing, cancellation, or app termination. A deletion failure is shown prominently and retried on relaunch.
- Transcripts and cleaned drafts are kept only in memory for the running app session unless the local dictation archive is explicitly enabled.
- Dictation archive is off by default. When enabled, it stores final draft text and word counts locally; raw transcript storage is a separate opt-in.
- API keys are stored in Keychain, not in files or `UserDefaults`.
- A non-secret `UserDefaults` marker may remember that an API key was saved so startup does not read Keychain.
- The personal dictionary stores only explicit vocabulary/correction hints, not transcript history.
- Usage counters are local `UserDefaults` numbers only; they do not contain transcript text or audio metadata.
- Diagnostics copied from the app are redacted and omit transcripts, cleaned drafts, archive contents, audio paths, and clipboard contents.
- No telemetry, analytics, cloud database, transcript history, or Slack API integration.

## Uninstall And Local Data Cleanup

1. Disable `Launch at login` and delete the API key from Settings before removing the app when possible.
2. Quit BabbelStream and remove `BabbelStream.app` from `/Applications`.
3. If you no longer want the dictionary or optional archive, remove `~/Library/Application Support/BabbelStream` manually after reviewing its contents.
4. Remove the BabbelStream entry from System Settings > Privacy & Security > Microphone and Accessibility if desired.
5. If the app was removed before launch-at-login was disabled, remove `~/Library/LaunchAgents/com.sichgeis.babbelstream.loginitem.plist` manually.
6. The optional `BabbelStream Local Code Signing` identity can be removed in Keychain Access when it is no longer used for development builds.

Removing the app bundle alone intentionally does not delete local dictionary or archive data.

## Release Status

BabbelStream is currently a local MVP. The next production release step is Developer ID signing and notarization for GitHub Releases.
