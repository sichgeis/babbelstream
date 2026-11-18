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

Parakeet and optional Qwen cleanup ship in 0.6.0. Measure the supported path on the upgraded pilot Mac first. Qwen-ASR and Granite speech builds remain deferred pending a demonstrated need, native tooling, pinned offline loading, cancellation, licensing, multilingual quality and desktop resource measurements.

### 4. Public macOS Distribution

- Complete managed-device installation and upgrade trust checks for the existing Homebrew and manual pilot channels. See [release status](project-status.md) and the [Homebrew contract](features/homebrew-distribution/spec.md).
- Wider distribution with Developer ID and notarization requires separately authorized credentials and native validation.

### 5. Update Delivery

Homebrew provides user-initiated upgrades. An in-app updater remains a candidate requiring a separate decision about dependencies, signing and network access.

## Additional Product Candidates

- Per-app cleanup style defaults.
- Optional local price inputs and estimated cleanup tokens.
- A standalone deterministic correction mode beyond the implemented local-cleanup spelling pass.
- Preview/editor and email-specific cleanup modes.

## Maintenance and menu design

- Review the Swift toolchain, deployment target, Apple APIs and pinned native helpers before releases and after major platform upgrades. Revisit CI as outside contribution or distribution needs grow.
- Consider showing archive and recovery tools only when they contain data. Evaluate discoverability for people who rely on stable menu locations.
- A status popover could show readiness and draft recovery together. Evaluate focus behavior with the active editor before committing to this design.

## Input compatibility

- Evaluate direct Accessibility insertion only for a demonstrated need to avoid clipboard use. Define field eligibility, acceptance checks and duplicate-safe recovery before implementation. See the [clipboard delivery contract](features/clipboard-only-insertion/spec.md).
- Consider content-free delivery diagnostics for permissions, app matching, clipboard ownership and event posting.
- Exercise selection replacement, multiline drafts, alternate layouts, IME and held modifiers in additional native and rich editors. Current delivery uses ANSI-V keycode 9.
- Define explicit handling for protected fields, terminals and remote desktops if the application-level target policy proves insufficient.

## Provider lifecycle

Track the model and proxy alias inventory, replacement approvals, deadlines and acceptance checks in the [provider lifecycle plan](provider-lifecycle.md). Colleague deployment also needs an approved connection profile, per-user key issuance and a support and revocation owner.

## Pilot validation still needed

- Compare Settings and onboarding at both documented sizes on macOS 27.0.1, including Increase Contrast.
- Exercise permission repair, dictation gestures, language, recovery and approved personal-provider compatibility with the [test plan](test-plan.md).
- On the upgraded Mac, check permission and Keychain continuity after restarting and time local dictation through an unsent draft.
- Use an isolated pilot account to test cask uninstall retention, reinstall, optional manual-app adoption and rollback. Verify data compatibility, version and Homebrew records when restoring an earlier bundle. Follow the [Homebrew operator matrix](homebrew-release.md).
