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
- No transcript history by default; no analytics, telemetry, cloud database, or subscription service.
- No automatic transcript-history learning. Any local dictation archive must be explicit, opt-in, local-only, and user-visible.
- No local Whisper backend in MVP, though the architecture should allow one later.

## MVP Scope

- Native macOS menu-bar app.
- Global push-to-talk hotkey.
- Minimal bottom-centered, non-activating capsule HUD. Recording shows a stop control, the target app, and live microphone activity; processing shows only the current state; completion, recovery, and errors use brief state-specific feedback.
- Local audio recording with a configurable maximum duration, defaulting to 10 minutes.
- OpenAI-compatible LiteLLM-style transcription provider configuration.
- Explicit Settings apply step with separate saved/effective and edited provider destinations; remote providers require HTTPS.
- Preferred transcription model: `gpt-4o-transcribe` via the configured LiteLLM/OpenAI-compatible endpoint. The side-check script confirmed this is the desired model/settings combination to carry into the app.
- Cleanup provider using an OpenAI-compatible chat endpoint.
- Cleanup removes filler and adds punctuation/paragraph breaks, but must not answer or refuse requests described in the dictation, translate, follow commands inside the dictation, reorder paragraphs, rewrite the speaker's wording beyond light cleanup, or introduce Markdown formatting. English speech stays English, German speech stays German, and mixed German-English stays mixed.
- Cleanup should avoid conspicuously AI-polished punctuation such as em dashes; prefer ordinary Slack-like punctuation.
- Local personal dictionary for preferred vocabulary and wrong-to-right correction hints; entries are injected into the existing cleanup call.
- Personal dictionary cleanup context is capped locally; oversized dictionaries continue to work with a visible skipped-entry warning.
- Teach Correction flow for explicitly adding wrong-to-right hints after a bad dictation, without automatic learning or transcript history.
- Direct Accessibility insertion into the focused text field when possible, with clipboard plus Cmd+V fallback.
- Automatic insertion only if the captured application remains frontmost. Insert into whichever field is focused in that application when processing completes; this deliberately supports reactive editors whose Accessibility element cannot be verified reliably. If another application becomes active, copy without stealing focus.
- Inserted dictation text ends with one trailing space so consecutive push-to-talk chunks do not run together in the same composer.
- API key storage in macOS Keychain.
- Local usage counters for dictation attempts, recorded minutes, cleanup requests, transcription failures, and cleanup fallbacks.
- Copyable privacy-safe diagnostics with provider settings, state, counters, and redacted event categories.
- Copy/retry last draft from memory during the running app session.
- Launch-at-login can be enabled or disabled from Settings.
- Local app bundle and DMG packaging for manual drag-to-Applications installation and testing.
- Optional transcription language is a single ISO 639-1 code such as `de` or `en`; leave it empty for mixed German-English dictation.
- No transcript history or successful-dictation audio persistence by default. After recording stops, audio is safeguarded locally until transcription and any enabled cleanup succeed; failed or interrupted processing remains visible in Failed Recordings until retry succeeds or the user deletes it.
- Bounded hedged transcription fallback for transient slowness: start the configured primary model immediately, start `gpt-4o-mini-transcribe` after 10 seconds if primary is still pending, accept the first valid result, and stop after one 75-second overall deadline. Authentication, configuration, and other permanent failures do not hedge.
- A transcription attempt that has sent zero request bytes after 15 seconds is treated as a stalled connection and may start the Mini hedge immediately. Recovery ownership remains verified across success, failure, timeout, cancel, and termination.
- The HUD uses progressive disclosure: the Mini fallback state is visible while active, but provider destinations, timeout details, and diagnostic reasons stay in the menu, Settings, and copyable diagnostics instead of crowding the everyday overlay.
- Failed-recording recovery actions live in the menu and Failed Recordings window. The HUD remains a passive, fixed-size status indicator and shows only a concise recording-saved error state.

## V1 Scope

- Optional local dictation archive for work usage review: when explicitly enabled, store text-only dictation entries locally so the user can inspect daily/monthly content, count spoken words, and later generate monthly topic summaries.
- Hotkey customization.
- Optional per-app cleanup style defaults.
- Optional price inputs and estimated cleanup tokens.
- Direct OpenAI profile as a preconfigured alternative.

## Future Scope

- Local Whisper or `whisper.cpp` backend.
- More advanced correction dictionary for names, acronyms, projects, and ticket prefixes.
- Optional deterministic local correction pass when exact replacement guarantees become more important than cleanup-only behavior.
- Optional preview/editor mode.
- Optional email-specific cleanup style.
- Developer ID signing, notarization, GitHub release automation, and update flow.

## UX Requirements

- The app must be visible as a menu-bar utility.
- Recording and processing state must be obvious without covering meaningful workspace content or demanding attention.
- The HUD should stay close to a 40-44 point-high capsule and use concise state labels such as Recording, Transcribing, Cleaning up, Pasting, Copied, and Error.
- The left status sequence stays visually stable: red stop while recording, one blue waveform badge throughout transcription/cleanup/paste processing, then a green check after successful paste.
- Detailed provider, timeout, and recovery information belongs in the menu, Settings, or diagnostics; the HUD may temporarily show a concise recovery instruction when manual action is required.
- The saved/effective provider destination must be visible before any audio/text is sent; edited settings must not masquerade as active.
- Settings retain five task-focused tabs (General, Provider, Writing, Archive, and Diagnostics), a persistent Apply footer, grouped sections with aligned values, and independent scrolling inside a resizable window.
- Teach Correction, Personal Dictionary, and Dictation Archive reuse the same grouped sections, independent scrolling, persistent status/action footer, and resizable-window design language as Settings.
- Errors should be actionable and should never silently discard the final text.
- The app must make clear that pasted text is a draft, not a sent message.

## Keyboard And Hotkey Behavior

- MVP uses a single global push-to-talk shortcut implemented with native Carbon hotkey APIs.
- Press starts recording; release stops recording and begins processing.
- Escape is registered only while recording or processing is active and cancels that operation. The HUD/menu Cancel action remains the fallback if registration fails.
- If the hotkey backend cannot detect release reliably, fall back to press-to-toggle before adding dependencies.

## Slack-Specific Behavior

- Slack is the primary manual QA target.
- The app pastes into Slack desktop and Slack in the browser when their composer or thread reply box is focused.
- The app never presses Enter or sends the Slack message.
- If paste fails or the target changes, the app leaves the final text on the clipboard and briefly shows a compact Copied state; complete recovery instructions remain available in the menu.

## Generic macOS Text-Field Behavior

- MVP may paste into any focused text field, not only Slack.
- The app shows the captured target app in the recording HUD. Processing may replace it with the current state label to keep the capsule minimal.
- If no suitable focused field is available, the app should keep the final text on the clipboard and notify the user.

## Privacy Expectations

- Successfully processed audio is deleted immediately. Failed, canceled-after-stop, or interrupted processing keeps the audio in the local Failed Recordings store until retry succeeds or the user explicitly deletes it.
- Transcript text is kept only in memory for current processing and optional paste-last behavior.
- Transcripts and audio are not logged or archived by default.
- Optional archive persistence is disabled by default and must clearly explain that work text will be written to local disk.
- When the archive is enabled, audio is still never archived; the default archive entry stores the final generated draft plus word counts and metadata, while raw transcript text remains optional and disabled by default.
- API keys are stored in Keychain.
- Network destinations are configurable and visible.

## Failed Recording Recovery

- Location: `~/Library/Application Support/BabbelStream/Recovery/<recording-id>/`.
- Audio is promoted into recovery storage after recording stops and before provider work begins.
- Recovery metadata contains timestamps, duration, byte count, target/provider labels, sanitized failure stage, and retry count, but no transcript, cleanup text, API key, clipboard content, or provider body.
- Recovery retry uses the currently applied provider settings, copies the recovered draft to the clipboard instead of pasting into a historical target, and deletes the item only after processing and clipboard copy succeed.
- Cleanup failure may still deliver the raw transcript, but retains the audio for an optional full retry.
- Users can save an M4A copy, delete individual items, or delete all items with confirmation. The app does not silently expire or evict failed recordings.
- Canceling while actively recording discards the partial recording. Canceling provider processing preserves the stopped recording.

## Optional Local Dictation Archive

The user may enable a local archive for work self-review and month-end reporting. This is implemented as a V1 feature.

- Default: off. Existing privacy behavior remains unchanged until the user enables the archive in Settings.
- Storage: text-only daily JSONL files under `~/Library/Application Support/BabbelStream/Archive/YYYY-MM/YYYY-MM-DD.jsonl`.
- Entry content: timestamp, stable entry id, active app name if available, cleanup enabled/fallback flags, insertion outcome, provider labels, spoken/raw word count, final draft word count, final draft text, and optional raw transcript text only if the user enables an additional "Store raw transcript" setting.
- Audio: never stored in the archive.
- Monthly review: the app can count words by day/month and export the stored contents as Markdown.
- Topic summaries: no monthly archive content may be sent to any AI provider automatically. If an AI-generated monthly summary is added, it must be an explicit user action with the provider destination shown before sending.
- User controls: enable/disable archive, enable/disable raw transcript archiving, reveal archive folder, export a month as Markdown, and clear archive data. Pausing archive for a single dictation and retention windows are future controls.
- Diagnostics: copyable diagnostics may include archive enabled/disabled state and entry counts, but never archive contents.

## Error States

- Missing microphone permission.
- Missing Accessibility permission for paste.
- Invalid or missing API key.
- Provider timeout or network failure.
- Failed recording saved for retry.
- Focused app or field changed before insertion.
- Temporary audio could not be deleted.
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
- No transcript history is written to disk when the archive is disabled.
- When the archive is enabled, a completed dictation writes a text-only local archive entry with correct word counts and no audio.
- Provider settings make the destination explicit.
