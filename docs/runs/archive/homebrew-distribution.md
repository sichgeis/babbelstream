# Homebrew Distribution Implementation Run

## Outcome

Completed on 2026-10-23 by the maintainer's explicit closeout approval. Published the
non-notarized 0.5.1 release, activated the tap, and verified public install/reinstall
and user dictation without a Keychain prompt. Main integration is authorized;
upgrade, uninstall retention and rollback remain recorded follow-ups.

Earlier staging entries below are historical evidence, not current availability.

## Baseline

- Base: main, 47414743f9ab9a517fff50abb7511858d6abc56b, verified equal to remote.
- Initial tree: only previous-turn planning edits in implementation-plan.md and
  the new Homebrew feature spec; these are the approved work, preserved here.
- App implementation branch: codex/homebrew-distribution. App runtime untouched.
- Existing release source: v0.5.1, 8f229fefe2ef344bf2e1c1869779f6d6b077b42e, build 7.
- Tap: new public sichgeis/homebrew-tap, main README commit
  6f189ccf6b3b127d96b3c90461836d93598069fd; staged cask branch
  codex/babbelstream-pilot at f38a52c423edb841ce07e2b2ccdfb06a88b4ec26.

## Authority And Gates

The maintainer approved the complete feature contract and autonomous implementation on
2026-10-23, including the narrow ad-hoc public-pilot exception. Later steering
explicitly reaffirmed the download/launch quality test before public rollout.
Do not publish the draft release or merge the cask into the tap default branch
until that test passes. The exact public Brew installation is tested afterward;
broad colleague rollout follows that evidence. No daily-app replacement, real
recording/provider call, TCC grant/reset or private signing-material access.

## Scope And Decisions

- Contract: docs/features/homebrew-distribution/spec.md (Approved).
- Reuse exact v0.5.1 DMG; no app-source/version/build/tag mutation.
- Publish only DMG and portable checksum, not dist/ or rollback/evidence/user data.
- Own cask-only tap, exact versioned HTTPS URL/hash, arm64, declared macOS >=13.
  Native evidence only on 26.7.1; other-Mac results pending.
- No executable install hooks, zap, launch, process kill, permission access or
  quarantine/Gatekeeper bypass. Normal uninstall preserves local data.
- No Sparkle/app dependency/updater traffic. Homebrew updates are user-initiated.
- Connector-first: official GitHub tools created tap and pushed README/cask.
  One connector could not create a branch (403 integration access); the other
  available GitHub connector's multi-file push created the feature branch successfully.
  Release-asset upload is absent from connectors; authenticated gh fallback used.
  Initial sandboxed gh auth check failed due network isolation; normal network
  access confirmed existing authentication without any login/reset/secret output.
- Homebrew 7.0.10 supports cask pinning, confirmed with local help/source. Pinning
  does not perform rollback or repair a manually replaced app's installed record.

## Stages

### 1. Contract and source-of-truth reconciliation — Completed

Approved spec, AGENTS pilot exception, product/security/architecture/release/test/
support/README/update-plan reconciliation. Added operator and human-smoke guides.
No runtime change or weakening of Developer ID distribution mode.

### 2. Exact artifact and draft/tap staging — Completed

- DMG SHA-256: 8dc567ac48285cc3612e1743b30262eb3dd40eecdb4b6d7879d322a41125824d.
- DMG integrity PASS; strict candidate app signature PASS; arm64; bundle and
  Mach-O min OS 13.0. Hardened runtime and sole audio-input entitlement verified;
  no debugger entitlement. Metadata source 8f229fe/build 7.
- Payload inventory: Info.plist, executable, app icon, CodeResources only, plus
  Applications symlink in DMG. No personal settings/recovery/archive/key files.
  High-confidence embedded credential-pattern scan found no matches; this is a
  bounded artifact review, not a claim of universal secret detection.
- Draft: https://github.com/sichgeis/babbelstream/releases/tag/untagged-f78f4e549aca8f0b9aea
  tagName v0.5.1, isDraft true. Only DMG (995833 bytes, asset 669768953) and
  portable checksum (89 bytes, asset 669768954) uploaded. Portable checksum has
  basename only, unlike the original local checksum's absolute path.
- Fresh authenticated download to /tmp/babbelstream-pilot-download validated using
  the downloaded checksum. GitHub asset digest independently matches local DMG.
- Tap README on main explicitly says staged; main has no installable cask.
  Recipe exists only on codex/babbelstream-pilot. No general availability claim.

### 3. Validation — Completed; preparation and later human evidence below

- Baseline full task check PASS: /tmp/babbelstream-homebrew-baseline-check.log.
  Existing compiler/toolchain warnings remain. No XCTest claim.
- Homebrew 7.0.10: brew style PASS, 1 file/no offenses, after changing minimum OS
  syntax to depends_on macos: :ventura as its lint requires.
- Named-cask brew audit PASS (without --online/--new). Path audit is unsupported
  and --offline is not an option in this version; used named audit via temporary
  local-remote tap registration instead. No online/public-URL audit claimed.
- Parsed brew info confirms version/hash/exact URL, arm64 and >=13 declaration,
  app-only artifact, installed null. No app installation or launch occurred.
- Gatekeeper assessment rejects the ad-hoc payload, as expected and disclosed.
  Recipe audit success does not mean Apple/Homebrew official-catalogue acceptance.
- Temporary Homebrew tap registration and read-only DMG mount are removed during
  closeout; original unrelated taps preserved. Homebrew developer mode restored
  after its first audit help invocation enabled it automatically.
- Final task check PASS: /tmp/babbelstream-homebrew-final-check.log. Whitespace
  review PASS; all app source, resources, VERSION, BUILD_NUMBER and tags unchanged.
  Installed executable still matches the prior release hash
  cf4862a37d307ca15d4b208f296eaf8effd4b2ce57dc2278e7c3e38446901a84.
  Temporary audit tap removed; only original unrelated taps remain. Read-only
  image detached successfully. No installation or daily app launch/termination.

### 4. Download/launch and activation — Completed

Follow docs/homebrew-pilot-smoke-test.md. On a pass: update evidence/notes, publish
release, verify anonymous bytes, then fast-forward tested tap cask into main.
Test exact public install before recommending rollout. Integrate documentation
branch after its current-state claims match actual availability. Do not create a
new app tag for distribution-metadata-only changes or rewrite old tags.

### 5. First real upgrade and additional lifecycle tests — Deferred explicitly

A genuine later binary release is needed for old-to-new brew upgrade evidence.
Manual-app conflict/move-aside and missing-bundle reinstall passed. Optional
adoption, uninstall retention and rollback remain untested. Durable follow-ups
are in docs/implementation-plan.md.

## Current Blocker

Public release/tap activation and Homebrew installation are complete, under
The maintainer's explicit authorization recorded below. After the missing-bundle Brew
reinstall, the maintainer confirmed launch and dictation without a Keychain prompt.
Earlier DMG restart smoke passed after the targeted Keychain repair; a further
restart of the Brew copy is not separately evidenced. No installation or
publication blocker remains. Future-version upgrade/lifecycle tests are deferred.

## Next Action

None for this closed pilot. Future lifecycle validation is tracked in
docs/implementation-plan.md; project-status.md owns the next project action.

## Documentation Polish (2026-10-23)

The maintainer requested a further documentation/README cleanup. The app README now
leads with pilot availability, requirements, onboarding, dictation and explicit
Homebrew update steps. Detailed provider/recovery/removal guidance is in
`docs/getting-started.md`; developer build/install details moved to
`docs/development.md`. `docs/README.md` provides navigation by reader task, and
pilot support distinguishes user setup from company/operator responsibilities.
No rollout gate, runtime behavior, release asset or installed app changes.

The staged tap README also links the user/developer documentation; its latest
commit is ff1c06c2e9091e69e6ca8e78e272da7b8a3157e8 (cask unchanged). Default tap
main remains README-only. The operator checklist now includes switching staging
documentation links to main after integration and before branch cleanup.
Validation: 7 documentation entry points checked; 46 local links/section anchors
resolve, and git diff --check passes. This pass changes only Markdown; the
previous full task check evidence remains applicable to unchanged app/tooling.

## Other-Mac Pilot — 2026-10-23

- Host: Apple Silicon, macOS 27.0.1 (26A434), Homebrew 7.0.9.
- Browser download/checksum and retained quarantine PASS. Installed exact
  0.5.1/build 7/8f229fe payload; candidate signature verified. Prior 0.4.5 bundle
  preserved locally. Canonical task check PASS on this host.
- Human launch required Privacy & Security > Open Anyway. User completed
  onboarding and reported successful dictation and both tap/hold gestures.
- Settings remained after quit/reopen and dictation worked, but first provider
  access after relaunch required a Keychain password. User considers this a
  blocking usability issue; initial restart acceptance failed, then passed the
  user retest after the targeted repair documented below.
- Screenshot shows the item-access consent dialog with Always Allow, Deny and
  Allow, not sufficient evidence that the entire login keychain is locked.
- Read-only source review: SecItemCopyMatching reads the key on demand;
  SecItemUpdate preserves the existing item, with no delete/add replacement.
  Installed ad-hoc designated requirement is tied to cdhash
  ee62ba00ce3cc2ffa6fc71cef09558b83d30925a. No secret or item ACL was read.
- User explicitly confirmed Always Allow was selected on every attempt and does
  not persist across same-build restarts. Do not repeat that suggestion or mark
  the problem as user error.
- Leading hypothesis: legacy item access/trust did not migrate cleanly from the
  prior locally certificate-signed 0.4.5 app to ad-hoc 0.5.1. Source preserves
  the old item with SecItemUpdate; this does not establish a new creator identity.
  Actual item ACL/partition state has not been inspected, so root cause remains
  unproven. Ad-hoc identity alone does not establish why the unchanged binary
  prompts on every restart.
- Next bounded diagnostic: user reviews only this item's Access Control and
  explicitly adds the verified Applications copy, retaining per-app restrictions;
  no Show Password, all-app access, deletion or broad partition-list changes.
  Separately evaluate stable signing for future distribution. Apple's code-signing
  guide documents certificate-based identity tracking, including self-signed
  identities for Keychain; this is not evidence of Gatekeeper/notarization acceptance.
- Release remains draft; public activation and Homebrew install remain blocked.
  No signing/security/storage changes are authorized by this diagnosis.

### Authorized Targeted Keychain Repair

User explicitly requested the targeted Access Control repair. In Keychain Access,
selected only login/com.sichgeis.babbelstream (account provider-api-key). The item
already listed three BabbelStream.app trusted-application entries. Added the exact
/Applications/BabbelStream.app through the application chooser and saved. Reopened
the item and verified four entries persist; Confirm before allowing access remains
selected, Allow all applications remains off, and Ask for Keychain password remains
off. No key value was displayed, copied or changed; no existing access entry was
removed. No authentication prompt was exposed by the returned UI. This records a
persisted UI policy edit. the maintainer subsequently confirmed the requested restart/
dictation retest works after this repair (2026-10-23). No claim is made that a
future binary upgrade preserves this trust or that the root cause is proven.

### Troubleshooting Documentation

At the maintainer's request, README Troubleshooting now records the exact symptom,
observed 0.4.5-to-0.5.1/macOS 27.0.1 context, targeted per-item Access Control
repair, privacy boundaries and restart verification. Getting Started links to
that single procedure. No runtime code, secret, signing identity or released
artifact changed. Public Homebrew installation remains a separate pending test.
Validation: all 16 local Markdown links/section targets in the four changed
documents resolve; git diff --check passes. Canonical task check passed earlier
on this host with unchanged runtime/tooling; not rerun for these documentation edits.

## Authorized Publication And Public Installation — 2026-10-23

The maintainer explicitly authorized publishing the staged release, activating the tap,
and testing Homebrew installation on this Mac. This supersedes the earlier pending
publication direction; it does not authorize an untested later-release upgrade or
destructive data removal.

- Published existing v0.5.1 draft after updating release notes with other-Mac
  results and Keychain troubleshooting. No asset/tag replacement.
- Public release: https://github.com/sichgeis/babbelstream/releases/tag/v0.5.1.
- Fresh anonymous HTTPS DMG/checksum downloads PASS; portable checksum OK and
  DMG SHA-256 remains 8dc567ac48285cc3612e1743b30262eb3dd40eecdb4b6d7879d322a41125824d.
- Compared tap main to staged branch: ahead 2/behind 0; reviewed app-only cask
  plus documentation, no hooks/zap/security bypass.
- GitHub connector ref mutation was forbidden by integration permissions;
  authenticated gh API fallback fast-forwarded main from 6f189cc to ff1c06c.
- Added sichgeis/tap on this Mac. Homebrew 7.0.9 style PASS (one file/no offenses)
  and named-cask audit PASS. Homebrew fetched its own developer-tool Ruby gems
  for lint/audit; this added no BabbelStream dependency. Developer mode was set
  only through the command environment, not persistently configured.
- Tap README activation/Keychain guidance committed on main at
  835429953c7f96d7de53c8c105194210fcbd42a2; cask unchanged from reviewed ff1c06c.
- User confirmed normal quit; process exit verified. Preserved manual 0.5.1
  bundle and matching executable checksum under ignored dist/pilot-backups/.
- Exact command `brew install --cask sichgeis/tap/babbelstream` (only unrelated
  auto-update disabled by environment) downloaded the public artifact, then
  failed safely with already-an-App conflict. It did not adopt the identical app.
- Moved the quit manual bundle into the rollback folder without deleting data;
  reran the same install command and Homebrew reported successful installation.
  Optional --adopt and --force were not used.
- Brew scoped trust to this named cask automatically during install. It warned
  about three preexisting untrusted unrelated taps; their trust was not changed.
- Installed/brew-recorded 0.5.1/build 7/8f229fe; strict candidate signature PASS,
  executable SHA-256 cf4862a37d307ca15d4b208f296eaf8effd4b2ce57dc2278e7c3e38446901a84,
  matching prior manual payload. Quarantine retained. No settings/key changes.
- Launched through Finder; one Applications process (83671) independently verified.
  User asked for harmless dictation, retained-settings and prompt-free restart
  confirmation. No new Gatekeeper/permission result is claimed before that reply.
- Preserved public downloads and before/after brew JSON under ignored
  dist/pilot-evidence/2026-10-23/. No private content or secrets were collected.
- Updated public release notes with actual install/conflict result. All 18 local
  links/section targets in seven edited docs resolve; git diff --check PASS.
  Canonical fixture checks remain the earlier same-host PASS for unchanged app
  source/tooling. This metadata-only publication does not rebuild/re-sign the app.
- App documentation remains on codex/homebrew-distribution; app main/tag untouched.
  Tap documentation links intentionally retain that branch until app-doc integration.

### Missing Bundle And Brew Reinstall

The maintainer reported the app appeared absent again. Fresh checks confirmed
/Applications/BabbelStream.app missing and no running Applications process, while
Homebrew still recorded babbelstream 0.5.1 installed. Cause of disappearance is
unknown; do not infer deletion or Gatekeeper approval from the installed record.
Under the explicit request to install via Brew, ran
`brew reinstall --cask sichgeis/tap/babbelstream` with unrelated auto-update
disabled. It completed successfully without zap or settings/Keychain changes.
Filesystem presence, strict candidate signature, 0.5.1/build 7/8f229fe metadata,
retained quarantine and Homebrew 0.5.1 record independently verified afterward.
README Troubleshooting now records this case and distinguishes Done/Open Anyway
from Move to Trash. User-visible launch/dictation confirmation is still pending;
reinstall success alone does not establish that outcome.

### Human Confirmation After Reinstall

The maintainer confirmed: "Dictation works now. It worked without a keychain prompt."
The Homebrew-installed app is visible in Applications and launch/dictation now
PASS. This is user evidence after reinstall, not an automated provider test. It
does not establish an additional quit/reopen cycle of the Brew copy or a genuine
future-version upgrade. No private text/key was captured. Public channel and
installation objective are achieved; app documentation integration remains open,
with no app-main mutation authorized in this chat. Updated README, support/status,
pilot checklist and release notes to reflect the exact evidence.
Public release notes updated; tap README evidence commit fdf5748451d845aace7bbfed35761e286b2ce36a
(recipe unchanged). Validation: 18 local links/section targets and git diff --check
PASS; no runtime changes, so the earlier canonical fixture evidence applies.

## Closeout — 2026-10-23

The maintainer explicitly authorized merging the Homebrew documentation into main and
closing the pilot while preserving upgrade, uninstall and rollback follow-ups.
Archived this run, updated contract/status/support/navigation links and moved the
untested lifecycle matrix into docs/implementation-plan.md. The release's exact
binary, VERSION, BUILD_NUMBER and v0.5.1 tag remain unchanged. Main is integrated
by fast-forward; the tap and release-note documentation links switch to main
only after that push. No additional provider/microphone or private-data check is
performed for this documentation closeout.

Closeout validation: task check PASS (behavior and release-tooling fixtures;
preexisting CLT linker search-path warnings remain), 47 local Markdown links/
section targets resolve, and git diff --check PASS. Diff against origin/main
contains only Markdown; no runtime/resource/tooling/VERSION/BUILD_NUMBER changes.

Integration verified: app main and origin/main both reached 8369189 by fast-forward.
Tap README main-link/follow-up update committed at b1cca7bc097612aad1445183ce80e85b07c63b37;
published release notes now link main as well. v0.5.1 still resolves to original
app-source 8f229fefe2ef344bf2e1c1869779f6d6b077b42e. Working tree clean after integration.
