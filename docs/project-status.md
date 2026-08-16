# Project Status

This file is the concise current-work entry point. Durable product behavior,
architecture, privacy rules, test coverage, and release procedures remain owned
by their dedicated specifications.

## Current Release

- Latest release: `0.4.1` (`v0.4.1`)
- Supported workflow: hybrid tap-for-hands-free and hold-for-push-to-talk
  dictation into Slack and other focused macOS text fields.
- Canonical validation: `task check`.
- Release posture: local signed builds are supported; public distribution still
  requires Developer ID signing, notarization, and publication automation.

## Active Work

- Active feature: Personal OpenAI fallback.
- Active feature spec: `docs/features/personal-openai-fallback/spec.md`.
- Active run tracker: `docs/runs/active/personal-openai-fallback.md`.
- GPT Transcribe implementation evidence, with its remaining real-provider
  matrix transferred to the active fallback feature, is archived at
  `docs/runs/archive/gpt-transcribe.md`.
- Completed launch-at-login migration recovery evidence:
  `docs/runs/archive/launch-at-login-migration-fix.md`.
- Completed maintenance evidence: `docs/runs/archive/maintenance-v0.4.1.md`.
- Completed run evidence is retained under `docs/runs/archive/`.

## Known Limitations

- The work LiteLLM proxy requires its existing `openai/*` namespace while the
  official OpenAI API requires bare model IDs. Provider Settings now persists
  this per-installation routing choice; other proxy namespace conventions still
  require a compatible proxy alias.
- Personal OpenAI fallback is implemented, pushed, and installed locally from
  feature commit `06862f0`, but has not yet passed the real LiteLLM-offline/
  personal-account smoke test or been merged to `main`.
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

Run the synthetic real-provider matrix from the active feature spec before
authorizing merge and local installation.
