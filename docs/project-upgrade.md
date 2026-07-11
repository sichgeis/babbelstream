# Unified Dialogs Patch Release

## Outcome

Ship BabbelStream 0.2.5 with Teach Correction, Personal Dictionary, and Dictation Archive using the same grouped, scrollable, resizable macOS design language as Settings, without changing dictation, persistence, provider, or privacy behavior.

## Accepted Scope

- Add small reusable SwiftUI primitives for grouped dialog content and persistent action/status footers.
- Apply them to Teach Correction, Personal Dictionary, and Dictation Archive.
- Make the three windows resizable with documented default and minimum sizes.
- Add deterministic window-only launch arguments for visual QA.
- Update release/test documentation, `VERSION`, and `CHANGELOG.md`.
- Run behavior checks, builds, visual QA, DMG/signature verification, publish `main` and `v0.2.5`, then install and launch the local signed build.

## Non-goals

- No dictation, provider, cleanup, dictionary-storage, or archive-storage behavior changes.
- No new dependencies, Slack integration, tabs for single-purpose dialogs, telemetry, or cloud services.
- No Developer ID or notarized public binary; the release artifact is for local installation.

## Acceptance Criteria

- All three dialogs share Settings' grouped sections, spacing, scrolling, footer treatment, status hierarchy, and native button roles.
- Every dialog remains usable at its minimum size and supports resizing.
- Existing actions, keyboard defaults, errors, confirmations, and privacy copy remain functional.
- Deterministic QA launch arguments open each dialog without requiring menu navigation.
- `task check`, release build, visual inspection, DMG verification, code-signature verification, and installed-app smoke checks pass.
- `main` and annotated tag `v0.2.5` are pushed; the installed app reports version 0.2.5 and the release commit.

## Baseline

- Branch: `codex/unified-dialogs-0.2.5`
- Commit: `5c12523`
- Baseline branch pushed to `origin`.
- Existing provider-benchmark work remains untouched in the original workspace.

## Stages

1. **Completed — Shared dialog design and window behavior**
2. **Completed — Deterministic visual QA and release documentation**
3. **In progress — Full validation and release artifact**
4. **Pending — Publish, install, launch, and verify**

## Dependencies And Risks

- SwiftUI layout must remain compatible with macOS 13.
- Footer actions must not obscure long status/error messages.
- Archive recovery rows and dictionary editors must scroll without moving their footers.
- Local signing must continue using `BabbelStream Local Code Signing` so macOS permissions retain a stable identity.

## Decisions

- Use shared layout primitives, but keep each dialog's domain content explicit.
- Keep confirmation for archive deletion and additionally present the action with a destructive role.
- Use a clean temporary Git worktree so unrelated local files cannot enter the release.

## Validation Evidence

- Baseline `task check`: passed on 2026-07-11.
- Stage 1 `task check`: app compiled and all behavior checks passed after the shared scaffold and window updates.
- Stage 2 `task check`: deterministic launch modes, version metadata, and release documentation compiled; all behavior checks passed.

## Current Blocker

None.

## Next Action

Commit the release metadata stage, then build and visually inspect every redesigned window.
