# Changelog

## Unreleased

- Added a non-activating recording, processing, completion, and recovery HUD.
- Added operation-scoped Escape cancellation with HUD and menu fallbacks.
- Made settings changes explicit with Apply, saved/effective provider labels,
  per-dictation snapshots, and stricter provider URL validation.
- Made Keychain key updates non-destructive and removed unnecessary key rewrites.
- Added bounded retry for transient transcription failures and strict JSON success
  parsing.
- Prevented automatic insertion after the captured application or focused field
  changes; the draft is copied for manual recovery instead.
- Added verified temporary-audio cleanup, visible cleanup failures, and
  termination cleanup.
- Made archive reads recover valid entries around damaged JSONL lines and expose
  recovery warnings in the UI and exports.
- Made dictionary bulk edits preserve notes and disabled entries, and made
  correction updates replace an earlier mapping for the same heard form.
- Added `task check` as the canonical build-and-behavior-check command and
  documented the current SwiftPM test-runner limitation.

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
