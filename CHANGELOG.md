# Changelog

## 0.1.0 - Local MVP

- Added native macOS menu-bar app bundle.
- Added push-to-talk dictation with `Control + Option + Space`.
- Added microphone recording and temporary audio cleanup.
- Added configurable OpenAI-compatible transcription and cleanup providers.
- Added Keychain-backed API key storage.
- Added Slack-ready cleanup that preserves German, English, and mixed German-English language.
- Added local personal dictionary context for cleanup vocabulary and correction hints.
- Added Teach Correction flow for explicit wrong-to-right dictation hints.
- Added direct Accessibility insertion with clipboard fallback.
- Added configurable max recording duration, defaulting to 10 minutes.
- Added trailing-space insertion between consecutive dictation chunks.
- Added local usage counters and privacy-safe diagnostics.
- Added optional local dictation archive with daily JSONL files, monthly word-count review, Markdown export, reveal-folder, and clear controls.
- Added in-app launch-at-login toggle.
- Added local DMG packaging script.
