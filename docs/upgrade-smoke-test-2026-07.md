# July 2026 Upgrade Smoke Test

This checklist tracks the current v0.4 behavior. Historical same-model retry language has been replaced by the primary-to-Mini fallback policy, and the fixed shortcut now supports both tap-latched hands-free and held push-to-talk dictation.

Use this checklist after installing the branch build on the Mac where BabbelStream
is normally used. It deliberately leaves real provider credentials, microphone
audio, Accessibility actions, Slack, and email clients out of automated validation.

## Preparation

- Run `task check` from the repository and confirm it passes.
- Build/install with `scripts/install-dev-app.sh`, then launch the copy from
  `/Applications`.
- Keep a harmless Slack draft channel or unsent direct-message composer available.
- Keep a second editable app or field available, such as TextEdit, Mail, Outlook,
  or another Slack composer. Do not use a field where an accidental paste would
  have a harmful effect.

## Settings And Provider Boundaries

- Open Settings. Edit a model or endpoint without selecting **Apply Settings**.
  Confirm the UI marks the value as edited and continues to show the previously
  saved destination as effective.
- Select **Apply Settings** and confirm the effective label updates and an inline
  success result appears.
- Confirm a remote `http://` provider is rejected, a loopback development URL such
  as `http://127.0.0.1:8000` can be applied, and the normal remote provider uses
  HTTPS.
- Confirm the saved API key still works after updating it once. Do not paste the
  key into diagnostics or this checklist.

## Core Dictation Workflow

- In Slack, tap `Control + Option + Space`, release within 0.5 seconds, and confirm
  recording remains active with the HUD lock indicator. Speak without holding the
  keys, press the shortcut again, and confirm processing begins exactly once.
- In Slack, hold `Control + Option + Space`, dictate English, release, and confirm
  the HUD hand indicator moves through recording and processing before inserting
  a draft.
- Repeat with German and mixed German-English technical speech, including one or
  two personal-dictionary terms.
- Confirm the message remains an unsent draft and consecutive dictations receive
  the expected separating space.
- Confirm the latest raw/final draft in the menu is updated after success. Trigger
  a subsequent failure or cancellation and confirm the previous successful draft
  remains available for copy recovery.

## Cancellation And Recovery

- Start recording and press Escape. Confirm recording stops, no draft is pasted,
  and Escape behaves normally again after cancellation.
- Start another dictation and cancel from the HUD while processing. Confirm the
  operation ends without a late paste.
- Repeat using **Cancel Active Operation** from the menu as the fallback.
- During processing, move to a different application. Confirm BabbelStream does
  not steal focus or paste into either app; it copies the draft and shows manual
  `Command + V` recovery guidance.
- During processing, move to a different editable field in the same application.
  Confirm the draft goes to the field focused at paste time.
- Temporarily revoke Accessibility permission and dictate once. Confirm the draft
  is copied with understandable recovery guidance rather than silently lost.

## Target Compatibility

- Verify direct or fallback insertion in the normal Slack composer.
- Verify one native text field such as TextEdit, Mail, or Outlook.
- If a browser text field is part of the normal workflow, verify it separately.
- In every target, confirm BabbelStream never presses Return or sends a message.

## Local Data And Failure Visibility

- With archive disabled, confirm a successful dictation creates no archive entry.
- Enable the archive, dictate once, and confirm the entry and monthly totals appear.
  If raw transcript storage is disabled, confirm the entry does not contain it.
- Export Markdown and confirm the content is understandable. Exercise **Clear
  Archive** only if the local archive has been backed up or contains disposable
  test data.
- After success and cancellation, confirm no BabbelStream recording remains in
  the temporary directory. Quit during an active recording and confirm relaunch
  cleanup leaves no recording behind.
- Confirm copyable diagnostics contain provider configuration and counters but no
  API key, transcript, audio path, clipboard content, or provider body.
- Force or observe a transient primary transcription failure. Confirm the HUD shows
  **Trying Mini transcription**, only one Mini attempt occurs, and diagnostics
  distinguish primary from fallback without including audio or transcript content.

## Startup And Sign-Off

- Toggle launch at login on and off once and confirm the displayed state follows.
- Quit and relaunch the application; confirm saved settings, dictionary, counters,
  and opt-in archive settings remain intact.
- Record any failure with the action, visible status/HUD text, target app, and
  whether the draft was preserved. Do not include dictated text or credentials
  unless they were intentionally non-sensitive test values.

The upgrade is smoke-test approved when the core English/German/mixed workflow,
all three cancellation paths, both target-change cases, permission fallback, one
Slack target, one native target, local-data checks, and the no-auto-send invariant
all pass.
