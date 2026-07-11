# BabbelStream

BabbelStream is a native macOS menu-bar hybrid dictation helper for Slack and other focused text fields.

Tap `Control + Option + Space` for hands-free recording or hold it for push-to-talk. BabbelStream transcribes through an OpenAI-compatible endpoint, optionally cleans the draft for Slack, and inserts it into the focused field. It never auto-sends messages.

## Current MVP

- Native macOS menu-bar app.
- Global hybrid hotkey: tap `Control + Option + Space` to record hands-free; hold it for at least 0.5 seconds for push-to-talk.
- Compact non-activating status HUD for recording, processing, cancellation, and paste recovery.
- Escape cancels only while a recording or provider operation is active; canceling a stopped recording's provider work preserves it under Failed Recordings.
- AVFoundation microphone recording with configurable max duration, defaulting to 10 minutes.
- OpenAI-compatible transcription endpoint, default path `/v1/audio/transcriptions`.
- OpenAI-compatible cleanup endpoint, default path `/v1/chat/completions`.
- One bounded hedge for transient transcription slowness: primary starts immediately, Mini starts after 10 seconds if needed, the first valid result wins, and both share a 75-second deadline. A zero-byte connection stall is canceled after 15 seconds.
- Failed or interrupted processing keeps the stopped M4A in a local, user-only Failed Recordings store. Retry uses current provider settings and copies the result instead of auto-pasting into a historical target.
- The HUD stays compact and passive; it distinguishes primary/Mini processing and shows Recording saved after failure. Privacy-safe diagnostics record stage, timing, status/error category, and byte counts.
- Cleanup preserves German, English, and mixed German-English speech without translating.
- Local personal dictionary injects preferred vocabulary and correction hints into cleanup.
- Local usage counters show dictations, recorded minutes, cleanup requests, and safe failure counts.
- Optional local dictation archive writes daily JSONL text files and provides monthly word-count review/export.
- Copyable diagnostics summarize state and provider settings without transcripts, audio paths, or API keys.
- Direct Accessibility insertion first, clipboard plus `Cmd+V` fallback.
- Automatic insertion only while the originally captured app remains frontmost; the currently focused field in that app receives the draft, including in VS Code, Codex, and other reactive editors.
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
dist/BabbelStream-$(cat VERSION).dmg
```

This local DMG is suitable for personal testing. Public distribution should use a Developer ID Application certificate and Apple notarization; see [docs/release.md](docs/release.md).

## First-Run Setup

1. Run `scripts/install-dev-app.sh`, then drag `BabbelStream.app` onto the Applications link in Finder.
2. Grant Microphone permission when prompted.
3. Open Settings from the menu-bar icon.
4. Configure the provider base URL, primary transcription model, cleanup model/timeout, and API key, then click `Apply Settings` in the persistent Settings footer. The Provider pane shows the fixed Mini hedge, 10-second hedge delay, 75-second overall deadline, and separate 15-second connection watchdog. During rare slow requests the same safeguarded audio may be sent to both models and may incur two transcription charges.
5. If processing fails, open **Failed Recordings…** from the menu to retry and copy the draft, save the M4A elsewhere, or explicitly delete it.
6. Request Accessibility permission so BabbelStream can insert text automatically.
7. Optionally enable `Launch at login` in Settings.
8. Optionally enable `Archive completed dictations` if you want local daily text files and monthly word-count review.
9. Focus Slack or another text field. Tap `Control + Option + Space`, release, speak hands-free, then press it again to process; or hold it while speaking and release for push-to-talk. The HUD Stop button also processes. Escape or the menu Cancel action discards/cancels instead of pasting.

For mixed German-English dictation, leave the language field blank. Use the optional transcription prompt only for transcription hints, not cleanup instructions.

Open `Teach Correction...` from the menu-bar icon or Settings to quickly add a wrong-to-right hint such as `David => Dawid`. Open `Personal Dictionary...` for bulk vocabulary and correction editing. BabbelStream stores these local hints at `~/Library/Application Support/BabbelStream/personal-dictionary.json`.

Open `Dictation Archive...` from the menu-bar icon to review monthly local word counts, copy a Markdown export, reveal the archive folder, or clear archive data. When enabled, archive files are stored under `~/Library/Application Support/BabbelStream/Archive/YYYY-MM/YYYY-MM-DD.jsonl`.

An optional local Codex skill can edit the same file from `~/.codex/skills/babbelstream-dictionary`.

## Privacy Defaults

- Audio is safeguarded after recording stops and deleted after transcription and any enabled cleanup succeed. Failed, canceled-after-stop, or interrupted work remains local under Failed Recordings until retry succeeds or you delete it.
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
