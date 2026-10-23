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

- Status: In progress
- Plan: record approval and baseline, inspect compiler/SDK selection, select a supported installed configuration locally, confirm `task check` without weakening checks.
- Evidence: baseline sandbox check fails writing normal module cache. Installed CLT Swift 6.4; default SDK symlink is macOS 27.0. No SwiftUIMacros plugin in CLT host plugins. Testing installed 26.5 SDK with normal cache access.

### B. Settings layout and visual evidence

- Status: Pending
- Plan: inspect shared form/scroll ownership; implement coherent native spacing, retain footer, inspect five tabs and secondary dialogs with isolated state. Record both-size evidence; 27.0.1 requires external host.

### C. Destination, credential, audio, parser, HUD and diagnostics boundaries

- Status: Pending
- Plan: fixture-backed focused fixes, update durable specs and checks together.

### D. Guided setup and support

- Status: Pending
- Plan: explicit generic presets, per-user credentials, disclosed synthetic test and honest connection status, Advanced settings; company inputs pending.

### E. Release preparation and final regression

- Status: Pending
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
| task check | sandbox cache failure; parent normal-cache missing SwiftUIMacros | pending SDK diagnosis |
| fixtures | parent partial core/coordinator pass | pending |
| build/package | parent full build blocked | pending |
| Settings screenshots | installed 0.4.5 baseline in temporary parent resources | pending isolated candidate |
| macOS 27.0.1 | unavailable on this host | human gate |
| microphone/provider/Slack | not authorized in automation | human gate |
| privacy/diff | clean baseline | pending |

## Current Blocker

Full canonical build environment under diagnosis; authoritative company preset/key issuance and other-host visual validation remain external inputs. No real data or production application touched.

## Next Action

Finish installed-SDK build diagnosis and establish a reproducible canonical check configuration.
