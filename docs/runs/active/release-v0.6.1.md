# BabbelStream 0.6.1 release run

## Baseline and authority

- Clean, pushed `codex/luna-cleanup` at `1bc4c68`, based on app main `decbc10`.
- Candidate build 16, `ac6a475`, is installed and verified on the development
  Mac. The release includes the dictation reliability and Luna cleanup changes.
- The maintainer authorized GitHub publication, the Homebrew bump, documentation
  alignment and local installation on 2026-11-20. They explicitly waived the
  microphone-to-editor and focus-switch smoke checks for 0.6.1.

## Stages

- Prepare the build 17 release commit and rerun canonical checks.
- Fast-forward main, tag the exact release commit, and package the polished DMG.
- Verify draft and anonymous public downloads, then align the Homebrew cask and
  standalone helper to the same artifact.
- Install and verify the final public bundle and record the release evidence.

## Next action

Run `task check` on the final release source.
