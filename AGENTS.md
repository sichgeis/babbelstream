## Mission

Build BabbelStream as a native macOS hybrid dictation helper for Slack and other focused text fields. A tap of the global shortcut starts hands-free recording; holding it provides push-to-talk. The product must remain predictable, private by default, and incapable of auto-sending the user's draft.

## Start Every Work Session

1. Read the sources of truth relevant to the task:
   - `docs/product-spec.md`
   - `docs/security-privacy.md`
   - `docs/architecture.md`
   - `docs/project-status.md`
   - `docs/implementation-plan.md`
   - `docs/test-plan.md`
   - `docs/release.md` for release or installation work
   - the active feature spec and implementation-run tracker, when present
2. Run `git status --short --branch` and record the baseline branch and commit.
3. Preserve existing user changes. If the tree is dirty, understand and isolate them; do not overwrite or silently include them.
4. For a substantial feature, create or update:
   - `docs/features/<feature>/spec.md`
   - `docs/runs/active/<feature>.md`
5. Confirm the canonical validation command still works before relying on it.

The project playbook is `docs/spec-driven-development.md`. New feature and run documents should start from the templates under `docs/templates/`.

## Source-of-Truth Responsibilities

- `AGENTS.md`: operating rules, project boundaries, validation, Git, approvals, and handoff behavior.
- `docs/product-spec.md`: user-visible behavior, scope, non-goals, and product acceptance criteria.
- `docs/security-privacy.md`: non-negotiable data, permission, provider, logging, and retention rules.
- `docs/architecture.md`: component boundaries, data flow, invariants, and accepted technical direction.
- `docs/project-status.md`: current release, active feature and tracker, known limitations, candidate-work pointer, and exactly one next action.
- `docs/implementation-plan.md`: remaining candidate work and delivery dependencies, not current status or release history.
- `docs/features/<feature>/spec.md`: the approved interaction and edge-case contract for one feature.
- `docs/runs/active/<feature>.md`: temporary execution state, baseline, stages, decisions, validation evidence, blocker, and next action.
- `docs/test-plan.md`: durable automated and manual validation coverage.
- `docs/release.md`: versioning, packaging, installation, tagging, and publication procedure.
- ADRs: durable decisions that would otherwise be repeatedly reconsidered.
- `README.md` and `CHANGELOG.md`: user-facing summaries, not substitutes for specifications.

Do not allow these artifacts to contradict each other. A feature spec may refine the product spec but must update the durable specs before implementation is considered complete.

## Product Boundaries

- Keep the primary Slack workflow and generic macOS text-field compatibility.
- Keep the app a local macOS-level helper, not a Slack app, bot, browser extension, subscription product, or cloud service.
- Do not add Slack API integration unless explicitly requested.
- Preserve German, English, and mixed German-English technical dictation.
- Never press Enter or auto-send a message.
- Keep provider configuration explicit and visible before audio or text is sent.

## Engineering Rules

- Prefer Swift, SwiftUI, AppKit/macOS APIs, AVFoundation, URLSession, Security/Keychain, Accessibility, and XCTest when the local toolchain exposes them cleanly.
- Do not introduce Electron.
- Do not add a dependency until the feature spec explains why native APIs are insufficient.
- Keep visible control flow and small testable policies. Do not create abstraction solely to make the architecture look layered.
- Keep dictation coordination on the main actor and isolate provider, storage, policy, and insertion behavior behind focused interfaces.
- Treat provider destinations, settings snapshots, cancellation, target validation, audio ownership, and recovery ownership as explicit state.
- Keep changes small enough that behavior, docs, checks, and manual QA can evolve together.

## Privacy And Safety Rules

- Do not log transcript text, draft text, audio, clipboard content, provider bodies, API keys, or private file paths.
- Do not persist transcript history or successful audio by default.
- Delete successful audio according to the product spec; preserve stopped audio only through the explicit Failed Recordings policy.
- Store API keys only in Keychain, never in files or `UserDefaults`.
- Ask before introducing telemetry, analytics, cloud databases, background sync, paid services, new providers, or new data retention.
- Keep Accessibility, microphone, and any future Input Monitoring implications explicit in UI copy, specs, and tests.
- Use fixtures and fakes for automated checks. Do not use real provider credentials, work content, Keychain secrets, microphone input, or archives without explicit authorization.

## Feature Lifecycle

1. Brainstorm and research the user problem. Present alternatives, tradeoffs, and a recommendation.
2. Write the feature spec with scope, non-goals, interaction contract, edge cases, invariants, acceptance criteria, and manual smoke test.
3. Treat user approval of that spec—or an explicit request to implement a clearly defined scope autonomously—as the implementation gate.
4. Create a feature branch from a clean, pushed baseline and start an implementation-run tracker.
5. Implement coherent milestones. Update code, durable specs, checks, and tracker evidence together.
6. Run `task check` throughout. Use release-specific validation from `docs/release.md` before packaging.
7. Push the feature branch after coherent milestones so work is recoverable and reviewable.
8. Build and install a release candidate from a clean commit. Do not create the final release tag yet.
9. Stop for the user's real microphone/provider/Slack smoke test unless that validation was explicitly delegated and can be performed safely.
10. After smoke-test approval: finalize version/changelog/evidence, fast-forward or merge `main`, create the annotated tag on the final main commit, push main and tag, rebuild the clean final artifact, install it, launch it, and verify its version/commit.
11. Close and archive the implementation-run tracker.

## Validation

- Canonical check: `task check`.
- This Command Line Tools environment does not expose runnable XCTest or Swift Testing through SwiftPM. `BabbelStreamChecks` is the honest executable behavior suite until that changes.
- Run checks with normal developer cache access when the Codex sandbox cannot write Swift module caches.
- Keep pure policy and provider behavior in automated checks.
- Keep Carbon event delivery, microphone permission, Accessibility insertion, real Slack fields, signing identity, Finder installation, and visual layout in the manual/release matrix.
- Never claim an unavailable or unrun check passed. Record the limitation and the closest valid evidence.

## Git And Release Discipline

- Begin substantial work from a clean, pushed baseline. Use `codex/<feature>` branches.
- Commit coherent milestones; keep behavior and its tests/spec updates together.
- Do not mix unrelated user changes into a feature commit.
- Push feature branches early and after meaningful milestones.
- Do not force-push shared branches or rewrite published release history.
- A release candidate may be installed from a feature branch for human smoke testing.
- Do not push `main` or create the final annotated release tag until the human smoke gate passes, unless the user explicitly waives that gate.
- The final tag must point at the final release commit on `main`, with `VERSION` and `CHANGELOG.md` aligned.
- Final packaging must come from a clean commit so the installed app reports an exact non-dirty build hash.
- Public distribution additionally requires Developer ID signing and notarization; local signing is only for the development Mac.

## Autonomy And Approval Gates

Once the user approves a feature spec and authorizes implementation, proceed autonomously through implementation, checks, feature-branch commits, and release-candidate packaging unless blocked.

Stop and request direction when work would materially change:

- product meaning, accepted scope, or a non-goal;
- privacy, retention, permissions, provider destinations, cost, or external communication;
- dependencies, platform support, or architecture beyond the approved spec;
- destructive migration or user-data handling;
- `main`, release tags, public publication, or local production installation when not already authorized.

The user may preauthorize any of these gates in the initial request. Do not ask again for an action already clearly authorized.

## Progress And Communication

- Keep the implementation-run tracker current with baseline, stage status, decisions, validation evidence, blocker, and next action.
- Share concise progress updates during long work; lead with outcomes and risks, not tool narration.
- Ask only questions whose answers materially change the result. Make reversible in-scope assumptions and record them.
- At handoff, report behavior delivered, files/artifacts, validation performed, limitations, installed version/commit when applicable, Git state, and the exact remaining human action.
- If work pauses, leave the repository and run tracker understandable enough for a fresh agent to continue without reconstructing the conversation.
