# Project Status

This file owns current release/work state. Durable behavior, privacy, architecture,
validation and release procedure remain in their dedicated specifications.

## Current Release

- Public release **0.6.1**, build **17**, is tagged at `131ab28bcfabafa080b5af444603dcdd2262aeab`. The polished DMG and its portable checksum are the two uploaded assets. [GitHub release](https://github.com/sichgeis/babbelstream/releases/tag/v0.6.1)
- Homebrew tap main `0f85ca6` and the standalone helper use the same verified DMG. Homebrew style, strict audit and fetch passed. The published helper verified the public checksum, signature and CDHash in read-only mode.
- The published 0.6.1/build 17/`131ab28` payload was verified against the installation at release time.
- The release is an ad-hoc signed, non-notarized Apple Silicon pilot. The maintainer waived microphone-to-editor and focus-switch smoke checks for this release. [Release verification](runs/archive/release-v0.6.1.md)

## Active Work

Direct OpenAI Luna cleanup candidate **0.6.1 build 18** is installed locally and
awaits a live dictation smoke test. It sends reasoning off and leaves sampling
temperature at the provider default. See the [implementation run](runs/active/luna-direct-openai-cleanup.md).

The [dictation reliability update](features/dictation-reliability/spec.md) and
[GPT-6 Luna cleanup](features/luna-cleanup/spec.md) shipped in 0.6.1.

Local Parakeet dictation and Qwen3.5-4B cleanup first shipped in 0.6.0.
Implementation evidence is archived in `docs/runs/archive/local-transcription.md`
and `docs/runs/archive/local-cleanup.md`; final local release evidence is in
`docs/runs/archive/release-v0.6.0.md`. Qwen-ASR and Granite native builds remain
deferred. The second Mac completed its Homebrew upgrade to 0.6.0. Real
dictation, permission and Keychain validation on that Mac, expanded editor
coverage, long-form memory and the OS matrix remain open.

Optional generic installer provider configuration is implemented directly
on main by explicit maintainer request; canonical checks and 25 helper fixtures pass. Contract:
`docs/features/installer-provider-configuration/spec.md`; execution evidence:
`docs/runs/active/installer-provider-configuration.md`. One consent covers the
displayed non-secret profile and installation; API keys remain an app/Keychain
step. Organization-specific values are excluded from this public repository.

The optional [manual helper](features/manual-install-helper/spec.md) selects
the verified public 0.6.1 artifact. It requires exact consent for staging and
opens the illustrated installer for manual Finder installation. The published
bootstrap keeps its existing command. Managed-device installation and launch
remain unproven.
Earlier scrub/release work remains closed in its archived runs.

## Known Limitations And Deferred Follow-Ups

- The Homebrew 0.5.3-to-0.6.0 upgrade passed on the second Mac. The 0.6.1
  Homebrew upgrade, permission and Keychain continuity, and dictation remain
  pilot follow-ups. [Prior upgrade evidence](runs/archive/homebrew-v0.6.0.md)

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

Run a harmless unsent dictation with the installed build 18 candidate and confirm
direct OpenAI cleanup succeeds without HTTP 400.
