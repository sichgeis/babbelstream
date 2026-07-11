# Release Guide

## Versioning

The root `VERSION` file is the source of truth for the app bundle version, DMG filename, and local release tooling. BabbelStream uses `MAJOR.MINOR.PATCH` Semantic Versioning:

- Before 1.0, increment `MINOR` for substantial user-facing workflow, UI, or compatibility changes.
- Increment `PATCH` for compatible fixes, reliability work, and incremental behavior improvements.
- Create an annotated Git tag named `v<version>` on every release commit.
- Keep `CHANGELOG.md`, `VERSION`, the release commit, and its tag aligned.

Build scripts accept an explicit `VERSION=x.y.z` override for release automation, but ordinary local builds read `VERSION` automatically.

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

The local build signs with `BabbelStream Local Code Signing` when that identity exists, otherwise it falls back to ad-hoc signing. This is not enough for public distribution.

For deterministic Settings layout screenshots, launch a local build with `--settings` and an optional tab selector:

```bash
open -na dist/BabbelStream.app --args --settings --settings-tab=provider
```

Supported tab names are `general`, `provider`, `writing`, `archive`, and `diagnostics`. Window sharing is enabled only for this explicit QA mode; normal launches retain the default non-shareable window behavior.

### GitHub Release Candidate

Use this once the app is signed with a real Developer ID Application certificate:

```bash
CONFIGURATION=release CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" scripts/build-app.sh
DMG_CODESIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" scripts/package-dmg.sh
```

Then notarize the DMG with Apple's notary service and staple the result before publishing it.

## Developer ID And Notarization

For Mac software distributed outside the Mac App Store, Apple expects a Developer ID certificate and notarization. Apple documents that Developer ID signing plus a notarization ticket lets Gatekeeper verify that downloaded software is not known malware and has not been tampered with.

Official references:

- [Developer ID certificates](https://developer.apple.com/help/account/certificates/create-developer-id-certificates)
- [Notarizing macOS software before distribution](https://developer.apple.com/documentation/security/notarizing-macos-software-before-distribution)
- [Customizing the notarization workflow](https://developer.apple.com/documentation/security/customizing-the-notarization-workflow)

Typical command shape:

```bash
xcrun notarytool submit "dist/BabbelStream-$(cat VERSION).dmg" \
  --keychain-profile "notarytool-profile" \
  --wait

xcrun stapler staple "dist/BabbelStream-$(cat VERSION).dmg"
spctl --assess --type open --verbose "dist/BabbelStream-$(cat VERSION).dmg"
```

## Manual Release Checklist

- `task check`
- `scripts/package-dmg.sh`
- Open the DMG and copy `BabbelStream.app` to `/Applications`.
- Launch from `/Applications`.
- Confirm menu-bar icon appears.
- Confirm Settings opens.
- Confirm all five Settings tabs render without clipping at the 700×560 minimum and 760×640 default window sizes; Provider and Diagnostics should scroll without moving the Apply footer.
- Confirm Microphone and Accessibility prompts are understandable.
- Dictate English, German, and mixed German-English samples into Slack or TextEdit.
- Confirm no message is auto-sent.
- Confirm consecutive dictations are separated by a space.
- Confirm no temporary audio remains in the BabbelStream temp directory after success, failure, and cancel.
- Follow the current upgrade smoke test in `docs/upgrade-smoke-test-2026-07.md`
  when validating the July 2026 reliability changes.

## GitHub Release Assets

Publish:

- `BabbelStream-<VERSION>.dmg`
- `BabbelStream-<VERSION>.dmg.sha256`
- Release notes copied from `CHANGELOG.md`

Do not publish local `.env` files or provider secrets.
