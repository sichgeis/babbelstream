# Changelog

BabbelStream uses Semantic Versioning. Before 1.0, minor releases may contain substantial product or workflow changes; patch releases contain compatible fixes and incremental improvements.

## 0.2.1 - 2026-07-11

- Add privacy-safe provider lifecycle observability and persistent Unified Logging.
- Diagnose and explain stale Accessibility grants for rebuilt local apps.
- Use a stable local code-signing identity in development builds.
- Fall back from `gpt-4o-transcribe` to `gpt-4o-mini-transcribe` after one bounded transient failure.

## 0.2.0 - 2026-07-10

- Redesign the dictation HUD as a compact bottom-centered capsule.
- Add non-activating recording, processing, completion, and recovery states.

## 0.1.3 - 2026-07-10

- Use application-level paste targeting for reactive editors and safer focus handling.
- Copy the draft for manual recovery when the captured application changes.

## 0.1.2 - 2026-07-10

- Recover from stalled provider connections and show bounded retry progress.
- Add strict JSON success parsing and bounded transient-failure handling.

## 0.1.1 - 2026-07-10

- Complete the July settings, lifecycle, cancellation, recovery, and paste-safety upgrade.
- Make settings changes explicit with Apply, saved/effective provider labels, per-dictation snapshots, and stricter provider URL validation.
- Make Keychain key updates non-destructive and remove unnecessary key rewrites.
- Add operation-scoped Escape cancellation with HUD and menu fallbacks.
- Verify temporary-audio cleanup across completion, failure, cancellation, and termination.
- Recover valid archive entries around damaged JSONL lines and expose recovery warnings.
- Preserve notes and disabled entries in dictionary bulk edits, and replace earlier mappings for the same heard form.
- Establish `task check` as the canonical build and behavior check.

## 0.1.0 - 2026-07-06

- Ship the first working push-to-talk dictation MVP.
- Add the native macOS menu-bar app bundle and `Control + Option + Space` push-to-talk flow.
- Add microphone recording, temporary-audio cleanup, and configurable OpenAI-compatible transcription and cleanup providers.
- Store API keys in Keychain and preserve German, English, and mixed German-English dictation.
- Add the personal dictionary, Teach Correction, Accessibility insertion, and clipboard fallback.
- Add configurable recording duration, trailing-space insertion, usage counters, privacy-safe diagnostics, and the optional local archive.
- Add launch-at-login and local DMG packaging.
