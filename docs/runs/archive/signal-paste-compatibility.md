# Signal Paste Compatibility Implementation Run

## Outcome And Baseline

Investigate Signal draft insertion and prepare a targeted repair using the existing clipboard path. Baseline: clean `main` at `d662a72` (released 0.4.4); latest pushed documentation commit: `42711bf`. Christian explicitly approved committing the Signal-only fix and installing a 0.4.5 candidate on 2026-09-05. Continue direct-main commits/pushes; Signal smoke approval was received on 2026-09-05.

## Approved Contract

`docs/features/signal-paste-compatibility/spec.md`. Exact Signal bundle only; no new provider, permission, dependency, or persistence.

## Evidence And Decisions

- Installed app metadata: Signal 8.26.0, `org.whispersystems.signal-desktop`.
- Shipped app bundle contains a Quill editor. Source inspection only; no user conversation files read.
- Christian confirms Copy Last Draft plus Cmd+V works.
- Treat AX false success as the likely mechanism and route this app through normal paste. Do not claim live confirmation until smoke.

## Stages

1. Targeted policy, fake checks, and durable docs: Completed and pushed at `dfa0a5a`.
2. Commit/version/package/install: Completed.
3. Human Signal smoke: Passed per Christian on 2026-09-05. Final release packaging/install: Completed.

## Validation

Baseline and targeted `task check`: passed. Checks cover Signal normalization, rejection of a similarly named helper id, and bypass of a reportedly successful AX insertion in favor of exactly one clipboard write/paste. Existing insertion/coordinator checks pass. Clean candidate 0.4.5 / dfa0a5a is packaged, signed, installed, and running. No real provider request or Signal message sent by the agent.

## Current Blocker

None. Christian confirmed successful Signal smoke; no additional live-app checks are claimed.

## Next Action

None; release complete. Broader input compatibility remains unapproved candidate work.

## Candidate And Installation Evidence

- Candidate source: clean `main` commit `dfa0a5a`, pushed to origin.
- Final `task check`: passed; no private conversation, real clipboard, microphone, provider, or credential access in checks.
- Production package: `CONFIGURATION=release scripts/package-dmg.sh` passed; build completed in 6.95 seconds.
- Artifact: `dist/BabbelStream-0.4.5.dmg`, 929561 bytes; hdiutil verification passed.
- SHA-256: `c18f266e5c63fa61e097b18c0cd47cba8902a2b19a5bac815255af35e6d4cca1`; independent hash matches `.sha256` file.
- Mounted candidate read-only; contained app reports 0.4.5 / dfa0a5a and passes strict/deep local-signature verification.
- Installed via Finder at `/Applications/BabbelStream.app`; verified version, commit, signature, and running executable (PID 77537) on 2026-09-05. DMG detached afterward.
- Christian confirmed successful Signal smoke on 2026-09-05. Manual Cmd+V was already confirmed working.
- Release-finalization `task check`: passed on 2026-09-05.

## Final Release Evidence

- Annotated `v0.4.5` points to clean release commit `069acc3` on main; main/tag pushed.
- Final production package rebuilt from that commit; hdiutil checksum verification passed.
- Artifact: `dist/BabbelStream-0.4.5.dmg`, 929565 bytes.
- SHA-256: `d81fa47b8e9c76833edc702ca0c2fafc14f28c5c110658ab6bc38cc8b38d9d8b`; independent hash matched sidecar.
- Mounted read-only and verified contained app version/commit and strict/deep signature.
- Installed via Finder, launched, and verified `/Applications/BabbelStream.app` reports 0.4.5 / 069acc3 and runs from Applications (PID 85601) on 2026-09-05. DMG detached.
- Reviewed the complete production diff against v0.4.4: only the exact Signal routing entry changed; fixture checks and specifications accompany it. No new permissions, providers, dependencies, retention, or auto-send behavior.
- The user confirmed Signal smoke success. No broader keyboard-layout, terminal, or remote-desktop compatibility is claimed.
