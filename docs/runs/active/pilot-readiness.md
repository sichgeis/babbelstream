# Internal Pilot Readiness Implementation Run

## Outcome And Completion Contract

Deliver the approved internal-pilot improvements in `docs/features/pilot-readiness/spec.md`. Completion requires canonical checks, focused fixtures, clean candidate packaging, privacy/diff review, and manual visual evidence on both macOS versions plus human microphone/provider/Slack smoke. Never claim completion while required evidence is pending.

## Baseline

- Secured base: `codex/clipboard-only-insertion`, `162ddf3a0bac9c7ba074f2c7081b917e424f32b7`, clean and pushed.
- Implementation branch: `codex/pilot-readiness`, created and pushed 2026-10-23.
- VERSION 0.4.5; no release/version change yet. Existing clipboard-only tracker remains active and preserved.

## Authority And Gates

the maintainer explicitly requested autonomous implementation on 2026-10-23, carried in the new-chat delegation. Feature commits/pushes and local candidate preparation authorized. Initial scope excluded subagents, PR, main/tag/publication, production installation/launch, real data/keys/providers or signing-material access. the maintainer subsequently explicitly authorized installation and launch of candidate build 3 for his own smoke test; this does not authorize automated recording/provider calls or release/publication. No new providers/dependencies/permissions/retention/cost changes.

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
- Refreshed after the maintainer unlocked the Mac: all five tabs at default/minimum; Advanced, canceled synthetic-test confirmation and denied permissions at both sizes; metadata and incomplete setup in dark appearance; Teach Correction/Dictionary/Archive at minimum sizes. Evidence: `/tmp/babbelstream-pilot-screenshots/resumed/`. Native review found truncated Provider captions and automatic hosting-controller fitting enlarging Teach Correction. Fixed explicit vertical caption wrapping and disabled automatic dialog hosting sizing; final five-tab and secondary minimum captures verify the corrections. All isolated previews quit; no production stores or live providers used.
- Remaining: obtain 27.0.1 comparison and hands-on acceptance on both installations.

### C. Destination, credential, audio, parser, HUD and diagnostics boundaries

- Status: Completed
- Plan: fixture-backed focused fixes, update durable specs and checks together.

- Evidence: `task check` passes full application and expanded suite. Real loopback URLSession 307 test: synthetic audio and cleanup requests stop at redirect origin; second-origin count zero. No real provider or key accessed.
- Delivered: scheme/host/port redirect delegate; non-secret primary credential origin binding with explicit re-entry on change and fail-closed partial persistence; old in-flight origin/key retained only in memory to preserve approved snapshots; pre-store user-scoped instance lock and older-bundle check; explicit JSON/plain-text parsing; completion deadline policy; export allowlist excluding all private paths/arbitrary messages.
- Tests cover normalized/default origins, downgrade/port/userinfo/missing origin, HTML/broken JSON/scalars/untyped bodies, credential rejection/replacement/partial save, actual AppState Apply snapshots, lock contention/reacquisition, repeated HUD notifications and diagnostics path injection. Loopback fixture shutdown is bounded and uses a wake connection for Darwin accept.
- Limitation: all updated app copies enforce the lock; an old binary directly launched later cannot be retroactively changed. Quit older copies before pilot use. Native process lifecycle and HUD rendering remain manual.

### D. Guided setup and support

- Status: Blocked (external company input; local implementation/fixtures/visual review complete)
- Plan: explicit generic presets, per-user credentials, disclosed synthetic test and honest connection status, Advanced settings; company inputs pending.

- Evidence: full `task check` passes, including new ConnectionSetupChecks. Presets only stage URL/paths/routing and preserve models/fallback; per-user Keychain guidance, explicit silent-WAV confirmation, honest session-only readiness and Advanced controls implemented. No models-list proof, real keys or providers used. Test payload excludes speech hints, dictionary and transcript content; timeout ≤30 s and retry zero; results discarded and audio removed. Generation/cancel fixtures reject late results after Apply.
- Native setup review completed after unlock on 26.7.1, including complete/incomplete setup, Advanced, confirmation (canceled without sending), denied-permission guidance and metadata. Provider captions wrap fully after the visual correction.
- Support/installation/upgrade/rollback/credentials guide: `docs/pilot-support.md`. Company values and issuance remain pending authoritative input; no company host guessed.

### E. Release preparation and final regression

- Status: Completed (local preparation; public distribution remains externally gated)
- Plan: dedicated fail-closed distribution tooling, support/rollback docs, verify official lifecycle notices, broad regression and clean candidate packaging if possible.

- Implemented: shared release preflight, source BUILD_NUMBER=3 (previous fixed build 1; candidate 2 preceded final UI corrections), optimized clean candidate/distribution modes, explicit Developer ID without fallback, runtime/audio entitlement verification, secure distribution timestamp flag, noninteractive plain DMG path, explicit notarize/staple/Gatekeeper helper and support procedure. No private identity lookup, signing material, notarization, publication or installation used in validation.
- Evidence: `task check` passes full app + behavior/loopback/setup + disposable Git preflight fixtures. Shell syntax and entitlement plist lint pass. First optimized candidate build from 3b52773 succeeded; packaging stopped honestly because the new verifier matched only `(runtime)` instead of actual combined `(adhoc,runtime)` flags. Corrected flag token parsing and requested XML entitlement output explicitly; actual ad-hoc app verification now passes. Added fixture acceptance/rejection checks for combined runtime flags, missing runtime/audio, debug-task access and missing Developer ID/timestamp. Repackaged successfully from clean 5dd0e34: optimized arm64 app, actual ad-hoc signature, runtime flag, audio-input entitlement, embedded source metadata, DMG integrity and checksum verified. No install or production launch. Distribution positive validation requires owner-authorized identity/profile; negative preflight rejects absent/ad-hoc identities before lookup.
- Final UI correction candidate rebuilt from clean 4e6da0d with explicit ad-hoc identities: build 3, optimized arm64, actual signature/runtime/audio entitlement, embedded version/build/commit and DMG integrity/SHA-256 verified. Full `task check` passed after the final corrections (`/tmp/babbelstream-pilot-final-ui-check.log`).
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
| build/package | parent full build blocked | clean optimized arm64 candidate build 3 from 4e6da0d; actual signature/runtime/audio entitlement and DMG integrity/checksum verified |
| Settings screenshots | installed 0.4.5 baseline in temporary parent resources | layout milestone 323d7ea: five tabs at both content sizes, shared dialogs at minimum, dark and scoped high contrast; current setup/metadata/Advanced/confirmation/permissions and shared minimum dialogs refreshed in resumed captures |
| macOS 27.0.1 | unavailable on this host | human gate |
| microphone/provider/editor | not authorized in automation | the maintainer reports dictation/automatic paste works after permission repair; expanded matrix remains pending |
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
| B/D final native wrapping and hosting-size corrections | 4e6da0d |

- Current candidate source: clean `4e6da0d23fd0f400edf8754b5bb44d54169cb5cc`; final handoff documentation may be a later commit with no app-code change. Build 3 supersedes build 2 from 5dd0e34.
- Artifact: `dist/BabbelStream-0.4.5-candidate.3-4e6da0d.dmg` (893 KiB), version 0.4.5, bundle build 3, mode candidate, embedded commit 4e6da0d (no dirty suffix).
- SHA-256: `235618294924b162428de35721f983acccaf5ea1e7f193c8c16bc46d283a7cdd`; checksum file beside artifact; verification passed.
- Signature: ad-hoc, actual flags `0x10002(adhoc,runtime)`, audio-input entitlement true, no debugger-task entitlement. Host arm64 only; no universal/distribution compatibility claim.
- Refreshed canonical `task check` after final UI corrections: PASS (full app + behavior/setup/loopback + release-policy fixtures). `bash -n scripts/*.sh`, entitlement plist lint, baseline-to-HEAD `git diff --check`: PASS. Existing Swift capture and CLT framework-search warnings remain; no unavailable XCTest claim.
- Feature source commit 4e6da0d pushed successfully; original insertion branch remains preserved at 162ddf3. No PR, main/tag/release, private signing identity, notarization or production install/launch.
- All resumed isolated previews closed normally. No daily app was stopped. Temporary screenshot/log resources remain available but may expire.
- Safest rollback point: secured/pushed insertion baseline 162ddf3; use ordinary forward/revert work, never reset shared checkout or rewrite published history.

## Authorized Local Installation (2026-10-23)

- the maintainer requested install/launch of candidate build 3 for his UI review and smoke test. Verified the exact DMG SHA-256, mounted read-only, checked payload metadata/signature/runtime/entitlements, and staged the Applications replacement.
- Asked the prior running Applications copy to quit normally through macOS. Preserved its actual installed bundle (`0.4.5`, build 1, `a9c5547`) at `dist/rollback/BabbelStream-0.4.5-a9c5547.app`; this supersedes older installed-version evidence. No settings, Keychain entries, recordings or archives were copied or changed manually.
- Installed `/Applications/BabbelStream.app`, launched with `--settings`, and verified running process, version 0.4.5/build 3/commit 4e6da0d, strict candidate signature, and executable SHA-256 matching the prepared payload. Settings visible in General. DMG detached.
- Native General reports Microphone Not requested and Accessibility Not allowed under the candidate identity. the maintainer must grant permissions for his smoke test; ad-hoc identity may require Accessibility reapproval. No permission buttons, provider tests or recording controls were activated by automation.
- Release/main/tag/publication and full acceptance remain pending; local install authorization is not a smoke-test pass or release approval.

## Human Paste Retest (2026-10-23)

- the maintainer reported dictation completed but only copied to the clipboard in ChatGPT and Slack. Native General showed Microphone Allowed, Accessibility Not allowed. The insertion service correctly uses its copy-only fallback when AXIsProcessTrusted is false.
- System Settings showed the BabbelStream toggle enabled while the running candidate remained untrusted. Removing/re-adding initially did not resolve it. Reset only `Accessibility` for bundle `com.sichgeis.babbelstream` using tccutil; the maintainer reauthorized the installed Applications copy. No other application permission was reset.
- After a normal candidate restart, native General showed both Microphone Allowed and Accessibility Allowed. the maintainer then reported: “Now it works as expected.” This confirms his basic dictation/automatic-paste retest, without claiming the complete editor/language/gesture/recovery matrix or release approval. No automated recording/provider call or draft inspection was performed.

## Current Blocker And Human Gates

Implementation and local candidate preparation are delivered; full acceptance remains blocked. Current setup/metadata and shared dialogs passed fixture-only native review on 26.7.1 after unlock. No macOS 27.0.1 host is available in this chat. Authoritative company connection/key-issuance inputs and authorized Developer ID/notarization identity/profile are still pending. Candidate installation/launch was subsequently explicitly authorized and completed below. the maintainer confirmed the basic dictation/automatic-paste retest works after Accessibility repair; expanded language/editor/gesture/recovery matrix is not established by that report. Saved settings, keys and application data were preserved.

## Next Action

Obtain macOS 27.0.1 visual comparison of the current Settings and secondary dialogs at both documented sizes.

## Closeout

- [x] Approved repository implementation and local candidate preparation delivered in coherent pushed stages.
- [x] Durable specs/support/release guidance reconciled; clipboard-only history preserved.
- [x] Full canonical checks, focused fixtures, clean candidate metadata/signature/integrity and diff review recorded.
- [x] Latest native setup and secondary-dialog visual review on 26.7.1.
- [ ] Complete 27.0.1 visual acceptance.
- [ ] Authoritative company profile/credential issuance and distribution prerequisites supplied.
- [x] Human basic dictation/automatic-paste retest passed after permission repair.
- [ ] Expanded real-workflow smoke matrix and final acceptance; no waiver inferred.
- [x] Candidate build 3 local installation/launch explicitly authorized and verified.
- [ ] Final release/main/tag/publication separately authorized and performed.
- [ ] Tracker archived only after the required acceptance gates pass.
