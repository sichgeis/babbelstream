# Project Status

This file owns current release/work state. Durable behavior, privacy, architecture,
validation and release procedure remain in their dedicated specifications.

## Current Release

- Latest release: **0.5.3**, bundle build **11**, annotated tag **v0.5.3**, published on 2026-10-24 and pinned by the re-enabled Homebrew tap.
- App-source commit: `b9c0641f14598abe7388c496a78074b60cb168bf` on main.
- Canonical DMG: `dist/BabbelStream-0.5.3.dmg`; SHA-256 `41b8aed841824c66862b65a11c576364300e3cbd07760370e81f76b77a6a99a2`. The portable checksum and anonymous download match the same fully scanned bytes.
- Privacy evidence: source/history scans and complete mounted-payload/attribute scans find zero known private matches. Debug maps are stripped before signing; Finder metadata uses a neutral backing-image path.
- Release/cask evidence: `docs/runs/archive/release-v0.5.3.md`. This is the explicitly approved optimized ad-hoc, non-notarized pilot. Developer ID/notarization remains a separate channel.
- Older 0.5.1/0.5.2 installers and checksum assets remain withdrawn; their sanitized notes/tags remain historical. Local copies and backup mirrors are unchanged.
- No app installation or upgrade was performed for this release. Last reported installed copy remains the previously verified 0.5.1; no new native workflow validation is claimed here.
- Supported workflow remains tap/hold Control + Option + Space into Slack and other focused macOS text fields; no auto-send. Saved routing choices persist; direct pre-routing LiteLLM upgrades require one explicit routing selection.
- Canonical `task check`, full-payload privacy/signature/integrity checks, independent public-download verification and Homebrew recipe style/strict audit pass.

## Active Work

Local transcription is approved and implemented on `codex/local-transcription`
for a 0.6.0/build 12 Parakeet pilot candidate. Contract:
`docs/features/local-transcription/spec.md`; evidence:
`docs/runs/active/local-transcription.md`. The pinned native helper and network-
denied synthetic English/German inference pass. Qwen/Granite builds are explicitly
deferred because Metal build tooling is absent; their downloads stay disabled.
The maintainer explicitly requested local installation: the verified candidate
is installed and running from Applications. On 2026-10-28 the maintainer reported
successful English and German smoke tests. The wider editor/recovery matrix,
main integration and release publication remain pending. The clean 0.6.0/build 12 candidate is ready at
`dist/BabbelStream-0.6.0-candidate.12-eb6720b.dmg`, source `eb6720b`.
App/helper signatures, DMG checksum/integrity, complete payload privacy and exact
packaged-helper synthetic English/German tests pass. The run tracker records
its checksum and the maintainer-reported language acceptance; no additional
manual matrix result is inferred.


Optional generic installer provider configuration is implemented directly
on main by explicit maintainer request; canonical checks and 25 helper fixtures pass. Contract:
`docs/features/installer-provider-configuration/spec.md`; execution evidence:
`docs/runs/active/installer-provider-configuration.md`. One consent covers the
displayed non-secret profile and installation; API keys remain an app/Keychain
step. Organization-specific values are excluded from this public repository.

The approved optional manual download/install/update helper is implemented and
integrated on main. Contract: `docs/features/manual-install-helper/spec.md`;
tracker: `docs/runs/active/manual-install-helper.md`. It reuses 0.5.3 unchanged,
requires exact consent before removing quarantine from a verified staged app,
and opens the illustrated installer for manual Finder installation. The maintainer
explicitly authorized main integration before the remaining visual/managed-Mac
pilot. Managed-device installation and launch remain unproven.
Earlier scrub/release work remains closed in its archived runs.

## Known Limitations And Deferred Follow-Ups

- Real old-to-new upgrade, permission/Keychain behavior and expanded microphone/provider/editor coverage for 0.5.3 remain follow-up validation. The maintainer explicitly requested release without a new smoke result; no pass was fabricated.


- At initial local installation, microphone was Not requested and Accessibility Not allowed. After the explicitly authorized targeted repair on 2026-10-23, native setup reports both Allowed and Codex insertion works. Ad-hoc future builds may require reapproval; no global TCC reset was used.
- The maintainer approved the successful build 5 smoke test and explicitly authorized finalization on 2026-10-23, deferring macOS 27.0.1 comparison to the other Mac. Local 26.7.1 fixture evidence exists at both documented sizes in light/dark appearance. The 0.5.1 patch has focused grant/deny and native button/refresh evidence. Full OS Increase Contrast and expanded native/accessibility/provider matrices are not claimed complete.
- Company-approved connection profile, model aliases, per-user key issuance and support/revocation ownership remain required before colleague deployment. No company destination is guessed or bundled master key supplied.
- Ad-hoc rebuilds may require permission reapproval; onboarding reports actual running-process trust. Stable Developer ID signing/notarization and signed updates remain future work.
- On macOS 27.0.1, upgrading manual 0.4.5 to ad-hoc 0.5.1 caused a Keychain password prompt after every restart despite Always Allow. Adding the installed Applications copy to the saved item's restricted Access Control list resolved the user retest. See README Troubleshooting; root cause and future upgrade trust remain unproven. This does not complete the separate visual layout matrix.
- Project commands select installed SDK 26.5 because the CLT default SDK 27 lacks required SwiftUI macros. Full app/executable checks work; preexisting capture/framework-search warnings remain. This CLT environment does not expose runnable XCTest/Swift Testing.
- The global shortcut is fixed. Local Parakeet transcription is in candidate validation; other local backends and automatic updates remain deferred. Provider lifecycle milestones remain in `docs/provider-lifecycle.md`.

## Candidate Work

Unapproved work and deferred validation/distribution dependencies live in
`docs/implementation-plan.md`. Local release approval does not authorize new
providers, permissions, costs, signing-material access or updater traffic.

## Next Action

Obtain maintainer direction for main/tag/public release finalization after the
reported English/German smoke acceptance; retain the unverified wider matrix.
