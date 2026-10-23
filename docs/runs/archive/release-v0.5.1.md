# 0.5.1 First-Use Microphone Patch Release

## Authority And Baseline

Continue the maintainer’s explicit release-finalization/main/tag/install/cleanup authorization, correcting a first-use defect discovered during final native verification. Do not rewrite published v0.5.0. No signing-material access, actual permission grant, recording/provider call or public binary distribution.

- Base: clean main / v0.5.0 at a1a02274fe690523feb9c4e402aa1ebcb93b737e.
- Branch: codex/onboarding-microphone-first-use.
- Scope: show Allow Microphone for notDetermined (Not requested), with fixture grant/deny coverage and a native fake-consent preview. No permission API or policy expansion.
- Version 0.5.1/build 7; unchanged broader 0.5.0 release scope and deferred other-Mac/distribution gates.

## Stages

1. Completed: full task check PASS (`/tmp/babbelstream-release-0.5.1-check.log`), explicit fresh permission grant/deny fixtures with no recording/provider/secret side effects, native fixture Allow Microphone button observed for Not requested and fake consent updates to Allowed. Evidence image under dist/onboarding-evidence/microphone-first-use-patch.png.
2. Completed: reconciled documentation and full canonical checks; clean release commit 8f229fefe2ef344bf2e1c1869779f6d6b077b42e fast-forwarded into main. Annotated v0.5.1 tag object c5df84df45a672bb85efb4d812694c955bf7c2e5 pushed atomically with main; both independently verified through GitHub connector.
3. Completed: exact-tag optimized local artifact verified/installed/launched, merged task branches removed locally/remotely, and release tracker archived.

## Next Action

the maintainer grants microphone/Accessibility access for the final ad-hoc build using the open onboarding permission page.

## Final Release Evidence

- Final app source/main integration: 8f229fefe2ef344bf2e1c1869779f6d6b077b42e. Annotated tag v0.5.1 points to that commit. Published v0.5.0 remains unchanged at a1a02274fe690523feb9c4e402aa1ebcb93b737e. Later docs-only main evidence does not change the tagged app payload.
- VERSION 0.5.1, bundle build 7; optimized arm64 local package. Internal build mode candidate identifies the ad-hoc verification class; no claim of Developer ID or notarization.
- Artifact: dist/BabbelStream-0.5.1.dmg (972 KiB). SHA-256 8dc567ac48285cc3612e1743b30262eb3dd40eecdb4b6d7879d322a41125824d; checksum and DMG integrity PASS. Actual strict signature/runtime/audio-input entitlement PASS, no debugger task access.
- Installed /Applications/BabbelStream.app and running process verified: 0.5.1 / build 7 / commit 8f229fe. Installed/payload executable SHA-256 both cf4862a37d307ca15d4b208f296eaf8effd4b2ce57dc2278e7c3e38446901a84.
- Normal quit and staged replacement from read-only verified DMG; detached afterward. Temporary 0.5.0 bundle retained at dist/rollback/BabbelStream-0.5.0-build6-a1a0227.app; successful build 5 retained at dist/rollback/BabbelStream-0.4.5-build5-b3f7ff0.app. Settings, keys, recordings/archive data and TCC entries were not manually changed/reset.
- Native installed UI: setup step 2 shows Microphone Not requested with Allow Microphone visible and Accessibility Not allowed with Enable Automatic Paste/Open Settings. The missing request-button defect is fixed in the actual installed app. Leave these explicit grants to the user; no real prompt acceptance, microphone capture or provider request was automated.
- Full task check PASS (/tmp/babbelstream-release-0.5.1-check.log), including original behavior/loopback/setup/onboarding/release-policy suites and fresh grant/deny checks. Native fake-consent UI updates to Allowed; actual consent remains user-controlled. Shell syntax, entitlement plist and final whitespace checks PASS; preexisting toolchain warnings remain.
- Removed only fully merged task branches locally/remotely: codex/clipboard-only-insertion, codex/pilot-readiness, codex/onboarding, codex/onboarding-microphone-first-use. Their commits remain reachable from main/tags; unrelated branches, release artifacts, rollback bundles and evidence are preserved.
- All implementation/release trackers closed and archived. No outstanding repository release work. Deferred other-Mac macOS 27.0.1 validation, full native/accessibility/provider matrices, company distribution inputs, Developer ID/notarization and Sparkle remain in docs/implementation-plan.md and docs/project-status.md.
