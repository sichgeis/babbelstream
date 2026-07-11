# BabbelStream Upgrade Run - July 2026

> Historical implementation record. Its bounded same-model retry statements describe the v0.1.x milestone; v0.2.1 replaced coordinator retries with a one-shot Mini model fallback. Current behavior is defined in `product-spec.md` and `architecture.md`.

## Objective

Turn the July 2026 repository audit into a smoke-test-ready upgrade while preserving BabbelStream's product boundary: a dependable native macOS push-to-talk helper that never auto-sends, keeps persistence opt-in, and stays understandable as a personal tool.

## Baseline

- Baseline branch: `main`
- Baseline commit: `7eb8a28696970e060c149597360edd675959b521`
- Baseline push: confirmed up to date with `origin/main`
- Implementation branch: `codex/babbelstream-upgrade-run`
- Baseline behavior: considered working and must remain recoverable through Git history

## Working Decisions

These choices make the run autonomous while favoring privacy and predictable behavior:

- Settings use an explicit Apply action instead of provider autosave.
- The UI distinguishes edited settings from the saved configuration used by requests.
- Plain HTTP is accepted only for loopback development endpoints.
- A dictation uses one immutable settings snapshot from recording through archive metadata.
- If the insertion target changes or cannot be verified, BabbelStream copies the draft instead of guessing.
- Transcription retries are bounded and limited to transient transport, throttling, and server failures.
- Cancellation is cooperative and keeps temporary-audio cleanup mandatory.
- The existing native architecture is retained; extraction is limited to behavior that needs focused tests.

## Milestones

### 1. Tracker and executable test foundation

- [x] Preserve and push the clean baseline
- [x] Create the implementation branch
- [x] Add this implementation tracker
- [x] Confirm that this CLT installation cannot execute XCTest or Swift Testing through SwiftPM
- [x] Remove the misleading zero-test SwiftPM target
- [x] Make `task check` the canonical build-and-check command
- [x] Expand `BabbelStreamChecks` with focused regression coverage
- [x] Keep `BabbelStreamChecks` passing during the transition

### 2. Truthful settings and credential boundary

- [x] Add a Settings-wide Apply action and unsaved-change state
- [x] Show saved/effective provider destinations
- [x] Show validation and save results inside Settings
- [x] Reject ambiguous provider URLs and remote plain HTTP
- [x] Make Keychain updates non-destructive
- [x] Remove the first-dictation Keychain rewrite
- [x] Snapshot effective settings for each dictation
- [x] Add focused settings and endpoint regression checks

### 3. Processing lifecycle safety

- [x] Preserve the previous draft until a new final draft succeeds
- [x] Represent the active processing task explicitly
- [x] Support visible cancellation during recording and provider processing
- [x] Register Escape as a cancel hotkey only while an operation is active, with HUD/menu fallback
- [x] Add bounded transient transcription retry
- [x] Surface temporary-audio deletion failures
- [x] Clean active temporary audio on application termination
- [x] Cover provider success/retry/failure policies in automated checks and keep AppKit cancellation/cleanup branches in the manual matrix

### 4. Target-safe insertion and visible recovery

- [x] Detect whether the focused target changed during processing
- [x] Copy instead of auto-pasting when the target is uncertain
- [x] Show a compact non-activating recording/processing/recovery HUD
- [x] Keep clipboard recovery instructions immediately visible
- [x] Cover the application-level insertion policy with focused checks

### 5. Provider, archive, and dictionary resilience

- [x] Treat malformed JSON success responses as provider errors
- [x] Recover valid archive entries around a malformed JSONL line
- [x] Return archive recovery warnings without hiding valid entries
- [x] Update corrections by the wrong/heard form to avoid conflicting mappings
- [x] Preserve disabled dictionary entries and notes during bulk edits
- [x] Align the standalone STT checker default with its documentation

### 6. Documentation and handoff

- [x] Update product, architecture, security, test, and setup documentation
- [x] Add uninstall and local-data cleanup guidance
- [x] Run the full automated validation matrix
- [x] Review the final diff for privacy regressions and unnecessary complexity
- [x] Push all milestone commits
- [x] Prepare a manual smoke-test checklist for Slack, Mail/Outlook, permissions, and recovery

## Validation Matrix

| Check | Baseline | Final |
| --- | --- | --- |
| `swift build --product BabbelStream` | Passed | Passed through `task check` |
| `swift test` | No tests discovered | Expected `no tests found` failure verified; empty target removed |
| `swift run BabbelStreamChecks` | Passed | Passed through `task check` |
| Shell script syntax | Passed | Passed for every `scripts/*.sh` file |
| `task stt:help` | Not recorded | Passed without provider access |
| Local app-bundle build | Not recorded | Built and signature verified with normal Keychain trust access |
| Working tree clean after commits | Passed | Passed before tracker closeout |

Swift validation was run with normal developer cache access because the Codex
filesystem sandbox cannot write Swift's user module cache. No provider, Keychain
secret, microphone, Accessibility action, archive, or external account was used.

## Change Discipline

- Commit and push coherent milestones rather than one broad final commit.
- Keep behavior changes and supporting tests in the same milestone.
- Do not add dependencies unless native APIs are demonstrably insufficient.
- Do not access real providers, Keychain values, archives, transcripts, or external accounts during automated validation.
- Leave manual Slack and email smoke testing for the user after the branch is ready.
