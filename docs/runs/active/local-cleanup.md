# Local Cleanup Implementation Run

## Outcome And Authority
Implement approved Qwen3.5-4B local cleanup, verified download and installed candidate.
Contract: `docs/features/local-cleanup/spec.md`. Explicit autonomous implementation,
model download and local installation authorized; no main/tag/public publication.
Work paused on request before changes, resumed explicitly on 2026-10-28.

## Baseline
- Branch: `codex/local-transcription`, clean and pushed.
- Commit: `dd40d519263901202110343813d517b693f60c0a`.
- Feature branch: `codex/local-cleanup`.
- Candidate target: 0.6.0/build 13 or later.
- Baseline `task check` passed on resume; original paused check was canceled.

## Stages
1. Runtime/model verification: completed.
2. Settings, UI, coordinator and fixture checks: completed.
3. Synthetic native quality/memory, full checks and privacy review: completed.
4. Clean candidate, feature push, installation verification: pending.
5. Human smoke: pending.

## Decisions
One embedded text-only GGUF, no separate daemon. Sequential native helper lifetime.
Missing Xcode does not authorize installing Xcode or changing global tools.

## Evidence
Baseline canonical checks passed; fixture coordinator/local cleanup suite passed.
Native Metal source builds under Command Line Tools; static helper links only system
frameworks. Model revision/hash/size match its pinned public manifest. Network-denied
synthetic English/German/mixed/request/identifier checks pass with the stricter local
prompt. An initial prompt translated mixed text; this quality failure was diagnosed
with disposable synthetic-only tooling, never enabled in production logging.
Warm short-phrase native inference measured 1.66 seconds, maximum RSS 2,488,762,368
bytes and zero swaps; this excludes app/ASR memory and is not long-form certification.
Isolated native Provider preview inspected at 700x560, including scroll extremes,
fixed Apply footer and canceled 2.74 GB/Apache-2.0/source disclosure. No production
settings, microphone, keys or content were used. Preview closed afterwards.
Final canonical `task check` passes including both helpers, 25 installer fixtures,
release preflight and public hygiene fixtures. All six synthetic native checks pass,
including dictionary spelling. Explicit dictionary postprocessing is bounded by
the existing prompt context budget and tested against cascades/partial words/paths.
Source and unstripped optimized native helper privacy scans passed. No real
microphone content or user stores used for automated validation.

## Blocker
None.

## Next Action
Commit and push the clean candidate source, then package and verify build 13.
