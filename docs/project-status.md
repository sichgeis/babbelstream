# Project Status

This file is the concise current-work entry point. Durable product behavior,
architecture, privacy rules, test coverage, and release procedures remain owned
by their dedicated specifications.

## Current Release

- Latest release: `0.4.3` (`v0.4.3`)
- Supported workflow: hybrid tap-for-hands-free and hold-for-push-to-talk
  dictation into Slack and other focused macOS text fields.
- Canonical validation: `task check`.
- Release posture: local signed builds are supported; public distribution still
  requires Developer ID signing, notarization, and publication automation.

## Active Work

- Active feature: Recovery and delivery reliability (approved 2026-09-05).
- Spec: `docs/features/recovery-delivery-reliability/spec.md`.
- Tracker: `docs/runs/active/recovery-delivery-reliability.md`.
- Working directly on `main` with user authorization; target candidate: 0.4.4.
- Latest integrated feature: Web editor paste compatibility.
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
- Normal-cache `task check` and a fresh app build passed on 2026-09-05;
  the previously recorded Swift/SDK fresh-build blocker is no longer observed.
- Coordinator behavior coupled to AppKit, Accessibility, Keychain, microphone
  permission, Carbon event delivery, and application termination remains in the
  manual validation matrix because the current Command Line Tools environment
  does not expose runnable XCTest or Swift Testing through SwiftPM.
- The global shortcut remains fixed at `Control + Option + Space`.
- Local Whisper, Developer ID signing, notarization, and an update mechanism are
  not implemented.

## Candidate Work

Unapproved candidates are listed in `docs/implementation-plan.md`. A candidate
does not become active until its feature contract and approval envelope are
recorded.

## Next Action

Implement the approved recovery ownership and delivery reliability contract.
