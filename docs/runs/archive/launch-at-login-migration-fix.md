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

- Status: Completed
- [x] Commit and push the feature branch.
- [x] Package from a clean commit, install, launch, and verify migration state.
- Evidence: feature commit `716c60c` pushed; checksum-verified DMG built; candidate
  installed and launched from `/Applications`; legacy plist removed; macOS BTM
  reports the main app enabled; General Settings visually reports
  `Launch at login — Enabled`.

## Validation Matrix

| Check | Baseline | Current/final | Evidence |
| --- | --- | --- | --- |
| Canonical checks | Passed with normal developer cache access | Passed | `task check` |
| Focused checks | Missing `.notFound` recovery case | Passed | Behavior runner covers success and retained-legacy failure |
| Build/package | Existing 0.4.1 install | Passed | Local-identity-signed app; checksum-verified DMG |
| Manual smoke | Warning reproduced | Passed | Installed launch, BTM inspection, legacy removal, and General Settings screenshot |
| Diff/privacy review | Clean | Passed | `git diff --check`; no provider/private-data changes |
| Clean tree | Clean | Clean after evidence commit | Git status |

## Release Evidence

- Release commit: `716c60cf004aa6ccea8fbafdd85517ef92c14326`
- Main feature commit: `f2886b209328fb39901da167a96f168161238925`
- Annotated tag: not authorized
- Artifact/checksum: `dist/BabbelStream-0.4.1.dmg` /
  `444d8e73fa478fae3aafa272c9a6e3316d60f892d759c2020bc77a9fbfa96958`
- Installed/deployed version and commit: `0.4.1` / `716c60c`
- Running/health verification: PID `41204` runs the `/Applications` executable;
  installed and packaged executable hashes match; modern BTM item is enabled;
  the legacy plist is absent.
- UI evidence:
  `/private/tmp/babbelstream-launch-at-login-screenshots/general-settings-launch-at-login-enabled.png`
- Signing evidence: app metadata reports `BabbelStream Local Code Signing` and
  `security find-identity` reports that identity as valid. Strict `codesign`
  verification reports `CSSMERR_TP_NOT_TRUSTED` for the self-issued local
  certificate; the app launches and ServiceManagement registration succeeds.
- Recovery backup: prior installed bundle retained temporarily at
  `/private/tmp/babbelstream-login-fix-backup.2I0lAh/BabbelStream.app`.

## Current Blocker

None. The local certificate trust warning is a pre-existing packaging
limitation and did not block launch-at-login registration or app launch.

## Next Action

None. The implementation is merged to `main`; the unrelated GPT Transcribe
real-provider smoke test remains active.

## Closeout

- [x] Durable specs match shipped behavior.
- [x] Validation evidence is complete and truthful.
- [x] Candidate smoke validation passed.
- [x] Main and local deployment match the approved level; no tag was requested.
- [x] Working tree is clean after the final evidence commit.
- [x] Tracker moved from active to archive.
