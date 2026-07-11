# Hybrid Hotkey Specification

## Goal

Let the existing `Control + Option + Space` shortcut serve both quick push-to-talk dictation and longer hands-free dictation without adding a second shortcut or changing the provider, paste, recovery, or privacy workflows.

## Interaction Contract

The shortcut uses a fixed 0.5-second hold threshold:

- Press starts recording immediately.
- Release before 0.5 seconds latches the active recording into hands-free mode.
- Continue holding for at least 0.5 seconds to use push-to-talk; release stops and processes the recording.
- While hands-free recording is latched, press the same shortcut once to stop and process. Its later key-release event has no effect.
- The HUD red Stop control and the menu `Stop + Transcribe` action stop and process either recording style.
- Escape and the menu Cancel action retain their existing discard/cancel semantics. They never masquerade as Stop.

The boundary is deterministic: a duration strictly below 0.5 seconds is a tap; 0.5 seconds or longer is a hold.

## Visible States

| State | Shortcut press | Shortcut release | HUD |
| --- | --- | --- | --- |
| Idle | Start a hold candidate immediately | N/A | Hidden |
| Hold candidate | Ignore duplicate press | Tap latches; hold stops | Stop, target, hand indicator, waveform |
| Hands-free | Stop and process | Ignore the paired release | Stop, target, lock indicator, waveform |
| Processing | Ignore | Ignore | Existing processing state |

Starting dictation from the menu is equivalent to entering Hands-free directly. The same hybrid shortcut may stop that recording.

## Startup And Race Rules

- The press duration is measured from the global hotkey press, including time spent waiting for microphone permission or recorder startup.
- A tap released while recorder startup is pending must latch after startup succeeds.
- A hold released while startup is pending must stop as soon as startup succeeds.
- A second tap while a latched recording is still starting queues Stop after startup.
- If settings validation, permission, or recorder startup fails, all gesture state resets to Idle.
- Duplicate or late Carbon events must not start a second recording or stop a later operation.

## Targeting, Privacy, And Recovery

- Capture the paste target application and applied settings at the initial press, exactly as in push-to-talk.
- Successfully processed audio follows the existing deletion policy.
- Provider failure or processing cancellation follows the existing Failed Recordings policy.
- Canceling while actively recording discards the partial audio under the existing explicit cancellation behavior.
- The feature introduces no new permissions, persistence, provider calls, telemetry, or transcript logging.

## Acceptance Criteria

- A tap shorter than 0.5 seconds starts recording and releasing the shortcut does not process it.
- The HUD visibly distinguishes latched hands-free recording from a held recording while preserving the target-app label and live waveform.
- Pressing the shortcut again during hands-free recording stops once and begins the existing processing pipeline.
- Holding for at least 0.5 seconds preserves the existing release-to-process workflow.
- HUD Stop and menu Stop work for both styles.
- Menu Start begins a hands-free recording that the hybrid shortcut can stop.
- Recording startup failure resets the gesture so the next press works normally.
- Hotkey events during transcription, cleanup, paste, or recovery retry do not start a new recording.
- The maximum-duration auto-stop, Escape cancellation, target safety, recovery, archive, and no-auto-send policies remain unchanged.

## Agent Implementation Notes

- Keep gesture classification as a pure `BabbelStreamCore` policy and cover the threshold boundary in `BabbelStreamChecks`.
- Keep activation style separate from `RecordingMode`; dictation versus local test and hold versus hands-free are different concerns.
- Do not duplicate the audio or provider pipeline. Both gestures must converge on `stopAndProcessDictation()`.
- Reset gesture state only through the coordinator's recording reset path plus explicit startup-failure cleanup.
- Preserve the pending-release behavior across the `await` used for permission and recorder startup.
- Verify the installed build from `/Applications`, because Carbon registration and Accessibility behavior cannot be proven by the core executable checks.

## Manual Smoke Test

1. Focus TextEdit or a Slack draft and tap `Control + Option + Space` quickly.
2. Confirm the lock indicator appears, release all keys, speak for several seconds, and confirm recording continues.
3. Press the shortcut again and confirm one transcription begins and the draft is inserted but not sent.
4. Hold the shortcut for more than 0.5 seconds, speak, and release; confirm normal push-to-talk behavior.
5. Tap to latch, then click the red HUD Stop control; confirm processing begins.
6. Tap to latch, then use `Stop + Transcribe` from the menu; confirm processing begins.
7. Tap to latch and press Escape; confirm the active partial recording is canceled rather than processed.
8. Start from the menu and press the shortcut; confirm the menu-started recording stops and processes.
9. Trigger the configured maximum duration and confirm it auto-stops and processes.
10. During processing, press and release the shortcut; confirm no second recording starts.
