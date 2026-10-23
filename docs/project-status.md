# Project Status

This file owns current release/work state. Durable behavior, privacy, architecture,
validation and release procedure remain in their dedicated specifications.

## Current Release

- Latest release: **0.5.2**, bundle build **8**, annotated tag **v0.5.2**, published on GitHub and pinned by the tap cask. It changes only the app icon (blue design) and its `.icns` encoding; app behavior equals 0.5.1.
- App-source commit: **3fb7a736110a540e7f1c1de1e36247e9c0433509** on main. Artifact `dist/BabbelStream-0.5.2.dmg`, SHA-256 `728b702d394a21a7af7ebca8d2385422973d2b3ee22ac1c809448f16523a2c82`; evidence: `docs/runs/archive/release-v0.5.2.md`. 0.5.2 was not installed locally and its other-Mac downloaded/quarantined test is pending.
- Previous release: **0.5.1 / build 7 / 8f229fe**, last verified installed at `/Applications/BabbelStream.app`.
- 0.5.1 original artifact: `dist/BabbelStream-0.5.1.dmg`; checksum and release/installation evidence: `docs/runs/archive/release-v0.5.1.md`. The four additional `pretty`/`pretty-r2` preview assets were removed by explicit user request after 0.5.2 became available. The original canonical pair and tag remain intact. Future releases upload only one polished DMG and checksum, shared with Homebrew. Cleanup evidence: `docs/runs/archive/clean-release-assets.md`. Layout evidence: `docs/runs/archive/pretty-dmg-layout.md` and `docs/runs/archive/dmg-bottom-spacing.md`.
- Scope: clipboard paste for every application; provider/credential/parser/instance safeguards; private diagnostics/HUD fixes; guided provider setup; first-run permission onboarding/local paste verification; unified subtle Settings/dialog layout. Version 0.5.1 corrects the first-use microphone request action found during final 0.5.0 verification.
- Supported workflow: tap/hold Control + Option + Space into Slack and other focused macOS text fields; no auto-send.
- Canonical validation: `task check`; full app, behavior/loopback/setup/onboarding/release-tooling checks PASS.
- Optimized ad-hoc artifact (internal candidate verification mode), now published as an explicitly approved non-notarized own-tap pilot. Developer ID/notarization and in-app automatic updates remain deferred.

## Active Work

The public data scrub is pushed and verified in both repositories. A clean
optimized 0.5.3/build 9 candidate is prepared from `92efa2b`; it is not installed,
published or pinned by the tap. Current run/evidence:
`docs/runs/active/data-scrub.md`; ref mapping: `docs/runs/active/data-scrub-refs.tsv`.
Local checkout/worktree migration and old-object pruning await explicit approval
after automatic approval review rejected that broader local destruction. The
public source and release notes are sanitized; original downloads remain unchanged.

## Known Limitations And Deferred Follow-Ups

- Original 0.5.1/0.5.2 DMGs remain published with pre-scrub compiled strings and original source IDs. Their rewritten tags do not reproduce those bytes. Replacement publication/tap advancement and retiring those assets require smoke-test approval.


- At initial local installation, microphone was Not requested and Accessibility Not allowed. After the explicitly authorized targeted repair on 2026-10-23, native setup reports both Allowed and Codex insertion works. Ad-hoc future builds may require reapproval; no global TCC reset was used.
- The maintainer approved the successful build 5 smoke test and explicitly authorized finalization on 2026-10-23, deferring macOS 27.0.1 comparison to the other Mac. Local 26.7.1 fixture evidence exists at both documented sizes in light/dark appearance. The 0.5.1 patch has focused grant/deny and native button/refresh evidence. Full OS Increase Contrast and expanded native/accessibility/provider matrices are not claimed complete.
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

Resolve the local migration/object-pruning approval recorded in
`docs/runs/active/data-scrub.md` before installing the verified candidate for smoke testing.
