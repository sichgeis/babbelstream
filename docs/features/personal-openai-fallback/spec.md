# Personal OpenAI Fallback

## Problem And Outcome

BabbelStream's work configuration uses an OpenAI-compatible LiteLLM proxy that
is intentionally unavailable when the work cluster is shut down. A failed
connection currently leaves the recording recoverable but makes weekend
dictation unavailable.

Add an explicit, disabled-by-default personal OpenAI fallback. When the saved
primary destination is unreachable and the user has enabled this feature,
BabbelStream sends the safeguarded audio to the official OpenAI API with a
separate personal API key. If transcription used the personal fallback, cleanup
for that dictation also uses the personal OpenAI profile so the workflow does
not return to the unavailable work proxy.

## Design Decision

Automatic provider switching is useful here only as a narrow availability
policy. It is not a general retry across accounts. The fallback is therefore a
named, fixed official-OpenAI profile rather than a second arbitrary provider:

- the destination is always `https://api.openai.com` with the standard
  transcription/cleanup paths, supported logical transcription model, default
  cleanup model, and standard model IDs;
- the personal key is stored separately in Keychain;
- the user must explicitly enable and apply the fallback after its destination
  and disclosure are visible;
- fallback is allowed only for connection/reachability failures;
- gateway/service-unavailable HTTP 502, 503, and 504 responses count as
  reachability failures; authentication, authorization, rate limiting, other
  invalid requests, unsupported models, and invalid responses fail closed
  without switching accounts.

This is safer and easier to understand than silently treating every primary
error as permission to send work audio to a personal account.

## Scope

- Persist an opt-in `Personal OpenAI fallback` setting, default off.
- Store the personal OpenAI API key in a separate Keychain item and track only a
  non-secret presence marker in `UserDefaults`.
- Show the primary and personal fallback destinations in Provider Settings and
  General readiness.
- Derive the fallback profile from the applied dictation settings while fixing
  its base URL and model routing to official OpenAI values.
- Attempt fallback transcription once after the existing primary/Mini phase
  fails with a reachability-classified error.
- Do not run a second Mini hedge on the personal profile; the cross-account
  fallback is one bounded request.
- When personal transcription wins, run enabled cleanup through personal OpenAI
  with the personal key.
- If primary transcription succeeds but primary cleanup is unreachable, make
  one personal cleanup attempt when fallback is enabled; otherwise preserve the
  existing raw-transcript cleanup fallback.
- Surface fallback activation in status, warnings, archive provider labels, and
  privacy-safe diagnostics.
- Preserve stopped-audio recovery, cancellation, insertion, archive, and
  no-auto-send behavior.

## Non-Goals

- No arbitrary secondary provider or editable fallback destination.
- No fallback on HTTP 400/401/403/404/408/409/425/429, generic HTTP 500, or
  other client/application errors.
- No fallback on malformed/empty successful responses.
- No fallback when the personal key is missing.
- No periodic health check, background traffic, provider probing, or automatic
  switching before a real dictation request fails.
- No simultaneous request to work and personal accounts.
- No local transcription backend, new dependency, telemetry, or transcript
  history.
- No automatic enablement or migration for existing installations.

## User Workflow

1. In Provider Settings, the user sees the saved work destinations.
2. The user enables `Use personal OpenAI when primary is unreachable`, enters a
   personal OpenAI API key, reviews the fixed official destination, and applies
   Settings.
3. Normal dictations continue to use only the saved primary profile.
4. If the primary transcription phase ends in a reachability failure, the HUD
   shows `Trying personal OpenAI` and BabbelStream makes one official-OpenAI
   transcription request.
5. When fallback succeeds, any enabled cleanup uses the personal profile and the
   final draft is inserted normally. A visible warning states that personal
   OpenAI was used.
6. If fallback is unavailable or fails, the stopped recording stays in Failed
   Recordings under the existing recovery policy.

## Interaction And State Contract

| State | Event | Result | Network side effect |
| --- | --- | --- | --- |
| Settings, fallback off | User applies normal settings | Primary-only behavior | None |
| Settings, fallback on without saved/input key | Apply | Validation error; prior applied settings remain active | None |
| Transcribing on primary | Primary succeeds | Continue with primary cleanup | Primary only |
| Transcribing on primary | Reachability failure | Show personal fallback state | One personal transcription request |
| Transcribing on primary | HTTP 502/503/504 | Show personal fallback state | One personal transcription request |
| Transcribing on primary | Permanent/client/content failure | Fail and retain recording | No personal request |
| Personal transcription succeeds | Cleanup disabled | Insert raw transcript with fallback warning | No cleanup request |
| Personal transcription succeeds | Cleanup enabled | Clean through personal OpenAI | One personal cleanup request |
| Primary transcription succeeds | Primary cleanup unreachable | Try personal cleanup once | One personal cleanup request |
| Personal cleanup fails | Existing raw fallback | Insert raw transcript and retain audio for retry | No further request |
| User cancels | Any provider phase | Cancel work and retain stopped audio | No new fallback starts |

## Domain Rules And Invariants

- `PersonalProviderFallbackPolicy` is the single source of truth for eligible
  errors.
- Eligible errors are HTTP 502/503/504, connection watchdog expiry, and
  `URLError` codes for
  timeout, DNS/host lookup, connection refusal/loss, offline state, and resource
  unavailability. All other HTTP responses are ineligible because the primary
  service returned an application-level decision.
- A dictation snapshots both primary settings and fallback enablement before
  recording; editing Settings cannot reroute in-flight audio.
- The fallback uses the same logical transcription model, response format,
  language, and prompt, but official OpenAI routing and base URL.
- The personal fallback makes at most one transcription request and one cleanup
  request per dictation. It never participates in the primary Mini hedge.
- Fallback never starts without an explicitly enabled setting and a non-empty
  personal key read on demand from Keychain.
- A fallback key is never used with the primary destination, and the primary key
  is never used with the fallback destination.
- No API key, audio, transcript, cleanup text, request body, or provider response
  body appears in logs or copied diagnostics.
- BabbelStream never presses Enter or sends the inserted draft.

## Data, Privacy, Security, Cost, And Permissions

- Enabling fallback authorizes work audio and, when cleanup is enabled,
  transcript text and personal dictionary context to be sent to the user's
  personal OpenAI account after an eligible primary failure.
- This can create personal OpenAI API charges. Settings states this before Apply.
- Both provider keys remain device-only Keychain items. Startup reads presence
  markers, not secrets.
- The existing audio retention and deletion rules do not change.
- No new macOS permission is required.
- Diagnostics may include enabled/disabled state, saved-key presence, fixed
  destination, activation, stage, and sanitized failure category.

## Architecture Impact

- `AppSettings` and `UserDefaultsSettingsStore`: persisted opt-in.
- `SecretStore`: separate primary and personal-fallback credentials.
- `PersonalProviderFallbackPolicy`: pure reachability classification and fixed
  fallback settings derivation.
- `AppState`: read both keys only at request time, orchestrate sequential
  provider fallback, preserve the winning profile through cleanup and archive
  metadata, and publish visible state.
- `SettingsView`: opt-in, fixed destination, disclosure, and separate secret
  controls.
- Dependencies: none.

## Error And Recovery Behavior

| Failure | User-visible behavior | Recovery ownership |
| --- | --- | --- |
| Primary unreachable, fallback disabled | Existing provider error | Recording retained |
| Primary unreachable, fallback key unavailable | Actionable missing-personal-key error | Recording retained |
| Primary returns auth/rate/model error | Original error; no account switch | Recording retained |
| Personal transcription fails | Personal fallback error | Recording retained |
| Personal cleanup fails | Raw transcript inserted with warning | Recording retained for optional full retry |

## Acceptance Criteria

- Existing installations remain primary-only until fallback is explicitly
  enabled and applied.
- Enabling fallback without a saved or newly entered personal key is rejected.
- Primary success never sends audio or text to personal OpenAI.
- Eligible connection failures make exactly one personal transcription request.
- Only HTTP 502/503/504 activate personal fallback; other HTTP and response-
  shape errors do not.
- Personal transcription uses `https://api.openai.com`, standard model IDs, and
  the separate personal key.
- Cleanup follows the profile that produced the transcript; a primary cleanup
  reachability failure may make one personal cleanup attempt.
- Fallback activation and the active destination are visible without exposing
  content or secrets.
- Cancellation starts no later fallback work.
- Successful audio deletion, failed-recording ownership, archive labeling,
  insertion, and no-auto-send behavior remain correct.

## Automated Validation

- Settings default/persistence and disabled migration behavior.
- Fixed fallback settings derivation and model routing.
- Eligible and ineligible error classification.
- Separate Keychain accounts and presence markers through fakes/pure checks.
- Provider request shape remains correct for derived official settings.
- Diagnostics redaction continues to exclude both key values.
- Canonical command: `task check`.

## Manual Smoke Test

1. Configure the work LiteLLM profile, enable personal fallback, save a personal
   OpenAI key, and Apply.
2. With LiteLLM reachable, dictate a short synthetic/non-confidential phrase and
   confirm the work profile is used without fallback.
3. With LiteLLM unavailable, dictate another synthetic phrase and confirm the
   HUD shows personal fallback, the draft is inserted but not sent, and
   diagnostics name only the sanitized fallback stages/destination.
4. Disable fallback and repeat with LiteLLM unavailable; confirm no personal
   request occurs and the recording remains recoverable.
5. Re-enable fallback, use an invalid work API key while LiteLLM is reachable,
   and confirm the personal account is not used.
6. Restart BabbelStream and confirm both key-presence indicators and the applied
   opt-in remain correct without a startup Keychain prompt.

## Approval Gate

- Product decision and implementation authority: Christian's 2026-08-16 request
  to assess, plan, implement, and push this fallback using the repository's
  spec-driven workflow.
- Agent may proceed through: feature branch, implementation, validation,
  coherent commits, and feature-branch push.
- Must stop before: merge/push of `main`, local production installation, real
  provider calls with work/personal content or credentials, annotated tag, or
  public release.
