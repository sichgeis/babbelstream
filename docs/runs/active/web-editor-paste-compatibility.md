# Web Editor Paste Compatibility Implementation Run

## Outcome

Deliver and locally install a validated candidate that pastes reliably into
known web-backed editors by preferring the existing clipboard plus Command+V
path.

## Baseline

- Base branch: `main`
- Base commit: `4c0cece1acab0da6a28d61b21b66e254e01df921`
- Base pushed: yes (`origin/main` matched)
- Working tree: clean
- Implementation branch: `codex/web-editor-paste-compatibility`
- Version/release target: local `0.4.2` feature-branch candidate; no final tag

## Authority And Gates

- Approved spec: `docs/features/web-editor-paste-compatibility/spec.md` (Approved)
- Agent may proceed through: implementation, feature push, candidate install
- Required human gates: ChatGPT macOS composer smoke test before main/tag
- External systems/data explicitly authorized: harmless local/browser UI probes;
  no real message submission

## Accepted Scope

- Add a pure clipboard-preferred target policy for Mail, Outlook,
  ChatGPT/Codex, Chrome-family, and Arc bundle identities.
- Preserve direct-first behavior for Slack, native, unknown, and missing bundle
  identities.
- Update focused checks and durable insertion/test documentation.

## Non-Goals

- No DOM/browser extension integration, new permissions, new dependencies,
  auto-send behavior, `main` merge, or release tag.

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

- Status: In progress
- [x] Run `task check`
- [x] Review diff and privacy boundaries
- [x] Commit and push feature branch
- [x] Package, install, launch, and verify candidate
- [x] Exercise a harmless live Chrome web-field paste path
- Evidence: implementation commit `60b10a2` pushed; DMG verification passed;
  `/Applications/BabbelStream.app` runs version `0.4.2`, commit `60b10a2`;
  Computer Use pasted `BabbelStream candidate paste check` into the focused
  YouTube search field without submission, then removed it and closed the
  temporary tab.

## Validation Matrix

| Check | Baseline | Current/final | Evidence |
| --- | --- | --- | --- |
| Canonical checks | Passed | Passed | `task check`: behavior checks passed |
| Focused checks | Existing target guard passed | Passed | `TextInsertionStrategyPolicy` coverage in `BabbelStreamChecks` |
| Build/package | Existing v0.4.2 installed | Passed | verified DMG; candidate `0.4.2` / `60b10a2` running from `/Applications` |
| Manual smoke | Failure reproduced by user | Partial | Chrome clipboard path passed; ChatGPT real dictation pending |
| Diff/privacy review | Clean baseline | Passed | `git diff --check`; no data, permission, provider, or retention change |
| Clean tree | Clean | Passed at candidate build | clean `60b10a2` before packaging |

## Release Evidence

- Release commit: `60b10a2` (feature candidate)
- Main commit: not authorized
- Annotated tag: not authorized
- Artifact/checksum: `dist/BabbelStream-0.4.2.dmg`,
  `b9bdb8f230234df825c288f0fe76e76fc7e3db15ff7152b2848243f8eb92343b`
- Installed/deployed version and commit: `0.4.2`, `60b10a2`
- Running/health verification: PID resolved to
  `/Applications/BabbelStream.app/Contents/MacOS/BabbelStream`

## Current Blocker

The ChatGPT/Codex composer is protected from Computer Use, so its real dictation
smoke test requires the user.

## Next Action

Dictate one harmless phrase into the ChatGPT macOS composer and confirm that it
appears as an unsent draft.

## Closeout

- [ ] Durable specs match shipped behavior.
- [ ] Validation evidence is complete and truthful.
- [ ] Human smoke gate passed or was explicitly waived.
- [ ] Main/tag/deployment match the approved release level.
- [ ] Working tree is clean.
- [ ] Tracker moved from active to archive.
