# BabbelStream

BabbelStream is a native macOS menu-bar push-to-talk dictation helper for Slack and other focused text fields.

Hold `Control + Option + Space`, speak, release, and BabbelStream transcribes through an OpenAI-compatible endpoint, optionally cleans the draft for Slack, and inserts it into the focused field. It never auto-sends messages.

## Current MVP

- Native macOS menu-bar app.
- Global push-to-talk hotkey: `Control + Option + Space`.
- AVFoundation microphone recording with configurable max duration, defaulting to 10 minutes.
- OpenAI-compatible transcription endpoint, default path `/v1/audio/transcriptions`.
- OpenAI-compatible cleanup endpoint, default path `/v1/chat/completions`.
- Cleanup preserves German, English, and mixed German-English speech without translating.
- Local personal dictionary injects preferred vocabulary and correction hints into cleanup.
- Local usage counters show dictations, recorded minutes, cleanup requests, and safe failure counts.
- Copyable diagnostics summarize state and provider settings without transcripts, audio paths, or API keys.
- Direct Accessibility insertion first, clipboard plus `Cmd+V` fallback.
- One trailing space after inserted dictation chunks so repeated dictations do not run together.
- In-app launch-at-login toggle backed by a user LaunchAgent.
- API key stored in macOS Keychain; no transcript or audio history by default.

## Build Locally

```bash
swift test
swift run BabbelStreamChecks
scripts/build-app.sh
```

The app bundle is written to:

```text
dist/BabbelStream.app
```

For stable local permissions, create a local signing identity once:

```bash
scripts/create-local-codesign-identity.sh
scripts/build-app.sh
```

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

1. Open `dist/BabbelStream.app` or install from the DMG.
2. Grant Microphone permission when prompted.
3. Open Settings from the menu-bar icon.
4. Configure provider base URL, model names, and API key.
5. Request Accessibility permission so BabbelStream can insert text automatically.
6. Optionally enable `Launch at login` in Settings.
7. Focus Slack or another text field, hold `Control + Option + Space`, speak, and release.

For mixed German-English dictation, leave the language field blank. Use the optional transcription prompt only for transcription hints, not cleanup instructions.

Open `Personal Dictionary...` from the menu-bar icon to maintain preferred vocabulary and wrong-to-right correction hints. BabbelStream stores this locally at `~/Library/Application Support/BabbelStream/personal-dictionary.json`.

An optional local Codex skill can edit the same file from `~/.codex/skills/babbelstream-dictionary`.

## Privacy Defaults

- Temporary audio is deleted after processing or cancellation.
- Transcripts and cleaned drafts are kept only in memory for the running app session.
- API keys are stored in Keychain, not in files or `UserDefaults`.
- A non-secret `UserDefaults` marker may remember that an API key was saved so startup does not read Keychain.
- The personal dictionary stores only explicit vocabulary/correction hints, not transcript history.
- Usage counters are local `UserDefaults` numbers only; they do not contain transcript text or audio metadata.
- Diagnostics copied from the app are redacted and omit transcripts, cleaned drafts, audio paths, and clipboard contents.
- No telemetry, analytics, cloud database, transcript history, or Slack API integration.

## Release Status

BabbelStream is currently a local MVP. The next production release step is Developer ID signing and notarization for GitHub Releases.
