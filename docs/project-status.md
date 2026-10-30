# Project Status

This file owns current release/work state. Durable behavior, privacy, architecture,
validation and release procedure remain in their dedicated specifications.

## Current Release

- Public release: **0.6.0**, bundle build **14**, annotated tag **v0.6.0**. Exact app/tag source: `c36c28cba3ab968a3fca6ce6dfb250e1a7f5dc1f` on main; the tag is unchanged.
- The maintainer explicitly authorized GitHub publication, tap advancement and installation on the second Mac on 2026-10-29, superseding the earlier public deferral. No new real-microphone/provider smoke is claimed.
- Published installer: `BabbelStream-0.6.0.dmg`, 7,352,802 bytes, SHA-256 `2752d399f5b1575be0a0ed9e5e8bb107a8b6b029584c196653c7a9db66f98ce4`, plus its portable checksum. Both authenticated draft download and anonymous public download match the verified bytes.
- This is the first public 0.6.0 installer, rebuilt from the exact clean tag on the second Mac. The earlier local-only DMG/hash remains historical evidence in `docs/runs/archive/release-v0.6.0.md`; no published bytes were replaced.
- Tap main `1aa5318` advertises the verified public asset. Homebrew 7.0.11 upgraded 0.5.3 to 0.6.0 on arm64/macOS 27.0.1 after normal quit. Applications runs 0.6.0/build 14/c36c28c; all installed file bytes match the verified payload and quarantine remains intact. The old app and conflicted local tap checkout are preserved in ignored pilot backups.
- Full `task check`, source/history/binary and all 13 mounted payload file/attribute hygiene scans, app/helper/DMG signatures, image integrity, portable checksum, Homebrew style and strict cask audit pass. CMake was installed as the existing cleanup helper's build prerequisite.
- Ad-hoc signed, non-notarized pilot; internal candidate metadata describes signing class. No provider settings, credentials, models, permissions or user data were changed by the upgrade. Actual permission/Keychain continuity and dictation remain user checks.
- Publication/upgrade evidence: `docs/runs/archive/homebrew-v0.6.0.md`. Retired 0.5.1/0.5.2 installer assets remain withdrawn.

## Active Work

Local Parakeet dictation and Qwen3.5-4B cleanup are complete in 0.6.0.
Implementation evidence is archived in `docs/runs/archive/local-transcription.md`
and `docs/runs/archive/local-cleanup.md`; final local release evidence is in
`docs/runs/archive/release-v0.6.0.md`. Qwen-ASR and Granite native builds remain
deferred. Public release and the second-Mac Homebrew upgrade are complete;
real dictation/permission/Keychain validation on that Mac, expanded editor,
long-form memory and OS matrices remain explicitly unclaimed.

Optional generic installer provider configuration is implemented directly
on main by explicit maintainer request; canonical checks and 25 helper fixtures pass. Contract:
`docs/features/installer-provider-configuration/spec.md`; execution evidence:
`docs/runs/active/installer-provider-configuration.md`. One consent covers the
displayed non-secret profile and installation; API keys remain an app/Keychain
step. Organization-specific values are excluded from this public repository.

The approved optional manual download/install/update helper is implemented and
integrated on main. Contract: `docs/features/manual-install-helper/spec.md`;
tracker: `docs/runs/active/manual-install-helper.md`. It selects the verified
public 0.6.0/build 14/c36c28c artifact using refreshed pins on main,
requires exact consent before removing quarantine from a verified staged app,
and opens the illustrated installer for manual Finder installation. The maintainer
explicitly authorized main integration before the remaining visual/managed-Mac
pilot. Managed-device installation and launch remain unproven.
Installer alignment is complete: the unchanged shared main bootstrap now verifies
and prepares public 0.6.0, refusing stale pins when a newer public release exists.
The internal guide documents the current version; its command is preserved.
Evidence: `docs/runs/archive/installer-current-release.md`.
Earlier scrub/release work remains closed in its archived runs.

## Known Limitations And Deferred Follow-Ups

- The Homebrew 0.5.3-to-0.6.0 replacement and normal launch pass; actual permission/Keychain behavior and microphone/provider/editor coverage remain follow-up validation. The maintainer explicitly requested release without a new smoke result; no pass was fabricated.


- At initial local installation, microphone was Not requested and Accessibility Not allowed. After the explicitly authorized targeted repair on 2026-10-23, native setup reports both Allowed and Codex insertion works. Ad-hoc future builds may require reapproval; no global TCC reset was used.
- The maintainer approved the successful build 5 smoke test and explicitly authorized finalization on 2026-10-23, deferring macOS 27.0.1 comparison to the other Mac. Local 26.7.1 fixture evidence exists at both documented sizes in light/dark appearance. The 0.5.1 patch has focused grant/deny and native button/refresh evidence. Full OS Increase Contrast and expanded native/accessibility/provider matrices are not claimed complete.
- Company-approved connection profile, model aliases, per-user key issuance and support/revocation ownership remain required before colleague deployment. No company destination is guessed or bundled master key supplied.
- Ad-hoc rebuilds may require permission reapproval; onboarding reports actual running-process trust. Stable Developer ID signing/notarization and signed updates remain future work.
- On macOS 27.0.1, upgrading manual 0.4.5 to ad-hoc 0.5.1 caused a Keychain password prompt after every restart despite Always Allow. Adding the installed Applications copy to the saved item's restricted Access Control list resolved the user retest. See README Troubleshooting; root cause and future upgrade trust remain unproven. This does not complete the separate visual layout matrix.
- Project commands select installed SDK 26.5 because the CLT default SDK 27 lacks required SwiftUI macros. Full app/executable checks work; preexisting capture/framework-search warnings remain. This CLT environment does not expose runnable XCTest/Swift Testing.
- The global shortcut is fixed. Local Parakeet transcription is released in 0.6.0; other local backends and automatic updates remain deferred. Provider lifecycle milestones remain in `docs/provider-lifecycle.md`.

## Candidate Work

Unapproved work and deferred validation/distribution dependencies live in
`docs/implementation-plan.md`. Local release approval does not authorize new
providers, permissions, costs, signing-material access or updater traffic.

## Next Action

Run a harmless unsent dictation on the upgraded Mac and report permission/Keychain prompts and local speech/cleanup behavior.
