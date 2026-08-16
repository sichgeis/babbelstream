# Personal OpenAI Fallback Implementation Run

## Outcome

Keep BabbelStream available when the work LiteLLM cluster is offline by adding
an explicit, narrow, and visible fallback to the user's personal OpenAI account.

## Baseline

- Base branch: `main`
- Base commit: `9433253634206ecb20c321826674e5eabf5ec86f`
- Base pushed: yes (`main...origin/main`)
- Working tree: clean
- Baseline validation: `task check` passed with normal developer cache access;
  the sandbox-only run could not write Swift/Clang caches
- Implementation branch: `codex/personal-openai-fallback`
- Version/release target: none

## Authority And Gates

- Approved spec: `docs/features/personal-openai-fallback/spec.md`, authorized by
  Christian's 2026-08-16 request
- Agent may proceed through: implementation, checks, coherent commits, and
  feature-branch push
- Required human gates: real LiteLLM/personal OpenAI smoke test; merge/push
  `main`; release/tag/publication. Local release-candidate installation was
  authorized on 2026-08-16.
- External systems/data authorized: GitHub feature-branch push only; no real
  provider requests or private credentials

## Accepted Scope

- Disabled-by-default personal OpenAI fallback with a fixed official endpoint.
- Separate Keychain secret and non-secret presence marker.
- Reachability-only sequential failover for transcription and cleanup.
- Visible configuration, activation, diagnostics, and archive provider labels.
- Focused behavior checks and durable documentation.

## Non-Goals

- Arbitrary secondary endpoints, broad error fallback, health polling,
  simultaneous cross-account requests, new dependencies, main/release changes,
  or real-provider automated tests.

## Risks And Dependencies

- Work content may be sent to a personal account and incur charges; opt-in copy,
  fixed destination, narrow error policy, and visible activation are mandatory.
- The existing primary/Mini hedge already represents two possible work-profile
  requests. Personal fallback must remain sequential and bounded to one
  transcription request.
- AppState coordination is covered by the manual matrix in this CLT-only test
  environment; pure policies and provider request behavior remain automated.

## Decisions

- Use a fixed official-OpenAI fallback profile rather than a second arbitrary
  provider to keep destination and routing predictable.
- Treat transport failures and gateway/service-unavailable HTTP 502/503/504 as
  fallback-eligible. Other HTTP responses do not authorize account switching.
- Keep the existing primary/Mini hedge intact, then attempt one sequential
  personal transcription request if the phase ends in an eligible error.
- Route cleanup through the transcript-winning profile; allow one personal
  cleanup attempt after an eligible primary cleanup failure.

## Stages

### 1. Research And Contract

- Status: Completed
- [x] Read product, privacy, architecture, status, plan, test, playbook, and
  current provider feature/run sources.
- [x] Inspect settings, secrets, provider retry classification, hedging,
  coordinator, Settings UI, archive labels, and checks.
- [x] Record baseline and validate `task check`.
- [x] Write approved feature contract and execution plan.

### 2. Settings, Secrets, And Policy

- Status: Completed
- [x] Add persisted opt-in, separate Keychain account/presence marker, and pure
  fallback error/settings policy.
- [x] Add focused behavior checks.

### 3. Coordination And UI

- Status: Completed
- [x] Add sequential transcription/cleanup fallback and winning-profile labels.
- [x] Add Provider/General Settings controls, disclosures, and diagnostics.

### 4. Durable Docs And Validation

- Status: Completed
- [x] Align product, privacy, architecture, project status, implementation plan,
  and test plan.
- [x] Run `task check`, focused review, and `git diff --check`.

### 5. Feature Handoff

- Status: Completed
- [x] Commit coherent milestones and push the feature branch.
- [x] Report remaining human smoke and merge/install gates.
- Evidence: feature commit `72edb30` pushed to
  `origin/codex/personal-openai-fallback`.

## Validation Matrix

| Check | Baseline | Current/final | Evidence |
| --- | --- | --- | --- |
| Canonical checks | Passed | Passed | `task check` with normal developer cache access |
| Focused policy/settings checks | N/A | Passed | Defaults/persistence, independent markers, fixed official settings/request, eligible/ineligible failures, HUD phase |
| Manual provider smoke | Not run | Human gate | No real credentials/content authorized |
| Local build/install | N/A | Passed | `0.4.1` / `06862f0`; installed and packaged executable hashes match |
| Diff/privacy review | Clean baseline | Passed | `git diff --check`; separate secrets, content-free diagnostics, sequential request review |
| Git state | Clean main baseline | Feature commit pushed | `72edb30` on `origin/codex/personal-openai-fallback` |

## Current Blocker

None.

## Release-Candidate Evidence

- Canonical checks passed immediately before packaging.
- Packaged artifact: `dist/BabbelStream-0.4.1.dmg`.
- DMG SHA-256: `2e16bf71c7edff88b91e99340bb6b8325d30db9f2036a7e0e050f0718b8955d0`.
- Installed app: `/Applications/BabbelStream.app`.
- Installed version/commit: `0.4.1` / `06862f0`.
- Signing label: `BabbelStream Local Code Signing` (local testing only;
  TeamIdentifier is not set).
- Installed and packaged executable SHA-256:
  `433b6c4e3c5a5619cbd1a0069ff05cf8daff5d6dad42dabf63245735a9843865`.
- The installer launched the executable from `/Applications`; restart
  verification confirmed it remains active as PID `85941`.

## Next Action

Run the real-provider matrix in the feature spec with synthetic/non-confidential
dictation, then authorize merge and local installation if it passes.

## Closeout

- [x] Durable specs match implemented behavior.
- [x] Automated validation evidence is complete and truthful.
- [ ] Human smoke gate passed or explicitly deferred.
- [x] Feature branch pushed with a clean working tree.
- [ ] Tracker moved to archive after authorized integration or explicit closeout.
