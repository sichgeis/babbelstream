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
- Evidence: baseline sandbox check fails writing normal module cache. Installed CLT Swift 6.4; default SDK symlink is macOS 27.0. No SwiftUIMacros plugin in CLT host plugins. Testing installed 26.5 SDK with normal cache access.

### B. Settings layout and visual evidence

- Status: Blocked (other-host acceptance; local implementation complete)
- Plan: inspect shared form/scroll ownership; implement coherent native spacing, retain footer, inspect five tabs and secondary dialogs with isolated state. Record both-size evidence; 27.0.1 requires external host.

- Evidence: full `task check` passed with the local SDK wrapper. Actual native fixture preview inspected all five tabs at default 760×640 and minimum 700×560 content sizes (window captures include the 28-point title bar). Provider/Diagnostics scrolling and fixed Apply observed; General restored before preview exit, no saved production values changed. Long fixture paths wrap. Shared Teach Correction, Personal Dictionary and Archive minimum windows inspected; NSHostingController constraint reset discovered and corrected by assigning contentMinSize after hosting attachment.
- Screenshots: `/tmp/babbelstream-pilot-screenshots/`, five `*-default-macos-26.7.1.png`, five `*-minimum-macos-26.7.1.png`, `general-dark-default-macos-26.7.1.png`, `teach-minimum-macos-26.7.1.png`, `dictionary-minimum-contrast-macos-26.7.1.png`, `archive-dialog-minimum-macos-26.7.1.png`. Temporary resources may expire. Light/dark and app-scoped high-contrast appearance inspected; full OS accessibility-setting validation remains manual.
- the maintainer requested HIG color review during implementation. Reviewed Apple Color, Materials and Settings. Chose semantic window/control surfaces and separator, primary headings, native accent and no custom glass. See feature spec for links and decision. No claim of exact Apple-prescribed palette.
- Remaining: macOS 27.0.1 comparison and hands-on acceptance on both installations.

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

- Status: In progress
- Plan: dedicated fail-closed distribution tooling, support/rollback docs, verify official lifecycle notices, broad regression and clean candidate packaging if possible.

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
| fixtures | parent partial core/coordinator pass | pending |
| build/package | parent full build blocked | pending |
| Settings screenshots | installed 0.4.5 baseline in temporary parent resources | actual views/fake OS adapters: five tabs at both content sizes; shared dialogs at minimum |
| macOS 27.0.1 | unavailable on this host | human gate |
| microphone/provider/Slack | not authorized in automation | human gate |
| privacy/diff | clean baseline | pending |

## Current Blocker

Canonical build restored. macOS 27.0.1 visual acceptance unavailable here; authoritative company preset/key issuance and other-host visual validation remain external inputs. No real data or production application touched.

## Next Action

Prepare fail-closed candidate/distribution tooling and reconcile provider lifecycle/support documentation.
