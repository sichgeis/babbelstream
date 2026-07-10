# Implementation Plan

## Current Implementation Note

Milestones 1-4, the fixed-hotkey part of Milestone 5, Milestone 6, launch-at-login, local personal dictionary, privacy-safe usage counters/diagnostics from Milestone 7, local packaging from Milestone 8, and the opt-in local dictation archive/monthly review feature have been implemented as one usable MVP/V1 slice. The July 2026 reliability pass added a non-activating status HUD, operation-scoped Escape cancellation, bounded transient transcription retry, verified temporary-audio cleanup, immutable per-dictation settings snapshots, explicit Apply semantics with truthful provider destinations, non-destructive Keychain updates, target-safe Accessibility insertion, strict provider success parsing, recoverable JSONL reads, and safer personal-dictionary updates. `BabbelStreamChecks` now covers core/provider/archive policies through the canonical `task check` command. Future work should add full XCTest/Swift Testing coordinator coverage when the development toolchain exposes a runnable test framework, configurable push-to-talk hotkeys, optional deterministic correction if needed, Developer ID signing, notarization, GitHub release automation, and an update flow.

## Implemented V1 Slice: Optional Local Dictation Archive And Monthly Review

- Deliverable: opt-in local archive setting, daily JSONL archive files, completed-dictation archive writes, monthly word-count aggregation, month export, reveal-folder and clear-archive controls.
- Acceptance: archive is off by default; enabling it writes text-only entries under `~/Library/Application Support/BabbelStream/Archive/YYYY-MM/YYYY-MM-DD.jsonl`; audio is never archived; final draft text and word counts are captured; raw transcript text is stored only behind a separate opt-in; monthly review can answer words by day/month and export contents. Implemented.
- Manual test: enable archive, dictate several Slack and TextEdit samples across cleanup-on/off cases, inspect the daily JSONL file, compare word counts, export the month, clear the archive, and verify normal dictation/paste still works if archive writing fails.
- Privacy test: verify no archive files are created when disabled, diagnostics omit archive contents, topic-summary generation never sends archive text to an AI provider without explicit confirmation, and local files contain no audio paths, API keys, provider request bodies, or clipboard-only data.
- Risks: storing confidential work text locally, accidental raw transcript persistence, file corruption during append, confusing "spoken words" versus "final draft words", and unintentional provider sends for summaries.
- Complexity: M.

## Milestone 0: Repo Setup

- Deliverable: docs, Swift package scaffold, menu-bar shell, core defaults, basic test target.
- Acceptance: the package builds and the environment's canonical behavior-check command passes. This CLT setup uses `task check` because it does not expose a runnable XCTest or Swift Testing framework through SwiftPM.
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
- Acceptance: fixture or real endpoint returns transcript text; invalid key and timeout are handled; transient failures retry within a local bound while authentication and other client failures do not. Implemented in usable MVP slice and local URLProtocol checks.
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
- Acceptance: final draft appears in Slack desktop, Slack browser, and TextEdit only while the captured target remains focused; target changes copy with visible recovery instead. Implemented in usable MVP slice; still needs manual QA in Slack.
- Manual test: composer, thread reply, edit message field, browser Slack.
- Risks: Accessibility permission, clipboard timing, focus changes.
- Complexity: M.

## Milestone 5: Global Hotkey/Menu-Bar UX

- Deliverable: Carbon push-to-talk hotkey wired to recording and processing state.
- Acceptance: press starts recording, release processes, and Escape/HUD/menu cancellation is available only during the active operation. Fixed `Control + Option + Space` is implemented; configurable push-to-talk hotkeys are still future work.
- Manual test: use shortcut from Slack and another app.
- Risks: release detection, shortcut conflicts, layout differences.
- Complexity: M.

## Milestone 6: Settings UI And Keychain

- Deliverable: provider settings, API key storage, model names, cleanup toggle, max duration.
- Acceptance: secrets are stored and updated non-destructively in Keychain and never in `UserDefaults`; startup uses a non-secret API-key presence marker and does not read/rewrite the secret before dictation. Edited settings remain inactive until Apply succeeds.
- Manual test: edit settings, restart app, verify persistence and no startup Keychain prompt.
- Risks: Keychain error handling, validation UX.
- Complexity: M.

## Milestone 7: Privacy Hardening And Usage Tracking

- Deliverable: local counters, redacted diagnostics, debug mode guardrails, personal dictionary privacy checks, privacy tests, log review.
- Acceptance: no audio/transcript persistence in normal mode; usage counters are local and diagnostics are redacted.
- Manual test: inspect logs and app storage after several dictations.
- Risks: accidental logging, clipboard leakage, LaunchAgent pointing at an unintended app path after moving the bundle.
- Complexity: M.

## Milestone 8: Packaging, Local Install, And Notarization

- Deliverable: packaging decision, signing/notarization notes, local `.app` bundle, local DMG with an Applications symlink, and a no-`sudo` development install helper that opens the Finder drag-to-Applications flow. Local DMG packaging is implemented in `scripts/package-dmg.sh`; Developer ID signing and notarization remain future work.
- Acceptance: app can be packaged as a local DMG outside Xcode; daily development install opens the DMG and relies on Finder for any `/Applications` authorization prompt. Public release requires Developer ID signing and notarization.
- Manual test: build the DMG, drag `BabbelStream.app` onto the Applications link, launch from `/Applications`, and later verify a notarized build on a clean user account.
- Risks: entitlements, hardened runtime, update flow.
- Complexity: L.
