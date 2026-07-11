# Dictation Recovery And Hedged Transcription Release

## Outcome

Ship BabbelStream 0.3.0 so a stopped dictation is not discarded when transcription or cleanup fails, and rare provider stalls recover through a bounded hedged Mini request without enlarging or adding controls to the compact HUD.

## Accepted Scope

- Safeguard stopped audio in a local Recovery store before provider processing.
- Delete safeguarded audio only after transcription and any enabled cleanup succeed.
- Preserve audio after transcription failure, cleanup fallback, processing cancellation, or interruption.
- Add a menu-accessible Recovery Center with retry, Save Audio As, delete, and delete-all actions.
- Recovery retries use current saved settings, copy the result instead of auto-pasting, and delete the item only after success and clipboard copy.
- Start Mini after a 10-second hedge delay, accept the first valid transcription, and enforce one 75-second transcription deadline.
- Keep the HUD at its current size and interaction model; show only a concise failure/saved status.
- Update diagnostics, checks, privacy/product documentation, version, changelog, packaging, and release metadata.

## Non-goals

- No interactive recovery buttons or layout growth in the HUD.
- No LiteLLM work-environment access, cloud sync, transcript history, local Whisper, playback/editor, automatic retention expiry, silent eviction, telemetry, or new dependency.
- No Developer ID/notarized public binary release.

## Acceptance Criteria

- Normal successful processing leaves no recovery audio.
- Transcription failure, cleanup failure, processing cancellation, and interrupted processing leave a visible recovery item.
- Recording cancellation continues to discard the partial recording.
- Recovery retry copies the final draft and deletes the item; failed retry or clipboard copy retains it.
- Primary success before ten seconds does not start Mini; slow primary starts Mini; first valid result wins; total transcription time is bounded to 75 seconds.
- Recovery files use user-only permissions, diagnostics contain no audio/text/path content, and deletion is explicit or success-driven.
- The HUD stays 220×44 with its existing layout and shows a concise error/saved state only.
- Behavior checks, build, packaging, signature/DMG verification, and installed-app smoke checks pass.
- `main` and annotated tag `v0.3.0` are pushed.

## Baseline

- Branch: `codex/dictation-recovery-v030`
- Commit: `1bf66e0`
- Baseline branch pushed to `origin`.
- Existing provider-benchmark files remain local and excluded from implementation commits after safe publishing was denied for the audio fixture.

## Stages

1. **Completed — Specifications and recovery storage foundation**
2. **In progress — Recovery lifecycle and hedged transcription**
3. **Pending — Recovery Center and minimal HUD status**
4. **Pending — Full validation and v0.3.0 release**

## Dependencies And Risks

- Durable audio changes the default privacy lifecycle and must remain visible and user-controlled.
- Recovery promotion and metadata updates must survive partial failures without silently deleting the source audio.
- Hedging may submit the same audio to two models and may incur two charges during rare slow requests.
- Recovery retries must never paste into a stale historical target.
- Local benchmark work keeps the primary workspace dirty; release packaging must use a clean temporary worktree.

## Decisions

- Recovery audio uses ordinary M4A files with `0700` directories and `0600` files; no custom encrypted container is introduced in this release.
- No automatic retention or quota eviction; successful retry deletes automatically and explicit deletion requires confirmation.
- Cleanup fallback still delivers raw text but preserves the audio for a later full retry.
- Processing cancellation preserves stopped audio; cancellation while actively recording discards the partial recording.
- The HUD remains a passive compact indicator. Recovery actions belong in the menu and Recovery Center.

## Validation Evidence

- v0.2.5 baseline behavior checks passed before this upgrade.
- Stage 1 `task check`: recovery adoption, user-only permissions, startup interruption recovery, retry counting, export retention, deletion, app build, and existing behavior checks passed.

## Current Blocker

None.

## Next Action

Integrate recovery ownership and bounded hedged transcription into the coordinator.
