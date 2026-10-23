# Clipboard-Only Insertion Implementation Run

## Outcome And Baseline

Implement the approved clipboard-only contract without installation or release.
- Baseline: clean main, a9c55479efc6a213d575b79db78c78cc12573c76, matching origin/main; VERSION 0.4.5.
- Branch: codex/clipboard-only-insertion.
- Spec: docs/features/clipboard-only-insertion/spec.md.
- Authority: the maintainer, 2026-10-23, explicit clearly scoped implementation request. Feature commits/pushes allowed; no installation, main/tag, provider/microphone or private content access.

## Decisions

- Remove AX writes and application routing entirely; retain legacy archive enum only for safe historical decoding/export.
- Keep existing paste event sequence, timing and safety guards.
- Document direct insertion as deferred, unapproved work.

## Stages

1. Contract and durable specification reconciliation: completed.
2. Implementation and fixture regression checks: completed.
3. Partial validation and diff review: completed; feature commit/push recorded in Git. Full build/native smoke pending.

## Validation Evidence

- Baseline task check attempted in this chat, including normal cache access: failed because SwiftUIMacros.StateMacro plugin is unavailable. Full application validation remains blocked; no toolchain modification authorized.
- Current normal-cache `task check`: failed at SettingsView.swift with the same missing SwiftUIMacros.StateMacro plugin; core sources compiled before the UI failure.
- Isolated executable suite: PASSED, “BabbelStream behavior checks passed.” Compiled all current BabbelStreamCore sources, actual AppState.swift + AppRuntime.swift as a testable application module, then all existing BabbelStreamChecks sources. Excluded SwiftUI window sources, app bootstrap and launcher; no second app instance or OS adapter actions. This validates modified core/coordinator behavior, not a full app build or native paste.
- Reproduction driver: `/private/tmp/check-clipboard-only.py`; evidence/build log: `/var/folders/wl/8mwrbcz97672llskmv1zrpww0000gn/T/babbelstream-clipboard-checks-xcuo_7we/build.log`. Temporary artifacts may expire. Driver uses swiftc with a temporary module cache, Swift 6, emits core/application modules then links/runs all checks with DYLD_LIBRARY_PATH pointing to those fixture modules.
- Checks exercise uniform per-target clipboard delivery; contention including app changes; target changes before/during preparation; cancellation; missing permission; missing target; clipboard/event failure; legacy archive decoding; existing coordinator/provider/recovery suite.
- Diff review: `git diff --check` passed. No live AX setter, field-query or strategy-policy references remain in Sources. Legacy archive outcome retained only for old entries and fixture compatibility.
- Manual native delivery: not run. No packaging, install, version change, main/tag or release.

## Current Blocker

Full app build: selected Command Line Tools SDK cannot load SwiftUIMacros.StateMacro.

## Next Action

Restore a working SwiftUI build environment and rerun `task check` before candidate packaging and authorized native smoke testing.
