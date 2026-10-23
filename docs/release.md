# Release Guide

## Versioning And Build Provenance

`VERSION` owns the semantic app/DMG version; `BUILD_NUMBER` owns the increasing integer `CFBundleVersion`. Increment BUILD_NUMBER before each newly distributed iteration, including a materially new candidate, and keep it committed. The previous fixed bundle build was 1; subsequent candidates increment the committed source BUILD_NUMBER. The 0.5.0 local release used build 6; the corrected 0.5.1 release uses build 7; release tags point to the final app-source commit on main.

- Before 1.0, increment MINOR for substantial user-facing changes and PATCH for compatible fixes.
- Keep VERSION, CHANGELOG, final main commit and annotated `v<version>` tag aligned after the human smoke gate.
- Candidate/distribution packaging requires all tracked/untracked work clean, release optimization, source-matching version/build metadata, and the exact HEAD hash. Overrides cannot disguise a different source version/commit.
- Preflight compares BUILD_NUMBER to the most recent reachable release tag. Rebuilding the exact clean tagged commit with that tag's version/build remains allowed; new iterations must increase it. Avoid shallow/incomplete tag history for release work.

## Build Modes

| Mode | Configuration | Signature | Preconditions |
| --- | --- | --- | --- |
| development (default) | debug unless explicitly set | existing local identity or ad-hoc fallback | Local development; may be dirty |
| candidate | release | ad-hoc by default, no private-identity lookup | Clean commit, increasing source build; local review or approved non-notarized pilot |
| distribution | release | explicitly supplied Developer ID Application, secure timestamp | Clean commit/build; fails without authorized identity, never falls back |

Candidate/distribution signatures enable hardened runtime and the reviewed audio-input entitlement for existing microphone behavior. No App Sandbox, new permission, debug task allowance, JIT, library-validation exception or telemetry is added. `verify-app.sh` checks signature integrity, runtime flags and microphone entitlement; distribution additionally requires Developer ID and timestamp. Native microphone/Accessibility behavior under that signature still requires human QA.

## Release Levels

### Local Testing

Use this for daily development and personal smoke testing on the development Mac:

```bash
task check
scripts/install-dev-app.sh
```

`task check` builds the app and runs the dependency-free `BabbelStreamChecks`
behavior suite. The current Command Line Tools environment does not expose a
runnable XCTest or Swift Testing framework through SwiftPM, so `swift test` is
not the project check command.

`scripts/install-dev-app.sh` builds the app bundle, packages the local DMG, opens the Finder drag-to-Applications window, and stops any running BabbelStream copy so Finder can replace it cleanly. The script does not use `sudo`; if `/Applications` needs authorization, Finder shows the standard macOS prompt during the drag copy. After copying, run `RESTART_ONLY=1 scripts/install-dev-app.sh` to launch from `/Applications`.

For release-style manual QA, package a local DMG:

```bash
scripts/package-dmg.sh
```

Output:

```text
dist/BabbelStream-$(cat VERSION).dmg
```

The local build signs with `BabbelStream Local Code Signing` when that identity exists, otherwise it falls back to ad-hoc signing. This does not provide Apple-verified publisher identity or notarization. The approved own-tap pilot is a narrowly scoped exception described below.

For visual QA, use the fixture-only bundle rather than another production-store copy:

```bash
scripts/preview-layout.sh --settings --settings-tab=provider
scripts/preview-layout.sh --teach-correction --minimum-window-size
scripts/preview-layout.sh --personal-dictionary --minimum-window-size
scripts/preview-layout.sh --dictation-archive --minimum-window-size
```

Use `--preview-dark`, `--preview-high-contrast`, or `--preview-incomplete` for scoped fixtures/appearance without changing global settings. This is the actual UI with fake OS/store adapters, not a second daily app. Quit the preview when done. Settings dimensions refer to content size (minimum 700×560, default 760×640); native title bars add height. Capture all tabs/scroll extremes on both required macOS versions, restore the original tab, and never alter saved settings just for screenshots.

### Clean Local Candidate

```bash
task check
task app:candidate
```

This produces `dist/BabbelStream-<VERSION>-candidate.<BUILD_NUMBER>-<COMMIT>.dmg` from a clean commit without opening Finder, installing, launching the daily app or looking up a private signing identity. The ad-hoc candidate is not a distributable Developer ID artifact and does not pass the public Gatekeeper/notarization gate. An explicitly authorized stable signing identity can be supplied for later local permission QA; do not infer authorization from its availability.

User-facing development/manual and distribution DMGs default to the decorative `finder` layout: background, arrow, app on the left and Applications on the right. This mounts a writable staging image and configures Finder; use an unlocked desktop with Finder access. Candidate mode defaults to noninteractive `plain`. Explicit `DMG_LAYOUT=plain` supports unattended packaging in any mode; `DMG_LAYOUT=finder` opts a candidate into the decorative layout. Packaging alone never installs or launches an app.

### Developer ID Distribution Artifact (Separate Authorization)

```bash
BUILD_MODE=distribution CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" scripts/package-dmg.sh
```

Only run after the identity owner authorizes signing-material use. The same Developer ID identity signs the DMG unless a separate explicit Developer ID identity is supplied. No ad-hoc fallback occurs. This prepares an artifact; publication and installation remain separate gates.

## Developer ID And Notarization

For Mac software distributed outside the Mac App Store, Apple expects a Developer ID certificate and notarization. Apple documents that Developer ID signing plus a notarization ticket lets Gatekeeper verify that downloaded software is not known malware and has not been tampered with.

Official references:

- [Developer ID certificates](https://developer.apple.com/help/account/certificates/create-developer-id-certificates)
- [Notarizing macOS software before distribution](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)
- [Customizing the notarization workflow](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow)

After explicit authorization to submit the signed artifact to Apple, use an already configured approved Keychain profile; never put passwords/API keys into shell arguments, source files or this guide:

```bash
NOTARY_PROFILE="approved-notarytool-profile" scripts/notarize-dmg.sh "dist/BabbelStream-$(cat VERSION).dmg"
```

The helper verifies Developer ID/timestamp, submits with `notarytool --wait`, saves submission metadata and the notary log, requires Accepted, staples and validates the ticket, assesses the DMG with Gatekeeper, and regenerates the checksum after stapling. Always review the notary log for warnings, even on acceptance. Actual signing, Apple submission, stapling/Gatekeeper and clean-Mac installation were not performed during automated pilot preparation.

Verify the installed app (only after authorized installation):

```bash
scripts/verify-app.sh /Applications/BabbelStream.app distribution
spctl --assess --type execute --verbose=2 /Applications/BabbelStream.app
```

Test a downloaded/quarantined artifact on a clean pilot Mac, including offline ticket availability. Do not bypass Gatekeeper warnings to manufacture acceptance. `scripts/install-dev-app.sh` is a development convenience and may stop existing copies/open Finder; do not run it as an implicit packaging step or use it to replace a daily app without authorization. Follow `docs/pilot-support.md` for installation, upgrade, rollback, credentials and support.

Reviewed Apple references (2026-10-23): [distribution signing](https://developer.apple.com/documentation/xcode/creating-distribution-signed-code-for-the-mac/), [hardened runtime](https://developer.apple.com/documentation/xcode/configuring-the-hardened-runtime), [audio input entitlement](https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.device.audio-input), [CFBundleVersion](https://developer.apple.com/documentation/bundleresources/information-property-list/cfbundleversion), [notarization troubleshooting](https://developer.apple.com/documentation/security/resolving-common-notarization-issues). Secure timestamps, Developer ID, hardened runtime and absence of get-task-allow are distribution requirements; fixture preflight tests cannot establish certificate availability or notarization success.

## Manual Release Checklist

- `task check`
- Clean `task app:candidate` for local review or the explicitly authorized Developer ID path for distribution.
- Record artifact version/build/commit/checksum and signature/runtime/entitlement evidence.
- Open the DMG and copy `BabbelStream.app` to `/Applications`.
- Launch from `/Applications`.
- Confirm menu-bar icon appears.
- Confirm Settings opens.
- Confirm the menu is concise and Copy Last Draft remains a direct action; confirm Local Test Recording is available under Diagnostics.
- Confirm General Settings readiness matches permissions, Keychain/provider configuration, and the Login Items state.
- Toggle Launch at login and confirm the app appears in System Settings > General > Login Items; when upgrading an older installation, confirm the legacy LaunchAgent is removed only after registration succeeds.
- Confirm all five Settings tabs render without clipping at the 700×560 minimum and 760×640 default content sizes on macOS 26.7.1 and 27.0.1; Provider and Diagnostics should scroll without moving the Apply footer.
- Confirm Teach Correction renders at 500×420 minimum and 560×500 default sizes; section content scrolls without moving its footer.
- Confirm Personal Dictionary renders at 620×520 minimum and 720×640 default sizes; both editors remain usable and the footer stays fixed.
- Confirm Dictation Archive renders at 680×520 minimum and 760×640 default sizes; long daily/recovery content scrolls without moving its footer.
- Confirm Microphone and Accessibility prompts are understandable.
- Dictate English, German, and mixed German-English samples into Slack or TextEdit.
- Run the hybrid tap/hold smoke test in `docs/features/hybrid-hotkey/spec.md`.
- Confirm no message is auto-sent.
- Confirm consecutive dictations are separated by a space.
- Confirm no temporary audio remains after success; failed or canceled-after-stop processing appears under Failed Recordings; recording cancellation removes its partial file.
- Follow the current upgrade smoke test in `docs/upgrade-smoke-test-2026-07.md`
  when validating the July 2026 reliability changes.

## GitHub Release Assets

Upload exactly these two assets, using the polished Finder layout:

- `BabbelStream-<VERSION>.dmg`
- `BabbelStream-<VERSION>.dmg.sha256` (portable filename, no local absolute path)

Use the same DMG for direct download and Homebrew. Put release notes from
`CHANGELOG.md` in the release body. GitHub also generates source ZIP/tar archives;
these are not installers and do not count as uploaded assets.

Keep preview, revision and candidate variants local; do not upload `-pretty`,
`-r2`, plain alternatives or intermediate builds. Before updating the tap, list
the release assets and require exactly the canonical pair, independently download
both, verify the checksum, and match the cask version/URL/hash to that DMG.
Retain published canonical bytes and tags; a packaging correction after publication
requires a new version. Do not publish local `.env` files or provider secrets.

## 0.4.4 Reliability Smoke Test

The maintainer approved this smoke test on 2026-09-05. Final release `v0.4.4` is tagged at `d662a72`; release/install evidence is archived in `docs/runs/archive/recovery-delivery-reliability.md`.

1. Open `dist/BabbelStream-0.4.4.dmg`, quit the previous app, and drag the candidate to Applications. Launch it and verify version 0.4.4 plus the candidate commit shown in the run tracker under Diagnostics.
2. In an unsent Slack composer, dictate short synthetic English, German, and mixed-language phrases. Exercise both tap-to-latch and hold-to-talk. Confirm the text appears once, retains a trailing separator, and nothing is sent.
3. Dictate once while switching to a different application before delivery. Confirm no automatic paste into that application; recover using Copy Last Draft/manual paste.
4. Cancel while recording; confirm recording stops and the partial file is not a Failed Recordings entry. Cancel during processing on another synthetic attempt; confirm its stopped audio is retained and Retry and Copy recovers without auto-pasting.
5. Confirm Failed Recordings no longer contains the successfully recovered item. If a storage/deletion warning occurs, confirm it remains visible and the recording can be exported or explicitly deleted.
6. Confirm menu, Settings, and the recording/processing HUD still behave normally. Clipboard contention and filesystem fault timing are covered deterministically with fakes; do not manipulate real user files to force those cases.

Report pass/fail and any unexpected behavior. The pre-existing expanded personal-provider matrix remains a separately documented manual limitation; no real-provider validation is claimed by the executable checks.

## 0.4.5 Signal Smoke Test

The maintainer confirmed successful Signal smoke on 2026-09-05. Final release evidence is retained in `docs/runs/archive/signal-paste-compatibility.md`.

After installing the candidate, verify version 0.4.5 and its source commit under Diagnostics. Focus a Signal composer and dictate a harmless short phrase; confirm the draft appears exactly once and remains unsent. Repeat in one previously working application, and confirm Copy Last Draft/manual paste still works. Report pass/fail before the final v0.4.5 tag. Do not send a message just to validate insertion.

## Pilot Readiness Build And Layout Validation

`task check` and packaging use `scripts/swift-project.sh`, selecting the installed macOS 26.5 SDK locally. The current CLT default macOS 27 SDK lacks its required SwiftUI macros. No system selection is changed. Explicit `SDKROOT` or `BABBELSTREAM_SDK` overrides require independent full validation; a missing validated SDK fails with an actionable prerequisite. On 2026-10-23 the full application build and executable suite pass with 26.5; compiler capture warnings and CLT framework-search warnings remain pre-existing.

For isolated visual inspection, run `scripts/swift-project.sh run BabbelStreamChecks --layout-preview --settings --settings-tab=general` (optionally `--minimum-window-size`). This constructs the real views with CoordinatorFixture stores and fake recording/provider/Keychain/insertion/hotkey/login/runtime adapters; it never starts the production app or accesses its stores. Quit the preview to remove its temporary fixture directory. The same preview supports `--teach-correction`, `--personal-dictionary`, and `--dictation-archive`. Do not launch a second production-store copy for screenshots.

Shared sections use explicit 20-point section gaps, 24-point horizontal canvas margins, 12-point section insets and 10-point row spacing inside one scroll owner. The footer stays outside the scroll view. Validate all five tabs at 700×560 and 760×640, long content, scrolling and secondary dialogs on macOS 26.7.1 and 27.0.1; evidence from one host cannot establish the other.

## 0.5.0 Local Release Approval

The maintainer approved release finalization on 2026-10-23 after successful build 5 smoke. The macOS 27.0.1 comparison is deferred to the other Mac, not marked passed. Full canonical fixture checks remain required. Developer ID signing/notarization and colleague update delivery remain separately gated.

For this local release, use the clean optimized candidate pipeline with explicit ad-hoc identities and the stable final filename:

```bash
BUILD_MODE=candidate CODESIGN_IDENTITY=- DMG_CODESIGN_IDENTITY=- DMG_NAME=BabbelStream-0.5.0.dmg scripts/package-dmg.sh
```

The internal build-mode metadata stays `candidate` to describe the local ad-hoc verification class; semantic version 0.5.0, build 6, clean source commit and annotated v0.5.0 tag establish release provenance. Do not relabel this as Developer ID distribution or publish its binary as a notarized colleague installer. Verify the installed app with candidate-mode signature checks. A later docs-only evidence commit may follow the tagged app-source commit on main without moving the published tag or changing the installed payload.

## 0.5.1 First-Use Correction

The final 0.5.0 native check found that Allow Microphone checked unknown instead of notDetermined. Ship the correction as 0.5.1/build 7 with a new immutable tag, using the same explicit ad-hoc local pipeline and `DMG_NAME=BabbelStream-0.5.1.dmg`. Native fixture consent and grant/deny checks pass; real OS consent remains user-controlled. Preserve the original 0.5.0 tag and artifact history.

## Own Homebrew Tap: Approved Non-Notarized Pilot

The maintainer approved this channel on 2026-10-23 without paid Apple membership.
The app stays ad-hoc signed, explicitly non-notarized, arm64-only initially.
Keep existing Developer ID mode and checks unchanged; use exact clean-tag candidate
artifacts and their signature verification for this channel. Do not label these
as Apple-verified or official Homebrew catalogue builds.

- Contract and acceptance: `docs/features/homebrew-distribution/spec.md`.
- Maintainer: the maintainer (`sichgeis`) for app releases and `sichgeis/homebrew-tap`.
- Operator checklist: `docs/homebrew-release.md`.
- For each new release, public rollout waits for the downloaded/quarantined-payload
  test. The 0.5.1 pilot passed and is public; archived evidence is in
  `docs/runs/archive/homebrew-distribution.md`. Draft releases remain visible only
  to authorized repository users.
- Upload only the DMG and portable checksum file. Never upload all of dist,
  rollback bundles, local settings, secrets or user data.
- Update the cask only after the public asset is reachable and its downloaded
  SHA-256 matches; never rewrite old tags or replace published same-version bytes.
- No cask hooks that launch/kill the app, access Keychain, grant/reset permissions,
  remove quarantine or disable Gatekeeper. Users quit normally before upgrading.
- Homebrew/GitHub network activity is initiated outside BabbelStream; no Sparkle
  or in-app update request is introduced. Signing/notarization remains an optional
  separately authorized later transition.

## Historical 0.5.1 Decorative Previews

The following records the original authorization, superseded by the cleanup below.
The maintainer authorized `BabbelStream-0.5.1-pretty.dmg` plus its portable SHA-256 as
additional v0.5.1 release assets. This is a container/layout variant of the exact
released 0.5.1/build 7/8f229fe app, not a new app build or notarized installer.
Do not replace the original DMG/checksum, move v0.5.1 or change Homebrew's URL/hash.
Evidence: `docs/runs/archive/pretty-dmg-layout.md`. Repackaging an
unchanged verified app does not increment its version/build or claim the current
packaging-tool commit as app provenance. Newly compiled apps still follow normal
clean-source/version/build gates.

The spacing refinement is published separately as `BabbelStream-0.5.1-pretty-r2.dmg`
and checksum, with a 440-point background and a 468-point outer Finder window.
The outer height includes the 28-point title bar; do not reuse background height
as outer-window height. Its card border/corners remain visible with extra lower
padding and a softer shadow. Keep the original and first pretty assets intact.
Evidence: `docs/runs/archive/dmg-bottom-spacing.md`.

On 2026-10-23 the maintainer explicitly authorized removing both preview DMGs and their
checksums after the canonical polished 0.5.2 release became available. Those four
preview assets have been removed; the original 0.5.1 pair and tag remain intact.
The earlier instructions to preserve the previews no longer apply. Cleanup
verification: `docs/runs/archive/clean-release-assets.md`.

## 0.5.2 App Icon Release

The maintainer approved the blue icon (light tile, slate waveform, blue cursor)
on 2026-10-23 and explicitly authorized pushing main, the v0.5.2 tag, the GitHub
release and the tap update in the same request. Version 0.5.2/build 8 changes only
the icon and its `.icns` encoding. Since this release, one decorative
`BabbelStream-<version>.dmg` plus portable checksum serves both direct download and
the cask; there is no separate `-pretty` asset. Package it from the clean tag:

```bash
BUILD_MODE=candidate DMG_LAYOUT=finder CODESIGN_IDENTITY=- DMG_CODESIGN_IDENTITY=- DMG_NAME=BabbelStream-0.5.2.dmg scripts/package-dmg.sh
```

Finder layout needs an unlocked desktop with Finder automation access. The
other-Mac downloaded/quarantined pilot test was not repeated for this icon-only
release; record its outcome when performed. Evidence:
`docs/runs/archive/release-v0.5.2.md`.

## Public Data Scrub Provenance

The authorized history scrub rewrites existing source/tag IDs without replacing
old installer bytes. Preserve original source IDs/checksums in release evidence,
label the mismatch in existing release notes, and never rebuild/replace the same
version's uploaded bytes. Prepare 0.5.3/build 9 from a clean rewritten commit, run
all-ref and optimized-binary hygiene checks, and stop for installation/smoke
authorization before publishing, updating the tap or deleting older assets.

## Authorized Remote Installer Withdrawal (2026-10-24)

The maintainer explicitly authorized removal of the old remote DMGs while keeping
local copies. Both 0.5.1/0.5.2 DMGs and portable checksums were hash-verified against
GitHub asset digests before removal. Release notes and rewritten tags are retained
as historical records; source archives are sanitized and are not app installers.
The tap is temporarily disabled without changing its version/URL/checksum or any
installed app. This owner-approved privacy withdrawal is separate from publishing
0.5.3, which still requires candidate installation and real-Mac smoke approval.
