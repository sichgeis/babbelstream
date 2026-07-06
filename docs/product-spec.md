# Product Spec

## Problem Statement

Slack-heavy work creates a lot of short written messages that are faster to speak than type. macOS built-in dictation is not good enough for German, English, mixed German-English technical speech, names, acronyms, repository names, issue IDs, and code identifiers. The product should make voice input feel like a native writing tool rather than a chatbot.

## Target User

The primary user is a technical Mac user who writes many Slack messages during the workday, often mixing German and English. The user values speed, low friction, privacy, predictable behavior, and preserving their own tone over heavy corporate rewriting.

## Primary Workflow

1. The user focuses the Slack message box or another macOS text field.
2. The user holds a global push-to-talk hotkey.
3. The app records local microphone audio and shows a clear recording state.
4. The user releases the hotkey.
5. The app sends the temporary audio file to the configured transcription provider.
6. The app optionally runs the transcript through Slack-ready cleanup, enabled by default.
7. The app pastes the final draft into the focused field.
8. The user reviews the draft and manually presses Enter when ready.

## Non-Goals

- No Slack bot, Slack app, Slack API integration, or browser extension for MVP.
- No iOS app.
- No Electron.
- No auto-send in MVP, including no "press enter" voice command.
- No transcript history, analytics, telemetry, cloud database, or subscription service.
- No local Whisper backend in MVP, though the architecture should allow one later.

## MVP Scope

- Native macOS menu-bar app.
- Global push-to-talk hotkey.
- Local audio recording with a default maximum duration of 60 seconds.
- OpenAI-compatible LiteLLM-style transcription provider configuration.
- Preferred transcription model: `gpt-4o-transcribe` via the configured LiteLLM/OpenAI-compatible endpoint. The side-check script confirmed this is the desired model/settings combination to carry into the app.
- Cleanup provider using an OpenAI-compatible chat endpoint.
- Cleanup removes filler and adds punctuation, but must not translate. English speech stays English, German speech stays German, and mixed German-English stays mixed.
- Direct Accessibility insertion into the focused text field when possible, with clipboard plus Cmd+V fallback.
- API key storage in macOS Keychain.
- Copy/retry last draft from memory during the running app session.
- Optional transcription language is a single ISO 639-1 code such as `de` or `en`; leave it empty for mixed German-English dictation.
- No transcript/audio persistence by default.

## V1 Scope

- Editable provider settings UI with validation.
- Hotkey customization.
- Better active-app indication before paste.
- Optional per-app cleanup style defaults.
- Local usage counters for dictated minutes and estimated cleanup tokens.
- Direct OpenAI profile as a preconfigured alternative.

## Future Scope

- Local Whisper or `whisper.cpp` backend.
- More advanced correction dictionary for names, acronyms, projects, and ticket prefixes.
- Optional preview/editor mode.
- Optional email-specific cleanup style.
- Packaging, signing, notarization, and update flow.

## UX Requirements

- The app must be visible as a menu-bar utility.
- Recording state must be obvious.
- Provider destination must be visible before any audio/text is sent.
- Errors should be actionable and should never silently discard the final text.
- The app must make clear that pasted text is a draft, not a sent message.

## Keyboard And Hotkey Behavior

- MVP uses a single global push-to-talk shortcut implemented with native Carbon hotkey APIs.
- Press starts recording; release stops recording and begins processing.
- Escape cancels the active recording or processing where feasible.
- If the hotkey backend cannot detect release reliably, fall back to press-to-toggle before adding dependencies.

## Slack-Specific Behavior

- Slack is the primary manual QA target.
- The app pastes into Slack desktop and Slack in the browser when their composer or thread reply box is focused.
- The app never presses Enter or sends the Slack message.
- If paste fails, the app leaves the final text on the clipboard and shows a notification.

## Generic macOS Text-Field Behavior

- MVP may paste into any focused text field, not only Slack.
- The app should show the active app name before or during processing once active-app detection exists.
- If no suitable focused field is available, the app should keep the final text on the clipboard and notify the user.

## Privacy Expectations

- Temporary audio is deleted immediately after processing unless debug mode is explicitly enabled.
- Transcript text is kept only in memory for current processing and optional paste-last behavior.
- Transcripts and audio are not logged by default.
- API keys are stored in Keychain.
- Network destinations are configurable and visible.

## Error States

- Missing microphone permission.
- Missing Accessibility permission for paste.
- Invalid or missing API key.
- Provider timeout or network failure.
- Unsupported transcription endpoint shape.
- Cleanup failure.
- Clipboard or paste failure.
- Recording duration limit reached.

## Acceptance Criteria

- A short English Slack message can be dictated and pasted as a draft.
- A short German Slack message can be dictated and pasted as German.
- Mixed German-English technical speech preserves terms such as repository names, ticket IDs, acronyms, URLs, and code identifiers.
- No message is auto-sent.
- Audio is deleted after normal processing.
- No transcript history is written to disk.
- Provider settings make the destination explicit.
