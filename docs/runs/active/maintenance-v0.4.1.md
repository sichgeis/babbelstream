# Maintenance v0.4.1 Implementation Run

## Outcome

Deliver a dependency-free, behaviorally stable maintenance release candidate
with truthful Mini HUD presentation, supported launch-at-login integration,
calmer daily UI, and more maintainable coordination/check structure.

## Baseline

- Base branch: `main`
- Base commit: `99d4f2e7bb30b3d47f19f04f086095d383d384c1`
- Base pushed: yes
- Working tree: clean
- Implementation branch: `codex/maintenance-v0.4.1`
- Version/release target: `0.4.1` release candidate

## Authority And Gates

- Approved spec: `docs/features/maintenance-v0.4.1/spec.md` / Approved
- Agent may proceed through: feature push and release-candidate packaging
- Required human gates: real microphone/provider/Slack smoke test before install,
  `main`, final tag, or release
- External systems/data explicitly authorized: ordinary pushes to the dedicated
  feature branch; no CI pipeline

## Accepted Scope

- Dependency/toolchain audit with zero third-party dependencies retained.
- Mini fallback HUD correctness.
- `SMAppService` launch-at-login integration and safe legacy migration.
- Targeted GM refactor of shared processing and executable checks.
- Calmer menu and General Settings readiness summary.
- Copy Last Draft retained as a direct main-menu action.
- Durable docs, checks, clean candidate packaging, commits, and pushes.

## Non-Goals

- CI, new dependencies, providers, permissions, telemetry, retention, hotkey
  customization, local transcription, preview/editor behavior, `main`, tag,
  installation, or public release.

## Risks And Dependencies

- Login-item migration may require explicit system approval; preserve legacy
  state until registration succeeds.
- Coordinator refactoring touches privacy-sensitive ownership paths; keep
  orchestration visible and validate after each coherent change.
- AppKit/Accessibility/Carbon/provider reality remains manual-only.

## Decisions

- Keep `swift-tools-version: 6.0` and macOS 13 because no newer manifest or API
  requirement justifies narrowing compatibility.
- Do not add CI; local canonical validation remains the approved maintenance loop.
- Keep Copy Last Draft directly in the main menu.

## Stages

### 1. Contract And Baseline

- Status: Completed
- [x] Confirm clean, pushed baseline.
- [x] Create and push the dedicated feature branch.
- [x] Write the approved feature contract and tracker.
- [x] Commit and push the contract.
- Evidence: baseline `99d4f2e`; branch and contract pushed to origin.

### 2. HUD Correctness

- Status: Completed
- [x] Extract deterministic HUD presentation policy.
- [x] Fix Mini fallback label and add focused checks.
- Evidence: `task check` passed; Mini, recovery, and pasted outcomes are
  covered by `BabbelStreamChecks`.

### 3. Launch At Login

- Status: Completed
- [x] Adopt `SMAppService` behind a testable adapter.
- [x] Add safe legacy migration and truthful UI state.
- [x] Update privacy, architecture, and manual checks.
- Evidence: `task check` passed; fake-service checks prove register-before-remove
  migration and preservation of legacy intent when system approval is required.

### 4. GM Refactor

- Status: Completed
- [x] Extract meaningful shared audio-to-draft preparation.
- [x] Keep normal delivery and recovery-copy outcomes visible.
- [x] Split executable checks by concern with a readable runner.
- Evidence: normal and recovery processing now share one API-key/transcription/
  cleanup action while retaining their distinct delivery decisions; the check
  executable has a minimal runner and separate login/provider fixtures;
  `task check` passed.

### 5. Daily UX Polish

- Status: Completed
- [x] Simplify the main menu without removing Copy Last Draft.
- [x] Add compact readiness information to General Settings.
- [x] Update UX/manual validation documentation.
- Evidence: static build/hotkey/permission/draft/usage lines no longer crowd the
  menu; Copy Last Draft remains first-level, permission repair actions are
  contextual, Local Test Recording moved under Diagnostics, and General Settings
  exposes readiness with login-item approval repair. `task check` passed.

### 6. Candidate Validation

- Status: Completed
- [x] Reconcile durable docs and dependency audit.
- [x] Run focused checks, `task check`, clean build, packaging, and diff/privacy review.
- [x] Bump version/changelog for the candidate, commit, and push final evidence.
- Evidence: `swift package show-dependencies` reports no external dependencies;
  `task check` passed from clean candidate commit `8ee4c47`; packaging produced a
  valid `BabbelStream-0.4.1.dmg` whose app reports version `0.4.1` and commit
  `8ee4c47`; diff and privacy review found no new sensitive logging or retention.
  The package uses the existing local signing identity, which is suitable only
  for this Mac and is not trusted for public distribution.

## Validation Matrix

| Check | Baseline | Current/final | Evidence |
| --- | --- | --- | --- |
| Canonical checks | Passed | Passed | `task check` on `8ee4c47` |
| Focused checks | Not separate | Passed | HUD/login/refactor behavior checks |
| Build/package | Clean build passed | Passed | `BabbelStream-0.4.1.dmg`; hdiutil checksum valid |
| Manual smoke | Not run in this work session | User gate | Pending |
| Diff/privacy review | Clean baseline | Passed | no sensitive logging, retention, or destination changes |
| Clean tree | Yes | Yes after evidence commit | `git status --short --branch` |

## Release Evidence

- Candidate commit: `8ee4c47`
- Main commit: not authorized
- Annotated tag: not authorized
- Artifact: `dist/BabbelStream-0.4.1.dmg`
- SHA-256: `423b0fe20c9dd4b331a4595e97348f8871da7ccb743a900daa798ebf8b437d83`
- Installed/deployed version and commit: not authorized
- Running/health verification: user smoke gate pending

## Current Blocker

Human microphone/provider/Slack and visual validation cannot be replaced by the
executable checks and remains the approved release gate.

## Next Action

Run the feature-spec smoke test with the packaged `0.4.1` candidate, especially
the calm menu, Copy Last Draft, General readiness, Login Items migration, real
dictation, Mini state, and no-auto-send behavior.

## Closeout

- [x] Durable specs match candidate behavior.
- [x] Automated validation evidence is complete and truthful.
- [x] Human smoke gate remains the explicit next action.
- [ ] Main/tag/deployment match the approved release level.
- [x] Working tree is clean after the evidence commit.
- [ ] Tracker moved from active to archive after release completion.
