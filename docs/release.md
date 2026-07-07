# Release Guide

## Release Levels

### Local Testing

Use this for daily development and personal smoke testing on the development Mac:

```bash
swift test
swift run BabbelStreamChecks
scripts/install-dev-app.sh
```

`scripts/install-dev-app.sh` builds the app bundle, packages the local DMG, opens the Finder drag-to-Applications window, and stops any running BabbelStream copy so Finder can replace it cleanly. The script does not use `sudo`; if `/Applications` needs authorization, Finder shows the standard macOS prompt during the drag copy. After copying, run `RESTART_ONLY=1 scripts/install-dev-app.sh` to launch from `/Applications`.

For release-style manual QA, package a local DMG:

```bash
scripts/package-dmg.sh
```

Output:

```text
dist/BabbelStream-0.1.0.dmg
```

The local build signs with `BabbelStream Local Code Signing` when that identity exists, otherwise it falls back to ad-hoc signing. This is not enough for public distribution.

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
xcrun notarytool submit dist/BabbelStream-0.1.0.dmg \
  --keychain-profile "notarytool-profile" \
  --wait

xcrun stapler staple dist/BabbelStream-0.1.0.dmg
spctl --assess --type open --verbose dist/BabbelStream-0.1.0.dmg
```

## Manual Release Checklist

- `swift test`
- `swift run BabbelStreamChecks`
- `scripts/package-dmg.sh`
- Open the DMG and copy `BabbelStream.app` to `/Applications`.
- Launch from `/Applications`.
- Confirm menu-bar icon appears.
- Confirm Settings opens.
- Confirm Microphone and Accessibility prompts are understandable.
- Dictate English, German, and mixed German-English samples into Slack or TextEdit.
- Confirm no message is auto-sent.
- Confirm consecutive dictations are separated by a space.
- Confirm no temporary audio remains in the BabbelStream temp directory after success, failure, and cancel.

## GitHub Release Assets

Publish:

- `BabbelStream-0.1.0.dmg`
- `BabbelStream-0.1.0.dmg.sha256`
- Release notes copied from `CHANGELOG.md`

Do not publish local `.env` files or provider secrets.
