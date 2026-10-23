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

- Status: Completed. Local migration, old remote asset withdrawal and the explicitly requested clean 0.5.3 publication are complete. Earlier candidate evidence below is historical.
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

The subsequent direct release instruction authorized v0.5.3 publication and tap
advancement. No production installation occurred. Original older artifacts keep their
original source IDs; rewritten tags cannot claim byte-for-byte provenance.

## Backup Evidence

Disconnected mirrors outside both repositories:

- `~/babbelstream-pre-scrub-backup-20261023.git` (remote app refs).
- `~/homebrew-tap-pre-scrub-backup-20261023.git` (remote tap refs).
- `~/babbelstream-local-pre-scrub-backup-20261023.git` (all original local refs).
- `~/babbelstream-local-pre-migration-20261024.git` (all local refs immediately before adoption/pruning).

These deliberately contain pre-scrub data. They have no push remote and must
remain private until the owner confirms deletion. Temporary helpers/mirrors live
outside the repositories and must not be published.

## Local Migration And Purge (2026-10-24)

- The maintainer explicitly replied “do it” to the question authorizing migration
  of all clean local checkouts/worktrees and the installed tap, followed by
  expiring reflogs and pruning obsolete Git objects. This resolves the earlier
  automatic approval rejection; the authorized retry succeeded.
- Rechecked all branch tips, all three app worktrees and the installed tap for
  uncommitted/untracked work before mutation. All were clean and matched the
  recorded inventory. Existing disconnected backups were verified first.
- Added a fourth disconnected mirror, `~/babbelstream-local-pre-migration-20261024.git`,
  preserving the forward cleanup commits and current tool snapshots as well.
- Owner main migrated from `95e5238` to rewritten `4d50f8e` (before this evidence
  commit). Both existing worktrees migrated from `808f601` to the corresponding
  rewritten `2fbf595`; neither worktree was removed. Local branch tips were mapped
  individually, preserving their prior position rather than flattening them.
- Installed Homebrew tap migrated from `2c07bde` to `f28f4e4`. Its cask remains
  version 0.5.2 with unchanged URL/checksum; no Homebrew install/upgrade was run.
- Removed obsolete local snapshot refs only after backing them up. Expired all
  local reflogs and ran `git gc --prune=now` in the owner repository and tap.
- Ignored files, credentials, production settings, installed applications and
  older local release artifacts were preserved. Public noreply identity is set
  locally in both repositories; global configuration is unchanged.

## Current Blocker

None. The authorized source/history/local-Git scrub, remote installer withdrawal
and clean 0.5.3 publication/tap advancement are complete. Real workflow validation
remains unperformed; no production installation was requested or done.

## Next Action

No scrub work remains. Optional real upgrade/workflow validation is recorded in the implementation plan.

## Residual Exposure And Owner Actions

- Original 0.5.1/0.5.2 public DMGs and checksums have now been removed. Local
  copies remain private. Publish a clean replacement and advance the cask only
  after the real-Mac smoke gate.
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

## Local Post-Migration Verification

- `task check` from the actual owner checkout: PASS (full app build, executable
  behavior suite, release-tooling fixtures, hygiene and its four fixture tests).
- Owner all-ref scan with local denylist plus optimized candidate binary: PASS.
- Installed tap all-ref scan, four hygiene fixture tests and Ruby syntax: PASS.
- `git fsck --full --no-reflogs` in owner repository and installed tap: PASS.
- Every original commit object from both rewrite maps and every original app tag
  object is absent from the active object stores after pruning. Original recorded
  audio blob is absent too. Disconnected backups intentionally retain them.
- Owner main and installed tap match their public rewritten mains; all three
  app worktrees remain present. Only these evidence documents changed afterward.

## Remote Installer Withdrawal (2026-10-24)

- The maintainer requested clearing the remote, specifically removing older DMGs
  while retaining local copies. Removed exactly the 0.5.1 and 0.5.2 DMGs and their
  paired portable checksum assets (four files total), after verifying every local
  DMG hash/size against GitHub's asset digest and reconstructing each exact checksum.
- Local DMGs/backups, installed app, release records and rewritten tags retained.
  Both release asset lists were verified empty immediately after removal.
- Automatic approval review initially rejected an additional persistent cask-disable
  change as outside the asset-deletion request. Asset deletion proceeded alone.
  After that rejection was explained, the maintainer replied “do it”; the explicitly
  acknowledged follow-up authorizes the temporary remote cask-disable notice.
- The tap change preserves version/URL/checksum and adds a disabled reason instead
  of advertising a missing installer. Existing installed apps are untouched.
- Tap all-history hygiene/fixture tests and Ruby syntax pass. Homebrew's `info`
  rejects loading an untapped external cask path; no tap registration or installation
  was performed merely for validation. Installed Homebrew DSL source confirms the
  date/custom-reason disable contract.
- Existing release notes and current user docs now identify the withdrawals;
  clean replacement publication and tap advancement still await smoke approval.

## Subsequent Release Instruction

The maintainer subsequently explicitly requested “release 0.5.3”. Publication,
main/tag and tap advancement are authorized under the exception recorded in
`docs/release.md` and `release-v0.5.3.md`; this does not assert new real-provider/
microphone validation. Internal validation status is excluded from release notes
by the maintainer’s follow-up instruction. Production installation stays excluded.

## Final Closeout

Release 0.5.3/build 11 is published from `b9c0641f14598abe7388c496a78074b60cb168bf`. Its full mounted
payload (including raw debug-map bytes, Finder metadata and attributes) has zero
known private matches. Public DMG hash `41b8aed841824c66862b65a11c576364300e3cbd07760370e81f76b77a6a99a2` matches an
independent anonymous download. The tap is re-enabled at 0.5.3. Earlier public
DMGs/checksums remain removed; local copies and all backups remain intact. See
`release-v0.5.3.md` for the complete final-artifact evidence. Tracker archived.
