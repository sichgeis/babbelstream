# GPT Transcribe Migration Implementation Run

## Outcome

Move BabbelStream's default transcription integration to `gpt-transcribe` with
the documented request shape while preserving custom models and the Mini hedge.

## Baseline

- Base branch: `main`
- Base commit: `efe07110355a297a8ad021d5473009155bd7910d`
- Base pushed: yes
- Working tree: clean
- Implementation branch: `codex/gpt-transcribe`
- Version/release target: none

## Authority And Gates

- Approved spec: `docs/features/gpt-transcribe/spec.md` (approved by the 2026-07-28 request)
- Agent may proceed through: implementation, feature commit, and feature push
- Required human gates: real-provider microphone/language smoke test; separate approval for release candidate, main, and tag
- External systems/data explicitly authorized: official OpenAI documentation research and feature-branch push; no real transcription request

## Accepted Scope

- New default and former-default migration to `gpt-transcribe`.
- Model-aware `languages[]` versus `language` multipart fields.
- Checks and durable documentation.
- Preserve endpoint, response parser, prompt, Mini hedge, recovery, and privacy behavior.

## Non-Goals

- Realtime transcription, keyword UI, provider changes, new dependencies, release packaging, installation, main, or tags.

## Risks And Dependencies

- The configured LiteLLM endpoint may not yet expose `gpt-transcribe`; preserve recovery and require a real-provider smoke test.
- Official generated API reference model enums lag the current guide/model catalog; use the current GPT Transcribe model page and speech-to-text guide as the migration source.

## Decisions

- Keep `/v1/audio/transcriptions`, multipart upload, `response_format=json`, prompt, and top-level `text` parsing because the current guide documents them for `gpt-transcribe`.
- Migrate only the exact former default and preserve every other custom string.
- Keep `gpt-4o-mini-transcribe` as the bounded hedge because it remains documented and this migration does not introduce a new Mini replacement.

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

- Status: In progress
- [ ] Commit and push the feature branch.
- [ ] Provide the real-provider smoke test and stop before release actions.
- Evidence: Pending.

## Validation Matrix

| Check | Baseline | Current/final | Evidence |
| --- | --- | --- | --- |
| Canonical checks | Passed | Passed | `task check`; baseline and final passed with normal developer cache access |
| Focused checks | Covered by runner | Passed | Defaults, migration, custom preservation, request fields, response metadata |
| Build/package | Build passed | Build passed | `task check`; no package requested |
| Manual smoke | Not run | Required from user | Real provider/microphone/Slack |
| Diff/privacy review | Clean baseline | Passed | No new data, destination, permission, retention, or logs |
| Clean tree | Clean | Pending feature commits | `git status --short --branch` |

## Release Evidence

- Release commit: pending
- Main commit: not authorized
- Annotated tag: not authorized
- Artifact/checksum: not requested
- Installed/deployed version and commit: not authorized
- Running/health verification: manual provider smoke pending

## Current Blocker

None.

## Next Action

Commit and push the validated feature branch, then provide the real-provider smoke test.

## Closeout

- [ ] Durable specs match shipped behavior.
- [ ] Validation evidence is complete and truthful.
- [ ] Human smoke gate passed or was explicitly waived.
- [ ] Main/tag/deployment match the approved release level.
- [ ] Working tree is clean.
- [ ] Tracker moved from active to archive.
