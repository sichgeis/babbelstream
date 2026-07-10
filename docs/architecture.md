# Architecture

## Recommended Architecture

BabbelStream is a native macOS menu-bar app with an AppKit status item, SwiftUI settings, and a small core layer for testable logic. The MVP uses native macOS APIs before adding dependencies: AVFoundation for audio recording, Carbon for the global hotkey, URLSession for provider calls, Security/Keychain for secrets, Accessibility for direct insertion where possible, and NSPasteboard plus synthetic Cmd+V as a fallback.

## Alternatives Considered

- Slack bot/app: rejected for MVP because the desired UX is dictating into the focused composer, not talking to a bot or routing through Slack APIs.
- Browser extension: rejected because Slack desktop and other apps should work.
- Electron: rejected because the app is small, permission-heavy, and should feel native.
- Local Whisper first: deferred because packaging, performance, and model management would dominate the MVP.
- KeyboardShortcuts package: deferred until shortcut customization needs a polished recorder UI.

## Component Diagram

```text
AppKit status-item app
  -> HotkeyService
  -> AudioRecorder
  -> AppState dictation flow
     -> TranscriptionProvider
     -> CleanupProvider
     -> TextInsertionService
  -> SettingsStore
  -> SecretStore
  -> PersonalDictionaryStore
  -> DictationArchiveStore
  -> SwiftUI SettingsView
```

## Data Flow

1. Hotkey press starts `AudioRecorder`.
2. `AppState` snapshots the saved settings and the focused application/Accessibility element for the whole dictation.
3. The non-activating status HUD shows recording state, target, provider host, elapsed time, and cancellation controls.
4. Hotkey release stops recording and returns a temporary audio URL.
5. `TranscriptionProvider` uploads audio to the configured OpenAI-compatible endpoint and retries only bounded transient failures.
6. The temporary audio file remains tracked until verified deletion after success, failure, timeout, or cancellation. Termination performs a final synchronous cleanup attempt.
7. `AppState` reloads the local personal dictionary from Application Support when cleanup is enabled.
8. `CleanupProvider` lightly formats the transcript when cleanup is enabled, using dictionary context in the same model call.
9. Usage counters are updated locally for dictation attempts, recorded duration, cleanup requests, transcription failures, and cleanup fallbacks.
10. `TextInsertionService` inserts only if the captured application and focused Accessibility element still match. It never steals focus back from a different app. If the target changed or cannot be verified, the final draft is copied and the HUD instructs the user to paste manually.
11. If the optional local archive is enabled, `DictationArchiveStore` appends a text-only entry for completed dictations with the final draft, word counts, provider labels, cleanup state, and insertion outcome. Raw transcript text is stored only when a separate raw-transcript archive setting is enabled. Archive write failures are surfaced but must not undo paste or block access to the final draft.
12. The app keeps the latest successful raw/final draft in memory for copy/retry and does not discard it merely because a later attempt starts or fails.

## Permission Model

- Microphone: required for recording.
- Accessibility: required for reliable simulated paste and future active-app/focused-field checks.
- Input Monitoring: avoid for MVP if Carbon hotkeys work without it; document if a future hotkey path requires it.

## Provider Abstraction

Provider settings should include:

- Base URL.
- API key reference in Keychain.
- Transcription endpoint path.
- Cleanup endpoint path.
- Transcription model name.
- Cleanup model name.
- Optional transcription language code. This must be a single ISO 639-1 code such as `de` or `en`; mixed-language dictation should leave it empty and use prompt/cleanup hints.
- Timeout.
- Retry policy.
- Maximum audio duration, editable in Settings and defaulting to 10 minutes.
- Optional future price inputs for local cost estimates.

The default shape targets OpenAI-compatible LiteLLM endpoints. It is still an integration risk that a specific LiteLLM proxy may not support OpenAI-compatible audio transcription even if the app's request shape is valid.

Remote provider URLs must use HTTPS. Plain HTTP is accepted only for loopback development endpoints. Base URLs with embedded credentials, query parameters, or fragments are rejected so the effective destinations remain inspectable and diagnostics-safe.

## Audio Recording Approach

Use AVFoundation to record compressed audio to a temporary file. The MVP default maximum duration is 10 minutes and can be lowered in Settings. The recorder must clean up partial files on cancel, timeout, provider failure, and app quit.

## Transcription Approach

Use multipart upload for `/v1/audio/transcriptions`-style endpoints. The provider accepts a JSON object with a string `text` field or a genuinely plain-text response; other successful JSON shapes are rejected. The default retry count permits one additional attempt for timeouts, connection loss, HTTP 408/425/429, and 5xx responses. Authentication and other client failures are not retried.

## Cleanup Approach

Use a chat/completions-compatible endpoint with a fixed Slack-ready cleanup system prompt and a data-only JSON user message containing the transcript. Cleanup is enabled by default and can be disabled. Cleanup must treat the transcript as content, not instructions; it must preserve wording, order, and the language of each sentence or phrase, return plain text only, and must not translate between German and English. If cleanup fails after transcription succeeds, paste the raw transcript and notify the user.

## Personal Dictionary

Use a local JSON dictionary at `~/Library/Application Support/BabbelStream/personal-dictionary.json` for explicit vocabulary and correction hints. The app reloads it before each cleanup request and appends compact context to the cleanup system prompt. The injected context is capped by `ProjectDefaults.maxPersonalDictionaryPromptCharacters`; if entries are skipped, the app warns and records only counts. The Teach Correction window writes explicit wrong-to-right hints into the same store and de-duplicates them case-insensitively. This version is cleanup-only: it does not perform deterministic local replacements, automatic learning, or a second model call.

A lightweight personal Codex skill may edit the same file directly. No MCP server is required for this version.

## Dictation Archive Approach

The archive should use local daily JSONL text files instead of a database for the first version. This keeps the data inspectable, easy to back up or delete, and simple to query with app code or command-line tools while avoiding database migration and locking work until the feature needs richer search.

- Location: `~/Library/Application Support/BabbelStream/Archive/YYYY-MM/YYYY-MM-DD.jsonl`.
- File format: newline-delimited JSON, one completed dictation per line.
- Write model: a small serialized store or actor appends entries and creates parent directories with user-only permissions where possible.
- Entry identity: each entry receives a stable UUID plus `startedAt`/`completedAt` timestamps.
- Text fields: store the final draft text by default when archive is enabled. Store raw transcript text only when the user enables an additional raw-transcript option.
- Metadata fields: active app name/bundle id if available, cleanup enabled/fallback state, transcription and cleanup provider labels, optional language metadata, insertion mode/outcome, raw/spoken word count, final draft word count, and audio duration.
- Query model: monthly stats read a date range of JSONL files, aggregate word counts by day/month, and render a month to Markdown for review.
- Recovery: malformed JSONL lines are skipped with file/line warnings while valid entries remain available for review and export. The damaged local line is never silently deleted.
- Topic review: topic summaries should be generated only on explicit user action. If summary generation uses an AI provider, the UI must show the destination and approximate content scope before sending.
- Retention: default to "keep until deleted" for local control, with a future optional retention window.
- Deletion: Settings should include reveal archive folder and clear archive actions; destructive clears require confirmation.

## Paste Insertion Approach

Use direct Accessibility insertion when the captured focused element still matches. Fall back to NSPasteboard and simulated Cmd+V only while that same target remains focused. If the app or focused element changed, do not reactivate the old app or guess: leave the final text on the clipboard and explain the manual paste recovery in the HUD.

## Settings And Secrets

Use `UserDefaults` for non-secret settings and Keychain for API keys. Avoid plaintext config files for secrets. Text settings are staged until the persistent `Apply Settings` action succeeds; the UI separately shows saved/effective and edited destinations. Each dictation uses one immutable saved-settings snapshot. Startup must not read or rewrite the Keychain secret; it may use a non-secret `UserDefaults` presence marker so relaunching the app does not trigger a Keychain access prompt. The real API key is read only when a provider request is about to run, and updates use `SecItemUpdate` rather than delete-then-add replacement.

## Launch At Login

The app can create or remove a user LaunchAgent at `~/Library/LaunchAgents/com.sichgeis.babbelstream.loginitem.plist` from Settings. The LaunchAgent runs `/usr/bin/open` against the current app bundle path at login. This keeps launch-at-login local and reversible without adding a helper app or installer package for the MVP.

## Packaging And Local Install

SwiftPM builds the executable, and `scripts/build-app.sh` wraps it in a local `.app` bundle under `dist/` with the app `Info.plist`, current git short commit hash, an optional `-dirty` suffix for uncommitted local changes, and local code signature. `scripts/package-dmg.sh` creates a DMG containing the app bundle plus an `Applications` symlink, matching the standard Finder drag-to-Applications install pattern.

The daily developer install helper opens that DMG and lets Finder perform the copy to `/Applications`. The project scripts should not invoke `sudo` for local installation; if `/Applications` needs administrator authorization, Finder owns that prompt during the drag copy. Restarting the installed app is handled separately by opening `/Applications/BabbelStream.app`.

## Logging And Debugging

Default logs may include state transitions, provider names, durations, counts, build commit hash, and error categories. Copyable diagnostics include provider settings, state, permissions, counters, dictionary counts, optional archive enabled state, archive entry counts, build commit hash, and recent sanitized event categories. They must not include audio, transcripts, archive contents, cleanup input, cleanup output, API keys, clipboard contents, or audio file paths. Debug persistence must be explicit and visibly enabled.

## Security And Privacy

The main risks are accidental capture, accidental paste, clipboard exposure, overbroad Accessibility permission, local archive exposure, and sending work content to the wrong provider. The app should prefer obvious state, explicit provider configuration, no history by default, explicit opt-in archive controls, immediate audio deletion, and no auto-send.
