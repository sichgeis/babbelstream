# First-Run Onboarding Implementation Run

## Outcome And Authority

Implement the onboarding portion of `docs/features/onboarding-and-updates/spec.md`, explicitly approved 2026-10-23. Sparkle, colleague signing, updater traffic and distribution remain deferred. Authorized implementation, checks, feature commits/pushes and local candidate packaging. the maintainer explicitly authorized final quality review, documentation, commits/pushes and latest local installation/launch in the follow-up request on 2026-10-23. Real microphone/provider testing, main/tags/publication and signing-material use remain separately gated.

## Baseline

- Pushed base: `codex/pilot-readiness`, `dbf6be5b4c386c0df8df1863257fb6d2eb067ae1`.
- Tracked tree clean; only the agent-authored design draft from the preceding turn was untracked. Carried that approved design into `codex/onboarding` and committed it separately as 4206f92. No unrelated user changes.
- At baseline, installed candidate was 0.4.5 build 3 / 4e6da0d, with user-confirmed automatic paste after Accessibility repair. Do not replace it implicitly.
- Baseline `task check`: PASS with normal developer caches (`/tmp/babbelstream-onboarding-baseline.log`).

## Stages

1. Completed: setup persistence/policy, exact-target local paste session and coordinator exclusion; deterministic checks.
2. Completed locally: native setup/repair window, menu/General entry points, activation refresh and isolated fixture preview. Human permission/native paste acceptance remains pending.
3. Completed locally: durable specifications, canonical checks, native fixture evidence and clean candidate packaging. Installation and human acceptance remain separately gated.

## Decisions And Risks

- Keep current dictation's application-only target contract; add an optional stricter target guard only for the local test's owned editor.
- Receipt of the known sample, not shortcut posting, verifies a local test. No external field reads or private content involved.
- Postponed setup does not disable copy-only dictation. Live permissions always override remembered progress.
- New ad-hoc candidates may need permission repair. Signing changes are deferred; do not reset TCC or use keys in automation.

## Current Blocker

None.

## Next Action

the maintainer completes live permission onboarding and the local sample test in installed build 5, then reports the unsent dictation smoke result.

## Acceptance Remaining

- [x] Canonical suite and focused race/failure checks.
- [x] Native fixture review at both sizes/light/dark on this host; other-host 27.0.1 comparison remains manual.
- [x] Clean candidate packaging.
- [x] Explicitly authorized candidate build 5 installation/launch verified.
- [ ] Human consent/local paste/real dictation smoke.

## Implementation And Validation Evidence

- Onboarding includes five steps, postponement/reopen, actual permission queries on activation and Check Again, provider-pane navigation, dedicated local paste field and honest readiness. Previously observed grants trigger focused repair after revocation. No updater/dependency/signing material/new permission added.
- Local paste shares the production clipboard service with an additional owned-editor/window predicate. It reserves the coordinator through completion/cancellation, checks current permission again before posting, and requires exact known-sample receipt within a bounded wait. Ordinary dictation retains its application-only targeting. Existing Last Draft delivery also excludes a test; Last Draft content is never replaced by a sample.
- Full `task check` PASS after final spacing/header changes: `/tmp/babbelstream-onboarding-final-check.log`. Behavior/setup/loopback/onboarding and release-policy fixtures all pass. Existing compiler capture/CLT framework-search warnings remain. Numeric-type ambiguity in the NSTextView setup was fixed before these checks. No unavailable XCTest claim.
- Native fixture evidence: `/tmp/babbelstream-onboarding-screenshots/`. All five onboarding steps inspected at default/minimum with saved and incomplete configuration, skipped/unverified tests, denied permissions, native dark appearance and focused repair. The exact local focus guard correctly reports failure when the tool-driven preview is inactive; no native paste success is claimed from fake adapters. Known-sample success and all failure/race paths are proved by deterministic injected-field/environment checks.
- User accepted the nearly white surface, then requested shared-dialog coverage, removal of Settings' gray tab bands, and spacing cleanup. Implemented one shared adaptive canvas, a native segmented Picker without TabView bezel, consistent margins/label column, grouped Readiness actions and closer control/help spacing. Final five Settings sections captured at default/minimum (`settings-*-final*.png`); Dark Mode minimum and scoped-contrast repair captured. Forced app appearance does not establish full OS Increase Contrast behavior; that remains manual.
- Privacy/diff review: no external editor reads, old clipboard reads/restoration, sample persistence/logging, provider/Keychain/microphone actions or production changes during automation. Preview uses fake insertion/progress/provider/permission adapters. At that checkpoint, original build 3 remained running with its repaired permission grant.

## Remaining Human Acceptance

Candidate installation was explicitly authorized in the final-review request. After installation, verify real first-run/postpone/reopen, actual grant/activation refresh, local sample receipt, focus/close cancellation and an unsent real dictation. Existing build 3 smoke does not validate the new onboarding. macOS 27.0.1 and full OS accessibility-setting acceptance remain pending. Sparkle and colleague signing stay deferred.

## Candidate 4 Evidence (Superseded By Reviewed Build 5)

- Source: clean `3f6c3122b260f11ca4f0bb6725d5f5c08dba0ad2`, pushed on `codex/onboarding`. Later evidence-only documentation does not change the app payload.
- Artifact: `dist/BabbelStream-0.4.5-candidate.4-3f6c312.dmg` (972 KiB). SHA-256 `29e16d67a0572b67e011ffefc20bfc3c4f84b46d59bea6c75f3a55585623a92c`; checksum verification PASS.
- Packaging: explicit ad-hoc identities; clean release optimization; actual candidate signature/runtime/audio entitlement and embedded version 0.4.5/build 4/commit 3f6c312/mode candidate verified. DMG integrity verified by packaging. No private identity, installation, production launch, release tag or main change.
- Native secondary minimum-size checks completed for Teach Correction, Dictionary and Archive after final metrics; all use the accepted canvas and fixed footer. Selected evidence preserved under ignored `dist/onboarding-evidence/`; full temporary screenshots remain under `/tmp/babbelstream-onboarding-screenshots/`. Fixture preview processes closed. No production app/store was used for visual checks.
- Full `task check` and final diff whitespace checks PASS. Source behavior unchanged after those checks; final documentation records candidate evidence only. At that checkpoint, build 3 remained installed/running; its repaired permissions were not reset.
- Build 4 evidence above is historical; final-review installation is now authorized and a corrected build 5 supersedes it. After installation, the maintainer must test real consent/activation refresh and the local sample field before the expanded unsent dictation matrix. Current fixture focus-guard evidence is not native paste-success evidence.

## Final Review And Installation Pass (2026-10-23)

- Baseline: clean/pushed 0abea3d on codex/onboarding. Existing implementation/docs and candidate 4 already committed and pushed.
- Review scope: all onboarding code, integration, shared Settings styling, core paste delta, fixtures, privacy and release documentation. Use gm-refactor guidance for visible control flow and focused improvements.
- Follow-up findings to resolve: cancel on app/window focus-loss notifications so a rapid leave/return cannot resume an old test; refresh actual permissions after test completion so revoked access is visible immediately. Preserve the stricter editor guard and clipboard/cancellation preflight.
- Proceed through normal-cache canonical checks, coherent pushed fixes, clean latest candidate and local installation/launch with rollback bundle. No permission reset, actual recording/provider test or private signing key use.

## Final Review Findings Resolved

- Added window-key-loss and app-deactivation cancellation to the existing close/navigation checks. A focus-loss/return regression fixture proves the canceled attempt cannot post even when focus is restored before preparation ends.
- Local-test completion now re-queries permissions before releasing coordinator ownership. A revocation fixture proves General/onboarding no longer retain stale Allowed status after a denied test.
- Tightened busy-state wording and released fixture closure captures after tests. No added production abstraction, dependency, provider, permission or secret use.
- Reviewed setup/persistence, native field ownership, menu/Settings integration, AppState operation exclusion, clipboard origin/focus/cancellation preflight, preview isolation, specs and release gates. No additional blocking code issue found in this change. Real OS consent/event delivery still requires human smoke.
- Full canonical task check PASS after fixes: `/tmp/babbelstream-onboarding-review-check.log`; existing capture/toolchain warnings unchanged. Build incremented to 5 for the corrected iteration. Final source/diff/privacy review completed; clean packaging and authorized installation follow.

## Final Candidate 5 Installation Evidence

- Source: clean/pushed `b3f7ff0c93b94f220a947774c8155db20ba11e2d`. Version 0.4.5, bundle build 5, mode candidate, source commit b3f7ff0. No dirty suffix. Final evidence-only documentation may have a later HEAD.
- Artifact: `dist/BabbelStream-0.4.5-candidate.5-b3f7ff0.dmg` (973 KiB); SHA-256 `a57cbf8c45ae6436d90064901b0c7a36cac976a0d5fb5ad79f9618895901263b`. Checksum, DMG integrity and actual candidate signature/runtime/audio entitlement verification PASS. Explicit ad-hoc signing only, no private signing identity lookup.
- Normal quit of the existing Applications copy; exact DMG mounted read-only and payload metadata/signature checked. Staged replacement verified before activation; old installed build 3 preserved at `dist/rollback/BabbelStream-0.4.5-build3-4e6da0d.app`. DMG detached. No manual settings/Keychain/data changes or TCC reset.
- Installed `/Applications/BabbelStream.app` and launched normally (no forced window argument). Native UI confirms first-use Set Up BabbelStream window, step 1 of 5. Running executable, strict signature and installed metadata verified. Installed/payload executable SHA-256 both `5cbfc0220f3462e11d20c9fc4a106a54159d6945f820eba32cd56006bee8dab9`.
- Quality/checks/docs/source fixes committed and pushed before packaging/install. Final `task check`, shell syntax, entitlement plist lint and complete feature diff whitespace checks PASS. Final docs reconcile installation evidence; no code changed after candidate validation.
- User action remaining: complete permission consent and local paste test, then real unsent dictation smoke. No real recording/provider request, permission grant, main/tag/PR or publication was performed by automation. Sparkle/signing remains deferred. Tracker stays active until human acceptance.
