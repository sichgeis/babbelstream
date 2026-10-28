# Project Status

This file owns current release/work state. Durable behavior, privacy, architecture,
validation and release procedure remain in their dedicated specifications.

## Current Release

- Local release: **0.6.0**, bundle build **14**, annotated tag **v0.6.0**, finalized on 2026-10-28 after accepted fully local Parakeet/Qwen smoke.
- Exact app/tag source: `c36c28cba3ab968a3fca6ce6dfb250e1a7f5dc1f` on main. Later evidence-only commits do not move the tag or change the installer.
- Final canonical installer: `dist/BabbelStream-0.6.0.dmg` with portable `.dmg.sha256`, 7,403,398 bytes. SHA-256: `5ca750a4d1317b227a0c3eb6972803eaffbf049fcfcb77317ec899f06d1cd763`.
- Installed and running from Applications: 0.6.0/build 14/c36c28c, exact mounted-payload bytes verified. Previous build 13 retained in ignored `dist/rollback/`.
- Canonical checks, source/history and all 13 mounted payload file/attribute privacy scans, app/helper/DMG signatures, image integrity and portable checksum pass. Exact signed helper synthetic English/German speech and six cleanup/dictionary samples pass under network denial. Polished Finder layout visually inspected; image detached.
- Both local models remain Prepared. Mode flags matched before/after installation; a subsequently applied remote selection was observed during interactive verification and left intact. No provider or mode change was made by release installation.
- The new ad-hoc rebuild reports microphone Not requested and Accessibility Not allowed. Human reapproval remains necessary for real recording/automatic paste; no reset or grant was performed.
- Release evidence: `docs/runs/archive/release-v0.6.0.md`. This remains the explicitly approved ad-hoc, non-notarized pilot; internal build-mode metadata stays candidate to describe signing class.
- Public GitHub installer release and Homebrew remain **0.5.3/build 11**. Publication of 0.6.0 and tap changes are explicitly withheld until the second-Mac test. No release/assets were created; GitHub tag lookup returned no release. The pushed source tag is intentional.
- Retired 0.5.1/0.5.2 installer assets remain withdrawn; no old release bytes or tags were replaced.

## Active Work

Local Parakeet dictation and Qwen3.5-4B cleanup are complete in 0.6.0.
Implementation evidence is archived in `docs/runs/archive/local-transcription.md`
and `docs/runs/archive/local-cleanup.md`; final local release evidence is in
`docs/runs/archive/release-v0.6.0.md`. Qwen-ASR and Granite native builds remain
deferred. Second-Mac installer/dictation validation gates public publication and
Homebrew advancement; expanded editor, long-form memory and OS matrices remain
explicitly unclaimed.

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
- The global shortcut is fixed. Local Parakeet transcription is released locally in 0.6.0; other local backends and automatic updates remain deferred. Provider lifecycle milestones remain in `docs/provider-lifecycle.md`.

## Candidate Work

Unapproved work and deferred validation/distribution dependencies live in
`docs/implementation-plan.md`. Local release approval does not authorize new
providers, permissions, costs, signing-material access or updater traffic.

## Next Action

Test the exact 0.6.0 DMG on the second Mac before authorizing public installer publication and the Homebrew update.
