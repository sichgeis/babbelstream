# 0.5.1 First-Use Microphone Patch Release

## Authority And Baseline

Continue the maintainer’s explicit release-finalization/main/tag/install/cleanup authorization, correcting a first-use defect discovered during final native verification. Do not rewrite published v0.5.0. No signing-material access, actual permission grant, recording/provider call or public binary distribution.

- Base: clean main / v0.5.0 at a1a02274fe690523feb9c4e402aa1ebcb93b737e.
- Branch: codex/onboarding-microphone-first-use.
- Scope: show Allow Microphone for notDetermined (Not requested), with fixture grant/deny coverage and a native fake-consent preview. No permission API or policy expansion.
- Version 0.5.1/build 7; unchanged broader 0.5.0 release scope and deferred other-Mac/distribution gates.

## Stages

1. Completed: full task check PASS (`/tmp/babbelstream-release-0.5.1-check.log`), explicit fresh permission grant/deny fixtures with no recording/provider/secret side effects, native fixture Allow Microphone button observed for Not requested and fake consent updates to Allowed. Evidence image under dist/onboarding-evidence/microphone-first-use-patch.png.
2. Pending: documentation, canonical checks, clean release commit; main fast-forward and immutable annotated v0.5.1 tag.
3. Pending: final exact-tag local artifact/install/launch/verification and merged-branch cleanup; archive release tracker.

## Next Action

Commit the verified patch, fast-forward main and tag v0.5.1, then package/install exact source.
