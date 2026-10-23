# Clipboard-Only Insertion Specification

## Status

- State: Implemented on the feature branch; unreleased, full build and native smoke pending.
- Owner: the maintainer.
- Last approved: 2026-10-23 explicit request to remove direct writes and use clipboard paste exclusively.
- Supersedes application routing in web-editor-paste-compatibility and signal-paste-compatibility.

## Problem And Desired Outcome

Application-specific direct Accessibility writes can report success without updating editor state. Use one predictable delivery path for every application: copy the prepared draft to the clipboard, then post Cmd+V only while the captured application remains frontmost.

## Research And Alternatives

| Option | Benefit | Tradeoff | Decision |
| --- | --- | --- | --- |
| Clipboard-only insertion | One editing path and no application exceptions | Every delivered draft reaches the system clipboard | Accepted |
| Paste default with direct-write allowlist | Avoids clipboard in validated applications | Retains multiple paths and validation burden | Deferred |
| AX first with application exceptions | Avoids some clipboard writes | Silent AX success and growing exception list | Removed |

## Accepted Scope And Non-Goals

Remove direct AX insertion, its environment interface, live result handling, and bundle routing policy. Keep existing clipboard preparation, target, cancellation, ownership guards, permission checks and recovery. Retain the historical archive outcome solely to decode/export older opt-in archives; never produce it for new dictations. No archive migration/deletion, new permission, dependency, provider, retention, focus restoration, clipboard restoration, new event strategy, or auto-send. Direct insertion, including ChatGPT, is future unapproved work.

## User Workflow And Interaction Contract

1. Capture the target application when recording starts.
2. After processing, validate the draft and cancellation. Copy it to clipboard.
3. With Accessibility permission and the original app still frontmost, wait the existing 150 ms, then recheck cancellation, clipboard change count and application.
4. Post Cmd+V once. Report shortcut posted, not editor-confirmed delivery; retain clipboard and Copy Last Draft.

| Condition | Outcome | Recovery |
| --- | --- | --- |
| Permission absent | Copied for manual paste; no event | Manual Cmd+V |
| Target missing or changed | Copied; no focus activation or event | Manual Cmd+V |
| Clipboard replaced during preparation | Preserve newer clipboard; no event | Copy Last Draft |
| Cancellation during preparation | No paste | Existing cancellation/recovery behavior |
| Clipboard write fails | Existing copy-failure handling | In-memory draft remains available |
| Event creation fails | Copied after shortcut failure | Manual Cmd+V |

## Invariants, Races And Privacy

Never write AXSelectedText/AXValue, press Return, submit, steal focus or retry ambiguous delivery. Same-app field changes intentionally select the currently focused field. Unknown/missing bundle ids follow the same clipboard path. A process change blocks posting. macOS provides no atomic clipboard-and-target transaction; existing best-effort guards remain. All insertion uses the system clipboard and may expose drafts to clipboard readers. No clipboard/field text in diagnostics, no new field-content reads, no history by default. Accessibility remains required for synthetic paste; microphone/provider/audio lifecycle remains unchanged.

## Architecture And Compatibility

Keep TextInsertionService and its focused clipboard environment. Remove direct-writing adapter methods, routing policy and insertedDirectly result. Keep legacy archive decoding only. No persisted settings change or dependency.

## Acceptance And Automated Validation

- Native, Slack, Claude, ChatGPT/Codex, browser, mail, Signal, unknown and missing bundle targets all write clipboard once and post once when permitted.
- Target changes, cancellation, clipboard contention, denied permission and event/write failures preserve current recovery with no unintended event or second write.
- Actual coordinator fixtures use pasteShortcutPosted. Old direct-insertion archive entries still decode/export.
- Canonical command: task check. Record build-toolchain blockers honestly; isolated unchanged-source checks are partial evidence only.

## Manual Smoke Test

With a separately authorized candidate, use harmless unsent drafts in Slack channel/thread, Claude Code desktop surface, ChatGPT/Codex, Signal, Chrome/Arc, Mail/Outlook and TextEdit. Check selection replacement, existing text, multiline, repeated chunks, German/English/mixed text, tap/hold/menu stop, app switch, same-app field switch, cancellation, Copy Last Draft and clipboard contention. Characterize held modifiers, alternate layouts/IME and terminal/protected fields without changing their policy. Never submit or use private content as a fixture.

## Approval Gate And Rollback

the maintainer authorizes specification, implementation, fixture checks and feature-branch commits/pushes. Installation, main/tag/release remain gated. Revert this feature commit to restore prior routing; no data migration is required.

## Open Questions

None blocking implementation. Direct insertion requires a future approved contract and live editor-state validation.
