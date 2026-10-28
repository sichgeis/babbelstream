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

### 3. Additional Local Transcription Backends

The approved Parakeet candidate is tracked in `docs/project-status.md` and
`docs/features/local-transcription/spec.md`. Remaining work: Qwen/Granite native
builds with Metal tooling, pinned offline-load/cancellation/resource/license QA,
real multilingual quality and desktop memory/latency measurements. The maintainer
explicitly deferred these builds while the Parakeet pilot is prepared.

### 4. Public macOS Distribution

- Approved path (2026-10-23): a clearly labeled ad-hoc, non-notarized colleague
  pilot via GitHub Releases and our own Homebrew tap, without paid Apple membership.
  The approved contract, publication sequence, upgrade/rollback tests and
  required policy reconciliation are in
  `docs/features/homebrew-distribution/spec.md` (2026-10-23).
- Implementation and the narrow non-notarized pilot exception are approved.
  Completed pilot evidence: `docs/runs/archive/homebrew-distribution.md`. The
  public download, installation/reinstall and human dictation checks passed;
  the following lifecycle cases remain follow-ups, not acceptance claims.
- Developer ID/notarization remains an optional later channel requiring authorized
  identity/profile access and real distribution validation; do not weaken that
  build mode to accommodate the ad-hoc pilot.

### 5. Update Delivery

- First-run onboarding is released in 0.5.0; see `docs/features/onboarding-and-updates/spec.md`. Its Sparkle/update proposal remains deferred and does not authorize updater dependencies or network traffic.

- Approved first update mechanism: user-initiated Homebrew upgrades using a
  versioned cask and verified GitHub release assets; no in-app network traffic or
  Sparkle dependency. See the Homebrew distribution contract above.
- Dependency: first downloaded install and a separately
  evidenced upgrade to the next real release. Sparkle remains optional future work.

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

- The maintainer’s macOS 27.0.1 comparison of Settings/onboarding at both documented sizes; full OS Increase Contrast review.
- Broader permission repair, language/editor/gesture/recovery and personal-provider compatibility matrix.
- Approved company connection profile, per-user key issuance and support/revocation owner.
- Distribution/update direction is now approved as the non-notarized own-tap pilot
  above. Developer ID/notarization and Sparkle remain deferred alternatives;
  neither is a prerequisite for that explicitly limited pilot.

Keep these follow-ups in the existing candidate plan rather than reopening closed implementation runs. Provider lifecycle milestones remain in `docs/provider-lifecycle.md`.

## Homebrew Pilot Lifecycle Follow-Ups

The initial distribution pilot is closed. Keep these cases explicitly untested
until their own evidence is recorded:

- **Genuine version upgrade:** test 0.5.1 to the clean 0.5.3 release with
  increased VERSION/BUILD_NUMBER. Verify installed source/version, settings,
  dictionary/recovery preservation, permissions and Keychain trust. A same-version
  reinstall does not prove this case.
- **Uninstall retention and reinstall:** use an isolated pilot account with benign
  fixtures. Verify ordinary cask uninstall retains settings, dictionary, recovery,
  optional archive and Keychain entries, then reinstall. No zap or real-data
  deletion. The missing-bundle reinstall already passed; uninstall retention did not.
- **Rollback:** restore a known-good bundle after reviewing data compatibility;
  verify version, preserved data and Homebrew pin/version-record reconciliation.
  The documented procedure is not yet a tested recovery guarantee.
- **Additional restart/trust coverage:** a further quit/reopen cycle of the
  Homebrew-installed copy and trust across future binaries remain untested.
  Earlier manual-DMG restart passed after the targeted Keychain repair.
- **Manual-app adoption and missing bundle:** ordinary install conflict and move-
  aside recovery passed; optional --adopt is untested. The observed bundle
  disappearance cause remains unknown; brew reinstall recovery passed.

Follow the operator matrix in `docs/homebrew-release.md`; do not reopen the closed
initial pilot run merely to imply these follow-ups were completed.
