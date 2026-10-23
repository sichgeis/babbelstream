# Project Status

This file owns current release/work state. Durable behavior, privacy, architecture,
validation and release procedure remain in their dedicated specifications.

## Current Release

- Version: **0.5.1**, bundle build **7**; focused patch finalization in progress on `codex/onboarding-microphone-first-use` after the maintainer’s explicit 2026-10-23 smoke/release approval.
- Scope: clipboard paste for every application, provider/credential/parser/instance safeguards, private diagnostics/HUD fixes, guided provider setup, native first-run permission onboarding/local paste verification, and the unified subtle Settings/dialog layout.
- Supported workflow: tap/hold Control + Option + Space into Slack and other focused macOS text fields; no auto-send.
- Canonical validation: `task check`.
- Final local artifact uses optimized clean candidate packaging with explicit ad-hoc signing. Developer ID/notarized colleague distribution and automatic updates remain deferred.
- Installed baseline until patch replacement: **0.5.0 build 6 / a1a0227** at `/Applications/BabbelStream.app`. Build 5 smoke approval remains the broader release gate; the microphone patch has focused grant/deny fixture and native preview evidence.

## Active Work

- Patch release finalization: `docs/runs/active/release-v0.5.1.md`; immutable 0.5.0 source/artifact/install history is archived in `docs/runs/archive/release-v0.5.0.md`.
- Version 0.5.0 was integrated and tagged at a1a0227. The final native check found a missing first-use microphone button; 0.5.1 corrects its state check. The published 0.5.0 tag is retained.
- Implementation runs are closed under the user’s release approval:
  - `docs/runs/archive/clipboard-only-insertion.md`
  - `docs/runs/archive/pilot-readiness.md`
  - `docs/runs/archive/onboarding.md`
- Their feature contracts remain under `docs/features/`; implementation evidence is historical and outstanding follow-ups are listed below.

## Known Limitations And Deferred Follow-Ups

- the maintainer explicitly deferred macOS 27.0.1 comparison to the other Mac. Local 26.7.1 fixture evidence exists at both documented sizes in light/dark appearance. Full OS Increase Contrast and the expanded permission/editor/language/gesture/recovery/provider matrices are not claimed complete.
- Company-approved connection profile, model aliases, per-user key issuance and support/revocation ownership remain required before colleague deployment. No company destination is guessed or bundled master key supplied.
- Ad-hoc rebuilds may require Accessibility reapproval; onboarding reports the actual running process’s trust. Stable Developer ID signing/notarization and signed update delivery are separate future work.
- Project commands select installed SDK 26.5 because the CLT default SDK 27 lacks required SwiftUI macros. Full application/executable fixture checks work; preexisting compiler capture/framework-search warnings remain. This CLT environment does not expose runnable XCTest/Swift Testing.
- The global shortcut is fixed. Local transcription and automatic updates remain deferred.
- Provider lifecycle milestones remain in `docs/provider-lifecycle.md`.

## Candidate Work

Unapproved work and deferred validation/distribution dependencies live in
`docs/implementation-plan.md`. Release approval does not authorize new providers,
permissions, costs, signing-material access or updater network traffic.

## Next Action

Finalize the verified 0.5.1 patch, then package/install the exact tagged local release.
