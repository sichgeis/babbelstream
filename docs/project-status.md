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
- Optimized ad-hoc artifact (internal candidate verification mode), now published as an explicitly approved non-notarized own-tap pilot. Developer ID/notarization and in-app automatic updates remain deferred.

## Active Work

Approved non-notarized Homebrew colleague pilot on `codex/homebrew-distribution`.
Contract: `docs/features/homebrew-distribution/spec.md`; current staging/evidence:
`docs/runs/active/homebrew-distribution.md`. The existing v0.5.1 app is reused;
no source/version/tag change. The other Mac now has the downloaded candidate
installed through Homebrew with its prior manual app backed up. the maintainer authorized
publication, tap activation and installation on this Mac. Release v0.5.1 is public,
anonymous asset checksums match, and the reviewed cask is on tap main. The exact
public install command passed after the existing manual app was moved aside.
The bundle later disappeared while Brew still recorded it installed (cause
unknown); brew reinstall restored it. the maintainer confirmed launch and dictation
without a Keychain prompt afterward. A further restart of the Homebrew copy is
not separately evidenced. the maintainer reported
successful earlier downloaded-app launch,
onboarding, tap/hold dictation and restart after a targeted Keychain repair;
evidence and the initial failure are in the tracker. First real upgrade evidence
needs a later release; uninstall retention and rollback remain separately untested.

## Known Limitations And Deferred Follow-Ups

- At final local installation, microphone was Not requested and Accessibility Not allowed under the ad-hoc identity. Subsequent user grants have not been re-queried in this distribution-only task. Onboarding supports explicit repair; no TCC reset/grant is automated.
- the maintainer approved the successful build 5 smoke test and explicitly authorized finalization on 2026-10-23, deferring macOS 27.0.1 comparison to the other Mac. Local 26.7.1 fixture evidence exists at both documented sizes in light/dark appearance. The 0.5.1 patch has focused grant/deny and native button/refresh evidence. Full OS Increase Contrast and expanded native/accessibility/provider matrices are not claimed complete.
- Company-approved connection profile, model aliases, per-user key issuance and support/revocation ownership remain required before colleague deployment. No company destination is guessed or bundled master key supplied.
- Ad-hoc rebuilds may require permission reapproval; onboarding reports actual running-process trust. Stable Developer ID signing/notarization and signed updates remain future work.
- On macOS 27.0.1, upgrading manual 0.4.5 to ad-hoc 0.5.1 caused a Keychain password prompt after every restart despite Always Allow. Adding the installed Applications copy to the saved item's restricted Access Control list resolved the user retest. See README Troubleshooting; root cause and future upgrade trust remain unproven. This does not complete the separate visual layout matrix.
- Project commands select installed SDK 26.5 because the CLT default SDK 27 lacks required SwiftUI macros. Full app/executable checks work; preexisting capture/framework-search warnings remain. This CLT environment does not expose runnable XCTest/Swift Testing.
- The global shortcut is fixed. Local transcription and automatic updates remain deferred. Provider lifecycle milestones remain in `docs/provider-lifecycle.md`.

## Candidate Work

Unapproved work and deferred validation/distribution dependencies live in
`docs/implementation-plan.md`. Local release approval does not authorize new
providers, permissions, costs, signing-material access or updater traffic.

## Next Action

Review integration of the completed pilot channel documentation from codex/homebrew-distribution into main; future-version upgrade and lifecycle validation remain deferred.
