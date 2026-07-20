# Changelog

BabbelStream uses Semantic Versioning. Before 1.0, minor releases may contain substantial product or workflow changes; patch releases contain compatible fixes and incremental improvements.

## 0.4.1 - 2026-07-20

- Show the bounded Mini transcription hedge truthfully as `Trying Mini` in the compact HUD.
- Replace the handwritten LaunchAgent with macOS `SMAppService`, including safe migration that preserves the legacy login item until registration succeeds.
- Calm the everyday menu while keeping **Copy Last Draft** directly available; move local test recording into Diagnostics and show repair actions only when permissions need attention.
- Add a compact General Settings readiness section for permissions, Keychain configuration, the active provider, and launch-at-login approval.
- Share stable audio-to-draft preparation between normal dictation and failed-recording recovery, and split behavior-check support by concern without adding dependencies.

## 0.4.0 - 2026-07-11

- Turn the fixed `Control + Option + Space` shortcut into a hybrid control: tap to latch hands-free recording or hold for push-to-talk.
- Stop a hands-free recording with the same shortcut, the HUD Stop control, or the menu while preserving the existing transcription, cleanup, paste, and recovery pipeline.
- Show a lock or hand indicator in the compact recording HUD and cover the deterministic 0.5-second gesture boundary with behavior checks.
- Add a dedicated interaction, race-handling, privacy, and manual-QA specification for future implementation work.

## 0.3.0 - 2026-07-11

- Safeguard stopped audio locally until transcription and any enabled cleanup succeed, preserving failed, canceled-after-stop, and interrupted dictations for recovery.
- Add a menu-accessible Failed Recordings window with retry-and-copy, Save Audio As, individual deletion, confirmed bulk deletion, disk usage, and privacy-safe metadata.
- Hedge slow primary transcription with one Mini request after 10 seconds, accept the first valid result, and bound the complete transcription phase to 75 seconds.
- Keep the 220×44 HUD passive and layout-stable while showing a concise Recording saved failure state.

## 0.2.5 - 2026-07-11

- Unify Teach Correction, Personal Dictionary, and Dictation Archive with the grouped, scrollable Settings design language and persistent status/action footers.
- Make all three auxiliary windows resizable with practical minimum sizes and consistent native button roles.
- Add deterministic window-only launch options for visual QA of every redesigned dialog.

## 0.2.4 - 2026-07-11

- Keep privacy-safe diagnostics grouped by dictation operation and export the complete latest dictation timeline instead of only its final ten events.
- Add millisecond timestamps and monotonic elapsed time to diagnostic events.
- Measure recorder finalization, API-key loading, provider request preparation, paste, archive writing, and temporary-audio deletion without logging audio or text content.

## 0.2.3 - 2026-07-11

- Split application startup, status-menu orchestration, window construction, dictation coordination, and settings/editor views into responsibility-based source files.
- Refactor the dictation coordinator around explicit transcription-with-fallback and cleanup-with-raw-fallback actions while preserving the visible workflow.
- Reuse the coordinator's menu-bar state instead of duplicating recording/processing icon decisions.
- Delete temporary audio when AVFoundation recorder setup or startup fails.
- Remove an avoidable force unwrap from paste-target display names and cover the fallback with behavior checks.

## 0.2.2 - 2026-07-11

- Refine the five-tab Settings layout with a resizable window, consistent grouped sections, aligned long values, and a stable Apply footer.
- Split provider settings into active destinations, connection, models/timeouts, and API-key sections.
- Add deterministic window-only Settings visual-QA launch options.
- Audit all human-readable project documentation and resolve fallback, targeting, testing, and release-state drift.

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
