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

- Status: Completed for both public repositories.
- Atomic pushes used exact old-ref leases. App: 14 public branches (13 existing
  plus the scrub branch), 20 annotated tags. Tap: 2 branches, no tags. Every
  remote head/tag matched the verified mirror after pushing. No branches deleted.
- `data-scrub-refs.tsv` records old/new object IDs at the first verified push;
  later documentation-only main descendants may follow. Local-only worktree
  branches were rewritten in the mirror but never newly published.
- Existing 0.5.1/0.5.2 release notes sanitized and provenance caveat added with
  authenticated gh because the connector has no release-edit operation.
  No release assets, cask bytes or installed applications changed.
- Fresh mirrors rewritten with git-filter-repo: 150 app commits and 10 tap commits;
  all 20 app annotated tags use the public identity. Recorded audio removed from
  every historical ref; only the new synthetic blob is restored after rewriting.
- Tap all-ref scan and Ruby cask syntax: PASS. App scan initially flagged retina
  image filenames as emails; the scanner now recognizes those filenames and a
  regression fixture covers them. No additional private mailbox was found.
- Use fresh mirrors and git-filter-repo, then audit every reachable ref before push.

### 3. Candidate And Handoff

- Status: Candidate prepared; local migration and human handoff pending.
- Candidate source: `92efa2bcd354e15cf1be6a79c7bfbe74599399b3`; version 0.5.3, build 9.
- Artifact: `dist/BabbelStream-0.5.3-candidate.9-92efa2b.dmg` and portable checksum.
- SHA-256: `be0aa44db4aca13020f698005fd58bb9fde1e2c16a8be6d2d09f3a76f04f1059`.
- Candidate is optimized/ad-hoc, signature/runtime/audio entitlement verified;
  no production signing key, real provider, microphone or installation used.
- Candidate/distribution builds now enforce all-ref and optimized-executable hygiene.
- No installed app, permission grant, production setting or release asset changed.

## Validation Matrix

| Check | Baseline | Current/final |
| --- | --- | --- |
| Canonical checks | PASS | PASS again from rewritten candidate source (build, behavior, release-tooling and hygiene) |
| Hygiene fixtures | absent | PASS (4 disposable tests) |
| Synthetic speech | recorded fixture | 7.08-second synthetic AAC; optional metadata removed |
| All-ref scan | known exposure | PASS for both repositories with local denylist |
| Optimized candidate | not built | PASS: release build, binary/history scan, real signature/runtime/entitlements and DMG integrity |
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

Local adoption and pruning require an explicit follow-up approval: automatic
approval review rejected resetting multiple worktrees plus expiring reflogs and
pruning objects as broader local destruction than the public-history permission.
The owner checkout, worktrees and installed Homebrew tap remain on original local
history; the public remotes are clean. Nothing was lost. An approval question is
pending in this chat. Backups remain disconnected and private.

## Next Action

Resolve the local migration/purge approval, then hand off the verified candidate for installation/smoke approval.

## Residual Exposure And Owner Actions

- Original 0.5.1/0.5.2 public DMGs still contain old compiled strings. Publish a
  new clean version and advance the cask only after the real-Mac smoke gate;
  choose whether to retire their old assets/releases separately.
- Cached old SHA views may remain accessible. GitHub Support determines eligibility
  for a cache/GC removal request; provide both repository names, zero affected PRs,
  old root/changed commit IDs and the rewrite maps. Guide:
  https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/removing-sensitive-data-from-a-repository
- Existing clones/downloads cannot be remotely erased. Reclone or carefully rebase
  other clones; do not merge old history back.
- Delete the disconnected backups and temporary helper workspace only after
  confirming the scrub. They intentionally retain original data.
- Consider the public noreply identity globally and GitHub email privacy/push
  blocking settings; no global account configuration was changed here.

## Final Verification Before Local Adoption

Final `task check`: PASS after all source/tooling changes. Both existing release
notes independently reread through the GitHub connector: zero private-reference
matches; each still has exactly its original DMG/checksum pair. Cask file is
unchanged. The newly copied local candidate has a portable checksum. Older ignored
build outputs/installers and private files were preserved, not scanned or deleted.
