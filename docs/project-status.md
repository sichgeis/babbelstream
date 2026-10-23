# Project Status

This file is the concise current-work entry point. Durable product behavior,
architecture, privacy rules, test coverage, and release procedures remain owned
by their dedicated specifications.

## Current Release

- Latest release: `0.4.5` (`v0.4.5`)
- Supported workflow: hybrid tap-for-hands-free and hold-for-push-to-talk
  dictation into Slack and other focused macOS text fields.
- Canonical validation: `task check`.
- Release posture: local signed builds are supported; public distribution still
  requires Developer ID signing, notarization, and publication automation.

## Active Work

- Onboarding implementation/local preparation delivered on `codex/onboarding`; approved contract `docs/features/onboarding-and-updates/spec.md`, tracker `docs/runs/active/onboarding.md`. First-run/repair permissions, local sample verification and accepted nearly white shared canvas; Sparkle/signing deferred. Final quality review adds focus-loss cancellation and post-test permission refresh; candidate build 5 packaging/local installation is authorized and in progress. Installed build 3 remains until replacement. Human onboarding/paste acceptance pending.

- Pilot readiness implementation/local preparation delivered; full acceptance pending: `docs/features/pilot-readiness/spec.md`, tracker `docs/runs/active/pilot-readiness.md`, branch `codex/pilot-readiness`. Approved autonomous implementation, unreleased; clean local candidate 0.4.5 build 3 / 4e6da0d prepared after native UI corrections; explicitly authorized local installation/launch completed for human smoke on 2026-10-23.
- Preserved dependency: clipboard-only insertion implemented 2026-10-23; unreleased on `codex/clipboard-only-insertion`.
- Contract: `docs/features/clipboard-only-insertion/spec.md`.
- Tracker: `docs/runs/active/clipboard-only-insertion.md`.
- Latest released compatibility feature remains Signal paste compatibility.
- Installed/running local candidate: `0.4.5`, build `3`, commit `4e6da0d` at `/Applications/BabbelStream.app`; version, signature, running executable and payload hash verified. the maintainer confirmed dictation/automatic paste works after Accessibility repair; expanded smoke coverage remains pending. Previous installed bundle `0.4.5` / `a9c5547` preserved under `dist/rollback/`.
- Spec: `docs/features/signal-paste-compatibility/spec.md`.
- Tracker: `docs/runs/archive/signal-paste-compatibility.md`.
- Completed reliability evidence: `docs/runs/archive/recovery-delivery-reliability.md`.
- Latest integrated feature: Signal paste compatibility.
- Completed web-editor compatibility evidence:
  `docs/runs/archive/web-editor-paste-compatibility.md`.
- Previously integrated feature: Personal OpenAI fallback and direct-personal
  mode.
- Completed run evidence:
  `docs/runs/archive/personal-openai-fallback.md`.
- GPT Transcribe implementation evidence, with its remaining real-provider
  matrix retained in the completed fallback evidence, is archived at
  `docs/runs/archive/gpt-transcribe.md`.
- Completed launch-at-login migration recovery evidence:
  `docs/runs/archive/launch-at-login-migration-fix.md`.
- Completed maintenance evidence: `docs/runs/archive/maintenance-v0.4.1.md`.
- Source-release evidence: `docs/runs/archive/release-v0.4.2.md`.
- Completed run evidence is retained under `docs/runs/archive/`.

## Known Limitations

- The work LiteLLM proxy requires its existing `openai/*` namespace while the
  official OpenAI API requires bare model IDs. Provider Settings now persists
  this per-installation routing choice; other proxy namespace conventions still
  require a compatible proxy alias.
- Personal OpenAI automatic fallback plus direct-personal mode and the purple
  HUD are integrated on `main`. The expanded real-provider matrix remains
  pending.
- Full `task check` restored on 2026-10-23 using the installed macOS 26.5 SDK selected by `scripts/swift-project.sh`; the CLT default macOS 27 SDK lacks required SwiftUI macros. Current Settings/setup/metadata and shared dialogs have 26.7.1 fixture-preview evidence at both documented sizes, including light/dark appearance. Full 27.0.1 acceptance remains pending.
- The executable suite now covers AppState recovery, cancellation, delivery,
  and settings-snapshot workflows through fakes. Native AppKit/Accessibility,
  microphone, Keychain, Carbon, and process termination remain manual checks.
- The global shortcut remains fixed at `Control + Option + Space`.
- Local Whisper and automatic updates remain deferred. Developer ID and notarization tooling is prepared but requires authorized identity/profile and actual distribution validation.

## Candidate Work

Unapproved candidates are listed in `docs/implementation-plan.md`. A candidate
does not become active until its feature contract and approval envelope are
recorded.

## Next Action

Package and install the quality-reviewed candidate build 5, then hand off live permission onboarding and local sample receipt validation.
