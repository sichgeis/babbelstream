# BabbelStream 0.6.1 release run

## Baseline and authority

- Clean, pushed `codex/luna-cleanup` at `1bc4c68`, based on app main `decbc10`.
- Candidate build 16, `ac6a475`, is installed and verified on the development
  Mac. The release includes the dictation reliability and Luna cleanup changes.
- The maintainer authorized GitHub publication, the Homebrew bump, documentation
  alignment and local installation on 2026-11-20. They explicitly waived the
  microphone-to-editor and focus-switch smoke checks for 0.6.1.

## Verification and publication

- `task check` passed with CMake 4.4.4. The polished, ad-hoc signed DMG was
  built from the clean annotated tag `v0.6.1`, commit
  `131ab28bcfabafa080b5af444603dcdd2262aeab`. The app and both helpers are
  arm64. Signatures, audio entitlement, Finder metadata, DMG integrity,
  portable checksum and hygiene scans of 13 mounted files and attributes passed.
- The authenticated draft and anonymous public downloads both matched the local
  files byte for byte. The stable release publishes the canonical DMG and its
  portable checksum. [GitHub release](https://github.com/sichgeis/babbelstream/releases/tag/v0.6.1)
- The Homebrew cask and setup instructions shipped in tap commit `0f85ca6`.
  Homebrew 7.0.14 style and strict audit passed. `brew fetch --cask` retrieved
  the same verified bytes. Homebrew installation and upgrade testing for
  0.6.1 remain pilot follow-ups.
- Helper pins and fixtures shipped on app main in `cc0659e`. All 26 helper
  fixtures and five release metadata fixtures passed. `task installer:check-release`
  matched the public tag and app inputs. The helper downloaded from main matched
  the checkout and verified the public payload in read-only mode.
- The development Mac on macOS 26.7.3 runs version 0.6.1, build 17, commit
  `131ab28` from Applications. The installed files and signatures matched the
  mounted public DMG, and the saved model remained `openai/gpt-6-luna`.
  The previous candidate is preserved under
  `dist/rollback/0.6.1-build16-before-release-build17/`.

## Artifact

- `BabbelStream-0.6.1.dmg` is 7,413,257 bytes.
- SHA-256 `5150941438e03fabc3cb03f8f95cd6cb0b8e0ce2b8e6915610503ce28a5f5748`.
- App CDHash `eec531a53823582c02c002726e60cc53422848ca`.
