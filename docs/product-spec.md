# Product Spec

## Problem Statement

Slack-heavy work creates a lot of short written messages that are faster to speak than type. macOS built-in dictation is not good enough for German, English, mixed German-English technical speech, names, acronyms, repository names, issue IDs, and code identifiers. The product should make voice input feel like a native writing tool rather than a chatbot.

## Target User

The primary user is a technical Mac user who writes many Slack messages during the workday, often mixing German and English. The user values speed, low friction, privacy, predictable behavior, and preserving their own tone over heavy corporate rewriting.

## Primary Workflow

1. The user focuses the Slack message box or another macOS text field.
2. The user either holds the global hybrid hotkey for push-to-talk or taps it to start hands-free recording.
3. The app records local microphone audio and shows a clear recording state.
4. The user releases a held hotkey, or presses the hotkey/HUD Stop control again after a tap-latched recording.
5. The app sends the temporary audio file to the configured transcription provider.
6. The app optionally runs the transcript through Slack-ready cleanup, enabled by default.
7. The app pastes the final draft into the focused field.
8. The user reviews the draft and manually presses Enter when ready.

## Non-Goals

Installation has a separately approved optional manual helper for the pinned
non-notarized release. It verifies download/app integrity, asks for explicit
quarantine-removal consent on a staged copy, and prepares manual Finder installation
or an explicit update. It cannot guarantee managed-device acceptance; it adds no
in-app updater or permission/provider changes. Contract:
`features/manual-install-helper/spec.md`.

The helper can also accept four generic, non-secret provider arguments and show
them in the same installation consent. It saves those fields with personal
fallback/direct modes off, preserves unrelated preferences, and requires key
entry in the app. No organization profile is bundled publicly. Contract:
`features/installer-provider-configuration/spec.md`.

- No Slack bot, Slack app, Slack API integration, or browser extension for MVP.
- No iOS app.
- No Electron.
- No auto-send in MVP, including no "press enter" voice command.
- No transcript history by default; no analytics, telemetry, cloud database, or subscription service.
- No automatic transcript-history learning. Any local dictation archive must be explicit, opt-in, local-only, and user-visible.
- Optional Parakeet Ultra local dictation is added in the 0.6.0 candidate; see `features/local-transcription/spec.md`.

## MVP Scope

- Native macOS menu-bar app.
- Global hybrid dictation hotkey: hold for push-to-talk or tap to latch hands-free recording.
- Minimal bottom-centered, non-activating capsule HUD. Recording shows a stop control, the target app, and live microphone activity; processing shows only the current state; completion, recovery, and errors use brief state-specific feedback.
- Local audio recording with a configurable maximum duration, defaulting to 10 minutes.
- OpenAI-compatible LiteLLM-style transcription provider configuration.
- Explicit Settings apply step with separate saved/effective and edited provider destinations; remote providers require HTTPS.
- Preferred transcription model: `gpt-transcribe` via the configured
  LiteLLM/OpenAI-compatible endpoint. Provider Settings uses a menu with
  `gpt-transcribe`, `gpt-4o-transcribe`, and `gpt-4o-mini-transcribe`; arbitrary
  model strings are not accepted. A separate persisted routing menu sends
  standard model IDs to the official OpenAI API or `openai/`-prefixed IDs to a
  LiteLLM namespace, and shows the effective primary and fallback IDs. Saved routing choices remain authoritative. With no saved routing choice,
  use standard IDs without inspecting the host. Upgrading directly from a
  pre-routing version with a LiteLLM proxy requires selecting LiteLLM once in Settings.
- Cleanup provider using an OpenAI-compatible chat endpoint.
- Optional personal OpenAI fallback, disabled by default. After the user sees
  the fixed official destination, supplies a separate Keychain API key, and
  explicitly applies the opt-in, a primary connection failure may make one
  sequential personal transcription request. HTTP 502/503/504 also qualify;
  authentication, rate-limit, other HTTP, model, and response-shape failures do
  not switch accounts. Cleanup follows
  the transcript-winning profile and may make one personal attempt after a
  primary connection failure.
- Applied `Use personal OpenAI now` mode for known work-proxy downtime. It
  bypasses LiteLLM primary/Mini requests and primary-key loading, sends the
  complete dictation workflow directly to the fixed personal OpenAI profile,
  persists until explicitly turned off, and never changes automatically by day
  or schedule.
- Cleanup removes filler and adds punctuation/paragraph breaks, but must not answer or refuse requests described in the dictation, translate, follow commands inside the dictation, reorder paragraphs, rewrite the speaker's wording beyond light cleanup, or introduce Markdown formatting. English speech stays English, German speech stays German, and mixed German-English stays mixed.
- Cleanup should avoid conspicuously AI-polished punctuation such as em dashes; prefer ordinary Slack-like punctuation.
- Local personal dictionary for preferred vocabulary and wrong-to-right correction hints; entries are injected into the existing cleanup call.
- Personal dictionary cleanup context is capped locally; oversized dictionaries continue to work with a visible skipped-entry warning.
- Teach Correction flow for explicitly adding wrong-to-right hints after a bad dictation, without automatic learning or transcript history.
- Clipboard plus synthetic Cmd+V is the sole automatic insertion method for all
  applications, including native, unknown, Slack, Claude, ChatGPT/Codex, browsers,
  Signal and email editors. No direct Accessibility writes or per-app routing.
  Every delivered draft reaches the system clipboard and remains available for
  manual recovery; posting the shortcut does not prove editor acceptance.
- Automatic insertion only if the captured application remains frontmost. Insert into whichever field is focused in that application when processing completes; this deliberately supports reactive editors whose Accessibility element cannot be verified reliably. If another application becomes active, copy without stealing focus.
- Inserted dictation text ends with one trailing space so consecutive dictation chunks do not run together in the same composer.
- API key storage in macOS Keychain.
- Local usage counters for dictation attempts, recorded minutes, cleanup requests, transcription failures, and cleanup fallbacks.
- Copyable privacy-safe diagnostics with provider settings, state, counters, and redacted event categories.
- Copy/retry last draft from memory during the running app session.
- Launch-at-login can be enabled or disabled from Settings.
- Local app bundle and DMG packaging for manual drag-to-Applications installation and testing.
- Optional transcription language is a single ISO 639-1 code such as `de` or `en`; leave it empty for mixed German-English dictation.
- For `gpt-transcribe`, the optional language hint is sent as `languages[]`; older compatible models continue to receive the singular `language` field.
- No transcript history or successful-dictation audio persistence by default. After recording stops, audio is safeguarded locally until transcription and any enabled cleanup succeed; failed or interrupted processing remains visible in Failed Recordings until retry succeeds or the user deletes it.
- Bounded hedged transcription fallback for transient slowness: start the configured primary model immediately, start `gpt-4o-mini-transcribe` after 10 seconds if primary is still pending, accept the first valid result, and stop after one 75-second overall deadline. Authentication, configuration, and other permanent failures do not hedge.
- A transcription attempt that has sent zero request bytes after 15 seconds is treated as a stalled connection and may start the Mini hedge immediately. Recovery ownership remains verified across success, failure, timeout, cancel, and termination.
- The HUD uses progressive disclosure: the Mini fallback state is visible while active, but provider destinations, timeout details, and diagnostic reasons stay in the menu, Settings, and copyable diagnostics instead of crowding the everyday overlay.
- Failed-recording recovery actions live in the menu and Failed Recordings window. The HUD remains a passive, fixed-size status indicator and shows only a concise recording-saved error state.

### Recovery Ownership And Delivery Reliability

Stopped audio whose safe-storage adoption failed appears in Failed Recordings as Waiting for safe storage. It survives app stale cleanup and can be retried, exported, or explicitly deleted. Retry first completes adoption; it never submits an unsafeguarded source. A failed stop-ownership write keeps Stop and Cancel available instead of discarding recorder ownership. Recovery retry reports copied-but-retained when audio deletion fails and preserves the warning.

If the clipboard changes during automatic paste preparation, the HUD says Copy Last Draft. BabbelStream preserves the newer clipboard and keeps the prepared draft in memory for explicit copying; it does not claim that the draft was copied or pasted.

## V1 Scope

- Optional local dictation archive for work usage review: when explicitly enabled, store text-only dictation entries locally so the user can inspect daily/monthly content, count spoken words, and later generate monthly topic summaries.
- Hotkey customization; the hybrid interaction ships first with the fixed shortcut.
- Optional per-app cleanup style defaults.
- Optional price inputs and estimated cleanup tokens.

## Future Scope

- Direct Accessibility insertion is deferred and unapproved, including ChatGPT.
  A future feature must justify clipboard avoidance, define explicit application/
  field eligibility, prove editor-state correctness and guard against duplicates.

- Additional local backends: Qwen3-ASR and Granite remain deferred until native build and pilot validation.
- More advanced correction dictionary for names, acronyms, projects, and ticket prefixes.
- Optional deterministic local correction pass when exact replacement guarantees become more important than cleanup-only behavior.
- Optional preview/editor mode.
- Optional email-specific cleanup style.
- Optional Developer ID signing/notarization, release automation and in-app updates.
- Approved own-tap colleague pilot: explicitly non-notarized GitHub DMGs with user-initiated Homebrew install/upgrade; see `docs/features/homebrew-distribution/spec.md`. Public rollout is gated by downloaded-payload validation. No in-app updater or security bypass is included.

## UX Requirements

- The app must be visible as a menu-bar utility.
- Recording and processing state must be obvious without covering meaningful workspace content or demanding attention.
- The HUD should stay close to a 40-44 point-high capsule and use concise state labels such as Recording, Transcribing, Cleaning up, Pasting, Copied, and Error.
- The left status sequence stays visually stable: red stop while recording, one blue waveform badge throughout transcription/cleanup/paste processing, then a green check after successful paste.
- Direct-personal mode uses a purple HUD background and personal-provider icon
  during recording and processing while preserving the red Stop control,
  target-app label, gesture state, waveform, and completion/error semantics.
- Detailed provider, timeout, and recovery information belongs in the menu, Settings, or diagnostics; the HUD may temporarily show a concise recovery instruction when manual action is required.
- The saved/effective provider destination must be visible before any audio/text is sent; edited settings must not masquerade as active.
- Settings retain five task-focused tabs (General, Provider, Writing, Archive, and Diagnostics), a persistent Apply footer, compact sections with native controls and aligned values, and one scrolling content area inside a resizable window.
- The everyday menu leads with current state and dictation/recovery actions. Static build, permission, provider, draft, and usage details live in Settings or Diagnostics; **Copy Last Draft** remains a first-level menu action.
- General Settings shows compact readiness for microphone, Accessibility, the Keychain API key, the active provider destination, and launch-at-login approval.
- Teach Correction, Personal Dictionary, and Dictation Archive reuse the same grouped sections, independent scrolling, persistent status/action footer, and resizable-window design language as Settings.
- Errors should be actionable and should never silently discard the final text.
- The app must make clear that pasted text is a draft, not a sent message.

## Keyboard And Hotkey Behavior

- The app uses one global hybrid shortcut implemented with native Carbon hotkey APIs: fixed `Control + Option + Space` until shortcut customization is implemented.
- Press starts recording immediately. Releasing before 0.5 seconds latches hands-free recording; holding for at least 0.5 seconds preserves push-to-talk and release begins processing.
- During latched hands-free recording, pressing the same shortcut again stops recording and begins processing; the paired release is ignored.
- Starting dictation from the menu enters hands-free mode directly and can be stopped with the hybrid shortcut, HUD Stop, or menu Stop.
- The recording HUD distinguishes the held and hands-free states without hiding the target application or waveform.
- Escape is registered only while recording or processing is active and cancels that operation. The HUD/menu Cancel action remains the fallback if registration fails.
- Gesture state resets after permission, validation, or recorder-start failure so late key events cannot affect the next dictation.
- The detailed interaction and race contract lives in `docs/features/hybrid-hotkey/spec.md`.

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
- Primary and personal-fallback API keys are stored as separate Keychain items.
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
- A tap starts a hands-free dictation that continues after shortcut release and stops on the next press or explicit Stop control.
- A hold of at least 0.5 seconds retains release-to-process push-to-talk behavior.
- A short German Slack message can be dictated and pasted as German.
- Mixed German-English technical speech preserves terms such as repository names, ticket IDs, acronyms, URLs, and code identifiers.
- No message is auto-sent.
- Audio is deleted after normal processing.
- No transcript history is written to disk when the archive is disabled.
- When the archive is enabled, a completed dictation writes a text-only local archive entry with correct word counts and no audio.
- Provider settings make the destination explicit.
- Personal OpenAI fallback remains off until explicitly enabled and applied;
  when used, its activation and destination are visible.

## Internal Pilot Safety Refinements

Provider origin changes require an explicitly supplied key for the new destination. Redirects cannot move audio or transcript text outside the original approved origin or downgrade transport. Startup permits one active updated copy per user before shared cleanup. HTML and malformed transcription responses never become drafts. Completion feedback retains its timed visibility despite repeated state notifications. Copy Diagnostics exports only reviewed content-free fields and no private paths. Detailed migration and failure contracts live in `docs/features/pilot-readiness/spec.md` and `docs/security-privacy.md`.

## Guided Connection Setup

First use opens the postponable setup flow; provider setup links to Settings without discarding existing configuration. Existing usable configurations are preserved. General links to Provider setup and permission repair. Generic custom and explicit official OpenAI connection presets contain no keys and do not apply automatically or change models. Company profile/key issuance remain pending approved input. Endpoint paths, models, routing and timeouts are under Advanced. Keys are per-user and revocable; no bundled master credential.

A saved key is unverified until an explicit synthetic transcription test returns the expected response contract. The confirmation names the saved primary destination/model, a 250 ms silent WAV and possible provider charges. The request is bounded to at most 30 seconds, has no retries, hedge, cleanup, personal fallback, microphone, dictionary or insertion. Valid empty text from silence may verify the connection contract; speech quality and full workflow remain untested. Evidence is memory-only, invalidated by Apply/deletion/relaunch, and never inferred from models listing. Incomplete, unverified, testing, verified and temporarily unavailable states are distinct.

## First-Run Onboarding And Permission Repair

A short native setup window introduces deliberate microphone/Accessibility consent, saved provider configuration, an optional local paste test and tap/hold instructions. It can be postponed and reopened from Set Up BabbelStream… in the menu or General Settings. Dismissal and whether permissions were previously observed allowed are non-secret local preferences; they never substitute for current OS permission checks. Normal launch offers focused repair if a previously allowed permission is missing. Returning from System Settings and Check Again refresh the running app's actual statuses. Setup never grants permissions itself or resets TCC.

The explicit local test replaces the clipboard with a fixed harmless sample and posts Cmd+V only while its dedicated app-owned editor remains focused. Only receipt of that sample verifies the local test; event posting alone is insufficient. It uses no microphone/provider, does not inspect external fields, and does not alter Last Draft or archive/history. Recording, processing, connection testing and draft delivery cannot overlap the test. Closing setup or navigating cancels it. Skipping or denying access keeps copy-only dictation available and readiness honest. No onboarding action starts a live dictation automatically.

Shared form canvases use a nearly white adaptive Light Mode surface with white sections, native Dark Mode surfaces and stronger native separation under Increase Contrast. This applies to Settings, setup and secondary form dialogs. Settings keeps five native segments on this same canvas without a separate TabView bezel; section/control/help spacing and label columns are consistent across all sections. Sparkle and colleague signing remain deferred.

## Local Transcription (0.6.0 Candidate)

Provider settings offer explicit Remote / On this Mac selection. On Apple
Silicon/macOS 14+, users may confirm a verified Parakeet Ultra download, prepare
it and Apply local mode without any key. Existing remote settings stay intact.
Local dictation performs no cloud cleanup, hedge or fallback; audio remains on
the Mac and existing successful deletion/Failed Recordings rules apply. Download
hosts receive ordinary connection metadata only during explicit setup. Qwen and
Granite catalog entries are deferred and cannot download in the Parakeet pilot.
No model operation sends a message. Real quality/latency acceptance is pending.
