# Test Plan

## Unit Tests

- Provider configuration validation.
- Cleanup prompt regression checks.
- Settings defaults and migrations.
- Usage estimate arithmetic once usage tracking is implemented.
- Temp-file deletion policy.
- Text insertion result handling behind an adapter.
- Keychain wrapper behavior with an in-memory fake.

## Integration Tests

- Mock transcription endpoint request shape and response parsing.
- Mock cleanup endpoint request shape and fallback behavior.
- Coordinator flow from audio URL to pasted text using fakes.
- Timeout, retry, invalid-key, and malformed-response cases.

## Manual QA Checklist

- App launches as a menu-bar utility.
- Recording state is visible.
- Cleanup can be toggled.
- Provider destination is visible in settings.
- No message is auto-sent.
- No transcript or audio file remains after normal use.

## Slack Desktop Cases

- Main channel composer.
- Thread reply composer.
- Message edit field.
- Empty composer.
- Composer with existing text.
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

## Latency Tests

- 5-second, 15-second, and 60-second dictations.
- Transcription-only versus transcription plus cleanup.
- Provider timeout and retry behavior.

## API-Cost Tests

- Future work until local usage tracking exists.
- Track dictated minutes locally.
- Track approximate cleanup tokens locally.
- Estimate monthly transcription cost as `minutes dictated * price per minute`.
- Estimate cleanup cost as `tokens used * model price`.
- Do not send analytics anywhere.

## Privacy Tests

- Confirm temporary audio deletion on success, failure, timeout, and cancel.
- Confirm no transcript history is written to disk.
- Confirm logs exclude audio, transcripts, API keys, and clipboard content.
- Confirm debug persistence is explicit and visible.

## Permissions Tests

- Missing microphone permission.
- Missing Accessibility permission.
- Permission granted after denial.
- App restart after permission changes.

## Failure Mode Tests

- Missing API key.
- Invalid base URL.
- Endpoint does not support audio transcription.
- Network offline.
- Cleanup provider failure after successful transcription.
- Clipboard unavailable.
- Paste target missing or focus lost.
