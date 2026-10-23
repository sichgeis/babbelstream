# Decorative DMG Layout

## Status and authority

Implemented and additional assets published on 2026-10-23. Approved by the maintainer: restore the pretty drag-to-Applications layout,
make it the user-facing default, build a separately named local installer and
publish that installer to the GitHub release page. The original 0.5.1 asset/tag
and Homebrew URL/checksum must stay unchanged.

## Contract

- Reuse the existing Resources/DmgBackground.svg, app-left / Applications-right
  placement, connecting arrow, 128-point icons and compact 660-point window.
- Development/manual and distribution packaging default to finder layout.
  Candidate packaging defaults to plain for unattended checks. Explicit
  DMG_LAYOUT=plain or finder remains supported and invalid values fail.
- Existing decorative packaging needs an unlocked desktop and Finder layout access;
  unattended callers must choose plain or candidate. No new runtime dependency. If native UI cannot expose Finder view options during this session, an isolated temporary dmgbuild tool may generate the layout metadata directly without becoming a project dependency.
- Produce BabbelStream-0.5.1-pretty.dmg and portable checksum as additional assets
  on the existing v0.5.1 release. Repackage the verified original app, without
  rebuilding/re-signing/relabeling it; version 0.5.1/build 7/source 8f229fe remain.
- No app installation, launch, permission change, notarization, new tag or cask
  update. Packaging appearance does not change managed-Mac security acceptance.
- Publication is explicitly authorized after visual and payload verification;
  no claim of colleague launch or future upgrades from layout-only verification.

## Validation

Run task check and shell syntax/whitespace checks. Open the separately named DMG,
visually confirm background/instructions/arrow and both icon positions, compare
all app bundle bytes/signature/metadata to the original, validate DMG/checksum,
and independently download the additional published assets. Original release
asset IDs/digests, tag and Homebrew recipe must remain unchanged.

## Bottom-spacing revision (2026-10-23)

the maintainer reported clipped/cramped lower corners in the first pretty installer.
Use a 440-point background in a 468-point outer window (28 points reserved for
the title bar), add lower card padding and soften the border/shadow. Keep the
icon positions/arrow and exact app payload. Preview/publish as a separately named
`BabbelStream-0.5.1-pretty-r2.dmg`; preserve both existing DMGs/checksums and cask.
The first pretty artifact's outer window was only 420 points, cropping its
420-point background; correct this mismatch explicitly in the metadata.
