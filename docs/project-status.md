# Project Status

This file is the concise current-work entry point. Durable product behavior,
architecture, privacy rules, test coverage, and release procedures remain owned
by their dedicated specifications.

## Current Release

- Latest release: `0.4.4` (`v0.4.4`)
- Supported workflow: hybrid tap-for-hands-free and hold-for-push-to-talk
  dictation into Slack and other focused macOS text fields.
- Canonical validation: `task check`.
- Release posture: local signed builds are supported; public distribution still
  requires Developer ID signing, notarization, and publication automation.

## Active Work

- Recovery and delivery reliability passed Christian's real-workflow smoke test on 2026-09-05.
- Final 0.4.4 packaging/installation is in progress from the final release commit.
- Spec: `docs/features/recovery-delivery-reliability/spec.md`.
- Tracker: `docs/runs/active/recovery-delivery-reliability.md`.
- New investigation: Signal composer insertion; installed Signal 8.26.0 has bundle id `org.whispersystems.signal-desktop` and a bundled Quill editor. Its current direct-first route may report an AX write without updating editor state.
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
- The executable suite now covers AppState recovery, cancellation, delivery,
  and settings-snapshot workflows through fakes. Native AppKit/Accessibility,
  microphone, Keychain, Carbon, and process termination remain manual checks.
- The global shortcut remains fixed at `Control + Option + Space`.
- Local Whisper, Developer ID signing, notarization, and an update mechanism are
  not implemented.

## Candidate Work

Unapproved candidates are listed in `docs/implementation-plan.md`. A candidate
does not become active until its feature contract and approval envelope are
recorded.

## Next Action

Complete final 0.4.4 release verification and confirm whether explicit clipboard paste works in Signal.
