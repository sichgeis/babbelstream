# Project Status

This file owns current release/work state. Durable behavior, privacy, architecture,
validation and release procedure remain in their dedicated specifications.

## Current Release

- Latest local release: **0.5.1**, bundle build **7**, annotated tag **v0.5.1**.
- App-source commit: **8f229fefe2ef344bf2e1c1869779f6d6b077b42e**, integrated into main and tagged/pushed. Later evidence-only documentation on main does not change the tagged payload.
- Installed/running: **0.5.1 / build 7 / 8f229fe** at `/Applications/BabbelStream.app`; actual signature, source/version metadata, running process and executable payload match verified.
- Artifact: `dist/BabbelStream-0.5.1.dmg`; checksum and release/installation evidence: `docs/runs/archive/release-v0.5.1.md`.
- Scope: clipboard paste for every application; provider/credential/parser/instance safeguards; private diagnostics/HUD fixes; guided provider setup; first-run permission onboarding/local paste verification; unified subtle Settings/dialog layout. Version 0.5.1 corrects the first-use microphone request action found during final 0.5.0 verification.
- Supported workflow: tap/hold Control + Option + Space into Slack and other focused macOS text fields; no auto-send.
- Canonical validation: `task check`; full app, behavior/loopback/setup/onboarding/release-tooling checks PASS.
- Local optimized ad-hoc artifact only (internal candidate verification mode). Developer ID/notarized colleague distribution and automatic updates remain deferred.

## Active Work

No release implementation remains active. The checkout is on main. All three
implementation trackers and the 0.5.0/0.5.1 release runs are archived under
`docs/runs/archive/`. Fully merged task branches were removed locally/remotely;
commits remain reachable from main/release tags. Artifacts, native evidence and
rollback bundles are preserved. The original v0.5.0 tag was not rewritten.

## Known Limitations And Deferred Follow-Ups

- Current final-build permissions: Microphone Not requested; Accessibility Not allowed under the ad-hoc identity. Onboarding is open at the permission step with Allow Microphone and Enable Automatic Paste. The user must consent before recording/automatic paste. No TCC reset or grant was automated.
- the maintainer approved the successful build 5 smoke test and explicitly authorized finalization on 2026-10-23, deferring macOS 27.0.1 comparison to the other Mac. Local 26.7.1 fixture evidence exists at both documented sizes in light/dark appearance. The 0.5.1 patch has focused grant/deny and native button/refresh evidence. Full OS Increase Contrast and expanded native/accessibility/provider matrices are not claimed complete.
- Company-approved connection profile, model aliases, per-user key issuance and support/revocation ownership remain required before colleague deployment. No company destination is guessed or bundled master key supplied.
- Ad-hoc rebuilds may require permission reapproval; onboarding reports actual running-process trust. Stable Developer ID signing/notarization and signed updates remain future work.
- Project commands select installed SDK 26.5 because the CLT default SDK 27 lacks required SwiftUI macros. Full app/executable checks work; preexisting capture/framework-search warnings remain. This CLT environment does not expose runnable XCTest/Swift Testing.
- The global shortcut is fixed. Local transcription and automatic updates remain deferred. Provider lifecycle milestones remain in `docs/provider-lifecycle.md`.

## Candidate Work

Unapproved work and deferred validation/distribution dependencies live in
`docs/implementation-plan.md`. Local release approval does not authorize new
providers, permissions, costs, signing-material access or updater traffic.

## Next Action

the maintainer grants microphone/Accessibility access to the final build through the open onboarding permission page.
