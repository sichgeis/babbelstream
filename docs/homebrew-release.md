# Homebrew Pilot Release Operations

Owner: the maintainer (`sichgeis`). Contract: [Homebrew distribution](features/homebrew-distribution/spec.md).
This is the approved ad-hoc/non-notarized pilot, not the Developer ID channel.
The 0.5.1 release is published, anonymous assets verified, and the cask activated;
public installation passed on macOS 27.0.1, with post-install human smoke pending.
See [execution evidence](runs/active/homebrew-distribution.md). Commands that publish or
replace an app are operator steps, not steps performed automatically by this guide.

## First publication

1. Run `task check` and verify the clean tagged artifact using `scripts/verify-app.sh <app> candidate`, DMG integrity, version/build/source, architecture, entitlements and SHA-256. Inspect the payload inventory; only app resources belong inside it.
2. Create release notes describing non-notarized status, architecture, tested OS, first-use approval, provider prerequisites and known gaps. Preserve immutable tags. Reuse the exact archived v0.5.1 artifact; don't regenerate it over the existing file.
3. Stage only `BabbelStream-0.5.1.dmg` and a portable checksum whose filename is `BabbelStream-0.5.1.dmg`, without a developer-local absolute path. Keep those staging files in dist, outside Git.
4. Create/upload a draft GitHub release at the existing tag. Download its assets as the authorized maintainer and compare the bytes. Draft releases are unavailable anonymously; they are not a public installation test.
5. On the other Apple Silicon Mac, try that downloaded/quarantined DMG normally. Record macOS version, approval warnings, successful Applications launch, current permissions, local paste and the explicitly authorized harmless unsent dictation test. Never grant permissions or use a provider on another user's behalf.
6. After that gate passes, publish the release. Download its public HTTPS URL without authentication, verify SHA-256 and the portable checksum. Do not skip failures or substitute the local payload for this test.
7. Validate `Casks/babbelstream.rb` in `sichgeis/homebrew-tap`: exact version/hash/URL; arm64 and macOS minimum; app-only artifact; no executable hooks, zap or security bypass. Validate with the installed Homebrew's style/audit tooling. Record expected non-notarized Gatekeeper findings, not a false official acceptance claim.
8. Fast-forward the tested cask into the tap default branch. Validate the exact public install command on the pilot Mac. Keep colleague rollout marked pending until it works. App documentation/main integration can then reflect actual channel availability; no app-source version bump/tag is needed for metadata-only channel setup. After app documentation integration, change the tap README’s staging-branch documentation links to main before deleting feature branches.

Connector-first publishing is preferred. If release upload is unavailable there,
use an already authenticated `gh` without putting credentials into arguments or
source. Example operator commands, from the app repo, after staging/review:

```sh
gh release create v0.5.1 dist/homebrew-release/BabbelStream-0.5.1.dmg dist/homebrew-release/BabbelStream-0.5.1.dmg.sha256 --repo sichgeis/babbelstream --verify-tag --draft --title 'BabbelStream 0.5.1 — colleague pilot (not notarized)' --notes-file docs/releases/v0.5.1.md
gh release download v0.5.1 --repo sichgeis/babbelstream --dir /tmp/babbelstream-pilot-download
gh release edit v0.5.1 --repo sichgeis/babbelstream --draft=false
```

Inspect existing release/assets before retrying an ambiguous result. Never use
`--clobber`, delete/recreate a published release or silently overwrite a tag.
Draft release notes may be updated with actual test results before publication.
No broad announcement or messages to colleagues are implicit in publication.

## Pilot smoke record

Use an isolated pilot account/Mac; leave the daily installation alone. Record:

- Mac architecture, macOS, Homebrew version and artifact hash.
- Normal downloaded launch with quarantine intact; supported Open Anyway or IT block.
- Exact public `brew install --cask sichgeis/tap/babbelstream` and any trust/conflict prompt.
- Applications version 0.5.1/build 7/source 8f229fe; one running copy.
- Deliberate Microphone/Accessibility approval, onboarding sample receipt and authorized unsent dictation.
- Existing manual app conflict/move-aside; adoption is not promised without evidence.
- Uninstall retains benign fixture settings/data and reinstall succeeds.
- Upgrade to the next genuine release: version/commit match, settings/dictionary/recovery preserved, actual OS/Keychain trust and repair recorded. Pending until a new version exists.
- Manual rollback: app version verified, data preserved, Homebrew record reconciled. Pending until tested.

## Every subsequent app release

Follow the existing feature/check/smoke/main/tag lifecycle first. Increment VERSION
and BUILD_NUMBER for new binaries, package from the exact clean release tag and
keep checksum/provenance. Publish/re-download/verify the release before changing
the cask; then update its version and sha256 in a reviewed tap commit. Test on the
pilot Mac before recommending the update broadly. Record release URL, app commit,
checksum, tap commit and test outcomes. No new automatic publishing workflow or
cross-repository secret is needed for the initial channel.

Cask source of truth is the tap, not a second copy in the app repository. Check
its current DSL with Homebrew rather than assuming all installed Brew versions
have the same audit/trust behavior. Keep exact HTTPS URLs and checksums; don't use
`latest`, `sha256 :no_check`, auto_updates or install hooks. Users initiate updates:

```sh
brew update
brew upgrade --cask sichgeis/tap/babbelstream
```

They first quit normally after completing/canceling active work. Upgrades may
require fresh macOS or Keychain approval. Do not add Full Disk Access to make
replacement appear seamless. No updater network request originates inside the app.

## Bad release and rollback

Stop advertising a broken cask, record an advisory and ship a higher-version fix.
Do not overwrite released assets or assume Brew downgrades automatically.
Preserve the installed bundle and a known-good versioned DMG. Quit, replace with
the known-good app manually, and verify its source before use; preserve data and
keys. Older app/data-schema compatibility must be assessed before downgrading.

Homebrew 7.0.10 on the development Mac supports cask pinning, confirmed by
`brew pin --help`. Before restoring a known-good manual bundle, prevent another
Brew upgrade of the installed cask:

```sh
brew pin --cask sichgeis/tap/babbelstream
```

This does not repair the Homebrew version record or perform a downgrade. Once a
known-good higher release exists, deliberately reconcile it:

```sh
brew unpin --cask sichgeis/tap/babbelstream
brew update
brew upgrade --cask sichgeis/tap/babbelstream
```

Verify the resulting bundle's version/commit; if Brew believes that version is
already installed after a manual replacement, use a reviewed `brew reinstall
--cask sichgeis/tap/babbelstream` while the app is quit. Older Brew versions may
have different pin support; check local help before relying on it. This rollback
procedure still needs pilot evidence. No destructive zap or permissions reset is
part of it.
