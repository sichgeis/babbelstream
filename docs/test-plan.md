# Test Plan

## Automated Check Runner

Run `task check`. It builds the app and executes `BabbelStreamChecks`, including settings validation, provider lifecycle/transient-failure checks through a local `URLProtocol`, zero-byte connection-stall recovery, provider cancellation without a second attempt, prompt/dictionary behavior, archive round trips and damaged-line recovery, diagnostics redaction, temp-file helpers, insertion policy, settings persistence, version metadata, and usage counters.

This CLT-only environment can compile but cannot execute XCTest or Swift Testing through SwiftPM. The empty test target was removed so `swift test` now fails honestly with `no tests found` instead of returning a false green. The debug executable suite imports `BabbelStreamApplication` with `@testable` and exercises actual AppState workflows through isolated adapters. Real AppKit, Accessibility, Keychain, microphone, Carbon, and process-termination integration remains in the manual matrix below.

## Unit Tests

- Provider configuration validation.
- Transcription language validation: `de`/`en` accepted, free-form `German, English` rejected, `gpt-transcribe` uses `languages[]`, older compatible models use `language`, and a blank setting sends neither field.
- Exact transcription-model picker options, `gpt-transcribe` default, one-time
  former-default migration, unsupported-value normalization, and persistence of
  later explicit picker selections.
- Standard and LiteLLM `openai/` model routing, effective primary/Mini IDs,
  host-independent defaults for absent/invalid routing, and persistence of an
  explicit routing choice independently of later base-URL edits.
- Cleanup prompt regression checks.
- Settings defaults and migrations.
- Personal OpenAI fallback defaults off, persists only after explicit Apply,
  keeps independent key-presence markers, derives the fixed official endpoint
  with standard model routing, and uses the separately supplied key.
- Direct-personal mode defaults off, cannot remain enabled when fallback is off,
  persists across restart, selects the fixed personal profile without a primary
  request, and returns to primary-first behavior after Apply turns it off.
- Personal fallback error policy accepts HTTP 502/503/504 plus connection
  watchdog/transport failures and rejects other HTTP, authentication/
  configuration, malformed-response, and empty-output failures.
- Configurable max recording duration defaults to 10 minutes and rejects values above the cap.
- Usage counter arithmetic and reset behavior.
- Dictation archive default-off behavior, JSONL round trip, damaged-line recovery, word-count aggregation, monthly export rendering, and clear behavior.
- Privacy-safe diagnostics redaction.
- Temp-file deletion policy.
- Text insertion result handling behind an adapter.
- Clipboard-only insertion for native, unknown, missing-bundle and previously
  special-cased applications; exactly one clipboard write and paste event.
- Historical direct-insertion archive outcome decoding/export compatibility.
- Hybrid hotkey release classification below, at, and above the 0.5-second threshold.
- Keychain wrapper behavior with an in-memory fake.
- Startup does not read either Keychain secret; primary and personal-key
  presence are represented by separate non-secret markers.
- Personal dictionary JSON round trip, text parsing, disabled-entry preservation, correction teaching/update de-duplication, cleanup prompt rendering, and prompt-size capping.

### Recovery Ownership Regression Checks

The executable suite injects copy, metadata-permission, and source-deletion failures. It verifies restart discovery, stale-cleanup exclusion, export retention, stable identity across partial adoption, reuse of the completed copy, damaged marker recovery, user-only marker permissions, and explicit deletion of pending sources. Tests use isolated temporary fixtures.

### Clipboard Workflow Regression Checks

All target identities, including Slack, TextEdit, VS Code, Claude, ChatGPT/Codex, Signal, browsers, email and missing/unknown ids, use exactly one clipboard write and paste. Fakes cover clipboard replacement, simultaneous clipboard/app changes, missing/changed target, cancellation, denied Accessibility, clipboard write failure, event failure and truthful Copy Last Draft HUD mapping. No AX field-writing interface remains. Native event delivery remains manual.

### Coordinator Workflow Regression Checks

The actual main-actor AppState runs with fixture-only recording, provider, insertion, settings, credentials, usage, login, and runtime adapters. Local dictionary/archive/recovery files are restricted to disposable test directories. Checks cover normal insertion and deletion; no startup credential reads; settings Apply during recording and retry; cleanup fallback; copy-only recovery; deletion failure warnings; failed adoption blocking requests; stop-ownership failure retaining controls; active task cancellation retaining stopped audio without delivery; copy failure; and clipboard contention, including simultaneous cleanup failure. No application is launched by the suite.

## Integration Tests

- Mock transcription endpoint request shape, standard/prefixed wire model IDs,
  model-specific language fields after routing, and response parsing.
- Mock cleanup endpoint request shape and fallback behavior.
- Provider HTTP error body extraction without logging request bodies or transcripts.
- Cleanup request encodes the transcript as data-only JSON rather than bare instruction-shaped user prose.
- Cleanup request includes dictionary context in the existing cleanup call when entries exist.
- Oversized dictionary context skips entries with counts instead of failing dictation.
- Archive integration writes one completed-dictation entry only when enabled and never writes audio paths or API keys.
- Coordinator flow from audio URL to pasted text using fakes.
- Connection timeout, request timeout, primary/Mini hedge policy, overall deadline, cancellation, invalid-key, and malformed-response cases.

## Manual QA Checklist

- App launches as a menu-bar utility.
- Tapping `Control + Option + Space` latches hands-free recording; releasing all keys does not process it, and the next press stops it exactly once.
- Holding `Control + Option + Space` for at least 0.5 seconds retains release-to-process push-to-talk behavior.
- The recording HUD uses a lock for hands-free and a hand for held recording while preserving the target-app label and waveform.
- Menu Start enters hands-free mode, and the hybrid shortcut, HUD Stop, and menu Stop all process it.
- The everyday menu stays concise, keeps Copy Last Draft directly available, and shows permission repair actions only while they are needed; local test recording remains available under Diagnostics.
- Recording shows a compact bottom-centered capsule with a stop control, target app, and live microphone activity without activating BabbelStream.
- Releasing the hotkey transitions the same capsule through concise Transcribing, Trying Mini transcription when needed, Cleaning up, and Pasting states without exposing transcript text.
- Transcribing, Mini fallback, Cleaning up, and Pasting keep the same blue waveform badge so state-label changes do not make the left side flicker.
- Successful paste feedback disappears quickly; Copied and Error feedback remain visible longer, while full provider, timeout, fallback, and recovery details remain available from the menu and copyable diagnostics.
- The capsule remains correctly positioned on normal and full-screen Spaces and does not steal focus when shown or clicked.
- Dictation pastes into the currently focused field in native Mail and in reactive editors such as VS Code and Codex.
- All applications receive drafts through clipboard plus Cmd+V, including native fields and Claude desktop’s Code surface.
- Moving focus to another field inside the same app directs the draft to that current field; switching to another application blocks auto-paste and leaves the draft on the clipboard.
- Escape cancels while recording and processing but behaves normally after the operation ends.
- Cleanup can be toggled.
- Provider destination is visible in settings.
- Personal fallback is visibly disabled/enabled, shows its fixed transcription
  and cleanup destinations and separate Keychain state, and discloses the work-
  content/cost boundary before Apply.
- Provider mode switches are visible without scrolling at the default Settings
  size. Applied direct-personal mode shows the personal destination in General
  readiness and a purple, icon-and-accessibility-labeled HUD throughout
  recording and processing.
- Edited provider values are visibly inactive until `Apply Settings` succeeds; the saved destination remains truthful.
- All five Settings tabs fit at the minimum window size; long destinations and paths wrap or compress inside their rows, and scrolling does not move the Apply footer.
- General Settings readiness truthfully reflects microphone, Accessibility, API-key, active-provider, and launch-at-login state; approval-required login items offer a direct route to System Settings.
- Teach Correction, Personal Dictionary, and Dictation Archive use the same grouped sections and stable footer design language as Settings.
- All three auxiliary windows remain usable at their documented minimum sizes, resize cleanly, and scroll without moving their footer actions or status.
- Usage counters are visible in Settings and can be reset.
- Copy Diagnostics produces a redacted report without transcripts, audio paths, clipboard contents, or API keys.
- Menu/Settings diagnostics show the semantic version and git short commit hash for the installed build.
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
- Switching applications before paste blocks automatic insertion; moving between fields within Slack intentionally uses the field focused at completion.

## Slack Browser Cases

- Chrome, Safari, or the user's default browser.
- Main composer and thread composer.
- Clipboard fallback leaves the final draft available for manual Cmd+V when automatic paste cannot be confirmed.

## ChatGPT And Web Editor Cases

- ChatGPT macOS composer receives an unsent draft through the paste-shortcut path.
- Chrome and Arc page editors receive an unsent/unsubmitted test draft.
- Chrome-family channel bundle suffixes retain the same routing.
- Native browser chrome such as the address bar still accepts the paste-shortcut
  path used for all applications.

## Email Compose Cases

- Apple Mail new-message body and subject fields.
- Microsoft Outlook new-message body and subject fields.
- Paste Last Draft from the menu after focusing an email compose field.
- Clipboard fallback leaves the final draft available for manual Cmd+V when automatic paste cannot be confirmed.

## Language Cases

- English: "Can you take a look at TASK-123 before standup?"
- German: "Kannst du bitte das Ticket nochmal prüfen und mir kurz Feedback geben?"
- Mixed: "Ich habe im example-service repo den TASK-123 fix gepusht, aber CI ist noch flaky."
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
- Primary/Mini hedge timing, first-success selection, and overall deadline behavior.
- Personal fallback starts sequentially only after an eligible primary phase
  failure, makes no Mini hedge of its own, and preserves cancellation.

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

- Confirm successful dictation audio deletion; confirm failure, timeout, processing cancellation, and interruption retention; confirm recording cancellation still deletes the partial file.
- Confirm Failed Recordings retry copies rather than auto-pastes, deletes only after full success, and retains audio after provider, cleanup, or clipboard failure.
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
- Launch-at-login uses the macOS main-app login service, reports approval-required
  state truthfully, safely migrates a legacy LaunchAgent, attempts registration
  even when the initial system status is unavailable, and survives app restart.

## Failure Mode Tests

- Missing API key.
- Enabled personal fallback with a missing personal key.
- Primary transport failure with fallback disabled, enabled/successful, and
  enabled/failing; primary HTTP/auth/model errors must make no personal request.
- Invalid base URL.
- Endpoint does not support audio transcription.
- Network offline.
- Cleanup provider failure after successful transcription.
- Clipboard unavailable.
- Paste target missing or focus lost.

## Clipboard-Only Candidate Matrix

After authorized candidate installation, validate Slack channel/thread/edit, Claude desktop Code/chat, ChatGPT/Codex, Signal, Chrome/Arc, Mail/Outlook and TextEdit with harmless unsent drafts. Check existing text, selection replacement, multiline, repeated chunks, English/German/mixed input, tap/hold/menu stop, app switching, same-app field changes, cancellation, Copy Last Draft and clipboard contention. Characterize alternate layouts/IME, held modifiers, terminals and protected fields without changing their policy. No candidate has been installed or smoke-tested for this feature.

## Pilot Readiness Build And Layout Validation

`task check` and packaging use `scripts/swift-project.sh`, selecting the installed macOS 26.5 SDK locally. The current CLT default macOS 27 SDK lacks its required SwiftUI macros. No system selection is changed. Explicit `SDKROOT` or `BABBELSTREAM_SDK` overrides require independent full validation; a missing validated SDK fails with an actionable prerequisite. On 2026-10-23 the full application build and executable suite pass with 26.5; compiler capture warnings and CLT framework-search warnings remain pre-existing.

For isolated visual inspection, run `scripts/swift-project.sh run BabbelStreamChecks --layout-preview --settings --settings-tab=general` (optionally `--minimum-window-size`). This constructs the real views with CoordinatorFixture stores and fake recording/provider/Keychain/insertion/hotkey/login/runtime adapters; it never starts the production app or accesses its stores. Quit the preview to remove its temporary fixture directory. The same preview supports `--teach-correction`, `--personal-dictionary`, and `--dictation-archive`. Do not launch a second production-store copy for screenshots.

Shared sections use explicit 20-point section gaps, 24-point horizontal canvas margins, 12-point section insets and 10-point row spacing inside one scroll owner. The footer stays outside the scroll view. Validate all five tabs at 700×560 and 760×640, long content, scrolling and secondary dialogs on macOS 26.7.1 and 27.0.1; evidence from one host cannot establish the other. Reopen Teach Correction at 500×420 content size and confirm SwiftUI fitting measurements do not enlarge its minimum; retain scrolling and the visible footer. Provider guidance must wrap without ellipses at both Settings sizes.

Refreshed 26.7.1 native fixture evidence on 2026-10-23: `/tmp/babbelstream-pilot-screenshots/resumed/` contains all five tabs at both sizes, Advanced and canceled connection confirmation at both sizes, denied-permission guidance, metadata, incomplete setup in dark appearance, and secondary dialogs at minimum sizes. No connection request or permission repair was triggered. Temporary resources may expire; 27.0.1 remains pending.

`script` convenience: `scripts/preview-layout.sh --settings` builds a separately identified temporary bundle. Use `--preview-dark` or `--preview-high-contrast` for app-scoped appearance inspection; these do not toggle OS settings. Window sizes in the layout matrix refer to content dimensions, excluding the title bar. Native accessibility settings still require manual review.

## Pilot Boundary Regression Checks

`task check` includes real URLSession uploads against two ephemeral 127.0.0.1 HTTP fixtures: a 307 redirect at the first origin fails for transcription and cleanup, and the second origin receives zero requests. Payloads and keys are synthetic. Pure origin checks cover default-port/host normalization, cross-origin/port, missing origin, credential-bearing URL and transport downgrade. Parser fixtures reject HTML, broken JSON, scalar/array and untyped text while retaining valid JSON and explicit text/plain.

Coordinator fixtures verify legacy approval metadata without startup key reads, rejected origin edits, explicit replacement, key/settings partial persistence failing closed with recovery retained, and immutable old operation settings/keys during Apply. Two advisory locks against one disposable fixture directory prove duplicate exclusion and release/reacquisition. HUD policy checks repeated completions, late warning extension, expiry and next-operation replacement. Diagnostics checks inject private paths/arbitrary messages and assert their absence from exports. Actual duplicate production launches and visible HUD timing remain manual integration checks; do not run competing production-store copies to force them.

## Guided Setup Checks

Fixtures cover new-user incomplete state and no secret/request, presets staging without model/fallback changes, saved-but-unverified status, disabled tests while edits are pending, explicit cost/content/destination disclosure, exact silent WAV bytes, exclusion of private speech hints, one primary request without hedge/cleanup/personal key/insertion, result/audio disposal, empty-valid-response semantics, outage/auth distinction, Apply cancellation and stale-generation rejection. `--preview-incomplete` renders real views with missing fake keys and denied fake permissions. After startup/UI changes, recheck Provider with Advanced collapsed/expanded, confirmation copy, General repair buttons, long messages and both window sizes/OS versions.

## Release Tooling Validation

Canonical checks include disposable Git fixtures for missing/ad-hoc distribution identity rejection, required release optimization, invalid/version-mismatched build metadata, dirty/untracked sources, forged commit override, increasing build numbers and reproducible exact-tag rebuilds. Preflight fixtures never inspect private keys or submit anything; signature-policy fixtures substitute synthetic codesign output to test combined runtime flags, missing runtime/audio entitlements, prohibited debug-task access and missing Developer ID/timestamp. Actual ad-hoc candidate verification independently exercises the real codesign tool. `bash -n scripts/*.sh` and `plutil -lint Resources/BabbelStream.entitlements` verify syntax/resources. A clean `BUILD_MODE=candidate` build/package must additionally verify actual ad-hoc signature, hardened-runtime flag, microphone entitlement and embedded version/build/commit plus DMG checksum/integrity. No candidate launch or production installation is implicit. After packaging, confirm the bundle's `.icns` holds only PNG entries (no legacy `ic04`/`ic05` ARGB data) and review the Finder app icon at 16, 32, 64 and 256 px on light and dark backgrounds. Developer ID, timestamp service, notarization, stapling, Gatekeeper and microphone/paste integration require their separately authorized environment and manual matrix.

## First-Run Onboarding

`task check` runs OnboardingChecks: first-use/deferred/revoked-grant presentation, fresh notDetermined microphone access with explicit grant/deny outcomes and no recording/provider side effects, isolated preference persistence, live adapter refresh, absence of provider/key/recording effects, known-sample receipt versus posting-only, focus loss, clipboard replacement, permission revocation during preparation, cancellation (including rapid focus loss/return and delayed success), post-test live permission refresh, posting/write errors, duplicate starts, recording/connection-test exclusion and existing Last Draft delivery exclusion.

Use `scripts/preview-layout.sh --onboarding` with `--preview-not-requested` (fake microphone consent), `--preview-incomplete`, `--preview-dark`, `--preview-high-contrast`, `--preview-repair` and `--minimum-window-size` for isolated native review. Preview uses fake permissions and insertion; it cannot prove real Accessibility consent or native event acceptance. All five steps must remain readable at 640×580/default and 600×500/minimum content size, with scrollable content and a fixed footer. Verify the nearly white canvas across Settings and secondary dialogs, native Dark Mode and Increase Contrast separation.

After separately authorized installation, manually test first-use/postpone/reopen, granting denied permissions in System Settings and returning without restart when macOS permits, stale-grant repair, and permission loss after a signing update. The local test must receive its sample, preserve newer clipboard content on contention, cancel safely on window/app switch/close, and leave Last Draft intact. Test the real unsent dictation workflow separately; local paste does not verify provider speech quality or every editor. Other-host macOS 27.0.1 visual acceptance remains pending.

## Homebrew Pilot Distribution

Run `task check` plus Homebrew syntax/style/recipe audits on the own-tap cask.
Record Homebrew/macOS versions and expected non-notarized Gatekeeper failures
separately from recipe errors. Verify the exact DMG checksum, signature, runtime,
entitlements, architecture, minimum OS and version/build/source. Review the
complete payload inventory; publish no user data or secrets. Verify uploaded bytes
by an independent download before updating the cask.

Manual pilot tests cover downloaded/quarantined launch, supported per-app approval,
first-run permission/local paste setup, explicitly authorized unsent dictation,
manual-install adoption/conflicts, first real old-to-new Homebrew upgrade,
permission/Keychain repair, rollback, uninstall retention and reinstall. Use an
isolated pilot installation, never mutate the daily app or private data to prove
these cases. First install does not prove upgrades. Other-Mac/native checks remain
pending until reported; see `docs/runs/archive/homebrew-distribution.md`.

## Public Repository Hygiene

`task check` scans tracked and non-ignored new files and the effective Git identity.
The local, untracked `.git/info/hygiene-denylist` holds one private literal per line;
without it only generic patterns are checked. Diagnostics contain categories/counts,
never matched content. Deliberate synthetic private-path redaction fixtures remain
allowed only in their dedicated test file. Fixture checks exercise detection,
ignored-secret exclusion, denylist matching, identity enforcement and history scans.
Before push, run `python3 scripts/check-public-hygiene.py --history` to audit all
reachable commit/tag identities, messages and blobs. Before release, additionally
pass `--binary <optimized-executable>` for a `strings` scan. Historical violations
require a separately authorized rewrite; current-file success does not clear history.

Routing checks preserve saved LiteLLM choices after host edits and use standard
IDs when routing is absent or invalid, including a generic company proxy host.
A direct pre-routing LiteLLM upgrade requires one explicit Settings selection.
The benchmark speech fixture is synthetic with optional metadata removed.
