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
4. Clean candidate, feature push, installation verification: completed.
5. Human smoke: accepted by the maintainer on 2026-10-28 for fully local German technical dictation.

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

## Release Evidence
- Clean app source: `ad061304b44f8ede3044dd1fd8dd5b7b628cd36f`, pushed on the feature branch.
- Candidate: `dist/BabbelStream-0.6.0-candidate.13-ad06130.dmg` plus portable checksum.
- SHA-256: `00d02842d7e32a32f101592c32b995c04a32cdf8252cd8332aa8876d7127c4f7`.
- Installed/running: Applications, version 0.6.0, build 13, source `ad06130`, candidate/ad-hoc.
- Exact signed packaged cleanup helper passes all six synthetic checks; packaged
  Parakeet passes synthetic German again. All 11 mounted app payload files,
  attributes, source/history and both stripped native binaries pass privacy scans.
- DMG integrity/checksum, app and helper signatures, installed/source byte equality pass.
- Previous build 12 app preserved under ignored `dist/rollback/` before replacement.
- Verified weights copied into private managed storage with exact hash/size,
  preparation under network denial and ready marker; only the new model directory added.
- Installed UI reports Prepared; enabled local cleanup and explicitly Applied.
  Active cleanup destination is On this Mac / Qwen3.5-4B. Existing remote speech
  stays selected. No real provider request, microphone capture or paste was made.
- Prior human English/German speech outcomes are retained, but the currently
  selected remote backend means they do not independently prove local ASR quality.
- Installed Diagnostics confirms exact version/commit. General reports microphone
  Not requested and Accessibility Not allowed for this rebuild. Permission controls
  are left visible; no grants, TCC resets or quarantine changes were performed.
- Temporary installer QA initially stopped before replacement because this Python
  lacks xattr bindings; native xattr inspection then passed and installation completed.
- On 2026-10-28 the maintainer reported a successful real German technical
  dictation using Parakeet Ultra transcription and Qwen3.5-4B cleanup entirely
  on this Mac, and declared the smoke test complete. Only the outcome is retained;
  no dictated content is copied into evidence. This supersedes the earlier
  install-time remote selection; no expanded editor/long-form matrix is inferred.
- The maintainer requested the remaining steps to finalize an actual release on
  main. Main/tag/public publication have not yet been performed.

## Blocker
No implementation blocker. The maintainer accepted the local smoke; release preparation remains.

## Next Action
Prepare the final 0.6.0 release metadata and incremented build from the accepted feature branch.

## Implementation Closeout

Implementation and human local smoke are accepted. The maintainer explicitly
authorized local 0.6.0 finalization on 2026-10-28; remaining main/tag/build/install
execution is owned by `../active/release-v0.6.0.md`. Public installer and Homebrew
publication remain gated by the second-Mac test. This implementation run is closed;
historical pending-release statements above describe their original checkpoints.
