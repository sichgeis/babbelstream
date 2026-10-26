# Manual Download Installation Helper Specification

## Status

- State: Approved; implementation awaiting native pilot validation.
- Owner: Maintainer.
- Approval: 2026-10-26 conversation: implement the proposed manual helper, README disclaimer, commit and push; then extend it with explicit download/update commands.

## Problem And Desired Outcome

An explicitly consenting user can prepare the exact non-notarized release for
manual installation without developer tools. A release-pinned shell helper
downloads or accepts a DMG, verifies it, and removes quarantine only from its
verified staged app copy. This may resolve a quarantine-based first-open block;
it does not guarantee acceptance by macOS or managed endpoint policy.

## Research And Alternatives

| Route | Benefit | Limitation | Decision |
| --- | --- | --- | --- |
| Explicit manual helper | Native shell/tools; deliberate per-run consent | Removes a first-open security check; endpoint policy may still block | Approved limited pilot |
| Source build | Actual local compilation | Compiler/SDK prerequisites | Deferred |
| Managed deployment | Organization-owned approval | Requires IT involvement | Remains an alternative |
| Developer ID/notarization | Apple-verifiable distribution | Paid membership and signing authorization | Separate channel |

## Accepted Scope And Non-Goals

- Standalone Bash helper, macOS 13+ on Apple Silicon, using system tools only.
- Version 0.5.3/build 11/source b9c0641; pinned DMG SHA-256 and app CDHash.
- Local file, `--download`, `--update`, and mutation-free `--verify-only` modes.
- Download via HTTPS GitHub Releases, bounded connection/transfer timeouts and HTTPS-only redirects.
- The README bootstrap downloads the helper to a temporary file from an immutable source commit and executes it explicitly; never pipe network bytes into a shell.
- No background updates or dynamically trusted latest-release manifests. Refresh
  the helper's pins and README bootstrap for each future supported release.
- No global Gatekeeper change, TCC reset, broad xattr clearing, re-signing,
  credentials, telemetry, provider calls, process killing or automatic app launch.
- No automatic replacement of installed bundles or Homebrew ownership takeover.
- No additional release assets, changed DMG bytes, app version bump or new dependency.

## User Workflow And Interaction Contract

1. Review the README disclaimer and optional helper source; copy its command into Terminal.
2. Helper refuses noninteractive preparation, root execution, known Homebrew
   receipts/symlink ownership, a running app, unsupported platform or malformed input.
3. Update mode checks an existing Applications copy. A newer installed
   version/build is rejected; an equal version/build is a no-op only if signature
   integrity and pinned CDHash match. Older or absent installations continue.
4. Download the pinned DMG or copy the supplied file into a private temporary
   workspace, check its SHA-256 and image integrity, then mount read-only.
5. Verify bundle/executable identifiers, version/build/source, arm64 architecture,
   strict deep signature integrity, exact ad-hoc/runtime CDHash, audio entitlement
   and absence of debugger entitlement. Verification mode then exits and cleans up.
6. Explain the non-notarized status, security-check bypass, company-policy limits,
   mutation scope, and no automatic installation. Require exact `PREPARE` input;
   Return, EOF or any other input cancels without mutation.
7. Remount the private verified image snapshot with a private writable shadow;
   verify its app again and validate the Applications shortcut. The original
   artwork and Finder layout are retained. Inspect attributes, remove only
   `com.apple.quarantine` recursively within that copy, confirm removal and
   reverify signature integrity. Preserve all other attributes and the original DMG.
8. Open the mounted installer root in Finder, preserving its illustrated
   drag-to-Applications layout. Retain the private image/shadow and mount after
   helper exit. User preserves a rollback bundle and drags onto Applications.
   Finder owns any authorization prompt. User launches manually and checks Diagnostics.
9. Eject the installer in Finder, then remove its temporary backing folder after copying. macOS may clear temporary
   storage; the helper can be rerun. Updates use the current README helper command
   with `--update`, after normally quitting the app.

## State, Ownership, Errors And Recovery

| State/failure | Outcome and ownership |
| --- | --- |
| Wrong arguments/platform, running app or Homebrew conflict | Stop before staging; existing app/data untouched |
| Download/hash/image/signature/metadata failure | Abort and clean private workspace; never remove quarantine |
| Cancel, EOF, SIGINT or SIGTERM | Eject temporary image and discard staging where possible |
| Copy or attribute inspection/removal failure | Abort without revealing a prepared app; discard staging |
| Eject failure | Report manual ejection required; retain workspace rather than remove a mounted directory |
| Success | User owns mounted private installer and backing folder until ejected/deleted; original DMG and installed app unchanged |
| Native launch rejection | Contact IT; no escalation to global protection changes |

## Data, Privacy, Security And Permissions

Only release files, bundle metadata and attributes are read. GitHub receives
ordinary download connection metadata; no work content, app stores, keys or
provider data are accessed. No persistent logs are created. The terminal displays
the staged path only to help the user locate it. Workspace permissions are
user-only. A compromised bootstrap source or publishing account remains a trust
risk: a pinned checksum/ad-hoc signature is not Apple identity or malware review.
The script itself may be blocked by endpoint policy and does not strip its own
metadata. Users must have permission under their device policy to use this flow.

## Architecture Impact

Independent release tooling only; no app-runtime changes. The explicit manual
exception amends distribution guidance while the Homebrew cask retains quarantine
and has no executable hooks. Native verification APIs are accessed through system
commands; Python is used only by fixture checks, not the shipped helper.

## Acceptance Criteria And Automated Validation

- Invalid artifacts, metadata/signatures, noninteractive runs, Homebrew conflicts
  and running apps never lead to attribute removal or app reveal.
- Only exact consent prepares the release; source DMG and installed app stay unchanged.
- HTTP downgrade/redirects are refused by curl; failed downloads clean staging.
- Equal updates are no-ops, downgrades rejected, older installs retained for manual replacement.
- Fixture suite covers local/download/update flows, cancellation, corrupt image,
  every pinned metadata field, wrong architecture, invalid signatures before/after
  copying, attribute failures, debugger entitlement, and odd filenames.
- `task check` includes the helper fixture suite; native public-download
  `--verify-only --download` checks actual release integrity separately.

## Manual Smoke Test And Approval Gate

On a consenting pilot Mac: run the README bootstrap using an actual downloaded
release; cancel once, then consent. Confirm the actual illustrated installer window opens with the
Applications shortcut. Verify the original download still has its
attributes and only the staged copy loses quarantine. Preserve the previous app,
install using Finder, launch manually and confirm 0.5.3/build 11/b9c0641 in
Diagnostics. Record any endpoint-policy rejection honestly. Microphone/provider
smoke remains a separate human action using harmless unsent content.

Implementation, checks, feature-branch commit/push and preparation for the user
test are authorized. Main integration, publication of a new release and native
success claims await their own evidence/authorization. No signing-material access.

## Open Questions

- Does the real downloaded preparation/launch succeed on the target pilot Mac?
- What device-policy approval is required for broader colleague use?
