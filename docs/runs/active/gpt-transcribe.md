# GPT Transcribe Migration Implementation Run

## Outcome

Move BabbelStream's default transcription integration to `gpt-transcribe` with
the documented request shape and a constrained model picker while preserving the
Mini hedge.

## Baseline

- Base branch: `main`
- Base commit: `efe07110355a297a8ad021d5473009155bd7910d`
- Base pushed: yes
- Working tree: clean
- Implementation branch: `codex/gpt-transcribe`
- Version/release target: none

## Authority And Gates

- Approved spec: `docs/features/gpt-transcribe/spec.md` (approved by the 2026-07-28 request)
- Agent may proceed through: implementation, feature commit/push, `main`
  merge/push, local build/install/launch, and installed-app verification
- Required human gates: real-provider microphone/language smoke test remains
  manual; annotated tag and public release remain unauthorized
- External systems/data explicitly authorized: official OpenAI documentation,
  GitHub branch/main pushes, and local `/Applications` installation; no real
  transcription request

## Accepted Scope

- New default and former-default migration to `gpt-transcribe`.
- Three-option primary-model picker with no free-text entry.
- Unsupported-value normalization and persistence of explicit supported selections.
- Model-aware `languages[]` versus `language` multipart fields.
- Checks and durable documentation.
- Preserve endpoint, response parser, prompt, Mini hedge, recovery, and privacy behavior.

## Non-Goals

- Realtime transcription, keyword UI, provider changes, new dependencies,
  annotated tags, or public release publication.

## Risks And Dependencies

- The configured LiteLLM endpoint may not yet expose `gpt-transcribe`; preserve recovery and require a real-provider smoke test.
- Official generated API reference model enums lag the current guide/model catalog; use the current GPT Transcribe model page and speech-to-text guide as the migration source.

## Decisions

- Keep `/v1/audio/transcriptions`, multipart upload, `response_format=json`, prompt, and top-level `text` parsing because the current guide documents them for `gpt-transcribe`.
- The initial transport migration preserved custom strings; the approved picker
  follow-up supersedes that behavior and normalizes unsupported values.
- Keep `gpt-4o-mini-transcribe` as the bounded hedge because it remains documented and this migration does not introduce a new Mini replacement.
- Present only the three approved model IDs in a menu and normalize unsupported
  saved values to the default so Settings cannot enter an invalid state.
- Record the migration once so a later explicit `gpt-4o-transcribe` selection
  survives restart.

## Stages

### 1. Research And Contract

- Status: Completed
- [x] Verify the current model ID, endpoint, request fields, response shape, and legacy model status in official OpenAI documentation.
- [x] Record accepted scope and migration behavior.
- Evidence: OpenAI GPT Transcribe model page, Speech-to-text guide, transcription OpenAPI endpoint, and deprecations page fetched 2026-07-28.

### 2. Implementation And Checks

- Status: Completed
- [x] Update defaults, settings migration, and multipart request policy.
- [x] Align provider probe/benchmark defaults, add focused behavior checks, and update durable docs.
- [x] Run canonical validation and review the diff.
- Evidence: `task check` passed; both Python provider helpers passed syntax parsing; `git diff --check` passed.

### 3. Feature Handoff

- Status: Completed
- [x] Commit and push the feature branch.
- [x] Provide the real-provider smoke test and stop before release actions.
- Evidence: implementation commit `39ab8ac`; branch `codex/gpt-transcribe` pushed to `origin`.

### 4. Constrained Model Picker And Local Installation

- Status: In progress
- [x] Replace free text with the three-option model menu and add deterministic policy checks.
- [x] Update the feature contract and durable docs.
- [x] Run canonical and visual Provider Settings validation.
- [ ] Commit/push, merge/push `main`, then build/install/launch and verify from the clean main commit.
- Evidence: `task check` passed; `git diff --check` passed; deterministic
  Provider Settings launch rendered the menu-style control cleanly with
  `gpt-transcribe` selected at the default window size. Temporary screenshot:
  `/private/tmp/babbelstream-picker-screenshots/provider-settings.png`.

## Validation Matrix

| Check | Baseline | Current/final | Evidence |
| --- | --- | --- | --- |
| Canonical checks | Passed | Passed | `task check`; baseline and final passed with normal developer cache access |
| Focused checks | Covered by runner | Passed | Picker options, defaults, migration, selection persistence, validation, request fields, response metadata |
| Build/package | Build passed | Build passed | `task check`; no package requested |
| Manual smoke | Not run | Provider Settings visual check passed; real dictation remains manual | Deterministic Provider-tab launch and screenshot |
| Diff/privacy review | Clean baseline | Passed | No new data, destination, permission, retention, or logs; `git diff --check` passed |
| Clean tree | Clean | Pending tracker closeout commit | `git status --short --branch` |

## Release Evidence

- Feature implementation commit: `39ab8ac`
- Release commit: not requested
- Main commit: authorized, pending
- Annotated tag: not authorized
- Artifact/checksum: not requested
- Installed/deployed version and commit: authorized, pending
- Running/health verification: manual provider smoke pending

## Current Blocker

None.

## Next Action

Run canonical and visual picker validation, then commit/push, merge/push `main`,
and install/verify the clean main build.

## Closeout

- [x] Durable specs match implemented behavior.
- [x] Automated validation evidence is complete and truthful.
- [ ] Human smoke gate passed or was explicitly waived.
- [ ] Main/tag/deployment match the approved release level.
- [ ] Working tree is clean.
- [ ] Tracker moved from active to archive.
