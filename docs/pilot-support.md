# Internal Pilot Setup And Support

This branch is an unreleased candidate. Do not distribute or replace the daily app until the release/manual gates in `docs/release.md` are approved. the maintainer explicitly authorized installation/launch of the reviewed onboarding candidate on 2026-10-23. Build 5 / b3f7ff0 is installed in Applications with first-use setup open; the preceding build 3 bundle is preserved at `dist/rollback/BabbelStream-0.4.5-build3-4e6da0d.app`. Public pilot distribution remains gated.

## Install And Set Up

Builds with onboarding open a postponable setup window on first use. Reopen it through Set Up BabbelStream… in the menu or General Settings. It refreshes actual permission status on return from System Settings and offers a local paste test; that explicit test replaces the clipboard with a harmless sample without recording or contacting a provider. A pass verifies only the app-owned test field. Existing users keep their saved provider configuration. Signing changes may still require consent repair; a system toggle alone is not proof that the running app is trusted.

1. Obtain the approved signed/notarized DMG and verify its checksum and source version with the pilot maintainer. Quit every older BabbelStream copy, including copies launched from a DMG or development folder. Drag the app to Applications, eject the DMG, and launch only the Applications copy. Updated copies enforce one active instance per user.
2. In Provider Settings, confirm the destination authorized for your work. The company profile, production-versus-development endpoint, approved model aliases/routing and key-issuance process are pending authoritative IT input. Do not infer these values from a screenshot or another user's configuration.
3. Use a per-user, revocable company-issued key with appropriate scopes, usage limits and a documented revocation owner. Never bundle or share a master key in the app, repository, DMG, support message or screenshot. Each user enters their own key in the secure field; Apply stores it in their macOS Keychain.
4. A custom compatible-provider preset uses an intentionally nonfunctional example address. The official OpenAI preset is explicit, contains no secret, changes only connection URL/paths/routing and leaves models unchanged. Confirm account authorization and potential charges before Apply. Personal fallback is off for new users and remains a separate opt-in with its own key and destination disclosure.
5. Apply changes. Active and edited destinations remain distinct. Endpoint paths, model IDs/routing and timeout controls are under Advanced. A changed origin requires explicit key re-entry; this is approval of the key's use at that destination, even if the same key is intentionally authorized for both.
6. Optional: choose Test Saved Connection and review the confirmation before sending. It sends one 250 ms silent WAV to the saved **primary transcription** endpoint with its saved key/model, with a maximum 30-second request timeout and no retries/hedge, cleanup, dictionary, personal fallback, microphone or paste. The provider may bill this request. A models-list response is never used as transcription proof. Synthetic audio is deleted and returned text is discarded.
7. In General, grant Microphone and Accessibility when ready for actual dictation. Microphone controls audio capture; Accessibility permits synthetic Cmd+V. No Input Monitoring permission is added. For denied access, use the direct System Settings buttons, enable the exact installed app, and restart if macOS requests it. With rebuilt/ad-hoc apps, stale Accessibility entries may need removal and re-adding; use an authorized stable signature for pilot builds.
8. Run the approved microphone/provider/unsent-editor smoke matrix. The synthetic test does not establish recognition quality, cleanup authorization, native permissions or editor delivery. Review every draft; BabbelStream never presses Enter.

## Connection States

| State | Meaning | Next step |
| --- | --- | --- |
| Setup incomplete | Primary key absent or not approved for the saved origin | Confirm authorized destination, enter your key and Apply |
| Key saved, unverified | Key presence and origin match; transcription has not been tested in this session | Optionally run the disclosed test, or perform an authorized smoke test |
| Testing saved transcription connection | Explicit synthetic request active | Wait or Cancel Test; dictation start is paused during this request |
| Transcription connection verified | Endpoint returned the expected transcription contract, including valid empty text for silence | Still validate real speech, cleanup and paste; evidence is session-only |
| Temporarily unavailable | Transport/reachability or eligible gateway outage during test | Check network/provider availability and retry explicitly |

Authentication, model and malformed-response failures stay unverified, with content-free categories. Test never switches to personal fallback. Apply/key deletion cancels the test and invalidates previous evidence; stale responses cannot verify a later configuration. Relaunch starts saved keys unverified. No background network check runs.

## Upgrade, Recovery And Rollback

Before upgrading, stop recording/processing and quit the app normally. Preserve Application Support and Keychain; do not uninstall these to repair permissions. Retained Failed Recordings remain until successful retry or explicit deletion, and the text archive stays opt-in. Do not send recordings, archive files, transcripts or secrets to support. Export audio only when the user explicitly chooses it.

For rollback, quit the candidate and reinstall the previously approved signed DMG from a trusted source using Finder. Launch only Applications and verify version/commit under Diagnostics. Never run old and new copies concurrently. Keep application data and keys intact; the pilot's additional origin metadata is non-destructive, but an older binary does not enforce the newer origin/redirect protections. Confirm provider configuration before using a rolled-back version. No downgrade/deletion migration is required by this change.

## Support Packet

Copy Diagnostics exports an allowlist: version/build, provider origin and reviewed model/routing categories, key/permission flags, timeouts and operational counts/failure categories. It omits private filesystem paths, transcript/draft/audio/clipboard contents, raw errors and provider bodies. Review the report before sharing and send it only through an explicitly authorized support channel; this app does not send diagnostics itself.

Report the macOS version, app version/commit, tab/window size or editor, and reproducible steps using harmless synthetic text. A cropped screenshot should show only the app's relevant UI and should exclude secrets, work content and any local paths shown in on-screen storage details. Never ask users to disclose their API key. Fix key access through the issuer's approved replacement/revocation process.

## Pilot Owner Inputs Still Required

- Approved company base URL, endpoint paths, model aliases/routing and cleanup availability.
- Credential issuer, revocation/support owner, per-user scopes, limits and cost responsibility.
- Authorized Developer ID identity and notarization profile, and distribution/install approval.
- Both-machine Settings/dialog visual acceptance (macOS 26.7.1 and 27.0.1) and real unsent dictation smoke.
- Model lifecycle migration approval before the announced shutdowns; see `docs/provider-lifecycle.md`.
