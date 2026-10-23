# Local Development

```bash
task check
scripts/build-app.sh
```

`task check` builds the app, runs the fixture-based `BabbelStreamChecks` executable (including loopback-only transport checks), and verifies release preflight in disposable Git repositories. Project commands select the validated installed macOS 26.5 SDK locally; see `docs/release.md` for toolchain prerequisites and explicit overrides. This CLT-only environment does not expose XCTest or Swift Testing through SwiftPM, so the repository intentionally has no misleading empty `swift test` target.

The app bundle is written to:

```text
dist/BabbelStream.app
```

For stable local permissions, create a local signing identity once, then install the app from a stable path:

```bash
scripts/create-local-codesign-identity.sh
scripts/install-dev-app.sh
```

`scripts/install-dev-app.sh` is the daily development install loop. It builds the app, packages the local DMG, opens the Finder drag-to-Applications window, and stops any running BabbelStream copy so Finder can replace it cleanly. The script does not use `sudo`; if `/Applications` needs authorization, Finder shows the standard macOS prompt during the drag copy. After copying, restart the installed app with:

```bash
RESTART_ONLY=1 scripts/install-dev-app.sh
```

Set `WAIT_FOR_INSTALL=1` if you want the script to wait for the drag copy and launch `/Applications/BabbelStream.app` after it appears.

For a clean optimized review artifact without installation or signing-key lookup, use `task app:candidate`. The approved non-notarized Homebrew pilot and optional Developer ID channel have separate requirements; see [release guide](release.md).

Equivalent Taskfile shortcuts are available as `task app:build`, `task app:install-dev`, `task app:restart`, and `task app:package-dmg`.

## Package A DMG

```bash
scripts/package-dmg.sh
```

The DMG is written to:

```text
dist/BabbelStream-$(cat VERSION).dmg
```

The approved own-tap pilot reuses an exact tagged ad-hoc DMG, clearly labeled as non-notarized. Developer ID signing/notarization remains an optional later channel; see [release guide](release.md).


## Documentation and validation

Read [AGENTS.md](../AGENTS.md) before changing the project. The [documentation
index](README.md) links the product, architecture, privacy, feature and release
contracts. Start substantial work with the current project status and active run.

The canonical command is `task check`. Native microphone/Accessibility behavior,
actual editor delivery and visual acceptance retain explicit manual coverage.
See the [test plan](test-plan.md); passing executable checks does not establish
that a downloaded app launches on another Mac.

Building or packaging does not authorize changing the daily installation, using
private signing material, publishing a release or making a real provider request.
The Homebrew pilot's approved envelope and human gate are in its
[feature contract](features/homebrew-distribution/spec.md).
