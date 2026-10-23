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

## Post-restart verification

the maintainer reopened setup. Native UI now reports Microphone Allowed and Automatic
paste Allowed; the exact running app's OS trust is restored. Navigation to the
local paste step performed no provider action. Automated Test Automatic Paste
attempts stopped at "Keep the setup window active and try again", including after
raising/clicking the window. No sample arrived, and no pass is claimed. This is
a focus-guard result under the UI tool, not evidence that permission remains
missing. Left the test open and asked the maintainer to click it directly.

## Local paste and Codex verification

the maintainer clicked the test and reported that the sample appeared and the test
passed. Independently verified the native field contains exactly "BabbelStream
paste test." and the result says "Sample received. Automatic paste worked in
this test field." OS trust and actual local synthetic-paste receipt now PASS.
No microphone/provider use or external-field inspection was automated.

the maintainer confirmed on 2026-10-23: "It works now, dictation inserts directly into
the Codex input." The external-editor smoke check now passes by user report.
No automated recording/provider request or private dictation inspection occurred.

## Closeout

the maintainer explicitly requested merging the README update into main and pushing it.
README and Getting Started document the targeted repair; live Allowed status,
actual local sample receipt and human Codex insertion all passed. Archived this
run and reconciled project status. Documentation-only changes; no rebuild,
installation, new version/tag, Keychain edit or provider change. Exact underlying
OS grant mismatch cause and future-build trust remain unproven.

Validation: local documentation links/anchors and git diff --check pass. App,
resource and release tooling sources are unchanged; canonical task check already
passed at baseline main 874df08 and is not repeated for Markdown-only changes.

## Next action

None for this completed repair; future Homebrew lifecycle checks remain in
`docs/implementation-plan.md`.

