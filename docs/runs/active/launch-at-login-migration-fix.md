# Launch-At-Login Migration Recovery Implementation Run

## Outcome

Recover the reported launch-at-login migration, preserve the user's enabled
intent, and install a locally verified candidate.

## Baseline

- Base branch: `main`
- Base commit: `a2df3c45ccfd6adda7d6c33d651ca181dc8427df`
- Base pushed: yes
- Working tree: clean
- Implementation branch: `codex/launch-at-login-migration-fix`
- Version/release target: local `0.4.1` candidate, no tag

## Authority And Gates

- Approved spec: `docs/features/launch-at-login-migration-fix/spec.md`
- Agent may proceed through: implementation, feature commit/push, candidate
  install, launch, and local verification
- Required human gates: merge/push `main`, annotated tag, and public release
- External systems/data explicitly authorized: GitHub feature-branch push and
  local `/Applications` installation; no provider request

## Accepted Scope

- Attempt supported main-app registration from an initial `.notFound` status.
- Retain the legacy plist unless the system confirms enablement.
- Add regression coverage, documentation, and local installation evidence.

## Non-Goals

- UI redesign, Background Task Management reset, provider changes, version tag,
  public release, or main-branch mutation.

## Risks And Dependencies

- macOS may still reject registration or require approval; retain the legacy
  fallback and report the truthful state.

## Decisions

- Use `register()` as the authoritative recovery operation; evaluate status
  again after the call.
- Do not delete or manually rewrite the user's legacy plist.

## Stages

### 1. Diagnosis And Contract

- Status: Completed
- [x] Trace the warning to initial `.notFound` handling and the legacy plist.
- [x] Confirm the installed app is running and the legacy plist points to the
  former development bundle.
- [x] Record the approved behavior.
- Evidence: local bundle, legacy plist, BTM state, source inspection, and Apple
  ServiceManagement documentation reviewed 2026-07-28.

### 2. Implementation And Checks

- Status: Completed
- [x] Change registration policy and add regression coverage.
- [x] Update durable architecture, test plan, and changelog.
- [x] Run canonical checks and review the diff.
- Evidence: `task check` passed with normal developer cache access;
  `git diff --check` passed; focused checks cover successful and unsuccessful
  registration from an initial `.notFound` status.

### 3. Candidate Installation

- Status: Pending
- [ ] Commit and push the feature branch.
- [ ] Package from a clean commit, install, launch, and verify migration state.
- Evidence: pending.

## Validation Matrix

| Check | Baseline | Current/final | Evidence |
| --- | --- | --- | --- |
| Canonical checks | Passed with normal developer cache access | Passed | `task check` |
| Focused checks | Missing `.notFound` recovery case | Passed | Behavior runner covers success and retained-legacy failure |
| Build/package | Existing 0.4.1 install | Pending | Signed app and DMG |
| Manual smoke | Warning reproduced | Pending | Installed launch and state inspection |
| Diff/privacy review | Clean | Pending | No provider/private-data changes |
| Clean tree | Clean | Pending | Git status |

## Release Evidence

- Release commit: pending
- Main commit: not authorized
- Annotated tag: not authorized
- Artifact/checksum: pending
- Installed/deployed version and commit: pending
- Running/health verification: pending

## Current Blocker

None.

## Next Action

Commit and push the verified feature branch.

## Closeout

- [ ] Durable specs match shipped behavior.
- [ ] Validation evidence is complete and truthful.
- [ ] Human smoke gate passed or was explicitly waived.
- [ ] Main/tag/deployment match the approved release level.
- [ ] Working tree is clean.
- [ ] Tracker moved from active to archive.
