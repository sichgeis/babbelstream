# Public Data Scrub Implementation Run

## Outcome

Remove private data from public source and both repositories' reachable history,
with verified behavior and recoverable backups. Prepare a clean candidate only.

## Baseline

- Base branch: `main`; commit: `60994714ad1c9fb9aad6eba5678bcd2009f105e4`.
- Base pushed: yes; working tree: clean.
- Implementation branch: `codex/data-scrub`.
- Existing worktrees: two local audit/icon worktrees at `808f601`; preserve them.
- Version/release target: 0.5.3 candidate; public publication remains gated.

## Authority And Gates

Approved spec: `docs/features/data-scrub/spec.md`. The maintainer explicitly chose
“Also rewrite and force-push both repositories after backups and verification”
in this conversation. This permits the data-removal history exception; no blanket
permission from an attached document was assumed. No live data/keys/provider calls.
Stop before installation, publishing a new release, tap version changes or deleting
release assets. Existing release-note text may be sanitized as part of the scrub.

## Accepted Scope And Decisions

- Preserve saved routing and public application identifiers; remove hostname inference.
- Replace names/branding/internal examples with roles and neutral fixtures.
- Synthetic speech generated locally with `say`; optional M4A metadata removed.
- Filter the audio path out of all refs, then re-add only the synthetic file in a final commit.
- Preserve all branches rather than deleting merged branches during the rewrite.
- Backups outside repositories intentionally retain private data until owner deletion.

## Stages

### 1. Forward Cleanup

- Status: Completed.
- Source/docs/fixtures sanitized; public hygiene policy/checks added.
- Baseline `task check`: PASS with normal developer cache access. Sandbox-only
  attempt failed to write Swift module caches; no baseline code failure.

### 2. History Rewrite And Remote Verification

- Status: Pending.
- Use fresh mirrors and git-filter-repo, then audit every reachable ref before push.

### 3. Candidate And Handoff

- Status: Pending.
- No installed app, permission grant, production setting or release asset changed.

## Validation Matrix

| Check | Baseline | Current/final |
| --- | --- | --- |
| Canonical checks | PASS | PASS after routing/source/fixture cleanup |
| Hygiene fixtures | absent | PASS (4 disposable tests) |
| Synthetic speech | recorded fixture | 7.08-second synthetic AAC; optional metadata removed |
| All-ref scan | known exposure | Pending |
| Optimized candidate | not built | Pending |
| Real microphone/provider/Slack | not run | Human gate |

## Release Evidence

No new release/tag/installation authorized. Original older artifacts keep their
original source IDs; rewritten tags cannot claim byte-for-byte provenance.

## Backup Evidence

Disconnected mirrors outside both repositories:

- `~/babbelstream-pre-scrub-backup-20261023.git` (remote app refs).
- `~/homebrew-tap-pre-scrub-backup-20261023.git` (remote tap refs).
- `~/babbelstream-local-pre-scrub-backup-20261023.git` (all original local refs).

These deliberately contain pre-scrub data. They have no push remote and must
remain private until the owner confirms deletion. Temporary helpers/mirrors live
outside the repositories and must not be published.

## Current Blocker

None for implementation; human smoke/publication decisions remain later gates.

## Next Action

Complete forward validation and the verified mirror rewrite.
