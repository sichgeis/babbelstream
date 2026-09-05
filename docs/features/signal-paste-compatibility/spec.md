# Signal Paste Compatibility Specification

## Status

- State: Approved and implemented; 0.4.5 candidate awaits Signal smoke approval.
- Owner: Christian.
- Evidence: 2026-09-05 Signal failure report and explicit confirmation that Copy Last Draft plus manual Cmd+V works.

## Problem And Desired Outcome

Signal dictation does not appear in the composer. The installed Signal 8.26.0 uses bundle id `org.whispersystems.signal-desktop` and ships a Quill editor. BabbelStream currently attempts an AX selected-text write first and treats API success as delivery, without reaching the working clipboard path. This is the likely failure mechanism; no private Signal conversation was inspected or edited by the agent.

## Research And Alternatives

| Option | Benefit | Tradeoff | Decision |
| --- | --- | --- | --- |
| Add the verified Signal id to clipboard-preferred routing | Uses the user-confirmed working editing path | Writes the draft to clipboard | Accepted targeted repair |
| Use clipboard for all applications | Fewer app-specific exceptions | Broadens clipboard exposure and changes native behavior | Deferred |
| Read AX text back or paste again after AX success | Could detect some failures | AX can disagree with editor state; duplicate insertion risk | Rejected |

## Scope And Non-Goals

- Add exactly `org.whispersystems.signal-desktop` to the existing normalized clipboard-preferred policy.
- Use the existing application/cancellation/clipboard ownership guards and recovery behavior.
- Add policy and fake workflow regression checks, update durable specs, and package/install a 0.4.5 candidate.
- No beta/helper ids without evidence, global routing changes, new setting, permission, provider, dependency, retention, or Signal API integration.

## Interaction And Invariants

1. Capture Signal's application identity when dictation starts.
2. After preparing the draft, skip direct AX insertion for that identity.
3. Write the draft to clipboard, await preparation, verify clipboard ownership/cancellation/frontmost application, and post Cmd+V once.
4. Keep the draft available for manual paste. On clipboard replacement, preserve the newer clipboard and offer Copy Last Draft.
5. Never press Enter, send a message, or retry automatically after an ambiguous successful AX write.

## Architecture, Privacy, And Compatibility

One exact application-policy entry; no interface or persisted-settings changes. Existing clipboard exposure is explicit and uses the same path as the manual workaround and other known rich editors. Existing direct-first behavior for native/unknown apps and Slack remains unchanged. The rule applies to Signal's focused input fields, not a stored historical element.

## Acceptance And Automated Checks

- Signal, including case/whitespace normalization, selects clipboard insertion.
- An unrelated similarly named bundle remains direct-first.
- A fake Signal editor reporting successful direct AX insertion is never called; exactly one clipboard write and paste event occur.
- Existing target-switch, clipboard-contention, cancellation, native insertion, and coordinator checks pass under `task check`.

## Manual Smoke Test

With installed 0.4.5 candidate, focus an unsent Signal composer, dictate a harmless short phrase, and confirm it appears once. Keep the draft unsent. Confirm Copy Last Draft/manual paste and one previously working application still behave normally.

## Authority And Release Gate

Christian explicitly approved committing the Signal-only fix and installing a 0.4.5 candidate on 2026-09-05 after the initial automatic approval rejection. Ordinary direct-main commits/pushes, checks, versioning, packaging, and local installation are authorized. A final 0.4.5 tag awaits Signal smoke approval. Do not access private conversation content or send messages to validate the repair.

## Open Questions

None blocking the targeted repair. Other applications need concrete bundle ids or reports before extending the policy.
