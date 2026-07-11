# Core Interfaces

These are the main protocol boundaries for the native macOS MVP. Implemented interfaces should stay small and mockable; future-only interfaces are marked as such.

## `AudioRecorder`

- Responsibility: request microphone access, record audio to a temporary file, expose a normalized live input level for the recording HUD, stop/cancel recording, enforce max duration, delete partial files.
- Input: max duration, audio format settings.
- Output: normalized live input level while recording, then the temporary audio file URL and duration.
- Errors: permission denied, no input device, recording failed, duration exceeded, cancellation cleanup failed.
- Test strategy: fake recorder returning fixture URLs; unit test temp-file cleanup policy separately.

## `HotkeyService`

- Responsibility: register global push-to-talk hotkey and emit press/release/cancel events.
- Input: hotkey configuration.
- Output: event stream or callbacks.
- Errors: shortcut unavailable, registration failed, release not detectable.
- Test strategy: pure event-state tests with a fake implementation; manual QA for Carbon integration.

## `TranscriptionProvider`

- Responsibility: upload audio and return transcript text.
- Input: audio URL, provider configuration, API key.
- Output: transcript text plus privacy-safe lifecycle events.
- Errors: missing key, invalid endpoint, unsupported request format, timeout, network failure, malformed response.
- Test strategy: URLProtocol/mock server tests for request shape, timeout, lifecycle events, transient-failure classification, response parsing, and deterministic primary/Mini hedge outcomes.

## `CleanupProvider`

- Responsibility: convert raw transcript into Slack-ready draft while preserving meaning and technical terms.
- Input: transcript text, cleanup prompt, personal dictionary context, provider configuration, API key.
- Output: final draft text.
- Errors: missing key, timeout, provider failure, malformed response, empty output.
- Test strategy: mock provider tests plus prompt regression cases for German and mixed technical input.

## `TextInsertionService`

- Responsibility: capture the intended application, insert into its currently focused Accessibility element when possible, and use clipboard plus synthetic Cmd+V only while that captured application remains frontmost.
- Input: final text and captured target application.
- Output: insertion result, including an explicit copy-only recovery outcome when the active application changed.
- Errors: missing Accessibility permission, clipboard unavailable, paste event failed, no captured application, or changed active application.
- Test strategy: unit-test the application-level target policy and insertion result handling behind an adapter; manually verify behavior in Slack, VS Code, Codex, browsers, and native text fields, including switching applications during processing.

## `SettingsStore`

- Responsibility: stage and explicitly apply non-secret settings such as provider URLs, endpoint paths, the primary transcription model, cleanup model/timeout, cleanup toggle, transcription language, transcription prompt, and max recording duration. The Mini model, hedge delay, overall deadline, and connection watchdog are visible fixed policy values.
- Input: typed settings values.
- Output: current settings and validation errors.
- Errors: invalid URL, remote plain HTTP, embedded URL credentials/query data, invalid duration, missing model, unsupported endpoint path.

## `DictationRecoveryStore`

- Responsibility: safeguard stopped M4A audio before provider processing, persist privacy-safe failure metadata, reconstruct interrupted items, and own retry/export/deletion file operations.
- Input: recorded audio, target/provider labels, state transitions, export destination, and explicit deletion requests.
- Output: sorted recovery snapshots with count/size metadata and stable recording identifiers.
- Errors: missing source audio, failed copy or metadata write, missing recovery item, invalid export destination, or failed deletion.
- Test strategy: adoption removes the source only after a durable copy, `0700`/`0600` permissions, startup interruption recovery, malformed metadata recovery, export retention, retry counting, individual deletion, and confirmed UI bulk deletion.
- Test strategy: validation unit tests and migration/default tests.

## `SecretStore`

- Responsibility: store, update without a delete window, and retrieve API keys from macOS Keychain.
- Input: provider identifier and secret value.
- Output: secret value on demand.
- Errors: key not found, Keychain read/write failure, access denied.
- Test strategy: wrap Keychain behind a protocol; use in-memory fake for unit tests and manual Keychain verification.

## `LaunchAtLoginService`

- Responsibility: enable, disable, and report local launch-at-login state.
- Input: current app bundle URL.
- Output: user LaunchAgent presence and launchctl load/unload result.
- Errors: LaunchAgent write/remove failure, launchctl bootstrap/bootout failure.
- Test strategy: unit-test plist generation; manual QA state detection and enable/disable against the real user LaunchAgent.

## `PersonalDictionaryStore`

- Responsibility: persist explicit local vocabulary and correction hints.
- Input: vocabulary terms and wrong-to-right correction pairs.
- Output: typed dictionary plus cleanup prompt context.
- Errors: invalid JSON, empty terms, malformed correction pairs, file write failures.
- Test strategy: JSON round trip, text parsing, prompt rendering, disabled-entry preservation during bulk edits, correction replacement by heard form, disabled-entry omission from prompts, and prompt-size cap checks.

## `UsageTracker`

- Responsibility: track local-only usage counters without analytics or transcript history.
- Input: audio duration and event categories such as cleanup requested, transcription failed, and cleanup fallback used.
- Output: local totals for dictations, recorded duration, cleanup requests, transcription failures, and cleanup fallbacks.
- Errors: counter persistence failure should fail soft and never block dictation.
- Test strategy: deterministic arithmetic tests, reset behavior, and persistence tests with temporary stores.

## `DictationArchiveStore` (V1 opt-in)

- Responsibility: append, read, export, and delete opt-in local dictation archive entries without storing audio.
- Input: completed dictation metadata, final draft text, raw/spoken word count, final draft word count, and optional raw transcript text only when raw transcript archiving is enabled.
- Output: daily JSONL files, date-range archive entries, monthly word-count aggregates, and Markdown exports.
- Errors: archive write/read/delete failures should be visible but must not block paste or lose the final draft; malformed JSONL lines should be skipped with line-specific recovery warnings while valid surrounding entries remain available.
- Test strategy: disabled-by-default checks, JSONL round trip and damaged-line recovery with temporary directories, word-count aggregation checks, export rendering checks, raw-transcript opt-in checks, and destructive clear confirmation coverage.

## `ArchiveSummaryService` (future optional)

- Responsibility: prepare monthly topic-summary inputs from archive entries and, only after explicit user action, request an AI summary through the configured provider.
- Input: date range, selected archive entries, summary style, provider configuration, and API key if AI summary generation is chosen.
- Output: local monthly summary text or a provider-generated topic summary.
- Errors: provider failure, archive read failure, or oversized summary input should leave archive data unchanged and provide a copy/export fallback.
- Test strategy: provider-destination confirmation flow, prompt-size/content-scope checks, no automatic-send regression tests, and fallback export tests.

## `PrivacyDiagnosticsBuilder`

- Responsibility: produce or sanitize copyable diagnostics without secrets, transcripts, audio paths, clipboard contents, or provider request/response bodies.
- Input: state summaries, provider settings, counters, dictionary counts, and diagnostic event categories.
- Output: redacted plain-text diagnostics suitable for sharing during debugging.
- Errors: none; redaction must be conservative.
- Test strategy: redaction tests for API-key-like and bearer-token-like strings.
