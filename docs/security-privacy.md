# Security And Privacy Spec

## Data Handled

- Microphone audio for the active dictation.
- Raw transcript returned by the transcription provider.
- Cleaned Slack-ready draft text.
- Provider configuration.
- API keys.
- Temporary clipboard contents during paste.

## Storage And Lifetime

- Audio: temporary file only; delete immediately after transcription succeeds, fails, times out, or is canceled.
- Transcript text: memory only, plus last transcript in memory for retry/paste-last during the running app session.
- Cleaned text: memory and, when the clipboard fallback path is used, the clipboard.
- API keys: macOS Keychain only. A non-secret `UserDefaults` marker may remember that a key was saved so the app can avoid reading Keychain on startup.
- Launch at login: optional user LaunchAgent plist storing only the app bundle path; removable from Settings.
- Usage counters: future work; when added, they should use local non-secret settings storage only.

## Clipboard Implications

Clipboard fallback places work text on the system clipboard. Direct Accessibility insertion should avoid clipboard writes when the focused element supports it. When the app has to use synthetic Cmd+V, paste success cannot be confirmed reliably across all targets, so the final text remains on the clipboard with a visible status message.

## Network Destinations

The app sends audio to the configured transcription endpoint and transcript text to the configured cleanup endpoint when cleanup is enabled. The settings UI must show provider base URL and model names. The app must not silently switch providers.

## Debug Logging Policy

Default logs may include timestamps, state names, durations, provider labels, error categories, and short sanitized provider error messages. Default logs must not include audio, transcripts, cleanup input/output, API keys, clipboard contents, or request bodies. Debug persistence must be opt-in and visibly enabled.

## Threat Model

- Accidental recording of private speech.
- Accidental paste into the wrong app.
- Sending work content to the wrong provider.
- API key leakage.
- Repeated Keychain prompts caused by startup secret reads or unstable local code signatures.
- Transcript/audio persistence through logs or temp files.
- Clipboard exposure to other apps.
- Accessibility permission abuse if compromised.

## Accessibility Risks

Accessibility permission allows the app to synthesize paste shortcuts and may enable future focused-app inspection. The app should request it only with clear explanation, avoid broad automation beyond paste, and fail safely when permission is absent.

## Provider Transparency

Before first use, the app should show which provider base URL receives audio and which endpoint receives cleanup text. Changing provider settings should be explicit. Direct OpenAI and LiteLLM-compatible providers should be represented as profiles, not hidden behavior.

## Work Slack Considerations

Slack messages may contain confidential work data. The MVP should avoid history, telemetry, cloud sync, and auto-send. Users should be able to disable cleanup to avoid sending transcript text to a second model endpoint.
