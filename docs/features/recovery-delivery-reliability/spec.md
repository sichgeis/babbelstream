# Recovery And Delivery Reliability Specification

## Status

- State: Approved
- Owner: Christian
- Last approved: 2026-09-05, explicit implementation request in this conversation.
- Related ADRs/issues: none.

## Problem

Failed audio adoption can leave stopped audio eligible for stale cleanup. Recovery retry can hide a deletion failure. Clipboard replacement during paste preparation can insert unrelated text. Coordinator interactions lack executable regression coverage.

## Desired Outcome

Stopped dictation remains recoverable, retention messages reflect actual deletion outcomes, and automatic paste only uses the clipboard version written by this operation.

## Research And Alternatives

| Option | Benefits | Costs/Risks | Decision |
| --- | --- | --- | --- |
| Focused ownership and delivery fixes with executable workflow checks | Addresses observed failure paths using native APIs | Requires explicit failure states and test boundaries | Accepted |
| Broad coordinator rewrite or new testing dependency | Larger redesign surface | More regression risk without necessary product benefit | Rejected |

## Accepted Scope

- Durable stopped-audio ownership before releasing recorder ownership; rediscovery through Failed Recordings and exclusion from stale cleanup.
- Idempotent adoption, retry/export/delete for unsafeguarded recordings, and truthful deletion outcomes.
- Clipboard change-count validation immediately before paste, with a distinct draft-in-memory outcome.
- Fake-driven coordinator and insertion checks in the executable suite.
- Spec reconciliation and a clean 0.4.4 release candidate.

## Non-Goals

No new providers, permissions, dependencies, telemetry, transcript history, shortcut customization, public distribution, or broad rewrite.

## User Workflow

1. Record and stop using the existing controls.
2. Successful processing delivers an unsent draft and deletes safeguarded audio.
3. Storage or processing failure retains stopped audio in Failed Recordings for Retry and Copy, Save Audio As, or explicit deletion.
4. Clipboard contention skips automatic paste and tells the user to use Copy Last Draft; the newer clipboard is left intact.

## Interaction And State Contract

| State | Event | Next state | Visible result | Side effects |
| --- | --- | --- | --- | --- |
| Recording | Stop ownership cannot be persisted | Stop needs retry | Actionable stop error; retry or cancel remains available | No provider request or silent source deletion |
| Stopped, awaiting safeguard | Adoption fails | Safeguard pending | Failed Recordings entry | Source and ownership survive app cleanup/restart |
| Safeguard pending | Retry | Processing after adoption | Retry with current applied settings | One stable recovery identity |
| Draft copied | Audio deletion fails | Recording retained | Copied, but audio remains | Keep warning and recovery entry |
| Paste preparing | Clipboard changes | Draft available in memory | Use Copy Last Draft | No Cmd+V and no clipboard overwrite |

## Domain Rules And Invariants

- Never press Enter or send a message.
- Never call providers before safeguarding succeeds.
- Mark stopped ownership before the recorder relinquishes the source; if marking fails, retain recorder ownership and allow retry/cancel.
- Stale cleanup deletes disposable partial recordings only, never marked stopped audio.
- Deletion success is reported only after all owned audio copies have been removed.
- Recovery retry snapshots currently applied settings and only copies output.
- Preserve current successful-audio deletion, cancellation, target application, provider, and archive rules.

## Edge Cases And Races

Cover storage failures at marker/copy/metadata/source-removal boundaries, restart after partial adoption, duplicate adoption, malformed recovery metadata, cleanup/copy/deletion failure, cancellation, clipboard replacement, focus switching, and settings edits during an operation.

## Data, Privacy, Security, And Permissions

Ownership metadata contains only a stable identifier, timestamp, and duration; no transcript, credentials, or provider bodies. Owned source files and metadata use user-only permissions and backup exclusion where supported. Existing Failed Recordings retention applies; no silent expiry or migration of unrelated user files. Automated checks use isolated synthetic fixtures only.

## Architecture Impact

Add explicit stopped-audio ownership and deletion results, a distinct insertion outcome, and injectable clipboard/coordinator boundaries. Keep main-actor coordination. No third-party dependencies. Existing recovery JSON remains readable; missing new state metadata is handled conservatively.

## Error And Recovery Behavior

| Failure | User-visible state | Data ownership | Recovery |
| --- | --- | --- | --- |
| Stop marker fails | Stop failed | Recorder retains source | Retry Stop or Cancel |
| Adoption fails | Safeguard pending | Durable stopped source | Retry, export, delete |
| Deletion fails | Audio retained | Recovery store | Explicit deletion retry |
| Clipboard replacement | Use Copy Last Draft | In-memory last draft | Explicit copy, then manual paste |

## Acceptance Criteria

- Stopped audio survives failed adoption, stale cleanup, and restart; partial adoption does not duplicate entries.
- Provider processing is blocked until adoption completes.
- Recovery deletion failures remain visible without claiming deletion succeeded.
- Clipboard replacement posts no paste event, does not overwrite the new clipboard, and preserves Copy Last Draft.
- Executable checks cover the affected workflows with fakes, and task check plus a fresh build pass.

## Automated Validation

Canonical command: `task check`. Add focused storage fault, clipboard/event, and workflow tests. Keep real AVFoundation, Carbon, Accessibility, Keychain, and Slack delivery in manual QA.

## Manual Smoke Test

1. Install the clean candidate and verify version/commit.
2. Dictate a synthetic English, German, and mixed-language phrase into an unsent Slack draft; exercise tap and hold.
3. Check normal insertion and Copy Last Draft, cancellation, and Failed Recordings Retry and Copy.
4. Confirm successful audio removal, honest retained-audio warnings when applicable, and no auto-send.

## Approval Gate

- Christian authorized direct-main implementation, regular commits/pushes, docs, and a 0.4.4 candidate.
- Stop before final release tag until real microphone/provider/Slack smoke approval (or explicit waiver).

## Open Questions

None blocking implementation.
