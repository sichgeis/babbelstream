# [Feature Name] Specification

## Status

- State: Draft | Approved | Implemented | Released
- Owner: [user/product owner]
- Last approved: [date/commit or conversation reference]
- Related ADRs/issues: [links]

## Problem

[What user problem exists, who experiences it, and why solving it matters.]

## Desired Outcome

[One concise description of the successful user-visible result.]

## Research And Alternatives

| Option | Benefits | Costs/Risks | Decision |
| --- | --- | --- | --- |
| [A] | | | |
| [B] | | | |

## Accepted Scope

- [In-scope behavior.]

## Non-Goals

- [Explicitly excluded behavior.]

## User Workflow

1. [User action.]
2. [Visible system behavior.]
3. [Completion/recovery.]

## Interaction And State Contract

| State | Event | Next state | Visible result | Side effects |
| --- | --- | --- | --- | --- |
| | | | | |

## Domain Rules And Invariants

- [Rule that must always hold.]
- [What must never happen.]

## Edge Cases And Races

- [Startup/duplicate/cancellation/concurrency case.]
- [Offline/partial failure/retry case.]

## Data, Privacy, Security, And Permissions

- Data read/sent/stored: [details].
- Retention/deletion: [details].
- Providers/destinations/cost: [details].
- Permissions: [details].
- Logging/diagnostics: [details].

## Architecture Impact

- Components changed: [details].
- New/changed interfaces: [details].
- Dependencies: none | [justification].
- Migration/compatibility: [details].

## Error And Recovery Behavior

| Failure | User-visible state | Data ownership | Recovery |
| --- | --- | --- | --- |
| | | | |

## Acceptance Criteria

- [Observable criterion.]
- [Boundary/negative criterion.]

## Automated Validation

- [Policy/unit/integration check.]
- Canonical command: `[command]`.

## Manual Smoke Test

1. [Smallest safe real-world scenario.]
2. [Expected result.]
3. [Failure/recovery scenario.]

## Approval Gate

- Product decision approved by: [name/date].
- Agent autonomy envelope: [implement only | through candidate | through main/tag/deploy].
- Must stop before: [action or none].

## Open Questions

- [Only questions that materially affect behavior or risk.]
