# Decorative DMG Layout Run

## Baseline and scope

- Clean main/origin main 6df88a59d928ce00c7cc11f56743176950a78af6.
- Branch codex/pretty-dmg-layout.
- Approved feature: docs/features/pretty-dmg-layout/spec.md.
- User authorizes additional decorative installer publication on GitHub, with
  original v0.5.1 payload/tag/assets and Homebrew cask preserved.
- No install, launch, security bypass or private signing-material use.

## Stages

1. Completed: restore user-facing packaging default; reconcile release docs.
2. Completed: decorate and package existing verified app without rebuilding.
3. Completed: visual/payload/checksum verification and additional asset publication.

## Decisions

Candidate remains plain/unattended. Default decorative development/distribution
packaging retains the existing Finder method. For this session's artifact, native UI navigation opened the staging image but
could not expose the separate Finder view-options panel. Use dmgbuild 1.6.7 in
an isolated temporary Python environment to write Finder metadata directly (no
AppleScript execution). Native APIs alone do not expose .DS_Store construction;
this transient artifact tool adds no app/repository/runtime dependency. Future
normal packaging continues to use the existing Finder implementation.

## Verification and publication

- Baseline and final task check PASS, logs /tmp/babbelstream-pretty-{baseline,final}-check.log.
  Shell syntax and whitespace checks PASS. Existing toolchain warnings unchanged.
- Native UI could not expose Finder's floating view-options panel. An isolated
  /tmp/babbelstream-dmg-tools environment supplied dmgbuild 1.6.7 and its
  ds_store/mac_alias libraries; no dependency added to repo or app. dmgbuild and
  manual hdiutil convert both hit Resource temporarily unavailable on this host.
  Wrote the same Finder view dictionaries/icon locations using those libraries,
  then used the project's working hdiutil create -srcfolder UDZO path.
- Original SVG rendered/cropped to 660x420. Finder metadata: window 660x420,
  icon size 128, text size 12, app (180,232), Applications (480,232), background
  alias and icon view; no toolbar/sidebar/status bar. Final compressed image
  opened with visible original instructions, curved arrow, left app/right folder.
  Actual native screenshot visually inspected. Applications symlink is /Applications.
- diff -qr of complete app bundles PASS; exact executable SHA-256 remains
  cf4862a37d307ca15d4b208f296eaf8effd4b2ce57dc2278e7c3e38446901a84.
  Strict candidate signature PASS, version/build/source unchanged 0.5.1/7/8f229fe.
- New container ad-hoc signed without private key; strict container signature and
  hdiutil integrity PASS. DMG 1068268 bytes, SHA-256
  a03b0482f4a264c5e7aecf1d3235d83cce367745741b5baf67f65577dcda6b20.
- Published only BabbelStream-0.5.1-pretty.dmg and its portable checksum, using
  gh upload fallback because connectors do not support release-asset upload.
  No clobber, replacement, release-body edit, cask edit, app launch/install or new tag.
- Additional GitHub asset IDs RA_kwDOTO-pL84n9bAt and RA_kwDOTO-pL84n9bAr.
  Fresh anonymous HTTPS download and checksum PASS under
  /tmp/babbelstream-pretty-public-download. All prior release asset IDs, digests,
  sizes and updatedAt timestamps compared unchanged against saved baseline.
- Original local/public DMG SHA-256 remains
  8dc567ac48285cc3612e1743b30262eb3dd40eecdb4b6d7879d322a41125824d.
  v0.5.1 remains at 8f229fefe2ef344bf2e1c1869779f6d6b077b42e;
  Homebrew retains its original filename/hash. No dependency or app-source change.

## Closeout

User authorized packaging default restoration and additional public asset.
Checks and delegated visual review passed. Commit/push packaging/docs, fast-forward
main without a new app release tag. Leave the final pretty image open for user
inspection; retain existing app installation untouched. Host policy acceptance of
this ad-hoc app remains unproven by an appearance-only change.

## Next action

The maintainer tries the separately named decorative installer manually if desired.

