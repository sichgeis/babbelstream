# Installer Provider Configuration

## Status

- State: Implemented; native user pilot pending.
- Owner: Maintainer.
- Approval: 2026-10-26 conversation: implement the combined one-command
  installation/configuration flow directly on main. Organization-specific values
  belong only in internal instructions, never this public repository.

## Problem And Desired Outcome

Pilot users should enter non-secret connection settings once as installer
arguments rather than copying several fields into Settings. One confirmation
covers the installer action and the displayed configuration. Each user still
enters their personal API key in the app and uses Apply Settings before dictation.

## Research And Alternatives

| Approach | Benefit | Tradeoff | Decision |
| --- | --- | --- | --- |
| Generic helper arguments + native preferences | Works with 0.5.3, no app rebuild | Requires careful merge/rollback and credential binding | Adopt |
| App configuration import | App owns validation | New app release and import flow | Defer |
| Organization preset in public app | Simple selection | Publishes private endpoint details | Excluded |

## Accepted Scope

- Optional all-or-none arguments: `--provider-url`, `--model-routing`,
  `--transcription-model`, `--cleanup-model`.
- HTTPS origin only, optional valid port; reject userinfo, path, query, fragment,
  whitespace and command/plist syntax. Models/routing must fit shipped support.
- Set standard transcription/cleanup paths, selected models/routing and migration
  marker; disable personal fallback and direct-personal mode.
- Set the non-secret primary key origin marker to `unassociated`, including for
  legacy installations. Never silently approve an existing key for a new origin.
- Preserve all other settings and all Keychain items, recordings and archives.
- Configure an exact current installed app without redownloading or changing its
  quarantine. Older installations retain manual Finder upgrade semantics.
- Default public installation without these arguments leaves configuration alone.

## Non-Goals

No API-key argument, secret access, key distribution, provider call, permission
grant, new provider, background updater or automatic installed-app replacement.
Do not bundle private profiles, organization names or internal URLs publicly.

## User Workflow And Interaction Contract

1. Internal instructions append four arguments to the same stable public command.
2. Validate arguments before downloads, secret access or preference writes. App
   must be quit; retain existing platform/Homebrew/artifact verification guards.
3. Display supplied values, endpoint paths, disabled personal modes, existing-field
   replacement and personal-key re-entry requirement before the single PREPARE
   prompt (case-insensitive). For an already-current app, explain configuration-only.
4. Cancellation/EOF or verification-only never reads or writes app preferences.
5. After consent and successful installer verification, export current non-secret
   preferences into a private temporary backup. Merge only the listed fields.
   Recheck that the app is closed, import once, then read back the written fields.
6. On success delete preference snapshots. Open the illustrated installer for a
   new/older installation. For a current app, finish without opening the installer.
7. User installs if needed, opens the app, enters a personal approved API key and
   chooses Apply Settings. No test request is sent automatically.

## State, Errors And Recovery

| Failure | Behavior |
| --- | --- |
| Partial/duplicate/unknown/invalid options | Stop before network or preference work; do not echo unknown argument values |
| Existing preferences unreadable | Stop without overwriting them |
| App starts during preparation | Stop before preference import |
| Save or readback fails, or signal during save | Restore prior values and delete only configuration keys absent from the backup; defaults import merges dictionaries |
| Restore fails | Stop, do not reveal installer; retain private recovery snapshot and print recovery location |
| Installation later canceled in Finder | Confirmed preferences remain; no app/data was replaced automatically |

## Data, Privacy, Security And Permissions

Inputs are non-secret but may contain internal hostnames: internal commands are
stored only in internal documentation. Terminal shell history may retain command
arguments; API keys are forbidden there. The summary shows the chosen destination
before consent. Temporary preference snapshots use a user-only directory and
are removed after success/rollback; failed rollback explicitly retains recovery
files. No persistent logs or private values in public fixtures/docs.

The app's saved-key presence marker and actual Keychain item remain unchanged,
but its approved-origin marker is invalidated so launch cannot adopt an old key
for the new destination. Personal fallback/direct mode are disabled regardless
of previous values. Do not grant a credential origin from a shell argument.

## Architecture Impact

Standalone system Bash, defaults, PlistBuddy and plutil; no added runtime
dependency or app source/binary change. Uses the 0.5.3 non-secret preference keys.
Live OS preferences can still race with another writer after the final app-closed
check; no claim of a cross-process lock or atomic multi-process transaction.

## Acceptance Criteria And Automated Validation

- One consent covers installation plus explicitly supplied connection fields.
- No configuration flags preserves original installer behavior.
- Preserve unrelated preferences and existing key presence; require key re-entry.
- Fake-driven tests cover all supplied fields, fresh/legacy/current installation,
  fallback disabling, cancellation, verify-only, malformed/partial arguments,
  no credential echo, import/readback failure and merge-aware rollback/recovery.
- Canonical `task check`; separate native import/read/restore validation uses
  a unique synthetic preference domain, never the production settings domain.

## Manual Smoke Test And Approval Gate

On a consenting pilot Mac, run the internal command, review summary and cancel
once, then rerun and consent. Install if needed, inspect configured values in
Provider settings, enter a personal key and Apply. Confirm the app stays blocked
from using old keys until explicit entry. A real provider test remains a separate
human-authorized action. Verify the current-app configuration-only route too.

Direct main work and coherent commits are explicitly authorized. No new app tag,
release assets or signing material are needed. Native user settings/provider
validation must remain pending until actually performed.

## Open Questions

- Native pilot confirmation of settings/UI/credential-entry flow remains pending.
