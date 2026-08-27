# Release v0.4.2 Implementation Run

## Outcome

Publish the integrated personal OpenAI fallback, direct-personal mode, and
transcription-routing improvements as an annotated source tag that can be
fetched from another computer.

## Baseline

- Base branch: `main`
- Base commit: `eb3905caccfef25d2b316914a79639fb038314a1`
- Base pushed: yes
- Working tree: clean
- Implementation branch: `main`
- Version/release target: `0.4.2`

## Authority And Gates

- Approved scope: integrated behavior documented in the durable specs and
  `docs/features/personal-openai-fallback/spec.md`
- Agent may proceed through: version commit, `main` push, annotated tag, and tag
  push
- Human gate: Christian explicitly requested the release on 2026-08-27 after
  the pending real-provider smoke test and local toolchain mismatch were
  disclosed
- External systems/data explicitly authorized: GitHub `main` and tag push; no
  provider requests, credentials, installation, or binary publication

## Accepted Scope

- Set `VERSION` to `0.4.2`.
- Move the integrated Unreleased notes into the dated `0.4.2` changelog entry.
- Create and push annotated tag `v0.4.2` on the final `main` release commit.

## Non-Goals

- No DMG publication, local installation, real-provider request, notarization,
  or public binary release.

## Risks And Dependencies

- A fresh build is unavailable because the installed Swift 6.3.3 compiler and
  Swift 6.3.2 SDK do not match. The feature build passed `task check` before the
  toolchain changed, and its existing behavior-check executable passed again on
  2026-08-27.

## Decisions

- Publish a source release only. This satisfies cross-computer Git retrieval
  without representing the existing `0.4.1` DMG as a `0.4.2` artifact.
- Use the user-requested patch version `0.4.2` for the compatible accumulated
  improvements.

## Stages

### 1. Release Metadata

- Status: Completed
- [x] Update `VERSION`, `CHANGELOG.md`, and `docs/project-status.md`.
- [x] Record validation and artifact limitations truthfully.

### 2. Git Publication

- Status: Completed
- [x] Commit release metadata on `main`.
- [x] Push `main`.
- [x] Create and push annotated tag `v0.4.2` on the release commit.

## Validation Matrix

| Check | Current/final | Evidence |
| --- | --- | --- |
| Canonical checks | Fresh run unavailable | Blocked before compilation by Swift 6.3.3 / SDK 6.3.2 mismatch |
| Existing behavior checks | Passed | `BabbelStream behavior checks passed.` on 2026-08-27 |
| Release metadata | Passed | `VERSION`, changelog, project status, and tag aligned to `0.4.2` |
| Diff review | Passed | `git diff --check` and release-only file review |
| Build/package | Not produced | Source release only; no mislabeled DMG |
| Manual provider smoke | Explicitly deferred | No real provider calls authorized |

## Release Evidence

- Release commit: commit referenced by `v0.4.2`
- Main commit: same commit as `v0.4.2`
- Annotated tag: `v0.4.2`
- Artifact/checksum: none; source release only
- Installed/deployed version and commit: not changed
- Running/health verification: existing feature behavior checks passed

## Current Blocker

A fresh package requires a repaired or matching Apple Command Line Tools
compiler and SDK.

## Next Action

Repair the Apple Command Line Tools before building a `0.4.2` DMG.

## Closeout

- [x] Durable specs match released behavior.
- [x] Validation evidence is complete and truthful.
- [x] Human smoke gate was explicitly deferred by the release request.
- [x] `main` and the annotated source tag match the approved release level.
- [x] Working tree is clean after publication.
- [x] Tracker is archived.
