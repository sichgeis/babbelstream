# Test Plan

## Unit Tests

- Provider configuration validation.
- Transcription language validation: `de`/`en` accepted, free-form `German, English` not sent as `language`.
- Cleanup prompt regression checks.
- Settings defaults and migrations.
- Configurable max recording duration defaults to 10 minutes and rejects values above the cap.
- Usage counter arithmetic and reset behavior.
- Privacy-safe diagnostics redaction.
- Temp-file deletion policy.
- Text insertion result handling behind an adapter.
- Keychain wrapper behavior with an in-memory fake.
- Startup does not read the Keychain secret; API key presence is represented by a non-secret marker.
- Personal dictionary JSON round trip, text parsing, disabled-entry omission, correction teaching de-duplication, cleanup prompt rendering, and prompt-size capping.

## Integration Tests

- Mock transcription endpoint request shape and response parsing.
- Mock cleanup endpoint request shape and fallback behavior.
- Provider HTTP error body extraction without logging request bodies or transcripts.
- Cleanup request includes dictionary context in the existing cleanup call when entries exist.
- Oversized dictionary context skips entries with counts instead of failing dictation.
- Coordinator flow from audio URL to pasted text using fakes.
- Timeout, retry, invalid-key, and malformed-response cases.

## Manual QA Checklist

- App launches as a menu-bar utility.
- Recording state is visible.
- Cleanup can be toggled.
- Provider destination is visible in settings.
- Usage counters are visible in Settings and can be reset.
- Copy Diagnostics produces a redacted report without transcripts, audio paths, clipboard contents, or API keys.
- No message is auto-sent.
- No transcript or audio file remains after normal use.
- Personal dictionary edits are picked up on the next cleanup without app restart.
- Teach Correction can add or update a correction hint without storing transcript history.

## Slack Desktop Cases

- Main channel composer.
- Thread reply composer.
- Message edit field.
- Empty composer.
- Composer with existing text.
- Consecutive dictations into the same composer leave at least one space between chunks.
- Focus changes before paste.

## Slack Browser Cases

- Chrome, Safari, or the user's default browser.
- Main composer and thread composer.
- Clipboard fallback leaves the final draft available for manual Cmd+V when automatic paste cannot be confirmed.

## Language Cases

- English: "Can you take a look at BACKEND-123 before standup?"
- German: "Kannst du bitte das Ticket nochmal prüfen und mir kurz Feedback geben?"
- Mixed: "Ich habe im prompting-service repo den BACKEND-123 fix gepusht, aber CI ist noch flaky."
- Technical: URLs, file paths, Swift symbols, Jira keys, acronyms, model names, and product names.
- Cleanup must not translate: English input remains English, German input remains German, and mixed input remains mixed.
- Cleanup should not introduce em dashes or other conspicuously AI-polished punctuation.
- Dictionary hints: preferred terms such as `LiteLLM` and corrections such as `light LM => LiteLLM`.

## Latency Tests

- 5-second, 15-second, 60-second, and long-form dictations up to the 10-minute cap.
- Transcription-only versus transcription plus cleanup.
- Provider timeout and retry behavior.

## Usage And API-Cost Tests

- Track dictated minutes locally.
- Track cleanup request count locally.
- Track transcription failures and cleanup fallbacks locally.
- Future work: track approximate cleanup tokens and optional price inputs.
- Do not send analytics anywhere.

## Privacy Tests

- Confirm temporary audio deletion on success, failure, timeout, and cancel.
- Confirm no transcript history is written to disk.
- Confirm personal dictionary contains only explicit terms/corrections and no transcript history.
- Confirm logs exclude audio, transcripts, API keys, and clipboard content.
- Confirm copied diagnostics exclude audio, transcripts, API keys, audio paths, request bodies, and clipboard content.
- Confirm usage counters contain only counts and durations.
- Confirm debug persistence is explicit and visible.

## Permissions Tests

- Missing microphone permission.
- Missing Accessibility permission.
- Permission granted after denial.
- App restart after permission changes.
- App restart with a saved API key does not show a Keychain prompt before dictation starts.
- Launch-at-login toggle creates/removes the BabbelStream user LaunchAgent and survives app restart.

## Failure Mode Tests

- Missing API key.
- Invalid base URL.
- Endpoint does not support audio transcription.
- Network offline.
- Cleanup provider failure after successful transcription.
- Clipboard unavailable.
- Paste target missing or focus lost.
