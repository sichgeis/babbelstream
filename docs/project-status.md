# Project Status

This file is the concise current-work entry point. Durable product behavior,
architecture, privacy rules, test coverage, and release procedures remain owned
by their dedicated specifications.

## Current Release

- Latest release: `0.4.0` (`v0.4.0`)
- Supported workflow: hybrid tap-for-hands-free and hold-for-push-to-talk
  dictation into Slack and other focused macOS text fields.
- Canonical validation: `task check`.
- Release posture: local signed builds are supported; public distribution still
  requires Developer ID signing, notarization, and publication automation.

## Active Work

- Active feature: `docs/features/maintenance-v0.4.1/spec.md`.
- Active run tracker: `docs/runs/active/maintenance-v0.4.1.md`.
- Candidate posture: implementation and clean local package complete; the human
  smoke gate remains before installation, `main`, or `v0.4.1`.
- Completed run evidence is retained under `docs/runs/archive/`.

## Known Limitations

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

Run the `0.4.1` feature smoke test from the packaged candidate before any
installation, `main` update, or final tag.
