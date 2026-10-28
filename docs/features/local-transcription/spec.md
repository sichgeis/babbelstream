# Local Transcription Specification

## Status

- State: Released locally in 0.6.0/build 14; public rollout awaits the second-Mac test.
- Owner: maintainer.
- Approved: 2026-10-28 conversation, autonomous implementation through candidate.
- Follow-up: maintainer selected Parakeet first and explicitly deferred Qwen/Granite
  builds because this CLT installation lacks the Metal compiler.
- Tracker: ../../runs/archive/local-transcription.md.

## Problem And Desired Outcome

Users without a remote API key can explicitly download a model, select On this
Mac, and dictate an unsent draft offline. German, English and mixed technical
speech remain required. Speech generation and voice cloning are not dictation.

## Research And Alternatives

The inspected host is Apple M5 with 16 GiB unified memory. Three curated choices
are retained, with exactly one enabled in the first pilot:

| Model | Artifact / approximate bytes | Runtime and decision |
| --- | --- | --- |
| Parakeet Ultra 0.6B | FluidInference/parakeet-ultra-coreml; 632 MB | Native FluidAudio/Core ML, enabled fast-default candidate; 25 European languages; CC-BY-4.0 |
| Qwen3-ASR 1.7B 8-bit | mlx-community/Qwen3-ASR-1.7B-8bit; 2.47 GB | Native MLXAudioSTT; deferred build; 30 languages plus Chinese dialects; Apache-2.0 |
| Granite Speech 5.0 2B | ibm-granite/granite-speech-5.0-2b; 5.05 GB | Experimental MLXAudioSTT; deferred build; German/English plus four other transcription languages; Apache-2.0 |

Download size is not peak RAM. All choices need local memory/latency/quality
measurements; no universal ranking or real mixed-language acceptance is claimed.
Whisper remains a mature comparison baseline. A user-managed Python server adds
installation/process management, so the approved pilot uses native inference.

Primary references:
- https://huggingface.co/moondream/parakeet-ultra
- https://github.com/FluidInference/FluidAudio/blob/main/Documentation/ASR/ParakeetUltra.md
- https://huggingface.co/Qwen/Qwen3-ASR-1.7B
- https://huggingface.co/ibm-granite/granite-speech-5.0-2b
- https://github.com/Blaizzy/mlx-audio-swift

Optional local cleanup is now separately approved in `../local-cleanup/spec.md`.
That contract refines the original raw-text pilot below.

## Accepted Scope

- Explicit Remote / On this Mac selection. Existing installs remain Remote.
- Parakeet download/source/size/license disclosure and confirmation, progress,
  cancel, retry, verified staging, preparation, readiness and confirmed removal.
- Three catalog entries; unsupported-runtime choices disclose their limitation
  and cannot download or Apply. No silent substitution for a selected model.
- Local mode reads no API key, performs no cloud cleanup or fallback and runs
  no Mini hedge. Inactive remote settings and credentials remain intact.
- Preserve recording, Last Draft, insertion, optional archive and recovery rules.
- Optional local inference requires Apple Silicon/macOS 14+. Remote app keeps
  macOS 13 support. No system toolchain/OS setting is changed.

## Non-Goals

TTS/cloning, installing Python/Homebrew/Ollama/LM Studio/Xcode, cloud cleanup in
local mode, vocabulary hint integration in the first speech pilot,
background model updates/downloads, telemetry, new permissions or retention.

## User Workflow

1. Select On this Mac in Provider settings; this is a pending edit.
2. Select Parakeet Ultra and review the model/source/download size/license.
3. Confirm Download and Prepare. Show progress, then verification/preparation.
4. After preparation, Apply Settings explicitly; download alone never changes
   the active backend. Unsupported or unprepared models cannot be applied.
5. Dictate using the existing shortcut and receive an unsent draft.
6. Confirm removal while idle to remove only that model; redownload to reuse it.

## Interaction And State Contract

| State | Event | Result |
| --- | --- | --- |
| Not downloaded | Confirm download | HTTPS retrieval to private UUID staging directory |
| Downloading | Cancel/failure | No activation; clean staged files; Retry remains available |
| Downloaded | Verify | Check every expected file length and SHA-256 |
| Verified | Prepare | Load actual native model with network denied |
| Prepared | Apply | Save local backend/model selection; preserve remote settings |
| Applied local | Dictate | Verify files, spawn one local inference, no key/cloud |
| Applied local | Failure/cancel | No late paste; stopped audio remains in Failed Recordings |
| Prepared/corrupt | Confirm removal while idle | Remove only managed model directory |

## Domain Rules And Invariants

- Snapshot backend/model/settings per operation. Apply during recording affects
  only later operations. Model setup/removal is excluded during active work.
- Exactly one native helper invocation at a time; no model persists in a daemon.
- The helper loads afresh per invocation; cold-start cost must be measured.
- Never download during inference, never substitute a cloud backend after failure.
- No key read, remote connection test or cloud cleanup in applied local mode.
- Keep original focus/clipboard/cancellation safeguards and never press Enter.
- Recovery retry snapshots current saved settings and copies without auto-paste.
- Same-length model corruption is caught by hashing before inference.

## Edge Cases And Races

Missing assets or unavailable runtime block local start before microphone access.
Handle offline download, HTTP failure, transport downgrade, credential-bearing
redirect, unexpected bytes, corruption, cancellation, insufficient disk, failed
preparation, unknown persisted backend, settings changes and removal races.

Downloads may follow HTTPS redirects to the file CDN, without credentials/cookies.
A crash may leave UUID staging data; the next explicit setup cleans only owned
staging directories. Cleanup failure is reported instead of claiming removal.

## Data, Privacy, Security, And Permissions

- Explicit model download contacts huggingface.co and its HTTPS file CDN; disclose
  ordinary connection metadata. No audio/text/key is sent for model preparation.
- Pin immutable repository revisions, expected lengths and SHA-256 in source.
- Keep assets under Application Support/BabbelStream/Models with private staging.
  Verify then prepare before atomic activation. Never execute downloaded scripts.
- Native inference runs in a bundled process under an OS network-denial sandbox.
  Use exact local-directory SDK loaders; never pretrained/download APIs.
- Suppress all upstream console output. A bounded private pipe carries only the
  transcript or a reviewed error category; no transcript/path goes into logs.
- Cancellation kills native inference and discards output. Existing audio recovery
  ownership stays in the main app. No additional permission is requested.
- Models remain until explicit removal. Audio/transcript/archive policies are
  unchanged. Download management never clears recordings or other app data.

## Architecture Impact

- AppSettings persists backend/model separately from inactive remote preferences.
- LocalModelCatalog holds reviewed static artifact manifests; LocalModelStore
  stages, verifies, prepares, activates and removes managed assets.
- LocalModelController owns main-actor model operation state and exclusion.
- AppState routes locally before any key load and preserves coordinator recovery.
- BundledLocalSpeechRuntime owns bounded subprocess IO/cancellation. The helper
  is an independent macOS 14 package; the app's macOS 13 target stays unchanged.
- Pin FluidAudio without TTS, diarization or NeMo text-normalization traits.
  System APIs alone cannot execute these model weights, justifying the dependency.
- Deferred full runtime needs Metal build tools and separate license/resource/
  performance validation. Default packaging advertises Parakeet capabilities only.

## Error And Recovery Behavior

Missing/unprepared model blocks Apply/start. Corrupt or incomplete installed assets
can be removed even when readiness is false. Download/preparation failure leaves
saved backend untouched. Inference failure/cancellation preserves stopped audio;
retry copies on success. Last Draft survives later failures.

## Acceptance Criteria And Automated Validation

- No key is required/read for local dictation or retry.
- Zero cloud/hedge/cloud-cleanup requests; no late insertion after cancellation.
- Original backend snapshot survives settings Apply during recording.
- Corruption, traversal and canceled setup cannot activate assets.
- Exact native Parakeet load/inference passes on synthetic audio with network denied.
- Canonical task check includes the app, fixture checks, native Parakeet helper,
  release/helper tooling and public hygiene.
- Human German/English/mixed technical quality, memory and latency remain unclaimed
  until measured; synthetic speech is integration evidence only.

## Manual Smoke Test

After authorized candidate installation, select On this Mac, confirm download,
cancel/retry once, prepare, Apply, restart offline and dictate harmless English,
German and mixed technical phrases into Slack. Verify unsent drafts, Cancel,
Failed Recordings retry, Copy Last Draft and switching back to saved Remote mode.
Measure cold/warm 5/15/60-second and up-to-10-minute recordings with other apps open.

## Approval Gate

Authorized: implementation, dependency/model preparation with synthetic inputs,
checks, feature commits/pushes and clean candidate packaging. The maintainer
explicitly deferred Qwen/Granite builds. Stop before production installation,
real microphone/Slack testing, main integration, final tag and public release.

## Local Release Authority (2026-10-28)

The maintainer accepted the fully local Parakeet/Qwen smoke and explicitly
authorized main integration, annotated v0.6.0, final build and local installation.
Public GitHub release/assets and Homebrew updates await the second-Mac test.
Release evidence: `../../runs/archive/release-v0.6.0.md`.
