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
  -> SwiftUI SettingsView
```

## Data Flow

1. Hotkey press starts `AudioRecorder`.
2. Hotkey release stops recording and returns a temporary audio URL.
3. `TranscriptionProvider` uploads audio to the configured OpenAI-compatible endpoint.
4. The temporary audio file is deleted after transcription completes or fails.
5. `AppState` reloads the local personal dictionary from Application Support when cleanup is enabled.
6. `CleanupProvider` rewrites the transcript when cleanup is enabled, using dictionary context in the same model call.
7. Usage counters are updated locally for dictation attempts, recorded duration, cleanup requests, transcription failures, and cleanup fallbacks.
8. `TextInsertionService` first tries direct Accessibility insertion into the focused element. If the target app does not support that path, it writes the final text to the clipboard, reactivates the captured target app, and simulates Cmd+V. Because the Cmd+V path cannot be confirmed reliably across Slack, browsers, and native apps, the final draft remains on the clipboard as a visible fallback.
9. The app keeps only the latest raw/final draft in memory for copy/retry during the running session.

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

## Audio Recording Approach

Use AVFoundation to record compressed audio to a temporary file. The MVP default maximum duration is 10 minutes and can be lowered in Settings. The recorder must clean up partial files on cancel, timeout, provider failure, and app quit.

## Transcription Approach

Use multipart upload for `/v1/audio/transcriptions`-style endpoints. The provider should return plain transcript text plus optional metadata if available. Do not build provider-specific assumptions into UI state.

## Cleanup Approach

Use a chat/completions-compatible endpoint with a fixed Slack-ready cleanup system prompt and the transcript as user input. Cleanup is enabled by default and can be disabled. Cleanup must preserve the language of each sentence or phrase; it must not translate between German and English. If cleanup fails after transcription succeeds, paste the raw transcript and notify the user.

## Personal Dictionary

Use a local JSON dictionary at `~/Library/Application Support/BabbelStream/personal-dictionary.json` for explicit vocabulary and correction hints. The app reloads it before each cleanup request and appends compact context to the cleanup system prompt. The injected context is capped by `ProjectDefaults.maxPersonalDictionaryPromptCharacters`; if entries are skipped, the app warns and records only counts. The Teach Correction window writes explicit wrong-to-right hints into the same store and de-duplicates them case-insensitively. This version is cleanup-only: it does not perform deterministic local replacements, automatic learning, or a second model call.

A lightweight personal Codex skill may edit the same file directly. No MCP server is required for this version.

## Paste Insertion Approach

Use direct Accessibility insertion when the focused element supports it. Fall back to NSPasteboard and simulated Cmd+V because it works across Slack desktop, browser Slack, and many native text fields. If paste cannot be confirmed, leave the final text on the clipboard and notify the user.

## Settings And Secrets

Use `UserDefaults` for non-secret settings and Keychain for API keys. Avoid plaintext config files for secrets. The settings UI should show which provider destination will receive audio and text. Startup must not read the Keychain secret; it may use a non-secret `UserDefaults` presence marker so relaunching the app does not trigger a Keychain access prompt. The real API key should be read only when a provider request is about to run.

## Launch At Login

The app can create or remove a user LaunchAgent at `~/Library/LaunchAgents/com.sichgeis.babbelstream.loginitem.plist` from Settings. The LaunchAgent runs `/usr/bin/open` against the current app bundle path at login. This keeps launch-at-login local and reversible without adding a helper app or installer package for the MVP.

## Logging And Debugging

Default logs may include state transitions, provider names, durations, counts, and error categories. Copyable diagnostics include provider settings, state, permissions, counters, dictionary counts, and recent sanitized event categories. They must not include audio, transcripts, cleanup input, cleanup output, API keys, clipboard contents, or audio file paths. Debug persistence must be explicit and visibly enabled.

## Security And Privacy

The main risks are accidental capture, accidental paste, clipboard exposure, overbroad Accessibility permission, and sending work content to the wrong provider. The app should prefer obvious state, explicit provider configuration, no history, immediate audio deletion, and no auto-send.
