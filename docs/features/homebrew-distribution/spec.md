# Homebrew Distribution And Updates

## Status

- State: Shipped; initial pilot closed on 2026-10-23. Upgrade, uninstall retention and rollback validation remain deferred.
- Owner: the maintainer.
- Requested: 2026-10-23, planning for our own Homebrew tap without paid Apple membership.
- Baseline: clean main at 47414743f9ab9a517fff50abb7511858d6abc56b.
- Existing app: v0.5.1 / build 7 / 8f229fe, local ad-hoc arm64 DMG.
- Approved by the maintainer on 2026-10-23: “I approve, and you please implement as autonomously as possible.” Includes the pilot policy exception, feature-branch pushes, tap creation and release/cask staging/publication in the specified sequence. Daily-app replacement, permission grants and real provider calls remain excluded.

## Problem And Desired Outcome

Colleagues who use Homebrew can install BabbelStream and deliberately upgrade it
with familiar commands. the maintainer can publish each tested version without a paid
Apple Developer membership or an in-app updater. The download remains available
for manual DMG installation too.

## Research And Alternatives

| Option | Benefit | Limitation | Recommendation |
| --- | --- | --- | --- |
| Own tap with a prebuilt cask | Small recipe, familiar install/upgrade, exact artifact checksum | Maintainer owns recipe; macOS warnings and company policy still apply | Adopt for the pilot |
| Official homebrew/cask catalogue | Wider discovery | Separate acceptance process; current artifact fails required Gatekeeper acceptance | Out of scope |
| Build-from-source formula | Users build locally | Requires compiler/SDK, slower installation and another signing/permission path | Defer |
| Sparkle | Updates from inside the app | Runtime dependency, update feed/signing and more maintenance | Defer |

Homebrew applies quarantine to cask downloads. An own tap does not establish an
Apple-verified publisher identity or remove Gatekeeper. Users may need Apple's
per-app Open Anyway flow; managed Macs may prohibit that. Never disable Gatekeeper,
remove quarantine attributes or reset TCC in the cask or installation instructions.

References checked 2026-10-23:

- https://docs.brew.sh/How-to-Create-and-Maintain-a-Tap
- https://docs.brew.sh/Cask-Cookbook
- https://docs.brew.sh/Homebrew-Security-and-Supply-Chain
- https://docs.brew.sh/Acceptable-Casks
- https://docs.brew.sh/FAQ
- https://support.apple.com/en-gb/102445

## Accepted Scope And Non-Goals

- Public release assets in existing public sichgeis/babbelstream.
- Public cask-only repository sichgeis/homebrew-tap; Casks/babbelstream.rb and README.
- Explicitly labeled ad-hoc, non-notarized colleague pilot; no Apple membership or signing-material access.
- Download DMG via version-specific HTTPS URL; exact SHA-256, no latest URL or no_check.
- Initially Apple Silicon only. Package.swift and bundle currently declare macOS 13.0 minimum; validate the packaged binary and runtime compatibility before advertising that entire range. Record tested OS versions separately. A deployment target is not proof of testing on every version.
- Manual, reviewed release publication and tap bump first. Automation can follow once install and upgrade work.
- No Sparkle, auto_updates declaration, background update checks, new app network destination, provider change or extra app permission.
- No official catalogue submission, Intel/universal build, enterprise deployment or guaranteed preservation of OS permission grants.

## User Workflow

The proposed tap must exist before advertising these commands:

```sh
brew install --cask sichgeis/tap/babbelstream
open /Applications/BabbelStream.app
```

Homebrew may require explicit third-party tap/cask trust depending on its version.
Explain only the specific prompt users encounter; do not grant broad tap trust
silently. Homebrew is a prerequisite; do not install it as an app side effect.

If blocked at launch, follow Apple's per-app Privacy & Security > Open Anyway
instructions where available. If company policy prohibits approval, ask IT; the
pilot has no supported workaround. Never describe unsigned/ad-hoc code as verified
by Apple. Then use existing onboarding for microphone, Accessibility and provider
setup. Each colleague supplies their own approved key; the installer carries none.

For upgrades, first finish/cancel recording, processing, paste or recovery work,
then quit BabbelStream normally. Copy Last Draft is session-only; quit discards it.
Do not force quit or replace a busy process.

```sh
brew update
brew outdated --cask sichgeis/tap/babbelstream
brew upgrade --cask sichgeis/tap/babbelstream
open /Applications/BabbelStream.app
```

Users initiate updates; Homebrew does not push an update into a running app.
Check version/commit in Diagnostics and reapprove permissions if needed. Keychain
may request access again after a signing change. Never grant Full Disk Access just
to make an upgrade appear seamless. Homebrew may use different replacement
strategies depending on existing terminal permissions; test actual outcomes.

For an existing manually installed app, quit it and preserve a rollback bundle.
Test Homebrew adoption only if the installed bundle matches the cask payload.
If it differs or adoption is unsupported, move the old app aside before installation;
do not recommend --force, delete app data or install a second running copy.

## Release Architecture And Cask Contract

The app repository owns source, VERSION/BUILD_NUMBER, immutable tags, the tested
DMG, checksum and release notes. The tap owns the current cask version, artifact
URL/checksum, supported platform declarations and user instructions. the maintainer is
the initial maintainer for both. The cask is metadata, not another app binary host.

Recipe requirements:

- version matches release, URL points to releases/download/v<VERSION>/BabbelStream-<VERSION>.dmg.
- sha256 matches bytes downloaded from that release, not merely a local filename.
- app artifact installs BabbelStream.app; declare macOS and arm64 restrictions with current supported cask syntax.
- Caveat explains non-notarized status, per-app approval, onboarding and quitting before upgrades.
- No pre/postinstall shell execution, provider setup, automatic app launch, permission granting or process killing.
- No zap stanza initially: normal uninstall removes the bundle, retaining settings, dictionary, recovery audio, archive and Keychain entries. Data deletion remains an explicit separate user action.
- No claim that a checksum proves publisher identity: it detects differences against the tap's expected bytes; both repositories must remain trusted.

Keep existing candidate and Developer ID distribution modes truthful. For the
pilot, use the explicit ad-hoc optimized candidate pipeline and label publication
accordingly; never weaken distribution-mode signing checks. A signed/notarized
channel can be added later as a separately tested transition.

## Implementation And Publication Stages

### 1. Approve the pilot contract and reconcile policy

- Approve this non-notarized public pilot and repository name.
- Start codex/homebrew-distribution from a clean pushed baseline; create docs/runs/archive/homebrew-distribution.md from the run template.
- Amend AGENTS.md's current blanket public Developer ID/notarization requirement with this narrow, explicit pilot exception. Retain stronger guarantees for a notarized distribution channel.
- Reconcile release.md, security-privacy.md, product-spec.md, architecture.md, test-plan.md, pilot-support.md and README; replace the old assumption that all update delivery depends on Sparkle/Developer ID.
- Do not change runtime behavior, retention, provider destinations or permission scope.

### 2. Prepare reviewable artifacts and tap contents

- Verify the existing v0.5.1 artifact checksum, strict ad-hoc signature, hardened runtime/audio entitlement, arm64 architecture, minimum OS, version/build/source and absence of debugger entitlement.
- Inspect the publication payload/notes for secrets, personal settings, private endpoints and generated user data without accessing real credentials or archives. Upload only the DMG and checksum, never the entire dist directory.
- Reuse the archived exact v0.5.1 DMG if valid; do not rebuild over it or rewrite its tag. A changed payload requires a new version/build/tag under the normal release process.
- Prepare release notes: features, build/source, tested OS, architecture, non-notarized status, installation/upgrade/rollback instructions and provider prerequisites.
- Draft the cask and tap README locally, with fixed version/hash and no hooks. Check the live tap/release names first; preserve any existing resources.
- Use official GitHub connector where supported; fall back to authenticated gh for release-asset upload/repository operations absent from the connector. No tokens in source, recipes or logs.

### 3. Validate before general availability

- Run task check; perform recipe syntax/style checks with the installed Homebrew version and inspect the diff. Run relevant cask audit and record expected unsigned Gatekeeper failures separately from recipe failures; do not claim official acceptance.
- Create the release as a draft and stage the tap contents under the approved publication envelope. Draft assets are not anonymously downloadable; prepublication tests can use an authorized maintainer download/local recipe. Do not claim this tests the final public URL.
- On the other Apple Silicon Mac, test the downloaded/quarantined payload and ordinary launch, per-app approval and onboarding. Real mic/provider/Slack testing requires the user's explicit participation; use harmless sample text, never auto-send.
- Publish the verified release, then check anonymous HTTPS download and SHA-256 before publishing the tap's installable cask. Release-before-cask avoids advertising a missing asset.
- Run the exact public brew install path on the test Mac; record Homebrew/macOS versions, trust prompts, launch result and actual permissions. If blocked by IT, stop that machine's rollout and document it honestly.
- Approve a colleague pilot only after the actual public path works. If it fails, halt rollout and fix/retract the cask; do not bypass OS protections.

### 4. Prove upgrades, recovery and uninstall

- First installation alone does not verify upgrades. Test v0.5.1 -> the next legitimate tested release with increased VERSION/BUILD_NUMBER. No fabricated same-version replacement just to exercise brew.
- Confirm brew detects the new version, replaces a normally quit app and launches the expected exact source/build. Verify benign settings/dictionary fixtures persist; provider destination never changes silently.
- Exercise permission repair and any Keychain access prompt with consenting test users. No automated secret reads/TCC manipulation. Validate recovery ownership with fake data, not private recordings.
- Test migration from an existing manual app and Homebrew's already-installed-app conflict.
- Test uninstall retains application data and reinstall works. Perform on an isolated pilot account/Mac, not the daily installation.
- Record remaining validation gaps, then archive the tracker after the initial channel is shipped; keep the first-real-upgrade follow-up explicit if no new app release exists yet.

## Every Subsequent Release

1. Implement/version/check/smoke/tag using the normal app release process. Build from the clean final tagged source; retain exact version/build/commit/hash evidence.
2. Upload the versioned DMG and checksum with accurate notes. Verify the hosted bytes. Never replace assets under an existing version to hide a fix.
3. Update only cask version, URL/hash and necessary compatibility/caveats in a reviewed tap change. Do not point users to unpublished assets.
4. Test the upgrade on a pilot Mac before broad announcement; publish the tap update after checks. Users run brew update and brew upgrade when ready.
5. Record app release URL/tag/hash, tap commit, tested OS/Homebrew, upgrade/permission results, limitations and rollback target in the release run.

Start with manual publication. A later helper may generate a recipe/diff from
verified release metadata and fail on missing assets, mismatched hash/version or
unsupported architecture. Avoid cross-repository tokens and autonomous publication
workflows until repeated manual releases establish the correct procedure.

## Failure And Rollback Contract

| Failure | Expected action |
| --- | --- |
| Offline, missing asset or checksum mismatch | Abort install/update; correct metadata/network and retry, preserving the working app/data |
| Gatekeeper or managed-device rejection | Use Apple's supported per-app approval only where allowed; otherwise involve IT |
| Existing Applications bundle conflict | Quit and preserve it; tested adoption or explicit move-aside, no forced overwrite |
| Update interrupts/replaces incorrectly | Quit all copies, restore known-good artifact, preserve application data; report actual outcome |
| Permission or Keychain trust changes | Existing onboarding/OS prompt; no silent grants, key deletion or TCC reset |
| Bad published release | Stop advertising it in the tap; retain historic provenance, document advisory and ship a higher-version fix |

For urgent local rollback, quit normally, preserve the current bundle and install
the documented prior exact DMG manually. Homebrew's recorded version may then
mismatch the restored app; pin the cask temporarily using the installed Homebrew's
supported mechanism and document the manual replacement. Verify version before
use and reconcile via the next known-good cask upgrade. Test this procedure; do
not promise brew upgrade automatically downgrades or provide arbitrary historical
cask installation commands. Remove the pin deliberately when adopting the fix.
Never uninstall with --zap or remove Application Support/Keychain to roll back.
If a future release changes persisted data, define backward compatibility before
claiming old binaries can safely read it.

## Privacy And Security

Homebrew/GitHub perform user-initiated metadata/artifact requests and can observe
normal connection metadata. BabbelStream adds no updater calls, analytics, appcast
or runtime dependency. Do not ship credentials, company configuration, dictionary,
usage, transcripts, clipboard contents, recovery audio or archives. Provider setup
and work-data authorization remain per-user/company responsibilities. A public tap
is accessible beyond colleagues; describe it as a pilot, not restricted access.

## Acceptance Criteria And Evidence

- Public versioned DMG/checksum and tap recipe agree on source/build/version/hash; anonymous hosted download verified.
- Exact documented brew install command works on the other supported pilot Mac with quarantine intact and no hidden privileged hooks.
- Non-notarized warnings/IT restrictions are disclosed; no Apple verification claim.
- Onboarding permission/paste flow and a user-authorized harmless dictation succeed; no auto-send.
- Compatibility restrictions match the artifact; macOS 13+ is a declared target, not blanket evidence of testing.
- First real upgrade is separately evidenced, preserves data and has a tested rollback. If pending, status says so.
- Ordinary uninstall preserves data; manual-install conflicts and interrupted updates have documented recovery.
- App and tap docs identify maintainers and the release checklist. No in-app updater, paid service or private signing key is introduced.

## Approval And Closeout

the maintainer approved this contract and autonomous implementation on 2026-10-23,
then explicitly authorized publication, tap activation, local Homebrew testing,
main documentation integration and pilot closeout. Initial public install/reinstall
and user dictation passed. Untested genuine upgrade, uninstall retention and rollback
cases remain in docs/implementation-plan.md; closeout does not mark them passed.
Archived execution evidence: `docs/runs/archive/homebrew-distribution.md`.
