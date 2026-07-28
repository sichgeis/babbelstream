# GPT Transcribe Migration Specification

## Status

- State: Implemented
- Owner: Christian
- Last approved: 2026-07-28 model-picker and local-install request
- Related ADRs/issues: none

## Problem

BabbelStream defaults to `gpt-4o-transcribe`, while OpenAI now recommends
`gpt-transcribe` for high-accuracy file transcription. A model-string-only
change would be incomplete because the new model replaces the singular
`language` request field with `languages[]`.

## Desired Outcome

New and existing default configurations use `gpt-transcribe` with its documented
multipart request shape. Settings offer only the three approved transcription
models through a picker, while the bounded Mini hedge remains compatible.

## Research And Alternatives

| Option | Benefits | Costs/Risks | Decision |
| --- | --- | --- | --- |
| Change the model string only | Smallest diff | Sends the wrong language field for the new model and does not reliably move existing saved settings | Rejected |
| Add model-aware request fields and a narrow settings migration | Matches the current OpenAI contract | LiteLLM deployments must expose the new model and field | Accepted for transport; custom-model preservation superseded by the picker |
| Keep a free-text model field | Supports arbitrary proxy aliases | Permits typos and unsupported request shapes | Rejected by the 2026-07-28 follow-up |
| Use a three-option model picker | Predictable configuration, no invalid free text, clear default | Arbitrary provider aliases are no longer configurable | Accepted |
| Replace the provider flow with Realtime transcription | Could stream live microphone audio | Material architecture, latency, and privacy change outside this request | Rejected |

## Accepted Scope

- Default primary transcription to `gpt-transcribe`.
- Replace the primary-model free-text field with a menu picker containing
  `gpt-transcribe`, `gpt-4o-transcribe`, and `gpt-4o-mini-transcribe`.
- Perform a one-time migration from the former default `gpt-4o-transcribe` to
  `gpt-transcribe`; preserve later explicit picker selections.
- Normalize unsupported saved model strings to `gpt-transcribe`.
- Send a configured single language hint as `languages[]` for `gpt-transcribe`.
- Keep the singular `language` field for older compatible models.
- Preserve endpoint, JSON response parsing, prompt, timeout, recovery, and Mini hedge behavior.

## Non-Goals

- No Realtime API migration or live partial transcript UI.
- No keyword-list UI or automatic dictionary submission to transcription.
- No new provider, dependency, endpoint, permission, retention, or logging.
- No change to the `gpt-4o-mini-transcribe` hedge.
- No arbitrary transcription-model aliases in Settings.
- No real provider call with private audio during automated validation.

## User Workflow

1. The app loads settings.
2. A former-default or unsupported saved value becomes `gpt-transcribe`.
3. The user may choose one of the three supported model IDs from a menu and explicitly apply it.
4. Dictation uses the existing visible provider destination and transcription endpoint.
5. The provider returns JSON with top-level `text`; BabbelStream continues cleanup and draft insertion normally.

## Interaction And State Contract

| State | Event | Next state | Visible result | Side effects |
| --- | --- | --- | --- | --- |
| Settings load | Former default found | Ready | Primary model shows `gpt-transcribe` | In-memory migration; next settings save persists it |
| Settings load | Unsupported model found | Ready | Primary model shows `gpt-transcribe` | Unsupported value is normalized |
| Settings edit | User opens model control | Settings draft | Three exact model IDs are available | No provider request until Apply |
| Settings apply | Supported model selected | Ready | Active destination reflects selection | Selection persists across restart |
| Transcribing | `gpt-transcribe` selected | Existing success/failure flow | Existing HUD states | Multipart uses `languages[]` when configured |
| Transcribing | Older model selected | Existing success/failure flow | Existing HUD states | Multipart uses `language` when configured |

## Domain Rules And Invariants

- Never send both `language` and `languages[]`.
- Only the three approved transcription model IDs may be applied.
- Empty language settings send neither field, preserving mixed-language detection.
- Keep `response_format=json` and accept the existing top-level `text` response.
- Never log audio, transcript text, prompt contents, or provider bodies.
- Never auto-send the inserted draft.

## Edge Cases And Races

- Whitespace around the configured model is trimmed before request-field selection.
- A legacy model chosen after the one-time migration must persist and must not be
  migrated again on restart.
- Unsupported/custom model aliases normalize to the default instead of appearing
  as an invalid picker state.
- Additional response metadata, including detected languages, does not break parsing.
- Hedge timing, first-valid-result selection, cancellation, and recovery ownership do not change.

## Data, Privacy, Security, And Permissions

- Data read/sent/stored: unchanged audio, optional prompt, and optional language hint.
- Retention/deletion: unchanged.
- Providers/destinations/cost: unchanged configured destination; the new model must be available through that endpoint. The existing rare Mini hedge may still incur a second transcription charge.
- Permissions: unchanged.
- Logging/diagnostics: unchanged privacy-safe model labels and lifecycle categories only.

## Architecture Impact

- Components changed: project defaults, settings migration/validation, Provider
  Settings UI, transcription form-field construction, behavior checks, provider
  probe/benchmark defaults, and durable provider docs.
- New/changed interfaces: one pure supported-model policy, a menu picker, and one
  model-aware form-field policy.
- Dependencies: none.
- Migration/compatibility: the historical default migrates once; explicit picker
  selections persist; unsupported values normalize to the default.

## Error And Recovery Behavior

| Failure | User-visible state | Data ownership | Recovery |
| --- | --- | --- | --- |
| Provider/LiteLLM does not expose `gpt-transcribe` | Existing provider error and saved recording | Existing recovery store | Configure a supported model or update the provider, then retry |
| Provider rejects new language field | Existing provider error and saved recording | Existing recovery store | Leave language empty or fix provider compatibility, then retry |

## Acceptance Criteria

- New settings default to `gpt-transcribe`.
- Former-default settings load as `gpt-transcribe`.
- Settings use a menu picker rather than free text.
- The picker exposes exactly `gpt-transcribe`, `gpt-4o-transcribe`, and
  `gpt-4o-mini-transcribe`.
- Unsupported saved model strings normalize to `gpt-transcribe`.
- An explicit supported-model selection persists across restart.
- `gpt-transcribe` sends `languages[]` and never `language`.
- Older compatible models send `language` and never `languages[]`.
- An empty language setting sends neither field so mixed-language
  auto-detection does not submit an invalid empty language code.
- Existing endpoint, response parser, hedge, privacy, recovery, and no-auto-send behavior remain unchanged.

## Automated Validation

- Behavior checks cover picker options, defaults, one-time migration, unsupported
  normalization, explicit selection persistence, validation, model-specific
  language fields, and omission of an empty language hint.
- Canonical command: `task check`.

## Manual Smoke Test

1. Open Provider Settings and confirm the primary transcription model is a menu,
   not a text field, with exactly the three approved model IDs.
2. Select each option and confirm the edited destination changes without becoming
   active until Apply.
3. Apply `gpt-transcribe`, restart the app, and confirm it remains selected.
4. Dictate one German, one English, and one mixed German-English technical message
   with language left empty.
5. Confirm each transcript reaches the cleanup/insertion flow, remains in the
   spoken language, and is inserted only as an unsent draft.

## Approval Gate

- Product decision approved by: Christian, 2026-07-28 follow-up request.
- Agent autonomy envelope: implement, validate, commit/push, merge/push `main`,
  build, install, launch, and verify locally.
- Must stop before: annotated tag or public release publication.

## Open Questions

- The configured LiteLLM deployment did not expose `gpt-transcribe` on
  2026-07-28. Its authenticated model list included `gpt-4o-transcribe` and
  `gpt-4o-mini-transcribe`; enabling the new default requires an upstream proxy
  deployment.
