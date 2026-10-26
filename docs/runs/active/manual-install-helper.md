# Manual Installation Helper Implementation Run

## Outcome

Deliver an explicit, verified download/preparation/update helper and README
instructions; commit and push a feature branch, then hand off the native test.

## Baseline

- Base: clean, pushed `main`, `3b60838dae4f121b5cb145780f495b3b8fd307fe`.
- Remote refreshed; HEAD/origin/main divergence 0/0.
- Branch: `codex/manual-install-helper`.
- Existing public release reused: 0.5.3/build 11/b9c0641; no new app release.
- Commit identity checked and matches required public identity.

## Authority And Gates

- Approved: `docs/features/manual-install-helper/spec.md`, conversation 2026-10-26.
- Authorized: implementation, tests, feature commit/push, explicit download/update
  helper and README bootstrap; stage a user test.
- Human gate: real managed-Mac installation/launch; no claimed microphone/provider smoke.
- Main/tag/release publication remain outside this implementation.

## Decisions And Risks

- README editorial follow-up: maintainer requested a clearer, shorter landing
  page with Wonder assistance. Reviewed the external editorial draft and applied
  a final concise edit: 2,001 to 1,056 words. Kept the bootstrap byte-for-byte,
  preserved externally linked headings, and moved complete repair procedures to
  `docs/troubleshooting.md`. No behavior or installation contract changed.

- Only a staged verified copy loses quarantine after exact interactive consent.
- Helper downloads the exact pinned GitHub release; update uses the current
  README helper, not an unverified dynamic latest-release manifest.
- Native drag-to-Applications is the installation step; no privileged copying.
- System command PATH is fixed; fixtures change only their disposable script copy.
- This is a narrowly approved change to the prior quarantine-preserving contract;
  cask hooks and global protection/permission changes remain excluded.
- Endpoint policy may block the helper or app; contact IT if it does.

## Stages

1. Baseline/checks: completed. Initial sandbox cache denial resolved by running
   `task check` with normal developer-cache access; baseline passes with existing warnings.
2. Helper and docs: completed; fixture-only local/download/update coverage added.
3. Final validation and feature push: completed. Helper commit:
   `cff15fe7202a95463fd44047e603d0645d036e13`; pinned README bootstrap commit:
   `0367134`. Both pushed to `origin/codex/manual-install-helper`.
4. Native downloaded pilot: pending user execution/consent; do not fabricate success.

## Validation Matrix

| Check | Evidence |
| --- | --- |
| Baseline `task check` | Passed with normal cache access; pre-existing Swift capture/framework warnings |
| Helper fixtures | 14 tests passed, including local/download/update and negative paths |
| Final `task check` | Passed with normal cache access; existing warnings only |
| Real public DMG verification | `bash scripts/prepare-downloaded-install.sh --verify-only --download` passed with normal disk-image access; no quarantine mutation/install/launch |
| Public history scan | Passed before feature push |
| Published README bootstrap | Immutable GitHub helper download and DMG download/mount/app verification passed end to end with `--verify-only --download` |
| Native attribute primitive | Synthetic temporary bundle: nested quarantine removed; unrelated attribute preserved; fixture discarded |
| Native installation/launch | Pending |
| README cleanup | Bootstrap identity/shell syntax, local file links, legacy heading anchors and public hygiene passed; canonical checks rerun |

## Release Evidence

DMG bytes and existing release assets remain unchanged. No installation, launch,
provider request, permission change, new tag or public release performed.

## Current Blocker

None for implementation. Managed-Mac behavior remains unproven.

## Next Action

Run the feature-branch README bootstrap interactively on the pilot Mac, then
record the actual Finder installation/launch outcome before integration.

## Closeout

- [x] Final checks and commit/push evidence recorded.
- [ ] User native pilot result recorded.
- [ ] Integration direction resolved and tracker archived when complete.
