# Launch-At-Login Migration Recovery Specification

## Status

- State: Approved
- Owner: Christian
- Last approved: 2026-07-28 conversation
- Related ADRs/issues: none

## Problem

An older BabbelStream installation may retain its legacy user LaunchAgent.
During migration, macOS can initially report `SMAppService.mainApp` as
`.notFound`. BabbelStream currently treats that status as a terminal failure
without calling `register()`, so the legacy item remains and every launch shows
a migration warning.

## Desired Outcome

BabbelStream attempts the supported main-app registration and removes the
legacy LaunchAgent only after macOS confirms that registration is enabled.

## Research And Alternatives

| Option | Benefits | Costs/Risks | Decision |
| --- | --- | --- | --- |
| Delete the legacy item | Removes the warning immediately | Silently loses the user's launch-at-login intent | Rejected |
| Treat `.notFound` as terminal | Avoids a call expected to fail | Prevents registration from recovering stale system state | Rejected |
| Attempt registration and inspect the result | Uses the authoritative ServiceManagement operation and preserves the existing safety gate | May still require approval or report a real registration failure | Accepted |

## Accepted Scope

- Attempt `SMAppService.mainApp.register()` even when its initial status is
  `.notFound`.
- Preserve the legacy LaunchAgent unless the post-registration status is
  `.enabled`.
- Preserve the existing approval-required and failure warnings.
- Add deterministic regression coverage and locally reinstall the candidate.

## Non-Goals

- Changing the launch-at-login UI or user preference.
- Resetting macOS Background Task Management state.
- Deleting a legacy LaunchAgent after failed or unapproved registration.
- Creating a public release or annotated tag.

## User Workflow

1. The user launches an upgraded BabbelStream installation with legacy
   launch-at-login enabled.
2. BabbelStream asks ServiceManagement to register the main application.
3. On confirmed enablement, BabbelStream removes the legacy plist and no longer
   displays the migration warning.
4. If registration fails or requires approval, the legacy plist remains and
   BabbelStream presents the existing actionable state.

## Domain Rules And Invariants

- Existing launch-at-login intent must not be silently lost.
- The legacy plist is removed only after modern registration is confirmed.
- A status snapshot is not a substitute for attempting registration.
- No provider, dictation, transcript, audio, or secret behavior changes.

## Data, Privacy, Security, And Permissions

- Data read: ServiceManagement state and legacy-plist existence.
- Data changed: system login-item registration and, after success, deletion of
  the obsolete legacy plist.
- Providers/destinations/cost: none.
- Permissions: existing macOS Login Items approval behavior only.
- Logging: existing privacy-safe error categories; no private paths.

## Architecture Impact

- Components changed: `LaunchAtLoginService` registration policy and behavior
  checks.
- Interfaces and dependencies: unchanged.
- Migration compatibility: retains the legacy fallback on every unsuccessful
  outcome.

## Error And Recovery Behavior

| Failure | User-visible state | Data ownership | Recovery |
| --- | --- | --- | --- |
| Registration requires approval | Existing approval warning | Legacy plist retained | Approve in System Settings |
| Registration remains unavailable | Existing service-unavailable warning | Legacy plist retained | Retry on a later launch |
| Other registration error | Existing registration-failed warning | Legacy plist retained | Retry after resolving the reported system error |

## Acceptance Criteria

- An initial `.notFound` status does not prevent a registration attempt.
- Successful registration changes the status to enabled and removes the legacy
  plist.
- Approval and registration failures retain the legacy plist.
- `task check` passes.
- The installed app no longer shows the reported migration warning after a
  successful local migration.

## Automated Validation

- Fake an initial `.notFound` status, allow registration to succeed, and assert
  one registration call, enabled state, and legacy removal.
- Retain existing successful and approval-required migration checks.
- Canonical command: `task check`.

## Manual Smoke Test

1. Build and install the candidate while the reported legacy plist exists.
2. Launch `/Applications/BabbelStream.app`.
3. Confirm the migration warning is absent.
4. Confirm launch-at-login status is enabled or, if macOS requires approval,
   that the legacy plist remains and the approval state is shown.

## Approval Gate

- Product decision approved by: Christian, 2026-07-28.
- Agent autonomy envelope: implementation through local candidate installation.
- Must stop before: merging or pushing `main`, creating a tag, or public release.

## Open Questions

- None.
