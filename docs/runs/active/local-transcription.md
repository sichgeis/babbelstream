# Local Transcription Implementation Run

## Outcome And Baseline

Deliver the approved local dictation flow through a clean 0.6.0/build 12
Parakeet-only pilot candidate. Main baseline is clean pushed
`efce34d7b2a208b8a1036c0e39dd78704053ba56`; refreshed divergence 0/0.
Branch: `codex/local-transcription`. The existing untracked feature spec was
created by this conversation; no unrelated user edits were present. Required
public Git identity was verified before work.

## Authority And Gates

Maintainer approved the three-model direction and autonomous implementation on
2026-10-28. Later they explicitly chose: prepare Parakeet first; defer Qwen and
Granite builds. Authorized: pinned dependencies/model metadata, synthetic model
preparation, code/docs/checks, feature commits/pushes and candidate packaging.
No private content, API credential, microphone, system clipboard, production
installation, main/tag or release publication is authorized/claimed here.
Human microphone/Slack smoke remains the next release gate.

## Decisions

- Apple M5 / 16 GiB host. Native dependencies require macOS 14; an independent
  bundled helper preserves the main application's macOS 13 remote support.
- Pin FluidAudio `2faffc237b7b78ae80d938c52cf91700d6709bc5` without TTS,
  diarization or NeMo normalization traits; include upstream license/attribution.
- MLX spike confirmed missing `metal` compiler. No Xcode/system installation or
  toolchain setting was changed. Deferred full-runtime source is opt-in and not
  claimed built or shippable; default capabilities/downloads enable only Parakeet.
- Model catalog pins immutable public revisions, exact lengths and SHA-256.
  No runtime catalog query or silent update. No weight files enter Git/DMG.
- Native loading uses exact local-directory APIs under OS network denial.
  Upstream console output is suppressed; bounded private result pipe; process
  kill on cancellation. One cold helper invocation per request; no background daemon.
- Local mode bypasses keys, cloud cleanup, Mini hedge and personal fallback.
  Remote settings persist. Unknown saved choices fail closed rather than redirect.
- Model setup/removal and dictation exclude one another. Interrupted UUID staging
  is cleaned only on the next explicit setup. Corrupt assets remain removable.

## Stages

1. Runtime feasibility — complete for Parakeet; MLX builds explicitly deferred.
2. Backend settings/coordinator — complete; fixture routing/snapshot/recovery/cancel checks pass.
3. Verified model management/native inference — complete for Parakeet; real synthetic integration passes.
4. Settings/onboarding/HUD/docs — complete; native minimum-size preview inspected.
5. Final canonical checks/feature push/candidate packaging — in progress.
6. Human microphone/Slack acceptance and final release — pending, separately gated.

## Validation Evidence

| Check | Result |
| --- | --- |
| Baseline task check | Pass with normal developer-cache access; sandbox initially denied module-cache writes |
| Actual Parakeet helper | Debug and optimized builds pass with existing CLT framework-search warnings |
| MLX spike | Fails on missing Metal compiler; maintainer explicitly deferred these builds |
| Fixture checks | Pass: three manifests, download integrity, traversal/symlink protection, cancellation, settings persistence, unknown selection, no keys/cloud, operation snapshots, Last Draft and recovery |
| Actual model setup | Pinned 632 MB Parakeet download, hash verification and native preparation pass in disposable temporary storage |
| Native English | Synthetic system speech yields text; optimized helper additionally checks an expected fixture word; text discarded |
| Native German | Synthetic system speech passes an expected-word assertion; text discarded |
| Network boundary | Native preparation/inference run under sandbox-exec with network denied |
| Public hygiene | Source and optimized helper scans pass; no model weights/audio in repository |
| Native UI | Minimum-size local Provider pane, download confirmation/cancel and disabled Qwen download inspected through CUA in fixture-only preview; preview closed |
| Full canonical final check | Pass after final code changes; app, executable checks, native helper and all tooling fixtures pass |
| Candidate package | Pending clean implementation commit |
| Real microphone / Slack | Not run; human gate |

Synthetic voices are not real speech-quality acceptance. Mixed-language technical
accuracy, long-form peak memory, latency with other apps open, other-host layout
and real permission/editor behavior remain unproven. No installed-app version was
changed or inspected; the daily installation is untouched.

## Release Evidence

Candidate target: 0.6.0/build 12. Final release/tag/main publication: none.
Candidate source commit, checksum and package validation will be recorded after
packaging from the clean implementation commit.

## Current Blocker

None for the approved Parakeet pilot. Deferred MLX builds require Metal tooling
and separate native/resource/license/performance validation.

## Next Action

Commit/push the validated implementation and package the clean candidate.
