# First-Run Setup And Update Delivery

## Status

Onboarding approved by the maintainer on 2026-10-23: implement the proposed first-run flow, live permission checks and local paste test. Sparkle, distribution signing and all update delivery changes remain deferred. Local implementation, canonical fixtures and candidate build 4 packaging completed; native human consent/local-paste acceptance remains pending. No signing-key access, background network traffic or release approval is implied.

## Problem And Desired Outcome

A colleague should understand the required permissions, grant them deliberately, and verify automatic paste before using dictation. Later releases should preserve configuration and privacy grants where macOS permits, with a clear recovery path if permissions change.

## Research And Alternatives

- Native, short setup checklist: recommended. Reuses existing readiness/permission/provider interfaces. A persistent setup-completed flag must never substitute for current OS trust.
- Manual DMG replacement: simplest pilot update path; users obtain each new release and replace the Applications bundle. A DMG alone does not discover or install updates.
- Sparkle 2: recommended for ongoing colleague distribution. Adds a reviewed dependency, HTTPS appcast/artifact hosting, update signing and maintenance. Native APIs do not provide an equivalent complete updater for this directly distributed app; building archive verification/replacement/relaunch ourselves would add security-critical code.
- Organization-managed deployment: alternative if IT already supports it; mechanism and ownership must be confirmed rather than assumed.

## Approved Onboarding Workflow

One native resizable setup window, semantic system surfaces, no decorative splash or forced tour. Show on first use; expose Set Up BabbelStream… later. Permit closing/postponing and retain explicit limited-mode status.

1. **Set up BabbelStream** — “Record with a shortcut. Paste into your focused app. Nothing is sent automatically.” Briefly disclose that recordings are processed by the configured provider. Continue / Set Up Later.
2. **Allow recording and automatic paste** — independent live status rows:
   - Microphone: “Record only when you start dictation.” Allow Microphone invokes the real OS prompt only on click; denied access offers Open Microphone Settings.
   - Accessibility: “Paste your finished draft into the focused app using Command–V.” Enable Automatic Paste invokes the OS permission request and offers Open Accessibility Settings. macOS owns consent; the app cannot grant it.
   - Refresh on return to the app and explicit Check Again. Mark Allowed only from the running process's actual OS query, never a screenshot, toggle appearance or remembered setup completion.
   - While not trusted: “Automatic paste is unavailable. Dictation can still copy the draft for manual paste.” Allow explicit Continue With Manual Paste. Do not disable existing copy-only dictation.
3. **Connect your provider** — reuse saved primary origin/key presence and existing explicit setup. Preserve settings; do not ask existing users to re-enter keys unnecessarily. Key saved is distinct from connection verified. No bundled shared key or guessed company endpoint. Optional synthetic provider test keeps its existing destination/content/cost confirmation.
4. **Try automatic paste** — optional local test with a dedicated app-owned test field and fixed harmless sample. Explicit Test Automatic Paste focuses only that field, runs guarded clipboard + Cmd+V and checks whether the known sample arrived. No microphone, provider or arbitrary external-field reads. Disclose clipboard replacement; retain normal clipboard-contention/cancellation rules. Report success only on sample receipt, not event posting. This proves the local paste path, not every external editor.
5. **Ready to dictate** — explain Control–Option–Space: tap to start/stop, hold for push-to-talk. Offer a human test in an unsent TextEdit/Slack draft; do not start recording or a billable provider call automatically. Launch at login remains a separate optional choice.

## Permission Recovery After Updates

Recheck actual permissions at every launch and before delivery, independently of setup history. If previously available automatic paste becomes unavailable, show a compact repair view rather than replaying provider setup. Open the relevant system pane; describe removing/re-adding the exact Applications copy if the toggle and actual trust disagree. Never reset TCC silently or repeatedly. A signing transition may require fresh consent; stable signing reduces identity churn but does not guarantee permanent OS permission.

## Deferred Update Proposal (Not Approved)

Phase 1: Developer ID-signed/notarized colleague builds with a consistent bundle ID and compatible designated requirement. Provide a trusted release location and manual DMG replacement procedure. Verify old-to-new permission/settings/Keychain compatibility on a real pilot Mac before claiming seamless upgrades.

Phase 2 (separate approval): embed Sparkle, add Check for Updates… and an explicit opt-in to automatic checks. Begin with user-confirmed Install and Relaunch, not silent installation. Serve appcast and signed update archives over HTTPS; authenticate archives with Sparkle EdDSA alongside Apple code signing/notarization. Keep signing secrets outside the app and hosting server. No provider credential is an updater credential. Keep pilot and stable feeds separate. Current candidate build 3 needs one manual replacement to acquire an updater.

The deferred updater must never replace/relaunch while recording, provider processing, recovery or delivery is active. A pending install must wait until idle and block new operations during replacement. Preserve settings, keys and owned recovery files. Offline/invalid-signature/incompatible-OS/read-only-DMG failures leave the working app intact with retry guidance. Declining an update does not prevent dictation. Update checks contact the feed host (which can observe request metadata); no transcripts, recordings, provider keys, dictionary or usage analytics are sent. Exact updater request fields must be reviewed before approval.

## Acceptance And Validation

- Fixture policies cover first use, deferred setup, current/denied/revoked permissions, activation refresh, saved providers, local test receipt/failure/contention and prevention of false Ready states.
- Canonical validation: task check. Native consent, stale-grant repair and real paste stay in manual QA.
- Test first-run and repair views at documented window sizes in light/dark appearance on both supported macOS test versions.
- Updater phase additionally requires actual signed old-to-new installation, active-operation deferral, settings/key/recovery preservation, offline/signature failures, pilot/stable separation and post-update permission checks.
- Existing basic human paste retest is not evidence that this proposed onboarding/updater exists.

## Approval Gate And Open Inputs

Onboarding implementation, checks, feature commits/pushes and candidate packaging are authorized. Follow-up authorization on 2026-10-23 includes latest local candidate installation/launch after final quality review. Stop before main/tag/publication, real provider/microphone validation or private signing-material use. Sparkle/hosting/network/signing work remains separately gated. Confirm company provider/key-issuance guidance, Developer ID owner, approved release/feed hosting and audience access, updater maintenance owner, and whether IT-managed deployment is preferred. Do not access signing material, publish or distribute based on this document alone.

## Sources

Reviewed 2026-10-23:

- Apple Onboarding: https://developer.apple.com/design/human-interface-guidelines/onboarding
- Apple Privacy: https://developer.apple.com/design/human-interface-guidelines/privacy
- Apple code identity/designated requirements: https://developer.apple.com/documentation/technotes/tn3127-inside-code-signing-requirements
- Sparkle setup, signing, appcast and distribution: https://sparkle-project.org/documentation/

## Implementation Contract Refinements

- Setup dismissal is stored as non-secret local preferences, together with whether each permission was ever observed allowed. Postponing suppresses the full introduction on later launches; a previously allowed permission now missing opens repair at the next normal launch. Menu/General can always reopen setup.
- Returning from System Settings refreshes actual permissions; no popup steals focus during an active dictation. Explicit window-launch modes bypass automatic setup presentation.
- Local paste test reserves the coordinator until its task ends, checks the exact test editor/window before clipboard preparation and posting, and cancels on window close, navigation, window key loss or app deactivation; quickly returning focus cannot resume that attempt. Completion refreshes actual permissions. Sample receipt is required within one second after posting; posting alone never passes. No field content or sample result is persisted or logged. The sample replaces the clipboard only on explicit test action; previous clipboard content is never read/restored.
- Default content size 640×580, minimum 600×500; one scroll owner and fixed footer. Provider editing reuses existing Settings/Apply/confirmation behavior. Launch-at-login remains unchanged.

## Approved Surface Refinement (2026-10-23)

the maintainer requested a nearly white Light Mode canvas because the native window gray contrasted too strongly with white sections. Blend 80% semantic control background over semantic window background in normal Light Mode; keep native Dark Mode surfaces and native separation under Increase Contrast. Text, accent and separator colors retain their semantic roles. Apply through the shared form component to Settings, onboarding and secondary dialogs. This is a project preference supported by adaptive-color guidance, not an Apple-prescribed gray value. Native before/after/light/dark evidence is required. Source rechecked: https://developer.apple.com/design/human-interface-guidelines/color and https://developer.apple.com/design/human-interface-guidelines/dark-mode .

the maintainer also approved removing the gray Settings TabView bezel/header bands. Keep the five native segments using a segmented Picker above the selected pane, on the same shared canvas. Preserve keyboard selection, staged settings, scrolling and fixed Apply footer; no custom tab widget or toolbar redesign.

The approved Settings spacing cleanup uses 24-point horizontal margins, 20-point section gaps, 8-point heading/control gaps, 12-point section insets, 10-point independent rows, 6-point control/help groups and 8-point button gaps. Settings panes fill available width so scrollbars do not shift the left alignment between sections. Short Writing labels keep the common 168-point label column; Advanced pickers use that column too. Readiness actions are grouped after the status rows.
