# GPT-6 Luna cleanup implementation run

## Outcome

Make GPT-6 Luna the default remote cleanup model, explicitly disable
reasoning, and verify the cleanup prompt with synthetic dictation.

## Baseline and authority

- Clean, pushed baseline `21e4c7f` on `codex/dictation-reliability`.
- Feature branch `codex/luna-cleanup` in a separate worktree. Existing
  provider benchmark edits remain in the original checkout.
- Target candidate 0.6.1, build 16. The pre-existing build 15 candidate
  remains covered by its own run.
- The [approved contract](../../features/luna-cleanup/spec.md) covers
  implementation, feature-branch publication and candidate packaging. The
  existing provider benchmark used synthetic transcripts on the configured
  proxy.

## Stages and evidence

- Baseline `task check` passed with CMake 4.4.4.
- Implemented the default, one-time migration, explicit reasoning setting and
  Luna prompt. Added disposable-preferences and loopback request checks.
- Compared both prompts on the configured proxy using six synthetic dictations
  and a synthetic dictionary. The original passed five of six targeted
  checks. It dropped an intentional repetition. The revised prompt preserved
  the repetition and passed all six, including mixed-language wording,
  negation, identifiers, a dictionary correction and a dictated instruction.
  Both prompts had a median complete response of 0.88 seconds in this sample.
  The proxy reported zero reasoning tokens. The check retained only metrics
  and pass/fail labels.
- Final `task check` passed, including settings and loopback fixtures, both
  native helper builds, release preflight, installer and hygiene checks.
- Feature commit `ac6a475` was pushed after the history scan. Built the plain
  candidate from that clean commit. Optimized binary hygiene, disk image
  integrity, portable checksum, mounted bundle metadata and signatures passed.

## Candidate

- Version 0.6.1, build 16, commit `ac6a475`.
- Artifact `dist/BabbelStream-0.6.1-candidate.16-ac6a475.dmg`.
- SHA-256 `245437c211190d2565e918a64dd956cc43a193d0f7567fcade8e576bfd1f0278`.
- Ad-hoc signed. The development Mac currently has 0.6.1, build 15,
  commit `795cc76` installed.

## Remaining gate

Candidate installation and the microphone-to-editor smoke test are pending.

## Next action

After installation approval, install build 16 and run the mixed-language
cleanup and focused delivery smoke checks.
