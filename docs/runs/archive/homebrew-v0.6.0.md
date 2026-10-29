# Homebrew 0.6.0 Publication Run

## Outcome
Publish the existing v0.6.0 release through the approved own-tap pilot and upgrade the requesting Mac with Homebrew.

## Baseline
- Original working checkout: clean main, 874df0858e5fee4cd5ff60f4bd58ee8c30a9e3dd; preserved.
- Public main: f0e937c (clean/pushed baseline); separate codex/homebrew-v0.6.0 evidence branch.
- Exact immutable app tag: v0.6.0, c36c28cba3ab968a3fca6ce6dfb250e1a7f5dc1f, build 14.
- Installed cask/app: 0.5.3. Tap main b23d7d3 advertises 0.5.3.
- Existing local tap has an interrupted rebase/README conflict; preserve it before replacing its checkout.

## Authority And Gates
On 2026-10-29 the maintainer explicitly requested publishing 0.6.0 through the Brew tap and installation on this Mac. This supersedes the previous publication deferral; it does not establish a second-Mac microphone/provider test pass. Publication, tap advancement and local installation are authorized. Retain ad-hoc/non-notarized labeling, quarantine and ordinary OS approval. No new provider calls, models, permissions, private signing material or user-store changes.

## Accepted Scope And Decisions
- Rebuild exact clean tag in an isolated checkout because the prior canonical installer is on the other Mac and unavailable here. Version/build/tag stay immutable. No 0.6.0 installer has been published previously.
- Publish exactly one polished DMG and portable checksum, then independently download and verify before changing the cask.
- Preserve public sanitized history and public Git identity in isolated publication checkouts. Original older source/tags remain untouched.

## Stages
1. Canonical checks and clean tagged polished package: completed.
2. All payload/signature/privacy checks, draft/public GitHub release: completed.
3. Cask style/strict audit/hygiene and tap main push: completed (`1aa5318`). Conflicted local tap preserved in ignored backups; replacement checkout is clean.
4. User confirmed normal quit; Homebrew upgrade, normal launch and byte/provenance verification: completed.
5. Durable specs/status/release notes/evidence reconciliation: completed; documentation branch prepared for fast-forward integration.

## Validation Matrix
- task check: PASS on arm64/macOS 27.0.1 (Homebrew 7.0.11). App/behavior checks, both helpers, release fixtures, 25 installer fixtures and four hygiene fixtures pass.
- Exact-tag package/signatures/privacy/DMG: PASS. Release app plus both helpers are arm64, strictly signed; app has hardened runtime/audio entitlement. Source/history and all binaries pass generic hygiene. Complete mounted scan covers 13 files and their attributes in raw/UTF-16 representations with zero findings. Payload contains only app/licenses, installer background/layout and Applications symlink; no model weights or user data. Helper dynamic dependencies are system libraries/frameworks only. No fresh native-model inference was run on this Mac; prior accepted smoke/native inference evidence remains in the local release archive.
- Independent hosted download: PASS. Authenticated draft and anonymous public downloads match local verified bytes; portable checksum agrees. Exactly two uploaded assets.
- Cask style/audit/hygiene: PASS. `brew style` reported no offenses; name-based `brew audit --cask --strict` exited 0. Path-based audit is disabled in Homebrew 7 and was replaced by the supported name-based invocation. Tap hygiene/history and all four hygiene fixtures pass.
- Real microphone/provider/editor/Keychain smoke: requires user; not claimed.

## Release Evidence
- Public release: https://github.com/sichgeis/babbelstream/releases/tag/v0.6.0
- Immutable app source: c36c28cba3ab968a3fca6ce6dfb250e1a7f5dc1f; version 0.6.0, build 14; tag unchanged.
- Published canonical DMG: 7,352,802 bytes; SHA-256 `2752d399f5b1575be0a0ed9e5e8bb107a8b6b029584c196653c7a9db66f98ce4`.
- Portable checksum is 89 bytes. GitHub asset digest and both independent downloads agree.
- Prior local-only DMG/hash is historical, not replaced public content. This is the first published 0.6.0 installer.
- Tap source: https://github.com/sichgeis/homebrew-tap/commit/1aa5318 (clean main).
- Actual `brew upgrade --cask sichgeis/tap/babbelstream`: PASS, 0.5.3 -> 0.6.0.
- Installed metadata: 0.6.0 / build 14 / c36c28c. All 11 app payload files match mounted release bytes; strict signature passes. Quarantine attribute retained. Normal Applications launch produced one BabbelStream PID (6406 at verification).
- Existing 0.5.3 app and conflicted tap checkout are preserved in ignored project pilot backups; no settings/model/key/recovery/archive reads or changes performed. Cask has no permission/launch/kill hooks or zap stanza.
- Verification image detached; original source working checkout remains on its original clean main. No older tags/branches were rewritten there.
- No native UI inspection is claimed: Computer Use app-state queries timed out. Process launch/provenance is verified; microphone, paste, real local inference and Keychain continuity need the user.


## Current Blocker
None.

## Next Action
Run a harmless unsent dictation on the upgraded Mac and report permission/Keychain prompts and local speech/cleanup behavior.

## Closeout
- [x] Durable docs match the public release and separate pending human validation.
- [x] Canonical, packaging, privacy, download, cask and installation evidence recorded.
- [x] Publication/local installation directly authorized by the maintainer; no smoke pass fabricated.
- [x] Immutable tag and published canonical bytes preserved.
- [x] Run archived; documentation committed/pushed with a clean tree at final verification.
