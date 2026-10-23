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

- Status: Completed; final build 11 passed.
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

- Status: Completed on 2026-10-24.
- Published exactly the canonical DMG and portable checksum, then independently
  downloaded both without authentication or user curl configuration. Both match
  the fully scanned local bytes exactly. GitHub asset digests agree.
- Updated and re-enabled the cask only after public download verification.
  Installed tap Git metadata fast-forwarded; no app install/upgrade/launch occurred.
- Existing release-note body independently reread: no internal smoke/test-status
  text and no known private names. Older release asset lists remain empty.
- Require canonical pair, portable checksum and independent anonymous download match.

## Validation Matrix

| Check | Evidence |
| --- | --- |
| Baseline canonical suite | PASS |
| Final canonical suite | PASS after native packaging and raw-byte privacy fixes |
| All-ref/private denylist | PASS in app and tap repositories |
| Full DMG payload/binary | PASS: zero known private matches in every mounted file and 7 file attributes, raw/ASCII/UTF-16 views |
| Signature/runtime/entitlements | PASS on actual mounted build 11; arm64, macOS 13 deployment |
| Anonymous download/checksum | PASS, exact byte equality for both assets |
| Cask syntax/style/audit | PASS: Ruby syntax, Homebrew style (1 file/no offenses), strict cask audit; brew info reports 0.5.3 and disabled=false |
| Actual microphone/provider/Slack | Not run; explicit release authority recorded above |

## Release Evidence

- Release: https://github.com/sichgeis/babbelstream/releases/tag/v0.5.3
- Annotated tag: `v0.5.3`; app-source commit: `b9c0641f14598abe7388c496a78074b60cb168bf` on main.
- Version/build: 0.5.3 / 11; optimized ad-hoc pilot, not notarized.
- Artifact: `dist/BabbelStream-0.5.3.dmg` and portable `.dmg.sha256`.
- DMG SHA-256: `41b8aed841824c66862b65a11c576364300e3cbd07760370e81f76b77a6a99a2`.
- Tap commit: `b23d7d321e7c58b28eb9257c7ffbbb1ba7c5a74a`; version/URL/hash match the public DMG.
- Mounted inventory contains only app, Applications symlink, Finder metadata and
  the synthetic installer background. PNG metadata is limited to numeric image
  geometry/color fields; all 8 icon slots hold PNG data.
- The earlier build 10 failed before upload and is kept only as a private negative
  control. Its unpublished tag was corrected under the data-removal authority.
  No published same-version installer bytes were replaced.
No production installation or launch performed.

## Current Blocker

None within the explicitly authorized release scope.

## Next Action

Optionally perform the real old-to-new upgrade and expanded unsent workflow matrix on the pilot Mac; no release work remains.

## Closeout

- Source, notes, VERSION and final tag align; main contains the release source.
- Canonical checks and artifact/privacy/download/recipe validation complete.
- Direct release authority recorded without inventing a smoke-test pass.
- Exactly two uploaded assets; older installers remain withdrawn.
- Local installed app, private stores, local DMGs and all backups remain intact.
- Tracker archived after publication/tap verification; follow-up integration
  validation remains in the candidate plan.
