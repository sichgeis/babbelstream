# Implementation Plan

## Current Implementation Note

Milestones 1-4, the fixed-hotkey part of Milestone 5, and local packaging from Milestone 8 have been implemented as one usable MVP slice: local recording, LiteLLM/OpenAI-compatible transcription, optional cleanup, clipboard paste/manual-copy fallback, Keychain API key storage, settings UI, the fixed `Control + Option + Space` hotkey, and a local DMG packaging script. Future work should harden this flow, add tests around providers/settings beyond `BabbelStreamChecks`, and then continue with configurable hotkeys, usage tracking, Developer ID signing, notarization, and GitHub release automation.

## Milestone 0: Repo Setup

- Deliverable: docs, Swift package scaffold, menu-bar shell, core defaults, basic test target.
- Acceptance: `swift test` passes; no recording or API code exists.
- Manual test: open package in Xcode or build with SwiftPM.
- Risks: SwiftPM app-bundle limitations may require an Xcode project later.
- Complexity: S.

## Milestone 1: Local Recording Prototype

- Deliverable: microphone permission flow, AVFoundation recorder, recording indicator, temp-file cleanup, and local `.app` bundle via `scripts/build-app.sh`.
- Acceptance: recording starts/stops locally and files are deleted on success/cancel/failure.
- Manual test: build `dist/BabbelStream.app`, request microphone permission, record short English/German samples, stop/cancel, and inspect that temp files are deleted.
- Risks: permission UX, audio format compatibility with provider.
- Complexity: M.

## Milestone 2: Transcription API Call

- Deliverable: configurable OpenAI-compatible transcription request using URLSession.
- Acceptance: fixture or real endpoint returns transcript text; invalid key and timeout are handled. Implemented in usable MVP slice.
- Manual test: verify LiteLLM/LightON audio compatibility; fall back to direct OpenAI-compatible endpoint if needed.
- Risks: proxy may not support `/v1/audio/transcriptions`.
- Complexity: M.

## Milestone 3: Cleanup Pass

- Deliverable: cleanup provider, Slack-ready prompt, cleanup toggle, raw-transcript fallback.
- Acceptance: cleanup preserves technical terms and language mixture in tests. Implemented in usable MVP slice.
- Manual test: dictate mixed German-English Slack messages.
- Risks: over-polishing, hallucinated facts, latency.
- Complexity: M.

## Milestone 4: Clipboard Paste Into Slack

- Deliverable: paste service with direct Accessibility insertion, clipboard Cmd+V fallback, and manual-copy fallback.
- Acceptance: final draft appears in Slack desktop, Slack browser, and TextEdit. Implemented in usable MVP slice; still needs manual QA in Slack.
- Manual test: composer, thread reply, edit message field, browser Slack.
- Risks: Accessibility permission, clipboard timing, focus changes.
- Complexity: M.

## Milestone 5: Global Hotkey/Menu-Bar UX

- Deliverable: Carbon push-to-talk hotkey wired to recording and processing state.
- Acceptance: press starts recording, release processes, cancel is available. Fixed `Control + Option + Space` is implemented; configurable hotkeys are still future work.
- Manual test: use shortcut from Slack and another app.
- Risks: release detection, shortcut conflicts, layout differences.
- Complexity: M.

## Milestone 6: Settings UI And Keychain

- Deliverable: provider settings, API key storage, model names, cleanup toggle, max duration.
- Acceptance: secrets are stored in Keychain and never in `UserDefaults`.
- Manual test: edit settings, restart app, verify persistence.
- Risks: Keychain error handling, validation UX.
- Complexity: M.

## Milestone 7: Privacy Hardening And Usage Tracking

- Deliverable: local counters, debug mode guardrails, privacy tests, log review.
- Acceptance: no audio/transcript persistence in normal mode; usage estimates are local.
- Manual test: inspect logs and app storage after several dictations.
- Risks: accidental logging or clipboard leakage.
- Complexity: M.

## Milestone 8: Packaging And Notarization

- Deliverable: packaging decision, signing/notarization notes, optional installer. Local DMG packaging is implemented in `scripts/package-dmg.sh`; Developer ID signing and notarization remain future work.
- Acceptance: app can be packaged as a local DMG outside Xcode. Public release requires Developer ID signing and notarization.
- Manual test: build the DMG, install on the user's Mac, and later verify a notarized build on a clean user account.
- Risks: entitlements, hardened runtime, update flow.
- Complexity: L.
