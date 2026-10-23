# 0.5.2 App Icon Release

## Authority And Baseline

the maintainer chose icon variant 8 (light blue-tinted tile, slate waveform, blue
cursor; brand tokens #FFFFFF→#E2EAFF, #030436, #0039D5) on 2026-10-23 and in the
same request authorized updating the repository, pushing main, a GitHub release with
a new DMG and the Homebrew tap update. That request waived the separate smoke gate
for this icon-only release.

- Base: main at bbf5977 (after rebasing over concurrent docs commits 47d247f/bbf5977).
- Branch: claude/app-icon-redesign-07a797, fast-forwarded into main.
- Scope: `Resources/AppIcon.svg`, `.icns` writer in `scripts/build-app.sh`, version 0.5.2/build 8, docs. No Swift source, permission, provider or entitlement change.

## Decisions

- `iconutil` stores 16/32 px as ARGB PackBits (`ic04`/`ic05`); with the light tile the 16 px entry decoded as a yellow band in Finder. PNG data in `icp4`/`icp5` decoded as noise on macOS 26.7.1. The build now writes only PNG entries `ic07`–`ic14`; macOS scales 16/32 px from the @2x entries. Verified by rendering the built bundle through NSWorkspace at 16–256 px on light/dark.
- One decorative (`DMG_LAYOUT=finder`) `BabbelStream-0.5.2.dmg` serves direct download and the cask, replacing the separate plain/pretty assets used for 0.5.1.

## Evidence

- `task check` PASS before and after the rebase (behavior checks and release preflight fixtures); preexisting compiler/linker warnings unchanged.
- Final commit 3fb7a736110a540e7f1c1de1e36247e9c0433509 pushed to main; annotated tag v0.5.2 (object 22c5e737effd49f855573cb89ef2956feb32dc2d) points to it.
- Package: `BUILD_MODE=candidate DMG_LAYOUT=finder CODESIGN_IDENTITY=- DMG_CODESIGN_IDENTITY=- DMG_NAME=BabbelStream-0.5.2.dmg scripts/package-dmg.sh` from the clean tagged commit. hdiutil verify VALID; DMG ad-hoc signature valid.
- Mounted payload: `verify-app.sh candidate` PASS; 0.5.2 / build 8 / BabbelStreamGitCommit 3fb7a73; arm64; LSMinimumSystemVersion 13.0; only `com.apple.security.device.audio-input`; app contains Info.plist, CodeResources, executable and BabbelStream.icns only; volume holds the app, Applications link, `.background` and `.DS_Store`.
- SHA-256 728b702d394a21a7af7ebca8d2385422973d2b3ee22ac1c809448f16523a2c82 (1.3 MB). Preserved at `dist/BabbelStream-0.5.2.dmg` in the main checkout with a portable checksum.
- GitHub release v0.5.2 created as draft; maintainer download byte-identical; then published as latest. Anonymous HTTPS download of DMG and checksum: `shasum -c` OK.
- Tap `sichgeis/homebrew-tap` commit 2c07bde on main pins 0.5.2 and the hash. `brew style` no offenses; Homebrew 7.0.10 `brew audit --cask --online sichgeis/tap/babbelstream` exit 0.

## Not Performed

- No local installation or launch of 0.5.2; the daily installation was not changed.
- Other-Mac downloaded/quarantined launch and the first real Homebrew upgrade 0.5.1 → 0.5.2 remain pending (see project status Next Action).
- Menu-bar status icons are SF Symbols and were intentionally unchanged.
