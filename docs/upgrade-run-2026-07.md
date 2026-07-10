# BabbelStream Upgrade Run - July 2026

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
- [ ] Expand `BabbelStreamChecks` with focused regression coverage
- [ ] Keep `BabbelStreamChecks` passing during the transition

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

- [ ] Preserve the previous draft until a new final draft succeeds
- [ ] Represent the active processing task explicitly
- [ ] Support visible cancellation during recording and provider processing
- [ ] Add bounded transcription retry with actionable status
- [ ] Surface temporary-audio deletion failures
- [ ] Clean active temporary audio on application termination
- [ ] Cover success, retry, failure, cancel, and cleanup branches

### 4. Target-safe insertion and visible recovery

- [ ] Detect whether the focused target changed during processing
- [ ] Copy instead of auto-pasting when the target is uncertain
- [ ] Show a compact non-activating recording/processing/recovery HUD
- [ ] Keep clipboard recovery instructions immediately visible
- [ ] Cover insertion policy with focused tests

### 5. Provider, archive, and dictionary resilience

- [ ] Treat malformed JSON success responses as provider errors
- [ ] Recover valid archive entries around a malformed JSONL line
- [ ] Return archive recovery warnings without hiding valid entries
- [ ] Update corrections by the wrong/heard form to avoid conflicting mappings
- [ ] Preserve disabled dictionary entries and notes during bulk edits
- [ ] Align the standalone STT checker default with its documentation

### 6. Documentation and handoff

- [ ] Update product, architecture, security, test, and setup documentation
- [ ] Add uninstall and local-data cleanup guidance
- [ ] Run the full automated validation matrix
- [ ] Review the final diff for privacy regressions and unnecessary complexity
- [ ] Push all milestone commits
- [ ] Prepare a manual smoke-test checklist for Slack, Mail/Outlook, permissions, and recovery

## Validation Matrix

| Check | Baseline | Final |
| --- | --- | --- |
| `swift build --product BabbelStream` | Passed | Pending |
| `swift test` | No tests discovered | Empty target removed; executable checks are canonical |
| `swift run BabbelStreamChecks` | Passed | Pending |
| Shell script syntax | Passed | Pending |
| Working tree clean after commits | Passed | Pending |

## Change Discipline

- Commit and push coherent milestones rather than one broad final commit.
- Keep behavior changes and supporting tests in the same milestone.
- Do not add dependencies unless native APIs are demonstrably insufficient.
- Do not access real providers, Keychain values, archives, transcripts, or external accounts during automated validation.
- Leave manual Slack and email smoke testing for the user after the branch is ready.
