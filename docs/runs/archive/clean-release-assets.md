# Clean release assets

## Authority and baseline

the maintainer approved one polished DMG/checksum, Homebrew alignment, removal of extra
preview variants and main/public cleanup. Coordinate with the finished icon release.
Baseline: clean main 808f601, app-source/tag v0.5.2 at 3fb7a73, version 0.5.2/build 8.
Branch: codex/clean-release-assets. No app changes, new version or tag required.

## Execution

- Existing 0.5.2 has exactly two assets and the polished layout/new icon.
- Independent anonymous download: portable checksum OK, hdiutil integrity valid,
  candidate app signature valid; app plus Applications symlink, background and
  Finder metadata present. Prior native layout evidence: release-v0.5.2.md.
- DMG SHA-256: 728b702d394a21a7af7ebca8d2385422973d2b3ee22ac1c809448f16523a2c82.
- Tap main 2c07bdee8f4704547863ae5057f1285403298f1b already pins 0.5.2 and
  that exact canonical URL/hash. Verified through GitHub connector; no redundant
  tap commit needed.
- Canonical asset IDs retained: 0.5.1 669768953/669768954; 0.5.2
  670450394/670450392. Preview files retained locally under ignored dist/.
- Updated README, release/operator rules and historical preview contract.

## Completed verification

- Removed only BabbelStream-0.5.1-pretty.dmg, its checksum, and the corresponding
  pretty-r2 pair. GitHub connector has no asset deletion operation; used already
  authenticated gh release delete-asset for these exact names.
- Re-read both releases through the GitHub connector: each has exactly its two
  canonical assets, with original IDs and digests unchanged.
- Downloaded 0.5.2 background is 660x440; Applications links to /Applications.
- task check passed: full app build, behavior checks and release preflight fixtures.
  Existing CLT framework-search warnings remain.
- git diff --check passed. Documentation-only change; no rebuild or new app tag.

## Closeout

Archive this record with the docs/policy commit and fast-forward main after a fresh
remote check. Release 0.5.2 and tap remain unchanged; cleanup is complete.
No local installation/launch, permission change or provider request is part of this
cleanup. Actual Homebrew 0.5.1-to-0.5.2 upgrade and other-Mac launch remain pending.
