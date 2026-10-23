# Internal Pilot Readiness Specification

## Status

Approved by the maintainer on 2026-10-23 through the explicit implementation request carried into this chat. Implementation in progress; release and full compatibility acceptance pending.

## Problem And Desired Outcome

Settings spacing differs visibly between macOS 26.7.1 and 27.0.1. Prepare a predictable native dictation helper for an internal pilot, with reproducible builds, compact readable Settings, explicit connection setup, bounded provider destinations, safe audio ownership, honest feedback, private diagnostics, and a verifiable distribution path.

## Research And Alternatives

Use a shared native form layout with one scrolling owner instead of OS-specific offsets. Preserve existing controls and staged Apply behavior. Keep existing native components and fixture checks rather than introduce dependencies or a UI rewrite. Credentials remain per-user revocable Keychain secrets; no bundled company master key or invented SSO.

## Accepted Scope

1. Diagnose installed compiler/SDK selection and restore reproducible canonical validation without changing global toolchains or hiding compiler errors.
2. Polish the Settings window first: all five tabs, native controls, consistent alignment/spacing, wrapping help/errors/long values, predictable scrolling and fixed Apply footer. Minimum 700×560; default 760×640. Preserve shared secondary dialogs.
3. Reject provider redirects outside the approved origin and transport downgrade. Bind primary credentials to approved origin; preserve existing keys and require explicit reassociation/replacement before a changed origin can use them.
4. Prevent multiple copies from interfering with live audio through instance/ownership protection. Preserve stopped recovery and retention.
5. Reject HTML and malformed JSON as transcription; support explicit JSON and plain-text response contracts.
6. Own HUD completion dismissal once per operation so repeated notifications retain feedback.
7. Export allowlisted content-free diagnostics without private paths.
8. Guide setup with generic non-secret presets/custom configuration, per-user key entry, actionable permissions and explicit disclosed synthetic connection test. Distinguish incomplete, saved/unverified, verified and unavailable. Models listing never proves transcription. Advanced contains endpoint/model/routing/timeouts. Preserve saved-vs-edited snapshots and existing explicit fallback choices; new-user fallback stays off. Company profile/key issuance remain pending authoritative input.
9. Prepare dedicated distribution build mode, increasing bundle builds, clean-commit packaging, signature/hardened runtime/microphone entitlement/timestamp review and notarization/stapling/Gatekeeper/support procedures. Fail clearly without authorized distribution identity.
10. Reconcile stale docs and verify official model retirement notices; schedule migration without silently changing IDs, destination or cost.

## Interaction, Errors And Invariants

Apply remains the boundary between edited configuration and active requests. Origin changes must never silently reuse an unrelated key. Network and parsing failures retain normal failed-recording recovery. Duplicate instances must exit before shared stores/cleanup or recording. Completion notifications do not restart or cancel their own dismissal. Setup tests require explicit action and disclose destination, synthetic content and potential cost before sending.

Preserve clipboard-only insertion and its separate approved feature history, no Enter/auto-send/focus theft/ambiguous retry, German/English/mixed dictation, tap/hold, existing settings/Keychain secrets, archive opt-ins and Failed Recordings ownership. No new dependency, provider, permission, retention, analytics, cloud service or broad architecture rewrite.

## Data, Privacy And Migration

Use fixture bytes and fake keys only in checks; never read real secrets, microphone, archive or clipboard content for validation. Do not migrate/delete real secrets during checks. Public diagnostics omit all private paths and content. Existing configuration migrates non-destructively; unresolved company settings are visibly pending rather than guessed.

## Architecture Impact

Focused changes to shared dialog presentation, providers, settings/secret policy, audio startup/cleanup, HUD state and release scripts; no added dependency.

## Acceptance And Validation

Canonical command: `task check`; broad regression and packaging from a clean commit when tooling permits. Add meaningful deterministic fixtures for security, response, credentials, ownership and timing changes. Read-only isolated UI validation must never run a second production-store copy or alter saved settings. Compare all five tabs at both sizes on both macOS versions and secondary dialogs. This host can establish only 26.7.1 evidence; 27.0.1 remains a human gate. Real microphone/provider/Slack smoke remains a human gate.

## Approval Gate And Non-Goals

Authorized: implementation, fixture checks, normal feature commits/pushes, local candidate preparation. Stop before PR creation, main merge/push, force push, final tags, publication, production install/launch, real credentials/provider calls or signing-material access. Windows and automatic updating remain deferred.

## Open Inputs

Authoritative company connection profile and credential issuance; authorized Developer ID/notarization; macOS 27.0.1 visual evidence; real-world smoke approval.

## Approved Visual Refinement (2026-10-23)

the maintainer requested a color/background review against Apple HIG during implementation. Use semantic NSColor windowBackgroundColor, controlBackgroundColor and separatorColor instead of compounded gray opacity fills. Primary headings and native accent-colored actions carry hierarchy; status color always retains text. Honor system appearance without a new app theme setting. Preview light, dark and increased-contrast appearances without changing global settings. Keep five tabs, fixed Apply and resizable/scrolling behavior; defer a toolbar/navigation redesign.

Sources: [Apple Color](https://developer.apple.com/design/human-interface-guidelines/color), [Materials](https://developer.apple.com/design/human-interface-guidelines/materials), [Settings](https://developer.apple.com/design/human-interface-guidelines/settings), reviewed 2026-10-23. Apple recommends semantic adaptive colors and native Settings conventions; the specific surface/spacing implementation is a project design decision, not a prescribed HIG palette.
