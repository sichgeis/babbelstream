# 0.5.0 Local Release Run

## Authority And Scope

the maintainer explicitly approved release finalization on 2026-10-23, accepted the smoke test, deferred the other-Mac check, and requested cleanup. Authorized: release metadata, main fast-forward, annotated tag/push, clean local packaging, installation/launch and verification. Private signing-material access, notarization submission, public binary distribution, new providers/costs and Sparkle remain deferred.

## Baseline And Version

- Clean/pushed codex/onboarding at d22d1552c47b1355f513aa3453ad0b7ea6219d27.
- GitHub connector and fresh git fetch confirm origin/main a9c55479efc6a213d575b79db78c78cc12573c76 is an ancestor; main can fast-forward without merge/rebase/history rewrite.
- Scope includes clipboard-only insertion, pilot safeguards/layout/setup/release tooling and onboarding/final quality fixes. Runtime app source is unchanged from human-tested build 5 / b3f7ff0.
- Version 0.5.0, build 6: minor increment for substantial user-visible functionality; no old release tag changes.
- Installed baseline: 0.4.5 build 5 / b3f7ff0, retained until final replacement.

## Acceptance

- the maintainer explicitly accepts the successful smoke test as the release gate.
- macOS 26.7.1 native fixture layout evidence, full behavior/setup/loopback/onboarding/release-policy checks and content-free privacy/diff review exist in the archived implementation runs.
- Other-Mac macOS 27.0.1 and detailed native/accessibility/provider matrices are deferred limitations, not passed checks.
- Final task check, release metadata/diff checks, clean packaging, actual signature/entitlements/DMG verification and final local installation remain to be completed below.

## Stages

1. Completed: VERSION 0.5.0/build 6, dated changelog/README/specs/support/status reconciled; three implementation trackers archived with explicit release decision and deferred follow-ups in the candidate plan.
2. Completed: full canonical checks PASS (`/tmp/babbelstream-release-0.5.0-check.log`), shell syntax/entitlement plist/diff checks PASS. Runtime Sources/Resources/Package/scripts unchanged from human-tested b3f7ff0. Release commit, main fast-forward, annotated v0.5.0 tag and atomic push completed; exact evidence below.
3. Completed: exact-tag artifact built, verified and installed; final native verification identified the first-use defect corrected in 0.5.1.
4. Completed with the 0.5.1 closeout: this run archived and merged task branches cleaned; all release tags/artifacts/rollback retained.

## Next Action

No action for superseded 0.5.0; latest installed release/evidence is in docs/runs/archive/release-v0.5.1.md.

## 0.5.0 Final Verification And Superseding Patch

- Main/tag: a1a02274fe690523feb9c4e402aa1ebcb93b737e; annotated tag object 3927880f0e4829d2c22e818fc1ef77c9716f319c. Both pushed atomically and independently verified through GitHub connector.
- Artifact: dist/BabbelStream-0.5.0.dmg (973 KiB), SHA-256 1e12af24bf22163ca9e2b191287396604425adfcd0ec4059d14ff5b1b79c803c. Clean optimized build, actual signature/runtime/audio entitlement, checksum and DMG integrity verified.
- Installed version 0.5.0 build 6 / a1a0227 and running Applications process verified. Executable hash 6f22660bfa06d43d417979ec140e229deef29fd8f406f8d3ab5cfcb02288624e matched payload. Build 5 backup retained under dist/rollback/BabbelStream-0.4.5-build5-b3f7ff0.app.
- Final native setup check exposed an onboarding defect: fresh microphone access is notDetermined, while the Allow Microphone button checked unknown. General Settings could still request access, but the intended onboarding button was missing. User informed; correct as 0.5.1 without rewriting the published 0.5.0 tag.
- At final 0.5.0 startup: Microphone Not requested, Accessibility Not allowed under the ad-hoc identity. No grant/reset/recording/provider action was automated. Permission reapproval remains a user action.
- This run is closed with the local artifact released and the discovered defect explicitly superseded by the focused 0.5.1 patch. Latest release/install evidence is archived in docs/runs/archive/release-v0.5.1.md.
