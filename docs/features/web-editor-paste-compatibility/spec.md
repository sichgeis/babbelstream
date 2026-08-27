# Web Editor Paste Compatibility Specification

## Status

- State: Implemented
- Owner: Christian
- Last approved: 2026-08-27 conversation authorization ("Do it")
- Related ADRs/issues: none

## Problem

BabbelStream can report successful direct Accessibility insertion even when a
web-backed editor does not accept the text into its internal editing state. The
failure is visible in ChatGPT/Codex, Chrome page fields, and Arc page fields,
while native email editors continue to work through the existing clipboard and
Command+V fallback. Chrome's native address bar also works, which makes the
failure appear field-specific and silent.

## Desired Outcome

Dictation drafts reliably appear in known web-backed editors by using the same
clipboard plus synthetic Command+V path already used for rich email editors,
while native fields retain direct Accessibility insertion when supported.

## Research And Alternatives

| Option | Benefits | Costs/Risks | Decision |
| --- | --- | --- | --- |
| Trust every successful `AXSelectedText` write | Avoids clipboard use when the Accessibility bridge works | Web editors may return success without updating their application/editor state | Rejected |
| Read back the Accessibility value after a direct write | Could detect some failures | A matching AX value still does not prove that React/contenteditable state accepted the edit | Rejected |
| Prefer clipboard plus Command+V for known web-backed application bundles | Uses the normal user editing path and the already-working fallback | Temporarily replaces clipboard contents as the current fallback already does | Accepted |

## Accepted Scope

- Treat Mail and Outlook as clipboard-preferred, preserving current behavior.
- Treat the installed ChatGPT/Codex app bundle identities as clipboard-preferred.
- Treat Chrome-family and Arc bundle identities as clipboard-preferred.
- Keep the existing application-level frontmost-process guard before and after
  clipboard preparation.
- Keep the draft on the clipboard after posting Command+V for recovery.
- Add pure policy checks for known clipboard-preferred and direct-insertion apps.

## Non-Goals

- No browser extension, DOM integration, JavaScript injection, or Slack API.
- No blanket disabling of direct Accessibility insertion for every application.
- No verification that a target application consumed the posted keyboard event.
- No new Accessibility, Input Monitoring, clipboard, or provider permission.
- No auto-send, Return key event, or editor-specific submission behavior.

## User Workflow

1. The user focuses a ChatGPT/Codex, Chrome-page, or Arc-page editor.
2. The user records and stops dictation with the existing hybrid shortcut.
3. BabbelStream verifies that the original application remains frontmost, writes
   the draft to the clipboard, and posts Command+V.
4. The editor receives the draft through its normal paste path; BabbelStream
   retains the clipboard copy and never submits the text.

## Interaction And State Contract

| State | Event | Next state | Visible result | Side effects |
| --- | --- | --- | --- | --- |
| Pasting | Known clipboard-preferred target remains frontmost | Ready | Paste shortcut sent; draft remains recoverable | Clipboard updated and Command+V posted |
| Pasting | Native target supports selected-text insertion | Ready | Draft inserted | Direct Accessibility selected-text write |
| Pasting | Original application changed | Copied | Manual-paste guidance | Clipboard updated; no key event posted |
| Pasting | Accessibility not allowed | Copied | Permission/manual-paste guidance | Clipboard updated; no key event posted |

## Domain Rules And Invariants

- The captured application must remain frontmost before any automatic insertion.
- BabbelStream never presses Return or sends a message.
- A successful Accessibility API return is not treated as sufficient for known
  web-backed editor applications.
- Clipboard-preferred routing is a pure policy based on a normalized bundle id.
- Unknown and native application bundle ids retain the existing direct-first
  behavior.

## Edge Cases And Races

- Chrome channel bundle suffixes use the Chrome-family policy rather than an
  exact stable-channel-only match.
- A missing bundle id retains direct-first behavior and still uses the existing
  fallback when direct insertion is unsupported.
- Focus changes between clipboard write and key posting are caught by the
  existing repeated application-level guard.
- Cancellation continues to stop before a late paste.

## Data, Privacy, Security, And Permissions

- Data read/sent/stored: no new data; the final draft uses the existing clipboard
  fallback and is not sent to a new destination.
- Retention/deletion: unchanged.
- Providers/destinations/cost: unchanged.
- Permissions: existing Accessibility permission only.
- Logging/diagnostics: existing privacy-safe insertion outcome categories only;
  no draft or clipboard contents.

## Architecture Impact

- Components changed: `TextInsertionStrategyPolicy` and
  `ClipboardTextInsertionService` in `BabbelStreamCore`.
- New/changed interfaces: one pure public policy for behavior checks.
- Dependencies: none.
- Migration/compatibility: no persisted migration; behavior changes immediately
  for the recognized application bundles.

## Error And Recovery Behavior

| Failure | User-visible state | Data ownership | Recovery |
| --- | --- | --- | --- |
| Target app changed | Copied | Draft on clipboard and in session memory | Focus intended field and press Cmd+V |
| Paste event cannot be created | Copied | Draft on clipboard and in session memory | Press Cmd+V manually |
| Accessibility revoked | Copied | Draft on clipboard and in session memory | Re-enable permission or paste manually |

## Acceptance Criteria

- ChatGPT/Codex, Chrome-family, and Arc bundle ids select clipboard plus Command+V.
- Mail and Outlook continue selecting clipboard plus Command+V.
- Slack and unknown native apps retain direct-first insertion.
- Target-change, cancellation, clipboard recovery, and no-auto-send invariants
  remain unchanged.
- A harmless draft can be pasted into a live Chrome web field without submission.

## Automated Validation

- Pure policy checks cover exact, case-normalized, family-prefix, unknown, and
  missing bundle ids.
- Canonical command: `task check`.

## Manual Smoke Test

1. Focus a harmless Chrome web field, dictate a short test phrase, and stop.
2. Confirm the phrase appears and no form is submitted.
3. Repeat in the ChatGPT macOS composer and confirm the draft remains unsent.
4. Confirm one Mail/Outlook compose field still receives a draft.

## Approval Gate

- Product decision approved by: Christian, 2026-08-27.
- Agent autonomy envelope: implement, test, commit/push feature branch, package,
  and install a local release candidate.
- Must stop before: merging/pushing `main` or creating a final release tag.

## Open Questions

- None for implementation. The real ChatGPT composer remains a human smoke-test
  target because Computer Use cannot operate that protected app surface.
