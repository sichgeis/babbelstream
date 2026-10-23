# Homebrew Distribution Implementation Run

## Outcome

Stage the approved non-notarized GitHub/Homebrew colleague channel and operational
documentation, then activate it only after the other-Mac quality gate passes.

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

the maintainer approved the complete feature contract and autonomous implementation on
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

### 3. Validation — Automated preparation complete; human gate pending

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

### 4. Download/launch and activation — Pending the maintainer

Follow docs/homebrew-pilot-smoke-test.md. On a pass: update evidence/notes, publish
release, verify anonymous bytes, then fast-forward tested tap cask into main.
Test exact public install before recommending rollout. Integrate documentation
branch after its current-state claims match actual availability. Do not create a
new app tag for distribution-metadata-only changes or rewrite old tags.

### 5. First real upgrade and additional lifecycle tests — Deferred explicitly

A genuine later binary release is needed for old-to-new brew upgrade evidence.
Manual-app adoption/conflicts, uninstall retention/reinstall and rollback need the
isolated pilot Mac. Do not claim them complete from static checks/first launch.

## Current Blocker

Other-Mac downloaded/quarantined launch/onboarding quality test not yet reported.
It is the approved publication gate, reaffirmed by the maintainer, not an auth failure.
All independent preparation is complete; current daily app remains unchanged.

## Next Action

the maintainer performs docs/homebrew-pilot-smoke-test.md using the staged draft download
and reports the result before the agent publishes/activates the channel.

## Documentation Polish (2026-10-23)

the maintainer requested a further documentation/README cleanup. The app README now
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
