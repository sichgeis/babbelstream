# Test Plan

## Automated Check Runner

Run `task check`. It builds the app and executes `BabbelStreamChecks`, including settings validation, provider response/retry checks through a local `URLProtocol`, zero-byte connection-stall recovery, provider cancellation without retry, prompt/dictionary behavior, archive round trips and damaged-line recovery, diagnostics redaction, temp-file helpers, insertion policy, settings persistence, and usage counters.

This CLT-only environment can compile but cannot execute XCTest or Swift Testing through SwiftPM. The empty test target was removed so `swift test` now fails honestly with `no tests found` instead of returning a false green. Coordinator behavior tied to AppKit, Accessibility, Keychain, microphone permissions, and application termination remains in the manual matrix below.

## Unit Tests

- Provider configuration validation.
- Transcription language validation: `de`/`en` accepted, free-form `German, English` not sent as `language`.
- Cleanup prompt regression checks.
- Settings defaults and migrations.
- Configurable max recording duration defaults to 10 minutes and rejects values above the cap.
- Usage counter arithmetic and reset behavior.
- Dictation archive default-off behavior, JSONL round trip, damaged-line recovery, word-count aggregation, monthly export rendering, and clear behavior.
- Privacy-safe diagnostics redaction.
- Temp-file deletion policy.
- Text insertion result handling behind an adapter.
- Keychain wrapper behavior with an in-memory fake.
- Startup does not read the Keychain secret; API key presence is represented by a non-secret marker.
- Personal dictionary JSON round trip, text parsing, disabled-entry preservation, correction teaching/update de-duplication, cleanup prompt rendering, and prompt-size capping.

## Integration Tests

- Mock transcription endpoint request shape and response parsing.
- Mock cleanup endpoint request shape and fallback behavior.
- Provider HTTP error body extraction without logging request bodies or transcripts.
- Cleanup request encodes the transcript as data-only JSON rather than bare instruction-shaped user prose.
- Cleanup request includes dictionary context in the existing cleanup call when entries exist.
- Oversized dictionary context skips entries with counts instead of failing dictation.
- Archive integration writes one completed-dictation entry only when enabled and never writes audio paths or API keys.
- Coordinator flow from audio URL to pasted text using fakes.
- Connection timeout, request timeout, retry, cancellation, invalid-key, and malformed-response cases.

## Manual QA Checklist

- App launches as a menu-bar utility.
- Recording state is visible.
- The HUD shows the captured target, provider host, elapsed time, cancellation control, transcription attempt count, connection/request timeout guidance, and retry reason without activating BabbelStream.
- Dictation pastes into the currently focused field in native Mail and in reactive editors such as VS Code and Codex.
- Moving focus to another field inside the same app directs the draft to that current field; switching to another application blocks auto-paste and leaves the draft on the clipboard.
- Escape cancels while recording and processing but behaves normally after the operation ends.
- Cleanup can be toggled.
- Provider destination is visible in settings.
- Edited provider values are visibly inactive until `Apply Settings` succeeds; the saved destination remains truthful.
- Usage counters are visible in Settings and can be reset.
- Copy Diagnostics produces a redacted report without transcripts, audio paths, clipboard contents, or API keys.
- Menu/Settings diagnostics show the git short commit hash for the installed build.
- No message is auto-sent.
- No transcript or audio file remains after normal use when the archive is disabled.
- Optional archive is visibly disabled by default.
- When enabled, the archive writes a daily local JSONL entry with final draft text, word counts, and no audio.
- Monthly archive review can count words by day/month and export the selected month for inspection.
- Personal dictionary edits are picked up on the next cleanup without app restart.
- Teach Correction can add or update a correction hint without storing transcript history.
- Starting or failing a later dictation does not erase the previous successful draft.

## Slack Desktop Cases

- Main channel composer.
- Thread reply composer.
- Message edit field.
- Empty composer.
- Composer with existing text.
- Consecutive dictations into the same composer leave at least one space between chunks.
- Focus changes before paste copy the draft instead of inserting into the wrong Slack composer.

## Slack Browser Cases

- Chrome, Safari, or the user's default browser.
- Main composer and thread composer.
- Clipboard fallback leaves the final draft available for manual Cmd+V when automatic paste cannot be confirmed.

## Email Compose Cases

- Apple Mail new-message body and subject fields.
- Microsoft Outlook new-message body and subject fields.
- Paste Last Draft from the menu after focusing an email compose field.
- Clipboard fallback leaves the final draft available for manual Cmd+V when automatic paste cannot be confirmed.

## Language Cases

- English: "Can you take a look at BACKEND-123 before standup?"
- German: "Kannst du bitte das Ticket nochmal prüfen und mir kurz Feedback geben?"
- Mixed: "Ich habe im prompting-service repo den BACKEND-123 fix gepusht, aber CI ist noch flaky."
- Technical: URLs, file paths, Swift symbols, Jira keys, acronyms, model names, and product names.
- Cleanup must not translate: English input remains English, German input remains German, and mixed input remains mixed.
- Cleanup treats command-like or prompt-like dictation as dictated content, not cleanup instructions.
- Cleanup must not answer, refuse, ask follow-up questions, or mention capabilities when the dictation itself sounds like a request.
- Cleanup preserves paragraph/sentence order and speaker wording except for light filler removal, punctuation, paragraph breaks, and obvious transcription slips.
- Cleanup returns plain text only, without Markdown headings, bullets, code fences, block quotes, labels, or commentary.
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

## Archive Tests

- Archive setting defaults to disabled for new installs and migrations.
- Disabled archive writes no transcript, final draft, raw transcript, or archive metadata files.
- Enabled archive appends one valid JSONL object per completed dictation to `Archive/YYYY-MM/YYYY-MM-DD.jsonl`.
- Archive entries include timestamp, id, provider labels, cleanup state, insertion outcome, audio duration, raw/spoken word count, final draft word count, and final draft text.
- Raw transcript text is omitted unless the separate raw-transcript archive setting is enabled.
- Audio file paths, API keys, provider request bodies, and clipboard contents are never stored in archive entries.
- Monthly aggregation counts words by day and month deterministically.
- Markdown monthly export preserves entry ordering and contents.
- A malformed JSONL line produces a visible recovery warning while valid entries remain reviewable/exportable.
- Future topic-summary generation requires explicit user action and visible provider destination before any archive text is sent.
- Clear archive requires confirmation and removes only archive files.

## Privacy Tests

- Confirm temporary audio deletion on success, failure, timeout, cancel, and app termination.
- Confirm a forced deletion failure remains visible and is retried by stale-file cleanup on relaunch.
- Confirm no transcript history is written to disk when the archive is disabled.
- Confirm archive files are local-only, text-only, user-visible, and absent unless explicitly enabled.
- Confirm personal dictionary contains only explicit terms/corrections and no transcript history.
- Confirm logs exclude audio, transcripts, archive contents, API keys, and clipboard content.
- Confirm copied diagnostics exclude audio, transcripts, archive contents, API keys, audio paths, request bodies, and clipboard content.
- Confirm copied diagnostics include the non-secret build commit hash.
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
