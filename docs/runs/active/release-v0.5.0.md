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
2. In progress: full canonical checks PASS (`/tmp/babbelstream-release-0.5.0-check.log`), shell syntax/entitlement plist/diff checks PASS. Runtime Sources/Resources/Package/scripts unchanged from human-tested b3f7ff0. Release commit, main fast-forward, annotated v0.5.0 tag and atomic push next.
3. Pending: rebuild exact tagged source using explicit ad-hoc candidate pipeline with final BabbelStream-0.5.0.dmg filename; verify/install/launch.
4. Pending: final evidence-only docs, archive this release run, clean merged task branches while preserving tags/artifacts/rollback.

## Next Action

Run final canonical and release metadata checks before committing the release preparation.
