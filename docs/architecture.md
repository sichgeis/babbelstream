# Architecture

## Recommended Architecture

BabbelStream is a native macOS menu-bar app with an AppKit status item, SwiftUI settings, and a small core layer for testable logic. The MVP uses native macOS APIs before adding dependencies: AVFoundation for audio recording, Carbon for the global hotkey, URLSession for provider calls, Security/Keychain for secrets, Accessibility permission for synthetic paste, and NSPasteboard plus Cmd+V for all insertion.

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
  -> DictationRecoveryStore
  -> SwiftUI SettingsView
```

## Application Composition

The executable target keeps the application shell separate from the behavior-heavy coordinator:

- `BabbelStreamLauncher/main.swift` is the executable entry point and invokes the native application bootstrap in `BabbelStreamApp.swift`.
- The existing app sources compile as `BabbelStreamApplication`, so executable debug checks can import the actual coordinator with `@testable` without running the app.
- `AppRuntime` isolates workspace observations, diagnostic logging, and temporary-directory discovery; production uses the native adapter and checks use fixture-only runtime state.
- `AppDelegate.swift` is the composition root that creates stores, `AppState`, window controllers, the status item, and the HUD.
- `StatusBarController.swift` owns menu-bar presentation and actions.
- `AppWindowControllers.swift`, `SettingsView.swift`, `DictationArchiveUI.swift`, and `DictationStatusHUD.swift` own their respective AppKit/SwiftUI presentation concerns.
- `AppState.swift` remains the main-actor workflow coordinator. Its top-level dictation path delegates the provider details to explicit transcription-with-fallback and cleanup-with-raw-fallback actions.
- `BabbelStreamCore` owns reusable policy, provider, storage, recording, hotkey, secret, and insertion implementations and does not depend on the app target.

This boundary keeps lifecycle and UI wiring out of the dictation flow without introducing a second coordinator or hiding simple decisions behind trivial abstractions.

## Data Flow

1. Hotkey press starts `AudioRecorder` immediately. `HybridDictationHotkeyPolicy` classifies release before 0.5 seconds as hands-free latch and release at or after 0.5 seconds as push-to-talk completion.
2. `AppState` snapshots the saved settings and the focused application identity for the whole dictation.
3. The bottom-centered, non-activating capsule HUD shows live microphone activity and the target while recording, then progressively discloses only the current processing, Mini fallback, completion, or recovery state. Full provider and timeout details remain in the menu, Settings, and diagnostics.
4. A held-hotkey release, a second press while hands-free, or an explicit Stop action stops recording and returns a temporary audio URL. All paths converge on the same coordinator action. `DictationRecoveryStore` copies the file into user-only Application Support storage before provider work and only then removes the temporary source.
5. The configured primary transcription begins immediately. If it remains pending for 10 seconds, an independent Mini request starts; the first valid response wins within one 75-second overall deadline.
6. Recovery audio is deleted only after transcription and any enabled cleanup succeed. Provider failure, cleanup fallback, processing cancellation, and interruption retain it for menu-driven retry or explicit deletion.
7. `AppState` reloads the local personal dictionary from Application Support when cleanup is enabled.
8. `CleanupProvider` lightly formats the transcript when cleanup is enabled, using dictionary context in the same model call.
9. Usage counters are updated locally for dictation attempts, recorded duration, cleanup requests, transcription failures, and cleanup fallbacks.
10. `TextInsertionService` copies the prepared draft to NSPasteboard for every target. With Accessibility permission and the captured process still frontmost, it waits for paste preparation, verifies cancellation and clipboard ownership, rechecks the application and posts Cmd+V once. There is no AX field write or application routing policy. It never steals focus; copied-only and clipboard-contention outcomes retain honest recovery guidance.
11. If the optional local archive is enabled, `DictationArchiveStore` appends a text-only entry for completed dictations with the final draft, word counts, provider labels, cleanup state, and insertion outcome. Raw transcript text is stored only when a separate raw-transcript archive setting is enabled. Archive write failures are surfaced but must not undo paste or block access to the final draft.
12. The app keeps the latest successful raw/final draft in memory for copy/retry and does not discard it merely because a later attempt starts or fails.
13. Recovery retry always uses current saved settings and copies the result to the clipboard rather than auto-pasting into the historical target.

## Permission Model

- Microphone: required for recording.
- Accessibility: required for reliable simulated paste and future active-app/focused-field checks.
- Input Monitoring: avoid for MVP if Carbon hotkeys work without it; document if a future hotkey path requires it.

## Provider Abstraction

Provider settings should include:

- Base URL.
- API key reference in Keychain.
- Optional personal OpenAI fallback opt-in and separate Keychain key presence.
- Persisted direct-personal mode, valid only when personal fallback is enabled.
- Transcription endpoint path.
- Cleanup endpoint path.
- Primary transcription model selected from `gpt-transcribe`,
  `gpt-4o-transcribe`, or `gpt-4o-mini-transcribe`.
- Transcription model routing selected between standard OpenAI IDs and
  LiteLLM's `openai/` namespace.
- Cleanup model name.
- Optional transcription language code. This must be a single ISO 639-1 code such as `de` or `en`; mixed-language dictation should leave it empty and use prompt/cleanup hints.
- Timeout.
- Retry policy.
- Maximum audio duration, editable in Settings and defaulting to 10 minutes.
- Optional future price inputs for local cost estimates.

The default request shape supports both the official OpenAI API and
OpenAI-compatible LiteLLM endpoints. The selected model remains a logical
official model ID. Immediately before multipart construction, the pure routing
policy either keeps that ID bare or adds one `openai/` prefix; primary and Mini
requests share the same immutable settings snapshot and routing. Existing
company proxy installations migrate once to prefixed routing, while the saved
choice remains authoritative afterward.

`PersonalOpenAIFallbackPolicy` derives a fixed official profile from the
immutable primary settings snapshot. It preserves the supported logical
transcription model and request hints while using `https://api.openai.com`, the
standard endpoint paths/default cleanup model, and standard OpenAI IDs. The existing
primary/Mini hedge completes first. Only a transport/reachability error may
start one sequential personal transcription request. Gateway/service-
unavailable HTTP 502, 503, and 504 also qualify; other HTTP and content errors do
not. Cleanup uses the transcript-winning profile, or makes one personal cleanup
attempt after an eligible primary cleanup failure. Provider labels in the local
archive reflect the profiles actually used.

Direct-personal mode is evaluated from the same immutable settings snapshot
captured before recording. When active, coordination skips primary-key loading
and the entire primary/Mini hedge, performs one personal transcription request,
and keeps enabled cleanup on the derived personal settings/key. The HUD receives
an explicit current-operation personal-provider signal so applying Settings
during an in-flight dictation cannot change that dictation's color or routing.

Remote provider URLs must use HTTPS. Plain HTTP is accepted only for loopback development endpoints. Base URLs with embedded credentials, query parameters, or fragments are rejected so the effective destinations remain inspectable and diagnostics-safe.

## Audio Recording Approach

Use AVFoundation to record compressed audio to a temporary file. The MVP default maximum duration is 10 minutes and can be lowered in Settings. The recorder must clean up partial files on cancel, timeout, provider failure, and app quit.

## Transcription Approach

Use multipart upload for `/v1/audio/transcriptions`-style endpoints.
`gpt-transcribe` uses the same endpoint, JSON response format, and top-level
`text` result as the previous default, but receives an optional language hint
through `languages[]`; older compatible models retain the singular `language`
field. Language-field selection uses the logical model before routing, so
`openai/gpt-transcribe` retains the same request contract. Additional response
metadata such as detected `languages` is ignored. The provider accepts a JSON
object with a string `text` field or an explicitly labeled `text/plain` response; HTML, malformed JSON, untyped non-JSON and other
successful JSON shapes are rejected. The app disables same-model retries and
permits only the configured primary plus one bounded Mini hedge.
Authentication and other permanent client failures fail immediately.

Primary transcription begins immediately and Mini is hedged after 10 seconds only when primary is still pending. An early retryable primary failure starts Mini immediately; permanent failures stop. First valid output wins and the complete transcription phase is bounded to 75 seconds. A separate 15-second zero-byte connection watchdog remains per request. Cleanup keeps its separately configured timeout and raw-transcript fallback. Provider lifecycle events distinguish primary, hedge, winner, loser cancellation, and cleanup without recording content.

## Failed Recording Recovery Approach

Use one directory per stopped recording under Application Support. The audio remains a normal M4A, directories use `0700`, files use `0600`, and recovery storage is excluded from backup where supported. Metadata writes are atomic and contain only operational labels and counts. Malformed metadata is reconstructed from the audio file so the recording is not hidden. There is no automatic expiry or silent quota eviction. Recovery Center actions own retry, Save Audio As, individual deletion, and confirmed delete-all. The HUD remains a fixed 220×44 passive indicator.

Stopped-audio ownership is persisted before `AudioRecorder.stop` releases its source. `StoppedAudioOwnership` derives the source location from a sidecar marker, never from a serialized path. The recovery store discovers markers in the app's known temporary directories, joins sources and completed copies by stable UUID, and finishes adoption idempotently before retry. Source deletion failure retains a single pending item and the completed copy. Stale cleanup ignores marked sources. Deletion returns an explicit coordinator outcome so delivery success cannot erase a retention warning.

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

Capture the intended application's process identifier at hotkey press. Every target uses NSPasteboard plus synthetic Cmd+V. Require the captured process to remain frontmost before clipboard preparation and again before event posting; insertion goes to its currently focused field. Stable original-field identity is intentionally not required for reactive editors. If another application becomes active, leave the draft on the clipboard without reactivation. Retain the existing 150 ms preparation and paste event sequence. No direct Accessibility writes, field-content queries, application allowlist or alternate strategy exists. Direct insertion is deferred future work under a new feature contract.

`ClipboardTextInsertionService` owns insertion sequencing through a native `TextInsertionEnvironment` adapter. The adapter exposes clipboard version, focused target, preparation wait, and paste event posting, allowing deterministic checks without system clipboard access. Clipboard ownership is checked after the wait and immediately before event posting. A distinct `clipboardChanged` outcome preserves the newer clipboard and maps to the Copy Last Draft HUD and archive outcome.

The archive decoder retains `directAccessibilityInsertion` only for historical entries; new delivery results cannot produce that outcome. No archive migration or deletion occurs.

## Settings And Secrets

Use `UserDefaults` for non-secret settings and Keychain for API keys. Primary and
personal-fallback keys use separate Keychain accounts and presence markers.
Avoid plaintext config files for secrets. Text settings are staged until the
persistent `Apply Settings` action succeeds; the UI separately shows
saved/effective and edited destinations. Each dictation uses one immutable
saved-settings snapshot. Startup must not read or rewrite either Keychain
secret; non-secret `UserDefaults` presence markers avoid a relaunch prompt. The
primary key is read when primary provider work is about to run. The personal key
is read only after an eligible failure is about to activate the applied
fallback. Updates use `SecItemUpdate` rather than delete-then-add replacement.

## Launch At Login

The app registers or unregisters `SMAppService.mainApp` from Settings and reports
the system's enabled, disabled, approval-required, or unavailable state. This
uses the supported macOS 13 ServiceManagement path without a helper executable
or a stored application path.

For upgrades from v0.4.0 and earlier, BabbelStream recognizes the legacy
`~/Library/LaunchAgents/com.sichgeis.babbelstream.loginitem.plist`. It registers
the main-app service first and removes the legacy plist only after registration
succeeds. If registration needs approval or fails, the legacy file remains so
the previous launch-at-login intent is not silently lost. A pre-registration
`.notFound` status does not suppress the registration attempt: the result of
`register()` and the post-registration status determine whether migration may
complete.

## Packaging And Local Install

SwiftPM builds the executable, and `scripts/build-app.sh` wraps it in a local `.app` bundle under `dist/` with the app `Info.plist`, current git short commit hash, an optional `-dirty` suffix for uncommitted local changes, and local code signature. `scripts/package-dmg.sh` creates a DMG containing the app bundle plus an `Applications` symlink, matching the standard Finder drag-to-Applications install pattern.

The daily developer install helper opens that DMG and lets Finder perform the copy to `/Applications`. The project scripts should not invoke `sudo` for local installation; if `/Applications` needs administrator authorization, Finder owns that prompt during the drag copy. Restarting the installed app is handled separately by opening `/Applications/BabbelStream.app`.

## Logging And Debugging

Default in-memory and macOS Unified Logs may include state transitions, provider names, durations, counts, semantic version, build commit hash, attempt numbers, timeout values, HTTP status, URL error codes, fallback/retry categories, and request/response byte counts. Copyable diagnostics are built from an explicit field allowlist of content-free build/provider-origin/configuration categories, booleans, permission/key-presence flags, timeouts, counters and constrained failure categories. Arbitrary status/errors and recent event messages are never appended. They must not include audio, transcripts, archive contents, cleanup input, cleanup output, API keys, clipboard contents, any private filesystem paths, raw provider messages, or request/response bodies. Debug persistence must be explicit and visibly enabled.

## Security And Privacy

The main risks are accidental capture, accidental paste, clipboard exposure, overbroad Accessibility permission, local archive exposure, and sending work content to the wrong provider. The app should prefer obvious state, explicit provider configuration, no history by default, explicit opt-in archive controls, immediate audio deletion, and no auto-send.

## Shared Dialog Layout

Settings and secondary dialogs use AppGroupedForm as the only scroll owner, with explicit AppFormSection stack spacing, semantic macOS window/control surfaces and separators, and native controls. They avoid nesting a grouped Form inside a ScrollView, whose automatic insets vary by SDK/OS. Settings uses a native segmented Picker with the selected pane below it, avoiding the TabView bezel and its gray header bands. All Settings panes use the same full-width canvas and left margin, so scrollbars do not shift label columns. Footer status and actions remain outside scrolling content. Long values wrap vertically. Dialog hosting controllers disable automatic SwiftUI sizing options so AppKit controllers retain ownership of documented initial and minimum content sizes. Provider guidance explicitly permits vertical wrapping.

## Pilot Boundary Policies

`ProviderOrigin` compares scheme, normalized host and effective port. A task-level redirect delegate enforces it for transcription and cleanup even with injected URLSessions. Primary-key presence metadata stores the approved origin; legacy metadata binds to saved settings without startup secret reads. Explicit new-origin key entry is required and partial persistence fails closed. Existing operations retain their prior origin/key only in memory until completion, preserving settings snapshots during Apply.

`SingleInstanceLock` holds an advisory user-scoped lock before AppDelegate construction and shared cleanup; bootstrap first checks existing production bundle processes. Fixtures acquire locks only in disposable directories. The lock file is never unlinked while live.

`DictationHUDVisibilityPolicy` owns active-to-completion transitions. Repeated idle notifications retain the existing 1.5-second success or 6-second attention deadline; a late warning may extend once. A new active operation cancels the prior dismissal. Expiry cannot be resurrected by idle notifications. HUD size and nonactivation stay unchanged.

## Guided Setup And Verification

AppState exposes connection readiness independently of key presence. Presets stage only non-secret connection URL/paths/routing; existing models and saved/effective settings remain unchanged until Apply. Startup shows Provider when credentials are incomplete, and General exposes permission/setup actions. `SyntheticConnectionAudio` generates a fixed silent PCM WAV locally. Explicit confirmation starts one primary TranscriptionProvider request without hints/retry/hedge/fallback/cleanup. A generation id owns the session verification state; Apply/deletion cancel the task and prevent stale completion. Results are discarded, fixtures prove content separation, and real speech/paste still require manual validation.

## Reproducible Release Preparation

Project Swift invocations pass through a local SDK selector. Packaging shares a non-mutating preflight for development, candidate and distribution modes. Candidate/distribution require release optimization, clean source and exact committed VERSION/BUILD_NUMBER/HEAD; no provenance override can conceal another source. New distributed iterations increase BUILD_NUMBER beyond the previous reachable release; exact clean tagged rebuilds remain possible. Candidate defaults to ad-hoc without private identity lookup. Distribution requires an explicit Developer ID and secure timestamp, and signatures enable hardened runtime with only the existing audio-input resource entitlement. Verification is explicit. Plain DMG packaging avoids Finder automation/mounts; an opt-in decorative developer path remains. Notarization is a separate, unexecuted helper requiring an approved existing profile and publication authorization.

## Onboarding And Local Paste Verification

`OnboardingWindowController` composes `OnboardingModel`, the shared native dialog scaffold and `LocalPasteTestSession`. A small injected progress store persists only dismissal/observed-grant booleans; `OnboardingPresentation.resolve` distinguishes first use, deferred setup and permission repair. AppDelegate refreshes live permission adapters on activation. The window also refreshes after explicit requests/Check Again. Menus and General reopen setup; Provider opens the existing Settings pane and retains staged Apply semantics. Explicit window-launch modes bypass automatic setup.

The optional local test uses the same ClipboardTextInsertionService as dictation, with an additional predicate checking its own NSTextView/window focus. Production dictation retains its existing application-only target policy. The native adapter inspects only its owned test field for the known sample; bounded receipt observation rejects posting-only success. Cancellation on navigation/close and AppState test/delivery occupancy prevent overlapping operations. The fixture preview injects memory progress and fake insertion; it never requests native access or posts a real paste.

`AppFormBackground` blends semantic control/window surfaces for a nearly white normal Light Mode canvas. Dark Mode and increased contrast retain native window surfaces. No fixed RGB system colors or global theme change is used.
