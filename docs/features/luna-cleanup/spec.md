# GPT-6 Luna cleanup

## Status

Released in 0.6.1 on 2026-11-20. The
[implementation run](../../runs/archive/luna-cleanup.md) records validation.

## Problem and outcome

GPT-4o mini's dated snapshot is scheduled for removal on January 14, 2027.
GPT-6 Luna is the [recommended replacement](https://developers.openai.com/api/docs/deprecations).
Use Luna with reasoning off for fast, conservative transcript cleanup.

## Research and alternatives

The configured proxy returned valid cleanup text in five of five synthetic
requests per model. Median complete-response times were 822 ms for GPT-4o
mini, 968 ms for GPT-5.6 Luna and 870 ms for GPT-6 Luna, with reasoning disabled
on both Luna models.
[OpenAI documents](https://developers.openai.com/api/docs/models/gpt-6-luna)
`none` as an explicit reasoning setting and Chat Completions as a supported
endpoint. The choice keeps the existing endpoint contract.

## Accepted scope and behavior

- New settings and the fixed personal OpenAI profile default to `gpt-6-luna`.
- On first upgrade, the exact saved aliases `gpt-4o-mini` and
  `openai/gpt-4o-mini` migrate to the matching Luna aliases. The migration
  marker lets later explicit model selections, including rollback, persist.
  Custom IDs, endpoint paths and provider origins retain their saved values.
- Both Luna IDs send `reasoning_effort: "none"` on the existing Chat Completions
  request. Cleanup has its own model ID, independent of transcription routing.
  On the official OpenAI origin, leave temperature at the provider default.
  Keep `temperature: 0` on compatible proxies and for other models.
- The system prompt already scopes edits to the JSON transcript, preserves
  code-switching and treats dictated instructions as text. The revised Luna
  prompt preserves those rules and explicitly protects negation, uncertainty,
  measurements and repetitions used for emphasis. Dictionary entries apply
  only as matching corrections. The user message remains the one-field JSON payload.
- The existing cleanup result, raw-transcript fallback and recovery behavior
  apply when Luna is unavailable. The local Qwen cleanup path uses its existing
  prompt and model.

## Data, privacy and permissions

Cleanup sends the transcript and bounded dictionary hints to the already
configured destination. Direct-personal cleanup and the opt-in fallback use
their existing official OpenAI profile. Model compatibility and pricing for
other proxy deployments depend on the operator's alias mapping. The change
adds no credentials, dependencies, storage, permissions or destinations.

## Acceptance and smoke test

1. Verify new, legacy, edited and custom settings with disposable preferences.
   Inspect both Luna requests and one custom model using a loopback fixture.
   Stub the official OpenAI origin and verify that Luna sends reasoning off
   with no temperature override.
2. Use synthetic transcripts on the configured proxy to check English,
   German, mixed phrasing, numbers, negation, dictated instructions, and a
   matching dictionary correction.
3. On the candidate, verify the saved cleanup ID in Provider settings and
   dictate a harmless German-English message with a technical term into an
   unsent draft. Check that the text is lightly edited and arrives once.

Canonical validation uses `task check`. The maintainer's request covers
implementation and feature-branch candidate packaging. Installation and
release follow the existing gates.
