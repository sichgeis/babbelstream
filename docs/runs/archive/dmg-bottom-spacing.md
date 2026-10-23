# DMG Bottom Spacing Revision

Baseline: clean main fe2d48ef3fb2e6864fb3fa6a56576b305690d97b.
Branch: codex/dmg-bottom-spacing. the maintainer requested less cramped lower spacing
and cleaner borders in the installer. Continues the approved decorative-DMG scope;
no app rebuild/install or original asset replacement.

Cause: first pretty metadata used a 420-point outer window for a 420-point
background, omitting title-bar height. Its lower card corners were clipped.
Revision: 440-point canvas, 468-point outer window, more bottom card space,
lighter border and softer shadow. Icon positions and exact 0.5.1 app stay intact.

Build as BabbelStream-0.5.1-pretty-r2.dmg. Reuse isolated temporary DSStore tools
and the working srcfolder compression path. Verify actual Finder screenshot,
full app equality/signature, DMG integrity/checksum and existing asset preservation.
No new app release/version/tag or Homebrew update.

## Completed verification

- Real Finder R2 window inspected: full lower rounded corners and border visible,
  extra clearance below arrow/icons, softer outline/shadow. Left R2 window open.
- 440-point raster canvas and 468-point outer window; standard packaging defaults
  match these values. Original square SVG crop offset changed from 120 to 110.
- Exact full app-bundle diff against released app PASS, strict candidate signature
  PASS. No executable, version/build/source, app signing identity or entitlements
  changed. No installation/launch or OS security alteration.
- New container ad-hoc signature and DMG integrity PASS. R2 is 1066584 bytes;
  SHA-256 dfbb3a66d0e0d6ae152a6d7686ea77ec0ad353c86e96ad83345f6839ca17bf97.
- Published R2/checksum as new assets, no clobber, tag or cask change. Fresh
  anonymous download and portable checksum verified. All four previous assets'
  IDs, digests, sizes and updatedAt timestamps compared unchanged.
- Canonical task check PASS (/tmp/babbelstream-dmg-spacing-check.log), shell
  syntax and whitespace checks PASS. No new dependency; reused temporary layout
  tools from prior run. Original app smoke evidence remains applicable; visual
  refinement does not prove launch acceptance on managed Macs.
- README/development links select R2; release/spec/status document geometry and
  preservation of prior assets. Archive run with packaging/docs commit.

## Next action

the maintainer reviews the open R2 installer visually and installs manually if desired.

