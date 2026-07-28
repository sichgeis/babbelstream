# GPT Transcribe Migration Specification

## Status

- State: Implemented
- Owner: Christian
- Last approved: 2026-07-28 conversation request
- Related ADRs/issues: none

## Problem

BabbelStream defaults to `gpt-4o-transcribe`, while OpenAI now recommends
`gpt-transcribe` for high-accuracy file transcription. A model-string-only
change would be incomplete because the new model replaces the singular
`language` request field with `languages[]`.

## Desired Outcome

New and existing default configurations use `gpt-transcribe` with its documented
multipart request shape, while custom model strings and the bounded Mini hedge
remain compatible.

## Research And Alternatives

| Option | Benefits | Costs/Risks | Decision |
| --- | --- | --- | --- |
| Change the model string only | Smallest diff | Sends the wrong language field for the new model and does not reliably move existing saved settings | Rejected |
| Add model-aware request fields and a narrow settings migration | Matches the current OpenAI contract and preserves custom configurations | LiteLLM deployments must expose the new model and field | Accepted |
| Replace the provider flow with Realtime transcription | Could stream live microphone audio | Material architecture, latency, and privacy change outside this request | Rejected |

## Accepted Scope

- Default primary transcription to `gpt-transcribe`.
- Migrate a saved model equal to the former default `gpt-4o-transcribe`.
- Preserve all other custom model strings.
- Send a configured single language hint as `languages[]` for `gpt-transcribe`.
- Keep the singular `language` field for older compatible models.
- Preserve endpoint, JSON response parsing, prompt, timeout, recovery, and Mini hedge behavior.

## Non-Goals

- No Realtime API migration or live partial transcript UI.
- No keyword-list UI or automatic dictionary submission to transcription.
- No new provider, dependency, endpoint, permission, retention, or logging.
- No change to the `gpt-4o-mini-transcribe` hedge.
- No real provider call with private audio during automated validation.

## User Workflow

1. The app loads settings.
2. A former-default `gpt-4o-transcribe` value becomes `gpt-transcribe`; a custom value remains unchanged.
3. Dictation uses the existing visible provider destination and transcription endpoint.
4. The provider returns JSON with top-level `text`; BabbelStream continues cleanup and draft insertion normally.

## Interaction And State Contract

| State | Event | Next state | Visible result | Side effects |
| --- | --- | --- | --- | --- |
| Settings load | Former default found | Ready | Primary model shows `gpt-transcribe` | In-memory migration; next settings save persists it |
| Settings load | Custom model found | Ready | Custom model remains visible | None |
| Transcribing | `gpt-transcribe` selected | Existing success/failure flow | Existing HUD states | Multipart uses `languages[]` when configured |
| Transcribing | Older model selected | Existing success/failure flow | Existing HUD states | Multipart uses `language` when configured |

## Domain Rules And Invariants

- Never send both `language` and `languages[]`.
- Empty language settings send neither field, preserving mixed-language detection.
- Keep `response_format=json` and accept the existing top-level `text` response.
- Never log audio, transcript text, prompt contents, or provider bodies.
- Never auto-send the inserted draft.

## Edge Cases And Races

- Whitespace around the configured model is trimmed before request-field selection.
- Unknown/custom model aliases retain the established OpenAI-compatible singular field.
- Additional response metadata, including detected languages, does not break parsing.
- Hedge timing, first-valid-result selection, cancellation, and recovery ownership do not change.

## Data, Privacy, Security, And Permissions

- Data read/sent/stored: unchanged audio, optional prompt, and optional language hint.
- Retention/deletion: unchanged.
- Providers/destinations/cost: unchanged configured destination; the new model must be available through that endpoint. The existing rare Mini hedge may still incur a second transcription charge.
- Permissions: unchanged.
- Logging/diagnostics: unchanged privacy-safe model labels and lifecycle categories only.

## Architecture Impact

- Components changed: project defaults, settings migration, transcription form-field construction, behavior checks, provider probe/benchmark defaults, and durable provider docs.
- New/changed interfaces: one pure model-aware form-field policy.
- Dependencies: none.
- Migration/compatibility: only the exact former default migrates; custom values remain.

## Error And Recovery Behavior

| Failure | User-visible state | Data ownership | Recovery |
| --- | --- | --- | --- |
| Provider/LiteLLM does not expose `gpt-transcribe` | Existing provider error and saved recording | Existing recovery store | Configure a supported model or update the provider, then retry |
| Provider rejects new language field | Existing provider error and saved recording | Existing recovery store | Leave language empty or fix provider compatibility, then retry |

## Acceptance Criteria

- New settings default to `gpt-transcribe`.
- Former-default settings load as `gpt-transcribe`.
- Other custom model strings remain unchanged.
- `gpt-transcribe` sends `languages[]` and never `language`.
- Older compatible models send `language` and never `languages[]`.
- Existing endpoint, response parser, hedge, privacy, recovery, and no-auto-send behavior remain unchanged.

## Automated Validation

- Behavior checks cover defaults, migration, custom preservation, and model-specific language fields.
- Canonical command: `task check`.

## Manual Smoke Test

1. Apply a provider configuration that exposes `gpt-transcribe`.
2. Dictate one German, one English, and one mixed German-English technical message with language left empty.
3. Confirm each transcript reaches the cleanup/insertion flow, remains in the spoken language, and is inserted only as an unsent draft.
4. Optionally set `de`, apply settings, and confirm a German dictation succeeds.

## Approval Gate

- Product decision approved by: Christian, 2026-07-28 request.
- Agent autonomy envelope: research and implement on a feature branch with automated validation.
- Must stop before: release-candidate installation, `main`, final tag, or release publication.

## Open Questions

- Whether the configured LiteLLM deployment already exposes `gpt-transcribe` must be confirmed by the manual provider smoke test.
