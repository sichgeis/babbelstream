# Current Installer Release Alignment Run

## Outcome

Make the existing shared bootstrap prepare the latest verified public release,
check that it includes current main app behavior, and prevent release-channel drift.

## Baseline

- Session checkout: clean main, f0e937ce1b62f903303937a818582d6d346ef9a8.
- Refreshed/fast-forwarded base: clean pushed main, c901f2a.
- Branch: codex/installer-current-release.
- Current app/tag: v0.6.0, c36c28c, build 14. No app/build changes since tag;
  only README and documentation changes on main.
- Shared main bootstrap fetched a helper still pinned to 0.5.3/build 11.
- Public GitHub release and Homebrew already advertise 0.6.0; no new release needed.
- Required public Git name/email verified before changes.

## Authority And Scope

The maintainer requested autonomous inspection and repair of the shared installer,
including release/main availability and internal installation instructions.
Refresh existing public-artifact pins, maintain fixture coverage and release
checks, publish the fix on main and update the internal guide. Preserve the
release-pinned trust model and generic non-secret provider arguments. No private
profile belongs in source/evidence. No app rebuild/tag/asset replacement, production
installation, user stores, permission changes or provider/microphone calls needed.

## Decisions

- Reuse the published canonical DMG, not the earlier local-only 0.6.0 artifact.
- Keep the existing shared command unchanged so already-copied commands benefit.
- Developer-only online check detects stale pins and current-source gaps; ordinary
  helper execution remains pinned and uses no dynamic release trust manifest.
  Download/update runs check GitHub's latest stable redirect solely to reject a
  stale/unavailable result before any staging or configuration. Local-file mode
  remains available without that network check.
- Canonical checks initially hit sandbox cache denial. With developer-cache access,
  app/behavior/speech checks pass, then the existing missing CMake prerequisite
  blocks cleanup. Prepare CMake in temporary storage only; no global installation.

## Stages And Validation

- Inspection: complete. Latest public release/tag/main and tap compared.
- Public DMG/checksum independently downloaded: pass; SHA-256
  `2752d399f5b1575be0a0ed9e5e8bb107a8b6b029584c196653c7a9db66f98ce4`.
- Mounted read-only metadata: 0.6.0/build 14/c36c28c, arm64/ad-hoc/runtime.
  CDHash `cfab070efd8afedb6fad882575b7ad2db29b68c3`.
- Implementation/docs/fixtures: complete.
- Full `task check`: pass with temporary CMake and normal developer-cache access;
  app/behavior, both native helper builds, release fixtures, 26 installation
  fixtures, five release-alignment tests and four hygiene fixtures pass.
- Online latest-release/tag/current-source alignment: pass.
- Native `--verify-only --download`: pass including latest redirect, independent
  public download, pinned checksum, deep strict signature, metadata, architecture
  and entitlements. No quarantine/settings/install/launch mutation.
- Working-tree public hygiene and pre-commit history checks: pass.
- Internal page changes dry-run validated; existing rich HTML and command preserved.
- Feature/main publication, published bootstrap verification and page readback: pending.
- Real managed-Mac installation/dictation remains human work; no pass claimed.

## Current Blocker

None for installer repair; complete validation/publication next.

## Next Action

Publish the validated fix on main, verify the fetched helper, then update the internal guide.
