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

### 1. Expand Coordinator Test Coverage

- Goal: automate more dictation coordination, cancellation, recovery ownership,
  and application lifecycle behavior when the local toolchain exposes a suitable
  runnable test framework.
- Dependency: an XCTest or Swift Testing environment that works honestly with the
  project build setup.
- Manual coverage remains authoritative until then.

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
- Dependency: signing identity, notarization credentials, hardened-runtime review,
  clean release automation, and an approved publication gate.

### 5. Update Delivery

- Goal: provide a predictable way to discover and install later releases.
- Dependency: the public distribution path and an approved update/security model.

## Additional Product Candidates

These remain unsequenced until the user selects them:

- Per-app cleanup style defaults.
- Optional local price inputs and estimated cleanup tokens.
- A preconfigured direct OpenAI provider profile.
- Deterministic local dictionary replacements.
- Preview/editor and email-specific cleanup modes.
