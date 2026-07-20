# Maintenance v0.4.1 Specification

## Status

- State: Approved
- Owner: Christian
- Last approved: 2026-07-20 conversation
- Related ADRs/issues: none

## Problem

BabbelStream is a successful daily-use tool, but its coordinator and executable
check suite have accumulated maintenance pressure. A rare Mini transcription
fallback is presented as generic processing, launch-at-login uses a handwritten
LaunchAgent despite the macOS 13 deployment target, and the menu gives static
diagnostic information the same prominence as everyday actions.

## Desired Outcome

Keep the existing dictation workflow behaviorally stable while making rare
processing states truthful, platform integration more durable, core control flow
easier to maintain, and the everyday menu calmer.

## Research And Alternatives

| Option | Benefits | Costs/Risks | Decision |
| --- | --- | --- | --- |
| Maintenance only | Lowest user-visible risk | Leaves the busy daily menu unchanged | Rejected |
| Maintenance plus calmer menu/readiness | Improves daily scanning without adding a workflow step | Some details move one level deeper | Accepted |
| Preview/editor workflow | More control over long drafts | Adds friction and a new state machine | Deferred |

## Accepted Scope

- Keep the project dependency-free and document the dependency/toolchain audit.
- Present the Mini transcription fallback truthfully in the HUD.
- Replace the custom user LaunchAgent with `SMAppService.mainApp` and safely
  migrate an enabled legacy LaunchAgent.
- Apply a targeted GM refactor to shared audio-to-draft preparation and the
  executable behavior-check runner while preserving visible orchestration.
- Keep only live status, actionable errors, primary dictation controls, cleanup,
  and draft recovery prominent in the main menu.
- Keep **Copy Last Draft** directly in the main menu whenever a draft exists.
- Add a compact readiness summary to General Settings.
- Update durable documentation, behavior checks, and release-candidate evidence.

## Non-Goals

- No CI pipeline.
- No third-party dependency, provider, permission, telemetry, or retention change.
- No configurable hotkey, local transcription backend, preview/editor, or
  correction-workflow redesign.
- No macOS deployment-target increase.
- No automatic message sending.
- No merge to `main`, final tag, public release, or `/Applications` installation
  before Christian completes the real microphone/provider/Slack smoke test.

## User Workflow

1. The user focuses Slack or another text field and dictates with the existing
   hybrid shortcut.
2. The HUD shows the actual recording or processing phase, including Mini when
   the fallback is active.
3. The resulting draft is inserted or copied exactly as before and is never sent.
4. The menu keeps everyday actions concise, including Copy Last Draft, while
   detailed static information remains available under Diagnostics or Settings.

## Interaction And State Contract

| State | Event | Next state | Visible result | Side effects |
| --- | --- | --- | --- | --- |
| Transcribing | Mini hedge starts | Mini transcribing | HUD says `Trying Mini` | Existing bounded second provider request |
| Idle | Menu opens | Idle | Concise readiness/status and daily actions | None |
| Draft available | Menu opens | Idle | `Copy Last Draft` remains directly available | None until selected |
| Launch at login off | User enables toggle | Registered or approval required | Truthful system status/instruction | Register main app with macOS |

## Domain Rules And Invariants

- The main dictation orchestration remains readable from recording stop through
  safeguard, transcription, cleanup, insertion, archive, and audio ownership.
- Recovery retry continues to copy rather than paste into a historical target.
- No refactor may weaken provider transparency, cancellation, target validation,
  recovery ownership, audio deletion, or no-auto-send behavior.
- The main menu must retain Copy Last Draft as a first-level action.

## Edge Cases And Races

- Mini presentation must remain correct through retry, cancellation, and winner
  selection without changing hedge timing.
- Legacy launch-at-login state must not be deleted unless system registration
  succeeds or the user explicitly disables it.
- A system login item awaiting user approval must not be shown as fully enabled.
- A missing latest draft keeps Copy Last Draft disabled or absent as today.

## Data, Privacy, Security, And Permissions

- Data read/sent/stored: unchanged.
- Retention/deletion: unchanged.
- Providers/destinations/cost: unchanged; the existing Mini hedge remains the
  only possible second transcription request.
- Permissions: unchanged. `SMAppService` may require visible approval in macOS
  Login Items but introduces no new privacy permission.
- Logging/diagnostics: no transcript, draft, audio path, API key, provider body,
  archive content, or clipboard content may be added.

## Architecture Impact

- `AppState` retains main-actor coordination and gains focused domain helpers
  only where they remove real shared detail.
- HUD presentation becomes deterministic policy covered by behavior checks.
- Launch-at-login delegates registration and status to ServiceManagement.
- `BabbelStreamChecks` is split by concern while retaining one executable runner.
- Dependencies: none.
- Migration/compatibility: macOS 13 remains the minimum; an enabled legacy
  LaunchAgent is migrated only after successful system registration.

## Error And Recovery Behavior

| Failure | User-visible state | Data ownership | Recovery |
| --- | --- | --- | --- |
| Login-item registration denied | Approval required or explanatory error | Legacy state retained | Open Login Items or retry toggle |
| Legacy cleanup fails after registration | Warning | System registration remains authoritative | Manual legacy cleanup guidance |
| Provider or cleanup failure | Existing recording-saved/copy behavior | Existing recovery rules | Existing retry flow |

## Acceptance Criteria

- `Trying Mini transcription` maps to a concise visible Mini HUD state.
- Normal, retry, cancellation, insertion, archive, and recovery checks pass.
- Launch at login uses `SMAppService` and reports its real status.
- An enabled legacy LaunchAgent is migrated without losing launch-at-login intent.
- The main menu is shorter and keeps Copy Last Draft directly accessible.
- General Settings shows actionable readiness for microphone, Accessibility,
  API key, provider configuration, and hotkey registration.
- No external package dependency or deployment-target bump is introduced.

## Automated Validation

- Deterministic HUD presentation checks.
- Launch-at-login state/migration checks through a fake system-service adapter.
- Existing provider, archive, recovery, privacy, hotkey, and settings checks.
- Canonical command: `task check`.
- Clean build and release-candidate packaging.

## Manual Smoke Test

1. Open the menu and confirm primary actions and Copy Last Draft remain easy to
   find while static build/usage details live under Diagnostics or Settings.
2. Open General Settings and confirm readiness matches current permissions,
   API-key presence, provider configuration, and hotkey state.
3. Toggle launch at login off and on, confirm System Settings reflects the
   choice, then restore the preferred state.
4. Dictate with tap and hold into Slack or TextEdit and confirm insertion without
   sending.
5. Trigger or inspect the Mini fallback path and confirm the HUD names it.

## Approval Gate

- Product decision approved by: Christian, 2026-07-20.
- Agent autonomy envelope: implementation, checks, coherent commits and pushes,
  and release-candidate packaging on `codex/maintenance-v0.4.1`.
- Must stop before: `/Applications` installation, `main`, final tag, or release.

## Open Questions

- None.
