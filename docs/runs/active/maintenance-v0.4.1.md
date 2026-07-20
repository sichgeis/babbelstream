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

- Status: In progress
- [ ] Extract deterministic HUD presentation policy.
- [ ] Fix Mini fallback label and add focused checks.
- Evidence: Pending

### 3. Launch At Login

- Status: Pending
- [ ] Adopt `SMAppService` behind a testable adapter.
- [ ] Add safe legacy migration and truthful UI state.
- [ ] Update privacy, architecture, and manual checks.
- Evidence: Pending

### 4. GM Refactor

- Status: Pending
- [ ] Extract meaningful shared audio-to-draft preparation.
- [ ] Keep normal delivery and recovery-copy outcomes visible.
- [ ] Split executable checks by concern with a readable runner.
- Evidence: Pending

### 5. Daily UX Polish

- Status: Pending
- [ ] Simplify the main menu without removing Copy Last Draft.
- [ ] Add compact readiness information to General Settings.
- [ ] Update UX/manual validation documentation.
- Evidence: Pending

### 6. Candidate Validation

- Status: Pending
- [ ] Reconcile durable docs and dependency audit.
- [ ] Run focused checks, `task check`, clean build, packaging, and diff/privacy review.
- [ ] Bump version/changelog for the candidate, commit, and push final evidence.
- Evidence: Pending

## Validation Matrix

| Check | Baseline | Current/final | Evidence |
| --- | --- | --- | --- |
| Canonical checks | Passed | Pending | `task check` |
| Focused checks | Not separate | Pending | HUD/login/refactor checks |
| Build/package | Clean build passed | Pending | candidate app/DMG |
| Manual smoke | Not run in this work session | User gate | Pending |
| Diff/privacy review | Clean baseline | Pending | Pending |
| Clean tree | Yes | Pending | `git status --short --branch` |

## Release Evidence

- Release commit: pending
- Main commit: not authorized
- Annotated tag: not authorized
- Artifact/checksum: pending
- Installed/deployed version and commit: not authorized
- Running/health verification: user smoke gate pending

## Current Blocker

None.

## Next Action

Extract the deterministic HUD presentation policy and cover the Mini state.

## Closeout

- [ ] Durable specs match shipped behavior.
- [ ] Validation evidence is complete and truthful.
- [ ] Human smoke gate passed or remains the explicit next action.
- [ ] Main/tag/deployment match the approved release level.
- [ ] Working tree is clean.
- [ ] Tracker moved from active to archive after release completion.
