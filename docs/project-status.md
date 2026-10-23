# Project Status

This file owns current release/work state. Durable behavior, privacy, architecture,
validation and release procedure remain in their dedicated specifications.

## Current Release

- Latest local release: **0.5.1**, bundle build **7**, annotated tag **v0.5.1**.
- App-source commit: **8f229fefe2ef344bf2e1c1869779f6d6b077b42e**, integrated into main and tagged/pushed. Later evidence-only documentation on main does not change the tagged payload.
- Installed/running: **0.5.1 / build 7 / 8f229fe** at `/Applications/BabbelStream.app`; actual signature, source/version metadata, running process and executable payload match verified.
- Original artifact: `dist/BabbelStream-0.5.1.dmg`; checksum and release/installation evidence: `docs/runs/archive/release-v0.5.1.md`. Additional illustrated installer `dist/BabbelStream-0.5.1-pretty-r2.dmg` is published on the same GitHub release page, with corrected lower spacing/borders. App payload and original/Homebrew/first-pretty artifacts unchanged. Layout evidence: `docs/runs/archive/pretty-dmg-layout.md` and `docs/runs/archive/dmg-bottom-spacing.md`.
- Scope: clipboard paste for every application; provider/credential/parser/instance safeguards; private diagnostics/HUD fixes; guided provider setup; first-run permission onboarding/local paste verification; unified subtle Settings/dialog layout. Version 0.5.1 corrects the first-use microphone request action found during final 0.5.0 verification.
- Supported workflow: tap/hold Control + Option + Space into Slack and other focused macOS text fields; no auto-send.
- Canonical validation: `task check`; full app, behavior/loopback/setup/onboarding/release-tooling checks PASS.
- Optimized ad-hoc artifact (internal candidate verification mode), now published as an explicitly approved non-notarized own-tap pilot. Developer ID/notarization and in-app automatic updates remain deferred.

## Active Work

No active repair implementation. On 2026-10-23, removing and re-adding the exact
Applications copy restored live Accessibility trust. The local sample actually
pasted, and the maintainer confirmed direct dictation insertion into Codex. Repair
procedure: README Troubleshooting; completed evidence:
`docs/runs/archive/accessibility-paste-repair.md`. No app code or release artifact
changed. The underlying reason for the stale OS grant remains unproven.

The Homebrew pilot is closed; public 0.5.1 release/tap and its completed installation
evidence remain in `docs/runs/archive/homebrew-distribution.md`. Genuine upgrade,
uninstall retention and rollback tests remain in `docs/implementation-plan.md`.

## Known Limitations And Deferred Follow-Ups

- At initial local installation, microphone was Not requested and Accessibility Not allowed. After the explicitly authorized targeted repair on 2026-10-23, native setup reports both Allowed and Codex insertion works. Ad-hoc future builds may require reapproval; no global TCC reset was used.
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

At the next genuine app release, validate the Homebrew old-to-new upgrade and its permission/Keychain behavior using the follow-up matrix in docs/implementation-plan.md.
