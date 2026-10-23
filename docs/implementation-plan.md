# Implementation Plan

This plan contains only remaining candidate work and delivery dependencies.
Current release state and the single next action live in `docs/project-status.md`.
Completed milestone history is retained in
`docs/runs/archive/mvp-through-v0.4-implementation-plan.md`, and shipped behavior
is defined by the durable product, architecture, privacy, and test specifications.

No candidate below is approved or active merely because it appears here. Before
implementation, create or approve a feature contract under `docs/features/` and
start a tracker under `docs/runs/active/`.

## Candidate Delivery Order

### 1. Extend Native Integration Validation

- Actual coordinator recovery, delivery, cancellation, and settings-snapshot
  regressions now run in the executable debug suite; they do not require XCTest.
- Remaining opportunities: broaden hybrid startup/event-ordering coverage and
  safely automate native event delivery when suitable platform tooling exists.
- Real microphone, Accessibility, Carbon, Keychain, and process termination
  retain manual coverage.

### 2. Configurable Global Hotkey

- Goal: let the user change the fixed hybrid shortcut without weakening tap/hold
  classification, startup-race handling, or permission transparency.
- Dependency: a feature contract covering conflicts, persistence, migration, and
  whether any implementation path changes the Input Monitoring requirement.

### 3. Local Transcription Backend

- Goal: offer an explicit local alternative to the configured OpenAI-compatible
  transcription endpoint.
- Dependency: approved model packaging, performance, storage, update, and privacy
  behavior; no backend may be selected silently.

### 4. Public macOS Distribution

- Goal: produce a Developer ID-signed and notarized build suitable for a GitHub
  Release.
- Dependency: authorized signing identity/notarization profile, real hardened-runtime microphone/paste validation, notarization/Gatekeeper evidence and an approved publication gate. Pilot readiness prepares the fail-closed tooling; it does not authorize or claim public distribution.

### 5. Update Delivery

- First-run onboarding is released in 0.5.0; see `docs/features/onboarding-and-updates/spec.md`. Its Sparkle/update proposal remains deferred and does not authorize updater dependencies or network traffic.

- Goal: provide a predictable way to discover and install later releases.
- Dependency: the public distribution path and an approved update/security model.

## Additional Product Candidates

These remain unsequenced until the user selects them:

- Per-app cleanup style defaults.
- Optional local price inputs and estimated cleanup tokens.
- Deterministic local dictionary replacements.
- Preview/editor and email-specific cleanup modes.

## Maintenance And UX Path

- Keep the dependency policy intentionally native-first. The current package has
  no third-party dependencies, so maintenance should review the Swift tools
  version, deployment target, deprecated Apple APIs, and release tooling rather
  than adding an updater merely to have one.
- Re-run the dependency/platform audit before each planned release or after a
  major macOS/Xcode upgrade. Local `task check` remains sufficient for this
  personal-only project; CI can be reconsidered only if distribution or outside
  contributors make it useful.
- Option B: make secondary tools contextual, showing recovery/archive entries
  only when they contain data. This would shorten the menu further but makes
  stable tool locations less predictable.
- Option C: replace the menu with a small status popover that combines readiness,
  recent draft recovery, and richer live state. This offers more visual polish
  but adds interaction and focus complexity to a utility whose strongest trait
  is immediacy.

## Input Compatibility Candidates (2026-09-05)

Clipboard-only insertion is released in 0.5.0; see `docs/features/clipboard-only-insertion/spec.md` and `docs/project-status.md` for execution state. Remaining unapproved candidates:

- Direct Accessibility insertion, including ChatGPT: postponed. A future feature must demonstrate a concrete clipboard-avoidance benefit, validate editor state beyond AX success, define application/field eligibility and duplicate-safe failure behavior, and preserve focus/clipboard/cancellation rules. No dormant direct-writing implementation or allowlist remains.
- Content-free delivery diagnostics: permission, application match, clipboard ownership and event-posted outcome; never draft, clipboard or field text.
- Broader native/manual coverage across rich/native editors, alternate layouts/IME, held modifiers, selection replacement and multiline input. Current paste uses ANSI-V keycode 9; measure before changing event strategy.
- Explicit protected-field, terminal and remote-desktop policies. Current targeting identifies an application, not an original field. Stricter behavior needs a feature contract compatible with unstable rich-editor AX elements. Never blindly retry ambiguous delivery.

## Provider Lifecycle Dependency

The approved pilot work records a separately gated model migration follow-up in `docs/provider-lifecycle.md`: inventory by 2026-11-13, spec/cost approval by 2026-12-04, cleanup validation by 2026-12-18 before the dated GPT-4o mini removal on 2027-01-14, and transcription/hedge validation by 2027-02-05 before 2027-02-26 removal. Company aliases require IT confirmation. This does not authorize a default/model/provider/cost change or create a recurring automation.

## Post-0.5.0 Follow-Ups

The local release was explicitly approved on 2026-10-23. Deferred work does not imply the following checks passed:

- the maintainer’s macOS 27.0.1 comparison of Settings/onboarding at both documented sizes; full OS Increase Contrast review.
- Broader permission repair, language/editor/gesture/recovery and personal-provider compatibility matrix.
- Approved company connection profile, per-user key issuance and support/revocation owner.
- Developer ID/notarized colleague installer, followed by the separately approved Sparkle/update plan.

Keep these follow-ups in the existing candidate plan rather than reopening closed implementation runs. Provider lifecycle milestones remain in `docs/provider-lifecycle.md`.
