# Internal Pilot Readiness Implementation Run

## Outcome And Completion Contract

Deliver the approved internal-pilot improvements in `docs/features/pilot-readiness/spec.md`. Completion requires canonical checks, focused fixtures, clean candidate packaging, privacy/diff review, and manual visual evidence on both macOS versions plus human microphone/provider/Slack smoke. Never claim completion while required evidence is pending.

## Baseline

- Secured base: `codex/clipboard-only-insertion`, `162ddf3a0bac9c7ba074f2c7081b917e424f32b7`, clean and pushed.
- Implementation branch: `codex/pilot-readiness`, created and pushed 2026-10-23.
- VERSION 0.4.5; no release/version change yet. Existing clipboard-only tracker remains active and preserved.

## Authority And Gates

the maintainer explicitly requested autonomous implementation on 2026-10-23, carried in the new-chat delegation. Feature commits/pushes and local candidate preparation authorized. No subagents, PR, main/tag/publication, production installation/launch, real data/keys/providers or signing-material access. No new providers/dependencies/permissions/retention/cost changes.

## Stages

### A. Baseline, contract and build confidence

- Status: Completed
- Plan: record approval and baseline, inspect compiler/SDK selection, select a supported installed configuration locally, confirm `task check` without weakening checks.
- Evidence: baseline sandbox check fails writing normal module cache. Installed CLT Swift 6.4; default SDK symlink is macOS 27.0. No SwiftUIMacros plugin in CLT host plugins. Full application and executable suite pass with installed SDK 26.5 via the project-local wrapper and normal developer cache access. No global developer/SDK setting changed.

### B. Settings layout and visual evidence

- Status: Blocked (other-host acceptance; local implementation complete)
- Plan: inspect shared form/scroll ownership; implement coherent native spacing, retain footer, inspect five tabs and secondary dialogs with isolated state. Record both-size evidence; 27.0.1 requires external host.

- Evidence: full `task check` passed with the local SDK wrapper. Actual native fixture preview inspected all five tabs at default 760×640 and minimum 700×560 content sizes (window captures include the 28-point title bar). Provider/Diagnostics scrolling and fixed Apply observed; General restored before preview exit, no saved production values changed. Long fixture paths wrap. Shared Teach Correction, Personal Dictionary and Archive minimum windows inspected; NSHostingController constraint reset discovered and corrected by assigning contentMinSize after hosting attachment.
- Screenshots: `/tmp/babbelstream-pilot-screenshots/`, five `*-default-macos-26.7.1.png`, five `*-minimum-macos-26.7.1.png`, `general-dark-default-macos-26.7.1.png`, `teach-minimum-macos-26.7.1.png`, `dictionary-minimum-contrast-macos-26.7.1.png`, `archive-dialog-minimum-macos-26.7.1.png`. Temporary resources may expire. Light/dark and app-scoped high-contrast appearance inspected; full OS accessibility-setting validation remains manual.
- the maintainer requested HIG color review during implementation. Reviewed Apple Color, Materials and Settings. Chose semantic window/control surfaces and separator, primary headings, native accent and no custom glass. See feature spec for links and decision. No claim of exact Apple-prescribed palette.
- Remaining: captures establish the shared layout/color milestone at 323d7ea, before later setup/metadata additions. Refresh General/Provider/Diagnostics and setup confirmation/Advanced states from current sources on 26.7.1 after unlock; obtain 27.0.1 comparison and hands-on acceptance on both installations.

### C. Destination, credential, audio, parser, HUD and diagnostics boundaries

- Status: Completed
- Plan: fixture-backed focused fixes, update durable specs and checks together.

- Evidence: `task check` passes full application and expanded suite. Real loopback URLSession 307 test: synthetic audio and cleanup requests stop at redirect origin; second-origin count zero. No real provider or key accessed.
- Delivered: scheme/host/port redirect delegate; non-secret primary credential origin binding with explicit re-entry on change and fail-closed partial persistence; old in-flight origin/key retained only in memory to preserve approved snapshots; pre-store user-scoped instance lock and older-bundle check; explicit JSON/plain-text parsing; completion deadline policy; export allowlist excluding all private paths/arbitrary messages.
- Tests cover normalized/default origins, downgrade/port/userinfo/missing origin, HTML/broken JSON/scalars/untyped bodies, credential rejection/replacement/partial save, actual AppState Apply snapshots, lock contention/reacquisition, repeated HUD notifications and diagnostics path injection. Loopback fixture shutdown is bounded and uses a wake connection for Darwin accept.
- Limitation: all updated app copies enforce the lock; an old binary directly launched later cannot be retroactively changed. Quit older copies before pilot use. Native process lifecycle and HUD rendering remain manual.

### D. Guided setup and support

- Status: Blocked (external company input and locked-host visual acceptance; implementation/fixtures complete)
- Plan: explicit generic presets, per-user credentials, disclosed synthetic test and honest connection status, Advanced settings; company inputs pending.

- Evidence: full `task check` passes, including new ConnectionSetupChecks. Presets only stage URL/paths/routing and preserve models/fallback; per-user Keychain guidance, explicit silent-WAV confirmation, honest session-only readiness and Advanced controls implemented. No models-list proof, real keys or providers used. Test payload excludes speech hints, dictionary and transcript content; timeout ≤30 s and retry zero; results discarded and audio removed. Generation/cancel fixtures reject late results after Apply.
- Native setup visual check attempted after fixture-only preview launch: CUA reports Mac locked and automatic unlock unavailable. User notified asynchronously; continue independent release preparation. Earlier layout evidence remains valid for shared surfaces but does not prove newly added setup controls.
- Support/installation/upgrade/rollback/credentials guide: `docs/pilot-support.md`. Company values and issuance remain pending authoritative input; no company host guessed.

### E. Release preparation and final regression

- Status: Completed (local preparation; public distribution remains externally gated)
- Plan: dedicated fail-closed distribution tooling, support/rollback docs, verify official lifecycle notices, broad regression and clean candidate packaging if possible.

- Implemented: shared release preflight, source BUILD_NUMBER=2 (previous fixed build 1), optimized clean candidate/distribution modes, explicit Developer ID without fallback, runtime/audio entitlement verification, secure distribution timestamp flag, noninteractive plain DMG path, explicit notarize/staple/Gatekeeper helper and support procedure. No private identity lookup, signing material, notarization, publication or installation used in validation.
- Evidence: `task check` passes full app + behavior/loopback/setup + disposable Git preflight fixtures. Shell syntax and entitlement plist lint pass. First optimized candidate build from 3b52773 succeeded; packaging stopped honestly because the new verifier matched only `(runtime)` instead of actual combined `(adhoc,runtime)` flags. Corrected flag token parsing and requested XML entitlement output explicitly; actual ad-hoc app verification now passes. Added fixture acceptance/rejection checks for combined runtime flags, missing runtime/audio, debug-task access and missing Developer ID/timestamp. Repackaged successfully from clean 5dd0e34: optimized arm64 app, actual ad-hoc signature, runtime flag, audio-input entitlement, embedded source metadata, DMG integrity and checksum verified. No install or production launch. Distribution positive validation requires owner-authorized identity/profile; negative preflight rejects absent/ad-hoc identities before lookup.
- Reviewed official Apple release/signing/runtime/entitlement/build-number guidance and official OpenAI deprecations. `docs/provider-lifecycle.md` records dated cleanup/transcription migration milestones without changing any model/provider/cost or creating an automation.

## Decisions And Risks

- Preserve clipboard-only delivery and separate tracker; no AX-first restoration.
- No OS-specific spacing offsets; one shared scrolling owner preferred.
- Visual root cause is a hypothesis; top clipped row was scroll position, not a confirmed clipping defect.
- Settings acceptance needs 26.7.1 and 27.0.1 evidence. This host is 26.7.1 only.
- Continue independent approved work when an external stage is blocked; next action is highest-priority unblocked stage.

## Validation Matrix

| Check | Baseline | Current |
| --- | --- | --- |
| task check | sandbox cache failure; parent normal-cache missing SwiftUIMacros | full app and behavior suite pass with SDK26.5 wrapper |
| fixtures | parent partial core/coordinator pass | full existing suite plus origin/transport, credential, parser, HUD, instance, diagnostics, setup and release-policy fixtures pass |
| build/package | parent full build blocked | clean optimized arm64 candidate from 5dd0e34; actual signature/runtime/audio entitlement and DMG integrity/checksum verified |
| Settings screenshots | installed 0.4.5 baseline in temporary parent resources | layout milestone 323d7ea: five tabs at both content sizes, shared dialogs at minimum, dark and scoped high contrast; latest setup/metadata additions still need native review after unlock |
| macOS 27.0.1 | unavailable on this host | human gate |
| microphone/provider/Slack | not authorized in automation | human gate |
| privacy/diff | clean baseline | full baseline-to-HEAD whitespace/diff review; no direct insertion restored, clipboard source/spec/tracker unchanged; no live keys/providers/content or production stores touched |

## Candidate And Stage Evidence

| Stage | Pushed commit |
| --- | --- |
| Approved contract/tracker | eb21a81 |
| A/B build and shared layout | 323d7ea |
| C provider/credential/ownership/privacy/HUD | e760ea4 |
| D guided setup/support/lifecycle | 008c505 |
| E release tooling | 3b52773 |
| E actual signature-format correction and fixtures | 5dd0e34 |

- Candidate source: clean `5dd0e340a6564c04cc80731b388ac15351da40cd`; final handoff documentation may be a later commit with no app-code change.
- Artifact: `dist/BabbelStream-0.4.5-candidate.2-5dd0e34.dmg` (892 KiB), version 0.4.5, bundle build 2, mode candidate, embedded commit 5dd0e34 (no dirty suffix).
- SHA-256: `13d40f917d9ae3ca8d86c2a171f2cb5573a7706609fea33bc9eed9a446b1cefb`; checksum file beside artifact; verification passed.
- Signature: ad-hoc, actual flags `0x10002(adhoc,runtime)`, audio-input entitlement true, no debugger-task entitlement. Host arm64 only; no universal/distribution compatibility claim.
- Final canonical `task check`: PASS (full app + behavior/setup/loopback + release-policy fixtures). `bash -n scripts/*.sh`, entitlement plist lint, baseline-to-HEAD `git diff --check`: PASS. Existing Swift capture and CLT framework-search warnings remain; no unavailable XCTest claim.
- GitHub connector independently confirmed pilot branch at 5dd0e34 and original insertion branch still at 162ddf3. No PR, main/tag/release, private signing identity, notarization or production install/launch.
- Stopped the task's exact isolated preview process after the Mac locked. No daily app was stopped. Temporary screenshot/log resources remain available but may expire.
- Safest rollback point: secured/pushed insertion baseline 162ddf3; use ordinary forward/revert work, never reset shared checkout or rewrite published history.

## Current Blocker And Human Gates

Implementation and local candidate preparation are delivered; full acceptance remains blocked. The Mac locked before native verification of newly added setup/metadata screens, and CUA cannot unlock it. Earlier shared-layout captures do not prove those later controls. No macOS 27.0.1 host is available in this chat. Authoritative company connection/key-issuance inputs and authorized Developer ID/notarization identity/profile are still pending. Real microphone/provider/unsent-editor smoke and candidate installation require the separately defined human gates. No real data or daily application was modified.

## Next Action

After the maintainer unlocks this Mac, run the current fixture-only preview and verify the new setup, Advanced/confirmation, permission-repair and metadata screens at both documented sizes before cross-host acceptance.

## Closeout

- [x] Approved repository implementation and local candidate preparation delivered in coherent pushed stages.
- [x] Durable specs/support/release guidance reconciled; clipboard-only history preserved.
- [x] Full canonical checks, focused fixtures, clean candidate metadata/signature/integrity and diff review recorded.
- [ ] Latest native setup visual review on 26.7.1 and complete 27.0.1 visual acceptance.
- [ ] Authoritative company profile/credential issuance and distribution prerequisites supplied.
- [ ] Human real-workflow smoke approved; no waiver inferred.
- [ ] Release/install/main/tag/publication separately authorized and performed.
- [ ] Tracker archived only after the required acceptance gates pass.
