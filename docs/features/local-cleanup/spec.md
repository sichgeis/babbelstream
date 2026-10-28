# Local Cleanup Specification

## Status
Approved for autonomous implementation and local candidate installation on 2026-10-28.
The maintainer selected Qwen3.5-4B with a downloadable model. Final main/tag/public
publication remain gated by a human smoke test and release direction.

Implemented in 0.6.0/build 13 candidate (`ad06130`); human cleanup smoke pending.

## Problem And Outcome
Local speech currently produces raw text. Offer optional light cleanup on this
Mac, preserving German, English, mixed speech, personal dictionary hints and the
speaker's meaning, without API keys or a separate server application.

## Research And Alternatives
Use pinned llama.cpp (MIT) with a Q4_K_M GGUF of Qwen3.5-4B (Apache-2.0).
Native macOS APIs do not load these weights; the small isolated C++ helper is
justified by the selected model. Embedded Metal sources compile through the
runtime API, avoiding the absent standalone Metal compiler. Ollama adds a separate
installation and service; Apple Foundation Models requires enabled Apple
Intelligence and does not provide the selected model. MLX remains deferred.
Sources: https://github.com/ggml-org/llama.cpp and
https://huggingface.co/unsloth/Qwen3.5-4B-GGUF.

## Scope And Workflow
- One optional cleanup model, separate from the speech picker. Download disclosure
  shows source, 2.74 GB size and license; confirm, progress, cancel and remove reuse
  the existing verified private model store. Pin immutable revision, size and SHA.
- Local cleanup defaults off. Explicitly download, prepare, enable and Apply.
  It can follow local or remote transcription; selecting it overrides cloud cleanup
  and never falls back to a cloud cleaner. Inactive remote preferences survive.
- Existing remote cleanup behavior and migration stay unchanged when local cleanup
  is off. Local transcription never activates cloud cleanup.
- The settings snapshot owns the entire operation. Speech helper exits before
  cleanup starts, bounding resident model memory. Model management and dictation
  exclude each other. Removal requires confirmation and preserves other data.
- Cleanup uses the existing conservative prompt and capped dictionary. The fixed
  Qwen ChatML template ends with an empty thinking section (non-thinking mode).
  No vision projector, reasoning UI, arbitrary model import or resident daemon.

## Invariants And Failure Contract
Transcript/prompt travel through private stdin, never process arguments or files.
Native logs are disabled; only final text travels through stdout. Network is denied
for the entire helper process. No new permission, history, telemetry or key access.
Model files remain until removal; audio/recovery/archive ownership stays unchanged.
Context is bounded to 8192 tokens, output to 4096 tokens, request to 128 KiB and
runtime to 180 seconds. Oversized input or incomplete/empty output fails rather
than silently truncating. Cancellation kills the owned child and prevents delivery.
Cleanup failure delivers raw text with a visible warning and retains stopped audio
for retry. No answer, translation, summary or commands in dictated content; never
Enter or auto-send. Learned model output still requires human review.

## Acceptance And Validation
Canonical `task check`: fixture-only settings migration, download integrity,
coordinator local success/failure/cancellation/snapshots and no cloud/key route.
Explicit synthetic inference checks English, German, mixed text, numbers, negation,
identifiers and dictated requests under network denial; record runtime/memory.
Candidate requires clean source, optimized helpers, licenses, privacy/signature
checks, installation verification and truthful evidence.

## Manual Smoke
Download and enable local cleanup in Provider Settings, Apply, then dictate harmless
English/German/mixed phrases with filler, punctuation, numbers and technical names.
Confirm cleanup preserves meaning, nothing is sent, and cancellation/retry still
works. Human microphone quality acceptance remains required before final release.

Local cleanup also enforces explicitly taught dictionary spellings after inference.
Only entries admitted by the existing prompt budget participate. Literal whole-phrase
matching is case-insensitive, longest-first and non-cascading; URL/path/email tokens
are protected. This addresses small-model failure to copy preferred spelling.
