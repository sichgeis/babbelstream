# Project Agent Instructions Template

Replace bracketed text and delete sections that do not apply. Keep this file concise enough that every agent can read it at the start of every session.

## Mission

[One paragraph describing the product, primary user, primary workflow, and quality bar.]

## Start Every Work Session

1. Read [list the durable sources of truth].
2. Run `[git status command]` and record branch/commit.
3. Preserve existing user changes; isolate rather than overwrite them.
4. For substantial work, create/update `[feature spec path]` and `[run tracker path]`.
5. Verify `[canonical check command]` before relying on it.

## Sources Of Truth

- `AGENTS.md`: operating rules and approval model.
- `[product spec]`: user-visible behavior and scope.
- `[security spec]`: data and permission invariants.
- `[architecture]`: technical boundaries and data flow.
- `[feature spec path]`: approved feature contract.
- `[run tracker path]`: temporary progress and evidence.
- `[test plan]`: automated/manual proof.
- `[release guide]`: version, deploy, main, and tag process.

If these conflict, stop and reconcile them explicitly. A run tracker never overrides a durable product or security invariant.

## Product Boundaries

- [Primary scope.]
- [Important non-goals.]
- [User-visible safety boundary.]
- [Compatibility constraints.]

## Engineering Rules

- Prefer [languages/frameworks/native APIs].
- Do not add dependencies without documenting why existing capabilities are insufficient.
- Keep behavior testable and avoid speculative abstraction.
- [Concurrency, platform, data ownership, or style invariants.]
- Keep behavior, tests, and affected docs in the same milestone.

## Security And Privacy

- [Secrets policy.]
- [Logging policy.]
- [Retention policy.]
- [External provider/network policy.]
- [Permissions policy.]
- Ask before adding telemetry, paid services, new providers, permissions, or persistence.

## Feature Lifecycle

1. Brainstorm/research and recommend options.
2. Write a feature spec with scope, non-goals, states, edge cases, acceptance, and smoke test.
3. Obtain or recognize explicit implementation authorization.
4. Create a clean feature branch and run tracker.
5. Implement coherent milestones with checks, docs, evidence, commits, and feature-branch pushes.
6. Package/install a release candidate from a clean commit when authorized.
7. Stop for the human smoke gate unless safely automated or explicitly waived.
8. After approval, update release metadata, merge main, tag the final main commit, push, rebuild, install/deploy, verify, and archive the tracker.

## Validation

- Canonical check: `[command]`.
- Additional focused checks: [commands].
- Manual-only checks: [list].
- Never claim an unavailable or unrun check passed.
- Use fakes/fixtures instead of private production data unless explicitly authorized.

## Git And Release Discipline

- Branch prefix: `[prefix/]`.
- Begin substantial work from a clean, pushed baseline.
- Commit coherent milestones and push the feature branch for recovery/handoff.
- Preserve unrelated user changes.
- Do not force-push shared history.
- Install/deploy a candidate before the final tag when human smoke is required.
- Merge/push main and create the final tag only after the release gate passes, unless explicitly preauthorized otherwise.
- Build final artifacts from a clean tagged commit with exact version/commit metadata.

## Approval Gates

Proceed autonomously within an approved spec. Stop for unapproved changes to:

- product meaning or scope;
- privacy, retention, permissions, cost, providers, or external communication;
- dependencies, architecture, or platform support;
- destructive migration or user data;
- main, final tags, public release, deployment, or production installation.

The user may preauthorize these actions. Do not ask twice for authority already granted.

## Progress And Handoff

- Keep `[run tracker]` current with baseline, stages, decisions, evidence, blocker, and next action.
- Send concise progress updates during long work.
- Ask only material questions; make and record reversible assumptions.
- Final handoff: delivered behavior, files, checks, limitations, release/deploy state, Git state, and exact remaining human action.
