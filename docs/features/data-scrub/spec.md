# Public Data Scrub Specification

## Status

- State: Approved for implementation by the maintainer on 2026-10-23.
- Owner: the maintainer.
- Authority: scrub personal/company data without breaking functionality; follow-up explicitly authorizes backed-up, verified force-pushes of both public repositories and tags. On 2026-10-24 the maintainer explicitly approved migrating clean local checkouts/worktrees and purging obsolete local Git objects.

## Problem And Desired Outcome

Public source, metadata and fixtures must contain no private identities, company
configuration or personal recordings. Preserve dictation, provider configuration,
Keychain/TCC identity, recovery, retention and no-auto-send behavior.

## Research And Alternatives

A forward-only cleanup leaves earlier public objects exposed. The maintainer
selected a complete rewrite of both repositories after backups and verification.
Use git-filter-repo in fresh mirrors; keep helper patterns outside tracked files.

## Accepted Scope And Non-Goals

Sanitize current and historical text, author/committer/tagger identities and tag
messages; remove the recorded fixture from every historical ref; add a synthetic
replacement afterward. Add public hygiene rules and validation. Preserve public
handles, bundle/Keychain identifiers, saved settings and generic company wording.
No new dependencies in the app, providers, permissions, retention or live calls.
No new release publication, tap version change or production installation.
On 2026-10-24 the maintainer explicitly authorized removing the old remote DMGs
while retaining local copies, then approved a temporary remote cask-disable notice.

## User Workflow And State Contract

Saved valid routing remains authoritative across upgrades and host changes.
Missing/invalid routing persists standard OpenAI IDs without hostname inference.
A direct upgrade from a pre-routing version using a LiteLLM namespace requires
selecting LiteLLM once in Settings. All request/hedge/cancellation behavior stays
unchanged. No migration reads real settings or keys during development.

## Domain Rules, Edge Cases And Recovery

Never auto-send. Preserve application identifiers and explicit destinations.
Preserve every branch, including unmerged/local work; keep disconnected backup
mirrors. Migrate only verified-clean worktrees after explicit authorization; never
delete private/ignored files. A rewrite
changes source SHAs; older release bytes retain their original build provenance.
Failure of any all-ref scan blocks pushing. Use leased pushes against captured
remote refs so concurrent upstream changes fail safely.

## Data, Privacy And Architecture

Only repository-controlled data is inspected. Ignore real credentials, archives,
UserDefaults, Keychain and microphone input. Optional fixture metadata is removed;
media encoding/undefined language headers are structural. Private deny terms stay
in Git-local info files or external helpers. Output reports counts/categories.
The only runtime change removes hostname inference; no new app dependency.

## Acceptance Criteria And Automated Validation

- Current files and all reachable historical blobs/messages pass private/generic scans.
- All author/committer/tagger identities use the public noreply identity.
- Only synthetic benchmark audio is reachable after the rewrite.
- `task check` passes; saved LiteLLM/standard choices, absent/invalid routing and host changes are checked with disposable settings.
- Optimized candidate binary passes `strings` hygiene scan.
- Release notes describe original artifacts truthfully after tag IDs change.

## Manual Smoke Test And Approval Gate

After separate installation authorization, verify saved provider/routing, tap/hold,
German/English/mixed speech and unsent paste into Slack. Preserve recovery and
permissions; never send automatically. Publishing a replacement release, updating
the tap to a replacement version require a real-Mac smoke gate. The separate
explicitly authorized withdrawal of old remote assets does not require installation. Cache cleanup by
the hosting service and copies already downloaded remain outside Git rewriting.
