# Web Editor Paste Compatibility Implementation Run

## Outcome

Release and locally install a validated build that pastes reliably into known
web-backed editors by preferring the existing clipboard plus Command+V path.

## Baseline

- Base branch: `main`
- Base commit: `4c0cece1acab0da6a28d61b21b66e254e01df921`
- Base pushed: yes (`origin/main` matched)
- Working tree: clean
- Implementation branch: `codex/web-editor-paste-compatibility`
- Version/release target: `0.4.3` (`v0.4.3`)

## Authority And Gates

- Approved spec: `docs/features/web-editor-paste-compatibility/spec.md` (Released)
- Agent may proceed through: implementation, feature push, candidate install,
  `main`/tag push, and final local installation
- Required human gates: satisfied; ChatGPT macOS composer smoke test passed
- External systems/data explicitly authorized: harmless local/browser UI probes;
  no real message submission

## Accepted Scope

- Add a pure clipboard-preferred target policy for Mail, Outlook,
  ChatGPT/Codex, Chrome-family, and Arc bundle identities.
- Preserve direct-first behavior for Slack, native, unknown, and missing bundle
  identities.
- Update focused checks and durable insertion/test documentation.

## Feature Non-Goals

- No DOM/browser extension integration, new permissions, new dependencies, or
  auto-send behavior. Release publication followed only after the separate
  human smoke-test approval.

## Risks And Dependencies

- Risk: a recognized app's native field also uses Command+V. Mitigation: this is
  the normal editing path and retains the existing application-level focus guard.
- Risk: synthetic key delivery cannot be proven by pure checks. Mitigation: live
  Chrome probe plus human ChatGPT smoke test.
- Dependency: existing Accessibility permission and clipboard fallback.

## Decisions

- Prefer app-level clipboard routing over AX read-back because AX state does not
  prove a web framework accepted the edit (2026-08-27).
- Include Chrome channel suffixes through a normalized family prefix
  (2026-08-27).

## Stages

### 1. Specify And Implement Policy

- Status: Completed
- [x] Record baseline and approved behavior contract
- [x] Implement pure target strategy policy
- [x] Add focused behavior checks
- Evidence: baseline and current `task check` passed; policy checks cover exact,
  normalized, Chrome-family, unrelated, and missing bundle identities.

### 2. Reconcile Durable Documentation

- Status: Completed
- [x] Update product/architecture/test contracts and release notes
- Evidence: product, architecture, security/privacy, test plan, README, and
  changelog describe the clipboard-preferred compatibility policy.

### 3. Validate And Install Candidate

- Status: Completed
- [x] Run `task check`
- [x] Review diff and privacy boundaries
- [x] Commit and push feature branch
- [x] Package, install, launch, and verify candidate
- [x] Exercise a harmless live Chrome web-field paste path
- [x] Complete the real ChatGPT macOS composer dictation smoke test
- Evidence: implementation commit `60b10a2` and release-preparation commit
  `46f2075` pushed; versioned candidate DMG verification passed;
  `/Applications/BabbelStream.app` ran version `0.4.3`, commit `46f2075`;
  Computer Use pasted `BabbelStream candidate paste check` into the focused
  YouTube search field without submission, then removed it and closed the
  temporary tab. Christian confirmed the real ChatGPT dictation appeared as an
  unsent draft on 2026-08-27.

## Validation Matrix

| Check | Baseline | Current/final | Evidence |
| --- | --- | --- | --- |
| Canonical checks | Passed | Passed at candidate; final rebuild blocked by local toolchain mismatch | `task check`: behavior checks passed before candidate packaging; final rerun found Swift 6.3.3 paired with a Swift 6.3.2 SDK, while the already-built behavior suite still passed with the normal system temp path |
| Focused checks | Existing target guard passed | Passed | `TextInsertionStrategyPolicy` coverage in `BabbelStreamChecks` |
| Build/package | Existing v0.4.2 installed | Passed | verified DMG; versioned candidate `0.4.3` / `46f2075` running from `/Applications` |
| Manual smoke | Failure reproduced by user | Passed | Chrome clipboard path and real ChatGPT unsent-draft dictation passed |
| Diff/privacy review | Clean baseline | Passed | `git diff --check`; no data, permission, provider, or retention change |
| Clean tree | Clean | Passed at candidate build | clean `46f2075` before packaging |

## Release Evidence

- Release commit: commit referenced by `v0.4.3`
- Main commit: same commit as `v0.4.3`
- Annotated tag: `v0.4.3`
- Versioned candidate artifact/checksum: `dist/BabbelStream-0.4.3.dmg`,
  `2be187f86dcc5bcb5d4b30b07a9a83da24d35ab9dbac2e9c66a71d03e4d1326e`
- Installed/deployed version and commit: validated candidate `0.4.3`, `46f2075`;
  source behavior matches the final release commit, which changes only release
  documentation after candidate packaging
- Running/health verification: PID resolved to
  `/Applications/BabbelStream.app/Contents/MacOS/BabbelStream`

## Current Blocker

Fresh builds are temporarily blocked by the locally mismatched Apple Swift
compiler and SDK. This does not block publication of the already built, checked,
and smoke-tested `0.4.3` candidate.

## Next Action

None. The feature is released; remaining project candidates live in
`docs/implementation-plan.md`.

## Closeout

- [x] Durable specs match shipped behavior.
- [x] Validation evidence is complete and truthful.
- [x] Human smoke gate passed.
- [x] Main/tag and the installed app version match the approved release level;
  the installed build metadata remains the validated candidate commit.
- [x] Working tree is clean at publication.
- [x] Tracker moved from active to archive.
