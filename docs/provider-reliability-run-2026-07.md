# Provider Reliability Run — July 2026

## Outcome

BabbelStream should recover promptly from a stalled provider connection and make timeout and retry activity understandable while preserving the existing private, cancelable push-to-talk workflow.

## Accepted Scope

- Separate prompt connection recovery from the longer overall provider request allowance.
- Keep transcription retries bounded and cancellation-aware.
- Show useful timeout and retry progress in the non-activating HUD and privacy-safe diagnostics.
- Clarify provider timeout settings and troubleshooting guidance.
- Add deterministic checks for the changed provider behavior.

## Non-Goals

- No provider, model, endpoint, API-key, or real user-data changes.
- No new dependencies, telemetry, transcript/audio logging, Slack API integration, auto-send, or architectural rewrite.
- No release, deployment, default-branch merge, or force-push.

## Acceptance Criteria

- A connection/TLS stall does not leave the HUD apparently idle for the full saved request timeout before recovery begins.
- A retry is visible with its attempt number and remains bounded by the saved retry policy.
- Legitimate transcription processing can still use the configured overall request timeout.
- Cancellation stops the current attempt and prevents further retries.
- Diagnostics contain only timing, attempt, state, destination-label, and error-category metadata; never audio, transcript, request body, API key, or file path.
- Focused provider checks, `task check`, and the app build pass.

## Baseline

- Branch: `codex/babbelstream-upgrade-run`
- Commit: `47e80d4`
- Upstream: `origin/codex/babbelstream-upgrade-run`
- Working tree: clean

## Stages

1. **Completed — Connection recovery policy and checks**
   - Add a short, bounded connection-establishment timeout without reducing the configured overall provider processing timeout.
   - Expose structured attempt lifecycle events from the provider executor.
   - Cover timeout, retry, success, and cancellation behavior deterministically.
2. **Completed — HUD and privacy-safe diagnostics**
   - Surface the current attempt, retry reason, and remaining timeout guidance without logging content.
3. **Completed — Documentation and settings guidance**
   - Document timeout semantics, defaults, recovery behavior, and troubleshooting.
4. **In progress — Final validation and handoff**
   - Run broad checks/build/package validation, review the full diff, and confirm clean pushed state.

## Dependencies And Risks

- Foundation `URLSession` timeout behavior differs between connection establishment and response processing; tests must avoid real network timing.
- Retrying transcription resends the same temporary audio, so retries remain explicitly bounded and visible.
- UI updates must stay on the main actor and must not expose provider payloads.

## Decisions

- Keep the user-configured timeout as the overall request allowance.
- Add a separate conservative connection timeout derived from a documented project default.
- Reuse the existing provider abstraction and lightweight `BabbelStreamChecks` scaffold.

## Validation Evidence

- Stage 1: `task check` passed after adding deterministic URLProtocol checks for HTTP retry events, a zero-byte connection stall followed by successful retry, and cancellation without retry.
- Stage 2: `task check` passed after ordering provider events onto AppState and surfacing attempt, retry reason, connection-recovery bound, and overall timeout in the HUD and redacted diagnostic event trail.
- Stage 3: `task check` passed after clarifying the overall request timeout, fixed connection timeout, maximum attempts, and audio-resend implication in Settings and user/technical/test documentation.

## Current Blocker

- None.

## Next Action

Run full checks, app bundle/DMG packaging, final privacy and concurrency diff review, then close the tracker.
