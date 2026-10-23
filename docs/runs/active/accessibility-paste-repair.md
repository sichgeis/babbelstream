# Accessibility Paste Repair

## Baseline and authority

- Clean main 874df0858e5fee4cd5ff60f4bd58ee8c30a9e3dd; branch codex/accessibility-paste-repair.
- the maintainer reported clipboard-only dictation into Codex and requested investigation plus README guidance.
- Installed running app: /Applications/BabbelStream.app, 0.5.1 / source 8f229fe, PID 73318 before repair.
- the maintainer explicitly approved repairing only BabbelStream's Accessibility entry and personally approved the resulting macOS authentication dialog.

## Findings

Native onboarding reports Microphone Allowed and Automatic paste Not allowed.
System Settings > Privacy & Security > Accessibility simultaneously shows the
BabbelStream switch on. The insertion service uses the running process's
AXIsProcessTrusted result; when false, it copies without posting Command-V.
This explains a clipboard-only outcome before any Codex editor handling. A stale
identity grant is consistent with the observation; its underlying OS cause is not
proven. No need to change Codex permissions or Keychain for this repair.

## Work and evidence

- Read insertion policy/result mapping and onboarding repair behavior.
- Native status and app-window screenshot inspected; no private draft, clipboard,
  credentials, TCC database or provider content read.
- Requested normal app quit, selected only BabbelStream's Accessibility row,
  and clicked Remove. macOS raised Touch ID/password authorization; the maintainer
  approved it himself. Verified the old row was removed.
- Added exactly /Applications/BabbelStream.app using the application chooser;
  verified its switch is on. Other application switches remain unchanged.
- Relaunched the Applications app. UI getter timed out because it is now menu-only;
  read-only process inspection verifies PID 95639 at the exact Applications path.
  Asked the maintainer to reopen setup for actual trust verification; no OS grant is
  inferred merely from the on switch.
- README documents the observed mismatch and proposed targeted repair, with
  separate explanations for lost focus and an unaccepted posted shortcut.
  Getting Started links to the single procedure. No app source/binary changes.

## Pending verification

Check actual Allowed status, then explicitly run the app-owned sample paste test.
Real Codex dictation is a user smoke test, not an automated provider call. Do not
claim repair success until live status/test evidence exists.

## Next action

the maintainer reopens Set Up BabbelStream or General Settings, allowing the agent to
verify the restarted app's live permission status and sample-paste result.
