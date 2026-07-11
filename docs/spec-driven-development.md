# Spec-Driven Development At BabbelStream

## Purpose

For this project, spec-driven development means that user intent is converted into durable behavioral contracts before or alongside implementation, and that code, tests, release evidence, and documentation are kept consistent with those contracts.

The specification is not a large frozen design document and it is not prose generated after the code. It is the shared memory that lets a user and successive Codex sessions make decisions without repeatedly reconstructing product meaning from source code.

The practical unit of work is:

> product intent + feature contract + execution tracker + evidence

Each part solves a different problem. Durable specs explain what must remain true. A feature spec resolves one change in enough detail to implement. A run tracker records temporary progress and decisions. Checks and smoke-test evidence show what was actually verified.

## What The Git History Shows

BabbelStream has 63 commits through v0.4.0. Fifty-seven touch `docs/`, and 43 touch both documentation and source code. The principal living specs have been revised repeatedly: `product-spec.md` 27 times, `architecture.md` 26 times, `test-plan.md` 26 times, `security-privacy.md` 20 times, and `implementation-plan.md` 20 times. This is strong evidence that documentation was treated as part of product development rather than a one-time introduction.

### Phase 1: A real spec-first foundation

The first commit, `4f7b8e6`, added `AGENTS.md`, the product spec, architecture, interfaces, security/privacy, implementation plan, test plan, and an ADR before application code. The initial documents already contained the product's most important durable decisions:

- Slack-first but generic macOS insertion;
- native macOS rather than Slack API, browser extension, or Electron;
- German, English, and mixed technical speech;
- visible provider destinations;
- Keychain secrets and no transcript history;
- no auto-send;
- milestone-sized implementation and explicit acceptance criteria.

Those constraints survived the entire project and prevented feature drift even while the implementation changed rapidly.

### Phase 2: Living specifications during rapid MVP work

Most early feature commits updated the relevant durable docs with the code: language preservation, deferred Keychain access, configurable duration, trailing separators, launch at login, dictionary behavior, archive behavior, privacy-safe diagnostics, packaging, and paste targeting.

This worked well because product, security, architecture, and test implications were usually considered together. The result is unusually good traceability for a vibe-coded personal project.

### Phase 3: Documentation sometimes followed shipped behavior

Commits such as `c7b2954` (`Align MVP specs with current app state`) and `d687e5c` (`Align archive docs with shipped behavior`) reveal that implementation occasionally moved faster than the source of truth. These reconciliations were responsible, but they show that “spec-driven” sometimes became “spec-corrected-afterward.”

The archive reconciliation is especially instructive: the planned retention and plain-text export options had not shipped, so the docs were narrowed to actual Markdown export and future retention. Correcting the record was good; separating approved intent from implemented status earlier would have avoided the drift.

### Phase 4: Operational specification emerged from real failures

Commit `6c4fb56` introduced `task check` and the first detailed implementation-run tracker after discovering that the original `swift test` acceptance claim was not truthful in the available Command Line Tools environment. This was a major improvement:

- validation matched the actual toolchain;
- the clean baseline and feature branch were recorded;
- milestones became checklists;
- working decisions and safety boundaries were explicit;
- validation evidence was accumulated rather than reconstructed at the end.

The provider reliability tracker then added accepted scope, non-goals, baseline, staged outcomes, risks, decisions, evidence, blockers, and next action. That is the point where the project developed a strong autonomous-agent operating model.

### Phase 5: Release trackers became effective agent memory

The v0.2.5 and v0.3.0 trackers show the strongest process in the history. They made UI, privacy, recovery ownership, clean-worktree packaging, manual QA, installed-app verification, branch publication, and tags part of one explicit definition of done.

The weakness is organizational: `docs/project-upgrade.md` was reused for different releases. Git preserves the old text, but a future agent reading the filesystem sees only the latest run. A run artifact should have a stable feature-specific path and later move to an archive.

### Phase 6: v0.4.0 added a strong feature contract but compressed the gates

`docs/hybrid-hotkey-spec.md` is a good feature specification. It captures the threshold boundary, visible states, startup races, privacy invariants, acceptance criteria, implementation advice, and a manual smoke test. The pure threshold policy and user smoke test followed directly from it.

However, the spec, implementation, version bump, and final release tag were created together, and the tag was pushed before the user's successful smoke test and before `main` was advanced. The result worked, but the safer sequence is release candidate first, human smoke second, then main and final tag.

## Start, Stop, Continue

### Start

- Create one feature spec and one execution tracker for every substantial feature.
- Give run trackers stable paths such as `docs/runs/active/hybrid-hotkey.md`; archive them without overwriting history.
- Verify the real build/test/toolchain baseline before promising an acceptance command.
- Require a short spec-approval gate before substantial behavior work, then let the agent run autonomously.
- Separate release-candidate installation from final release tagging.
- Put the final tag on the tested commit after it reaches `main`.
- Add explicit definitions of ready and done to each feature.
- Record manual validation evidence in the run tracker immediately after the user reports it.
- Push feature branches early for backup and handoff, while reserving `main` and release tags for the release gate.
- Add coordinator-level tests when the toolchain supports them; until then, keep interaction policies pure and testable and document the manual gap.

### Stop

- Stop treating `implementation-plan.md` as a mixture of roadmap, current status, and historical changelog.
- Stop reusing one generic tracker file for unrelated releases.
- Stop backfilling durable specs only after implementation has shipped.
- Stop creating final tags before the real-user smoke gate.
- Stop claiming a test command works before validating the local environment.
- Stop duplicating detailed behavior across README, changelog, product spec, architecture, and trackers without assigning ownership.
- Stop placing every historical run document in the top-level `docs/` directory with a current-sounding name.
- Stop making one broad release commit when milestone commits would provide safer rollback and clearer review.
- Stop interrupting autonomous work for reversible implementation details already covered by an approved spec.

### Continue

- Continue writing non-goals as carefully as goals.
- Continue treating privacy, provider visibility, no-auto-send, target safety, and audio ownership as invariants.
- Continue updating product, architecture, security, tests, and user documentation with behavior changes.
- Continue using native APIs and documenting dependency decisions.
- Continue keeping provider policies and other deterministic decisions in executable checks.
- Continue recording a clean baseline, branch, decisions, evidence, blocker, and next action.
- Continue using real Slack/macOS smoke tests for behavior automation cannot honestly prove.
- Continue embedding version and commit metadata in installed builds.
- Continue producing small, recoverable milestones and explicit handoffs.

## Artifact Model For A New Vibe-Coded Project

Start small. Every artifact needs a distinct owner and purpose.

| Artifact | Purpose | Lifetime |
| --- | --- | --- |
| `AGENTS.md` | Operating constitution for agents: required reading, boundaries, commands, Git, approvals, communication | Entire project |
| `docs/product-spec.md` | Problem, users, workflows, scope, non-goals, product acceptance | Entire project |
| `docs/architecture.md` | Components, data flow, technical invariants, dependency direction | Entire project |
| `docs/security-privacy.md` | Data inventory, permissions, retention, providers, logging, threat model | Entire project when relevant |
| `docs/test-plan.md` | Honest automated/manual coverage and environment limits | Entire project |
| `docs/release.md` | Version, build, package, deploy/install, main/tag/publication rules | Entire project |
| `docs/adr/NNNN-*.md` | Durable high-impact decisions and rejected alternatives | Permanent |
| `docs/features/<feature>/spec.md` | Approved contract for one feature, including edge cases and smoke test | Permanent or retained with feature |
| `docs/runs/active/<feature>.md` | Baseline, stages, decisions, evidence, blocker, next action | Active work only |
| `docs/runs/archive/<feature>.md` | Closed execution record | Historical |
| `README.md` | User/developer entry point and current supported workflow | Entire project |
| `CHANGELOG.md` + `VERSION` | User-visible release history and version source of truth | Entire project |
| `Taskfile.yml` or equivalent | Discoverable canonical commands | Entire project |

Avoid creating documents merely because a template lists them. A five-file project does not need an enterprise governance system. Add a separate artifact when it prevents a real ambiguity, safety failure, or context-reconstruction cost.

## Source-Of-Truth Rules

1. `AGENTS.md` explains how to work, not every product behavior.
2. The product spec owns user-visible intent and non-goals.
3. Security/privacy owns data and permission invariants and cannot be silently weakened by a feature spec.
4. Architecture owns durable technical boundaries, not task progress.
5. A feature spec owns the detailed approved change and must reconcile durable docs before completion.
6. A run tracker owns temporary status and evidence; it must not become the only place where shipped behavior is described.
7. Test and release guides own proof procedures.
8. README and changelog summarize; they do not override the specs.
9. If artifacts conflict, stop implementation long enough to reconcile them explicitly.

## Feature Development Lifecycle

### 0. Intake and clean baseline

- Understand the request, repository, and relevant external context.
- Inspect Git status, current branch, current version, and existing user changes.
- Read the relevant sources of truth.
- Verify the canonical check command and record limitations.

### 1. Brainstorm and research

- Clarify the user problem rather than jumping to the first implementation.
- Research comparable workflows when product convention matters.
- Present two or three meaningfully different options with tradeoffs.
- Recommend one option and identify irreversible or high-risk choices.

Human gate A: confirm the product direction. The user can explicitly authorize the agent to choose the recommendation and continue.

### 2. Specify

- Write the feature spec from `docs/templates/feature-spec.md`.
- Define scope, non-goals, interaction/state contract, invariants, errors, races, migrations, acceptance criteria, automated checks, and manual smoke test.
- Add an ADR only when a durable decision has meaningful alternatives or long-term consequences.
- Update durable specs now if the feature changes product or security meaning.

Human gate B: approve the behavioral contract. Once approved, implementation should normally proceed without further product questions.

### 3. Prepare the run

- Confirm a clean, pushed baseline.
- Create `codex/<feature>` from the intended base.
- Create the run tracker from `docs/templates/implementation-run.md`.
- Record baseline commit, branch, accepted scope, stages, risks, approval envelope, and next action.
- Push the branch early if remote backup/handoff is desired.

### 4. Implement in coherent milestones

For each milestone:

1. implement the smallest coherent behavior;
2. add or update focused checks;
3. update durable docs affected by the behavior;
4. run the canonical validation;
5. record evidence and decisions in the tracker;
6. review the diff for unrelated changes, privacy, and scope;
7. commit and push the feature branch.

The agent should stop only for a material scope expansion, new external effect, destructive action, or decision outside the approved envelope.

### 5. Release candidate

- Finish broad automated checks and diff review.
- Update candidate release notes, but do not create the final tag.
- Package from a clean commit with exact build metadata.
- Install and launch the candidate locally when authorized.
- Verify version, commit, signature, process, and artifact checksum.
- Provide the smallest real-user smoke script.

Human gate C: the user performs the microphone/provider/Slack or equivalent real-world smoke test and reports success or failure.

### 6. Final release

After smoke approval:

1. record the manual evidence;
2. fix any release notes/version drift;
3. run final checks from a clean tree;
4. fast-forward or merge the feature to `main` according to repository policy;
5. verify local `main` equals `origin/main` after push;
6. create the annotated version tag on the final main commit;
7. push the tag;
8. rebuild the final artifact from that clean tagged commit;
9. install, launch, and verify the final version/commit;
10. close and archive the run tracker.

For a public release, add the platform's signing, notarization, publication, and rollback requirements. A local personal deployment and a public production release are different gates.

## When To Push

- Push the clean baseline before broad autonomous work if losing local work would be costly.
- Push the feature branch after coherent, passing milestones and before handoff.
- Do not wait until the final release to create the only remote copy of the work.
- Do not push secrets, sensitive fixtures, generated personal data, or unrelated changes.
- Push `main` only after the repository's merge/release approval gate.
- Push the final tag only after it points at the accepted release commit on `main`.

## Human Approval Matrix

| Decision or action | Default owner |
| --- | --- |
| Read-only research, repository inspection, drafting specs | Agent |
| Reversible implementation within approved spec | Agent |
| Tests, local mocks, build, feature-branch commits/pushes when authorized | Agent |
| Product meaning and meaningful UX tradeoffs | User |
| New provider, paid service, permissions, dependency, retention, telemetry | User |
| Real external messages, provider calls with private data, destructive migration | User |
| Release-candidate local installation | Agent when preauthorized; otherwise user gate |
| Real-world product smoke test | User unless safe automation truly covers it |
| Merge/push main, final tag, public release, production installation | User authorization, which may be granted up front |

The user can grant a broad approval envelope such as: “Implement the approved spec autonomously through a locally installed release candidate; stop before main and the final tag.” That sentence removes most low-value interruptions while preserving the meaningful gate.

## How The User And Codex Collaborate

A high-quality feature request should include:

- the problem and why it matters;
- example workflows or failures;
- product constraints and non-goals;
- desired research depth;
- the autonomy envelope;
- definition of done;
- the last action that still requires human approval.

Useful interaction pattern:

1. User: “Research and brainstorm; recommend an interaction. Do not implement yet.”
2. Codex: options, recommendation, risks, open product decisions.
3. User: “Approve option B. Write the spec and implement autonomously through an installed release candidate. Stop before main/tag.”
4. Codex: spec, tracker, implementation, checks, candidate install, smoke instructions.
5. User: “Smoke test passed. Merge main, tag, push, rebuild, and install final.”
6. Codex: final release evidence and clean Git state.

Codex should keep commentary concise during work, make safe in-scope assumptions, and ask only when an answer changes product meaning, risk, or external state. The final handoff should be evidence-based and should name anything that remains unverified.

## Definition Of Ready

A substantial feature is ready to implement when:

- the user problem and target workflow are clear;
- scope and non-goals are explicit;
- important alternatives were considered;
- data, permission, cost, and migration implications are known;
- acceptance criteria and a smoke test exist;
- the repository baseline and validation command are known;
- the agent's approval envelope is clear.

## Definition Of Done

A feature is done when:

- approved behavior and edge cases are implemented;
- durable specs describe the shipped behavior;
- checks cover deterministic policy and regressions;
- manual-only gaps are listed and the required smoke test passed;
- privacy, security, provider, and migration implications were reviewed;
- the run tracker contains final evidence;
- version and changelog are aligned when releasing;
- main/tag/push/install state matches the authorized release level;
- the working tree is clean and the next action is unambiguous.

## Recommended BabbelStream Documentation Cleanup

Do this incrementally rather than in one disruptive rewrite:

1. Keep `docs/product-spec.md`, `architecture.md`, `security-privacy.md`, `test-plan.md`, and `release.md` as durable truth.
2. Split current implementation status from roadmap history. A small `docs/project-status.md` should describe only the current release, known limitations, and next candidates.
3. Move historical trackers into `docs/runs/archive/` and give every new run a unique path.
4. Put feature-specific contracts under `docs/features/<feature>/spec.md`; retain `hybrid-hotkey-spec.md` until a deliberate move avoids broken references.
5. Keep `implementation-plan.md` focused on remaining milestones and delivery order instead of duplicating the changelog.
6. Revisit `AGENTS.md` whenever the project changes its canonical validation, release, or approval workflow—not only when product behavior changes.
