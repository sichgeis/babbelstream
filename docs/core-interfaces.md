# Core Interfaces

These are the main protocol boundaries for the native macOS MVP. Implemented interfaces should stay small and mockable; future-only interfaces are marked as such.

## `AudioRecorder`

- Responsibility: request microphone access, record audio to a temporary file, stop/cancel recording, enforce max duration, delete partial files.
- Input: max duration, audio format settings.
- Output: temporary audio file URL and duration.
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
- Output: transcript text, optional language/duration metadata.
- Errors: missing key, invalid endpoint, unsupported request format, timeout, network failure, malformed response.
- Test strategy: URLProtocol/mock server tests for request shape, timeout, retry, and response parsing.

## `CleanupProvider`

- Responsibility: convert raw transcript into Slack-ready draft while preserving meaning and technical terms.
- Input: transcript text, cleanup prompt, provider configuration, API key.
- Output: final draft text.
- Errors: missing key, timeout, provider failure, malformed response, empty output.
- Test strategy: mock provider tests plus prompt regression cases for German and mixed technical input.

## `TextInsertionService`

- Responsibility: insert final text into the focused app using direct Accessibility insertion when possible, with clipboard plus synthetic Cmd+V as a fallback.
- Input: final text, optional captured target app.
- Output: insertion result.
- Errors: missing Accessibility permission, clipboard unavailable, paste event failed, no focused target.
- Test strategy: unit-test insertion result handling behind an adapter; manual QA for Slack, browsers, and native text fields.

## `SettingsStore`

- Responsibility: persist non-secret settings such as provider URLs, endpoint paths, model names, cleanup toggle, transcription language, transcription prompt, and max recording duration.
- Input: typed settings values.
- Output: current settings and validation errors.
- Errors: invalid URL, invalid duration, missing model, unsupported endpoint path.
- Test strategy: validation unit tests and migration/default tests.

## `SecretStore`

- Responsibility: store and retrieve API keys from macOS Keychain.
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

## `UsageTracker`

- Status: future work.
- Responsibility: track local-only usage estimates without analytics.
- Input: audio duration, estimated token counts, optional user-configured prices.
- Output: local totals and rough cost estimates.
- Errors: counter persistence failure, invalid price input.
- Test strategy: deterministic arithmetic tests and persistence tests with temporary stores.
