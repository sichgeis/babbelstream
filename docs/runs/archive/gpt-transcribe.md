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
- Persist a per-installation standard/OpenAI-namespace routing choice so the
  official public OpenAI API and the Hypatos LiteLLM proxy can use the same
  logical model picker.

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
- Keep official model IDs as the logical settings value and resolve the wire ID
  only while constructing transcription multipart fields. This preserves
  `gpt-transcribe` language-field behavior under both routing modes.
- Migrate the known Hypatos development/production proxy hosts to LiteLLM
  `openai/` routing only when no routing choice exists; persist the result so
  later URL changes do not silently alter routing.

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

- Status: Completed
- [x] Replace free text with the three-option model menu and add deterministic policy checks.
- [x] Update the feature contract and durable docs.
- [x] Run canonical and visual Provider Settings validation.
- [x] Commit/push, merge/push `main`, then build/install/launch and verify from the clean main commit.
- Evidence: `task check` passed; `git diff --check` passed; deterministic
  Provider Settings launch rendered the menu-style control cleanly with
  `gpt-transcribe` selected at the default window size. Temporary screenshot:
  `/private/tmp/babbelstream-picker-screenshots/provider-settings.png`.
  Feature commit `2f6b507` was pushed, fast-forwarded to `main`, validated there,
  packaged, installed, launched, and verified from `/Applications`.

### 5. Real-Provider Empty-Language Fix

- Status: Completed
- [x] Record the HTTP 400 real-provider smoke-test failure.
- [x] Trace the request to an invalid empty `languages[]` multipart field.
- [x] Omit language fields when the setting is blank and add regression coverage.
- [x] Run checks, commit/push, merge/push `main`, and reinstall.
- Evidence: 2026-07-28 diagnostics show a 2.5-second recording was uploaded and
  rejected with HTTP 400 in 192 ms while `gpt-transcribe` was selected and the
  language setting was blank. Current OpenAI guidance says language hints are
  optional and rejects invalid language codes. `task check` and
  `git diff --check` passed; fix commit `655a470` was pushed to the feature
  branch and `main`, packaged, installed, launched, and verified.

### 6. Proxy Deployment Diagnosis

- Status: Completed
- [x] Query the authenticated proxy model list without exposing the credential.
- [x] Submit one generated one-second silent-audio request with
  `gpt-transcribe`.
- [x] Record the sanitized provider result and remove all temporary diagnostic
  files.
- Evidence: `/v1/models` returned HTTP 200 and listed
  `openai/gpt-4o-transcribe`, `openai-flex/gpt-4o-transcribe`, and their Mini
  equivalents, but no `gpt-transcribe` model group. The synthetic request
  returned the same 711-byte HTTP 400 as BabbelStream: LiteLLM reported no
  healthy deployments and no fallback for `gpt-transcribe`. No user audio,
  transcript, or provider key was persisted or printed.

### 7. Per-Installation Model Routing

- Status: Completed
- [x] Record the personal official-OpenAI and work LiteLLM installation contract.
- [x] Add standard and LiteLLM `openai/` routing with a persisted Settings picker.
- [x] Route both primary and Mini wire IDs while preserving logical model behavior.
- [x] Add the one-time Hypatos-host migration, effective-ID UI/diagnostics, checks,
  and durable documentation.
- [x] Review, commit/push, merge/push `main`, package, install, launch, and verify.
- Evidence: authorized synthetic-silence A/B smoke test established
  `openai/gpt-transcribe` succeeds through the existing `openai/*` deployment
  while bare `gpt-transcribe` fails. Initial `task check` passed after the
  routing implementation and regression coverage. Deterministic Provider
  Settings launch showed the existing work proxy migrated to
  `LiteLLM (openai/ model prefix)` with its explanatory copy at the default
  window size; temporary cropped screenshot:
  `/private/tmp/babbelstream-routing-screenshots/provider-settings-cropped.png`.
  Feature commit `ce1a0f8` was pushed, fast-forwarded to `main`, and pushed.
  The clean `0.4.1` bundle was packaged, installed, launched from
  `/Applications`, and verified with matching installed/packaged executable
  hashes. The work installation now stores `gpt-transcribe` plus
  `litellm-openai-namespace`, producing effective model ID
  `openai/gpt-transcribe`.

## Validation Matrix

| Check | Baseline | Current/final | Evidence |
| --- | --- | --- | --- |
| Canonical checks | Passed | Passed | `task check`; baseline and final routing checks passed with normal developer cache access |
| Focused checks | Covered by runner | Passed | Picker options, defaults, model/routing migrations, selection persistence, both effective primary/Mini IDs, language fields, response metadata |
| Build/package | Build passed | Passed | `task check`; signed app and verified `BabbelStream-0.4.1.dmg` |
| Manual smoke | Not run | Provider Settings visual check and installed process verification passed; real dictation remains manual | Deterministic Provider-tab launch, screenshot, installed settings, and process path |
| Diff/privacy review | Clean baseline | Passed | No new data, destination, permission, retention, or logs; `git diff --check` passed |
| Clean tree | Clean | Clean after tracker evidence commit | `main` synchronized with `origin/main` |

## Release Evidence

- Feature implementation commit: `39ab8ac`
- Release commit: not requested
- Main feature commits: `2f6b507` (model picker) and `ce1a0f8`
  (per-installation routing), both fast-forwarded and pushed
- Annotated tag: not authorized
- Artifact/checksum: `dist/BabbelStream-0.4.1.dmg`;
  SHA-256 `e8651ce51983bcb4630a8761729a1da5accce0eb5aa8942a5add10f6e888b215`
- Installed/deployed version and commit: `0.4.1` / `ce1a0f8`
- Installed signing: `BabbelStream Local Code Signing`; the self-issued local
  certificate retains the documented strict trust warning
- Running/health verification:
  `/Applications/BabbelStream.app/Contents/MacOS/BabbelStream` running as PID
  `53070`; installed and packaged executable SHA-256 hashes both equal
  `3b64d7d150fadec363d589df42d82c8eebddaa17dfc3f32409c1f03025a37812`.
  Saved work settings are `gpt-transcribe` plus
  `litellm-openai-namespace`.
- Recovery backup: previous app retained temporarily under
  `/private/tmp/babbelstream-routing-install-backup.Wo8W02/`

## Current Blocker

None. The proxy's existing `openai/*` deployment provides a compatible app-side
routing path without changing the company-owned proxy. The remaining dual-
destination smoke coverage is transferred to the personal OpenAI fallback
feature run.

## Next Action

Complete the real-provider primary/fallback matrix in
`docs/features/personal-openai-fallback/spec.md` after that feature is built.

## Closeout

- [x] Durable specs match implemented behavior.
- [x] Automated validation evidence is complete and truthful.
- [ ] Human smoke gate passed or was explicitly waived; transferred to the
  personal OpenAI fallback run.
- [x] Main and local installation match the approved level; no tag was authorized.
- [x] Working tree is clean after the tracker evidence commit.
- [x] Tracker moved from active to archive; the remaining human evidence is
  tracked by the follow-up feature.
