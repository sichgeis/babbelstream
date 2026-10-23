# Release 0.5.3 Implementation Run

## Outcome

Publish one clean polished 0.5.3 DMG/checksum pair and restore the Homebrew cask.

## Baseline

- Base: clean pushed `main`, `7d22e4a4e4e4ecbe5eb5f8e1cc9590440082f205`.
- Implementation branch: `codex/release-0.5.3`.
- Version: 0.5.3; final build: 11 (local candidate was build 9).
- Existing local installs, private data and backup mirrors must remain untouched.

## Authority And Gates

The maintainer explicitly requested “release 0.5.3” on 2026-10-24 after the prior
candidate/privacy evidence and outstanding integration gate were explained. Treat
this as authorization for publishing the clean pilot with automated validation,
main/tag pushes and cask advancement. No new real microphone/provider/Slack smoke
is claimed. The request does not authorize production installation, live provider
calls, permissions or private signing-key lookup. Internal validation status stays
in this tracker, not the release notes, as subsequently requested.

## Accepted Scope And Decisions

- Keep product behavior from the validated scrub candidate; only release metadata changes.
- Increase build number to distinguish the final binary from the local candidate.
- Use optimized ad-hoc candidate signing with explicit Finder layout and canonical names.
- Inspect all mounted payload files and metadata, not just executable strings.
- Publish exactly two assets; independently download/verify before enabling the cask.
- Keep the earlier installer assets withdrawn and all local copies/backups intact.

## Stages

### 1. Finalize Source

- Status: Completed.
- Release notes exclude internal validation status as requested.
- Baseline `task check`: PASS; full behavior/release-tooling/hygiene suite.

### 2. Exact-Tag Packaging And Privacy Verification

- Status: In progress.
- Pre-publication build 10 failed the complete-payload scan despite the original
  default `strings` check passing: N_OSO debug maps and the Finder background
  alias retained the developer checkout path. No assets were uploaded.
- Fix: strip only debug maps (`strip -S`) before signing, scan raw bytes, UTF-16 and `strings -a`,
  and create the writable layout image in a neutral `/private/tmp` directory.
  This preserves app runtime symbols, image pixels and Finder layout. Native
  Mach-O-aware `strings -a` also omits these symbol bytes, so the actual raw-byte
  negative control is required; the revised checker correctly rejects build 10.
- Final build increased to 11. The unpublished v0.5.3 tag must move from the
  initial source to the corrected source using an exact old-tag lease, under the
  already-authorized data-removal tag-rewrite exception. Existing released tags
  and installer assets are untouched. No same-version published bytes are replaced.
- Require clean source, real signature/runtime/entitlements, correct version/build/hash,
  polished layout, inventory, ASCII/UTF-16 metadata scan and DMG integrity.

### 3. Publish And Restore Tap

- Status: Pending.
- Require canonical pair, portable checksum and independent anonymous download match.

## Validation Matrix

| Check | Evidence |
| --- | --- |
| Baseline canonical suite | PASS |
| Final canonical suite | Pending |
| All-ref/private denylist | Pending |
| Full DMG payload/binary | Pending |
| Signature/runtime/entitlements | Pending |
| Anonymous download/checksum | Pending |
| Cask syntax/style/audit | Pending |
| Actual microphone/provider/Slack | Not run; explicit release authority recorded above |

## Release Evidence

Tag `v0.5.3`, source/hash/checksum and tap commit: pending.
No production installation or launch performed.

## Current Blocker

None within the explicitly authorized release scope.

## Next Action

Finalize source, validate, tag and package the clean release.
