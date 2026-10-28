# Security And Privacy Spec

## Data Handled

- Microphone audio for the active dictation.
- Raw transcript returned by the transcription provider.
- Cleaned Slack-ready draft text.
- Provider configuration.
- API keys.
- Personal dictionary vocabulary and correction hints.
- Temporary clipboard contents during paste.
- Local usage counters and sanitized diagnostics.
- Optional local dictation archive entries when explicitly enabled.

## Storage And Lifetime

The separately approved manual installation helper is a narrow exception to the
ordinary quarantine-preserving DMG/Homebrew flow. It verifies a pinned release
snapshot and staged app, then removes only `com.apple.quarantine` from that copy
after exact interactive consent. It does not establish Apple verification or
override company policy. No global protection, other metadata, installed app,
Keychain or OS permissions are changed. The separately approved generic provider
arguments may replace the explicitly displayed non-secret connection settings
after the same confirmation; personal fallback/direct modes are disabled and
existing-key origin approval is invalidated. Actual keys are neither read nor
deleted; users enter an approved personal key in the app. Other preferences are
preserved. Private temporary preference backups are removed on success/rollback;
failed rollback explicitly retains a private recovery snapshot. See
`features/installer-provider-configuration/spec.md`. Downloads disclose
ordinary connection metadata to GitHub only. See
`features/manual-install-helper/spec.md`; endpoint rejection requires IT follow-up.

- Audio: temporary while recording, then safeguarded under Application Support before provider processing. Delete immediately after transcription and any enabled cleanup succeed. Preserve failed, canceled-after-stop, or interrupted processing until retry succeeds or the user explicitly deletes it.
- Transcript text: memory only by default, plus last transcript in memory for retry/paste-last during the running app session.
- Cleaned text: session memory and the system clipboard for every delivery attempt that successfully copies the draft.
- API keys: macOS Keychain only. Primary and personal-fallback credentials use
  separate Keychain items. Separate non-secret `UserDefaults` markers may
  remember that keys were saved so the app can avoid reading Keychain on startup.
- Personal dictionary: explicit local JSON only; no transcript history, audio, or automatic learning.
- Launch at login: optional macOS ServiceManagement registration for the main
  app, removable from Settings. An existing legacy user LaunchAgent is retained
  until system registration succeeds, then removed.
- Local install: development scripts open a DMG for manual Finder drag-to-Applications installation. They do not store administrator credentials or invoke `sudo`; Finder handles any required `/Applications` authorization prompt.
- Usage counters: local non-secret `UserDefaults` storage only, with counts and durations but no transcript, draft text, audio file path, provider body, or clipboard content.
- Optional local archive: disabled by default. When enabled, store text-only daily JSONL files in Application Support with final draft text, word counts, timestamps, provider labels, cleanup state, insertion outcome, and optional raw transcript text only if separately enabled. Never store audio in the archive.
- Failed recording recovery: user-only M4A and privacy-safe metadata under `Application Support/BabbelStream/Recovery`; excluded from backup where supported, never included in archive exports or diagnostics, and never silently expired.

Stopped dictation awaiting adoption carries a user-only `.m4a.stopped.json` ownership marker beside its source. The marker stores only a stable id, timestamp, and duration. App stale cleanup excludes marked audio; Failed Recordings discovers it after app restart, and Retry must complete safeguarding before provider work. A stop-marker write failure retains recorder ownership and offers Stop retry or explicit Cancel. Source audio and its marker are removed after adoption, or by explicit deletion/cancellation. Operating-system removal of temporary storage is outside the app's retention guarantee.

## Failed Recording Recovery Privacy Rules

- The app visibly states when a recording has been saved because processing did not complete normally.
- Metadata must not contain transcripts, cleanup input/output, API keys, clipboard content, request/response bodies, or audio paths in copied diagnostics.
- Retry may submit the same audio to primary and Mini during a rare hedge. If
  the explicitly applied personal fallback is enabled and that phase ends in a
  reachability failure, one sequential official-OpenAI attempt is also allowed;
  no other transcription attempt is allowed.
- Recovery retry uses current saved settings and never auto-pastes into the historical target.
- Save Audio As does not imply deletion. Individual and bulk deletion are explicit; bulk deletion requires confirmation.
- POSIX permissions are `0700` for directories and `0600` for files. Custom encryption and cloud backup are out of scope for this release.

## Optional Archive Privacy Rules

- Enabling the archive must be an explicit Settings action with copy that states work text will be stored locally.
- The archive must not be enabled through migration, defaults changes, or diagnostics/debug toggles.
- Raw transcript storage is a separate opt-in setting from final-draft archive storage.
- Archive files should be created with user-only permissions where possible.
- Copyable diagnostics may report archive enabled state and entry counts; never private filesystem paths, but must never include archived text or raw transcript text.
- Monthly topic summaries must be explicit user actions. If generated by an AI provider, the app must show the provider destination and content scope before sending archive text.
- Clear archive is destructive and requires confirmation.

## Clipboard Implications

All automatic insertion places the draft on the system clipboard and posts synthetic Cmd+V. This applies to native and unknown targets as well as rich editors; other applications and clipboard managers may read that text. BabbelStream neither restores the prior clipboard nor reads existing field text. There are no direct Accessibility writes or application routing exceptions. Automatic insertion is allowed only while the captured application remains frontmost, but the field focused at completion may differ from the field focused at recording start. This explicit tradeoff supports reactive editors that do not expose stable field identity. Switching to another application fails closed: the draft is copied without reactivating the original app. Shortcut posting does not prove editor acceptance, so the final draft remains on the clipboard and in session memory for recovery.

Before posting Cmd+V, BabbelStream verifies the pasteboard change count still matches its write, in addition to cancellation and the frontmost-app check. If another writer replaces the clipboard during preparation, no paste is posted and the newer clipboard is preserved. The draft remains in memory via Copy Last Draft. This is a best-effort preflight; macOS does not provide an atomic clipboard-and-target paste transaction.

## Network Destinations

The app normally sends audio to the configured primary transcription endpoint
and transcript text to the configured primary cleanup endpoint when cleanup is
enabled. The settings UI
distinguishes edited values from the saved/effective destinations used by
requests and shows whether transcription uses bare OpenAI model IDs or
LiteLLM's `openai/` namespace, including the effective primary and fallback
IDs. Routing never changes the configured destination. Each dictation snapshots
those saved settings before recording. The app must not silently switch
providers. The only automatic destination change is the separately applied,
disabled-by-default personal OpenAI fallback: after a transport/reachability
failure, including gateway/service-unavailable HTTP 502, 503, or 504, it may
send the safeguarded audio once to `https://api.openai.com` and route cleanup
there. Other HTTP responses, authentication/configuration failures, rate limits,
model errors, malformed responses, and empty output fail closed without cross-
account fallback.

The separately applied `Use personal OpenAI now` mode intentionally routes all
new dictations directly to the fixed personal profile without contacting the
work provider. Its purple HUD treatment and Settings mode/destination remain
visible before audio is sent. The setting persists until explicitly disabled;
the app must not infer weekends, schedules, or provider mode automatically.

Remote providers must use HTTPS. Plain HTTP is limited to loopback development endpoints, and base URLs must not embed credentials, query parameters, or fragments. API keys belong in Keychain.

When cleanup is enabled, personal dictionary entries are included in the cleanup request as context. They are explicit user-maintained hints, not inferred transcript history.

## Debug Logging Policy

Default logs may include timestamps, state names, durations, provider labels, counts, attempt numbers, HTTP status, URL error codes, request/response byte counts, archive enabled state, and archive entry counts. Copyable diagnostics use an explicit export allowlist: version/commit, recording/processing flags, approved provider origin, validated primary model/routing, default-or-custom cleanup classification, timeouts, permission/key-presence flags, archive/recovery/usage counts and constrained failure categories. They never append arbitrary status, error or event messages and omit all private filesystem paths, audio, transcripts, archive contents, cleanup input/output, clipboard contents and request/response bodies. Secret-pattern redaction is defense in depth, not the export boundary. Debug persistence must be opt-in and visibly enabled.

## Threat Model

- Accidental recording of private speech.
- Accidental paste into the wrong app.
- Sending work content to the wrong provider.
- API key leakage.
- Personal dictionary leakage through cleanup context.
- Repeated Keychain prompts caused by startup secret reads or unstable local code signatures.
- Transcript/audio persistence through logs or temp files.
- Disclosure of locally retained failed-recording audio to another process or person with access to the macOS account.
- Local archive disclosure if the user enables text persistence and another local process, backup, or person with account access can read those files.
- Clipboard exposure to other apps.
- Accessibility permission abuse if compromised.
- A slow or transiently failing primary transcription may send the same safeguarded audio once to `gpt-4o-mini-transcribe`. The 10-second hedge and 75-second overall deadline are fixed and visible; diagnostics record stage, model role, duration, status/error category, and byte counts, never audio content or request bodies.
- When explicitly enabled, a primary reachability failure may send the same
  safeguarded audio once more to the user's personal OpenAI account and may send
  transcript text plus personal dictionary context there for cleanup. Settings
  shows the fixed destination, cross-account disclosure, and possible personal
  API charges before Apply. The personal request is sequential and never joins
  the primary/Mini hedge.
- While direct-personal mode is applied, every new dictation sends audio and
  enabled cleanup/dictionary context to the personal account and may incur
  personal charges. No work-provider request is made for that dictation.

## Accessibility Risks

Accessibility permission enables synthetic paste shortcuts. The insertion service does not inspect or write field content. Request permission with clear explanation, avoid broad automation beyond paste, and fall back to copying if permission is absent or the target application changes. Direct field writes are deferred future work requiring an approved contract.

The hybrid hotkey does not require Input Monitoring or any new permission. A tap-latched recording remains visibly active in the HUD and menu until the same shortcut, an explicit Stop action, Escape/Cancel, or the configured maximum duration ends it. Tap/hold classification and activation style are privacy-safe state only and must not be persisted or included with transcript content.

## Provider Transparency

Before first use, the app shows which saved provider base URL receives audio,
which endpoint receives cleanup text, and the effective transcription model
IDs. Changing provider or routing settings is explicit through `Apply
Settings`; edited but unapplied values are not active. Direct OpenAI and
LiteLLM-compatible primary destinations remain explicit base URL/path settings.
The optional personal OpenAI fallback is a fixed, named official profile with a
separate key and a visible applied on/off state; no other hidden routing
behavior is allowed.

## Work Slack Considerations

Slack messages may contain confidential work data. The MVP should avoid history, telemetry, cloud sync, and auto-send. Users should be able to disable cleanup to avoid sending transcript text to a second model endpoint. The optional archive is local-only and off by default; when enabled, the UI should make clear that archived text may be included in local backups and should be cleared manually if it is no longer needed.

## Pilot Destination And Instance Boundaries

Each production launch acquires a user-scoped file lock before constructing stores, recovery discovery or cleanup. A duplicate exits without activating or touching shared audio; startup also checks older running copies with the production bundle identifier. All updated copies share the same Application Support lock, independent of app location. Never unlink the lock file while held. A failed safeguard stops startup visibly. Older binaries cannot be retroactively protected if launched directly after the updated copy; quit all old copies before pilot use.

Each provider task enforces its original scheme/host/effective-port origin through a task delegate. Different origins, credential-bearing redirect URLs and HTTPS-to-HTTP redirects are refused before delivery. Rejected redirects surface as HTTP failures; they do not qualify for personal fallback. Same-origin redirects remain supported.

Primary-key approval is stored as non-secret origin metadata. Existing installations bind once to their saved origin without reading/migrating/deleting the secret. Changing origin requires explicitly re-entering a key approved for that destination. An interrupted update or a key/settings persistence mismatch fails closed; re-enter the key for the saved destination to recover. During an already active operation, an old approved key may remain only in memory for its immutable origin snapshot; completion discards it. No key is silently reused for a different origin.

Transcription accepts the requested JSON object/string-text contract (including valid untyped JSON), or explicitly labeled text/plain compatibility. HTML, malformed JSON, JSON scalar/array shapes and arbitrary untyped UTF-8 fail as malformed responses and retain failed-recording recovery.

## Explicit Connection Tests

Only an explicit confirmation sends synthetic silence to the saved primary transcription endpoint; it uses the origin-approved key and selected model with no user-supplied prompt/language hints. Maximum request timeout is 30 seconds, retry count zero, and no hedge/fallback/cleanup/dictionary/microphone or paste occurs. Cost and destination are disclosed before sending. The short WAV uses user-only temporary storage, is removed on completion/cancellation, and response text is discarded. No test transcript, history, archive, telemetry or verification record is persisted. Only session status is displayed. Apply and key deletion cancel and invalidate test evidence; no live check runs automatically.

## Release Artifact Boundaries

Candidate preparation uses ad-hoc signing unless an identity is explicitly authorized/supplied; it never silently accesses a private signing key. Distribution mode requires explicit Developer ID, hardened runtime and secure timestamp and cannot fall back to local/ad-hoc signing. The audio-input entitlement only supports the existing microphone permission; no debug-task, JIT, sandbox, camera or Apple Events entitlement is added. Notarization uses an explicitly approved existing profile and separate submission authorization; no credential is stored in source or build metadata. Packaging does not install, launch, publish or send diagnostics.

## Onboarding And Local Paste Test

Onboarding stores only introduction dismissal and two previously-observed permission booleans in UserDefaults. These are presentation hints, never authorization. OS permissions are queried at launch, app activation, explicit refresh and paste delivery; only explicit user actions request microphone/Accessibility access. Missing permission retains the established copy-only fallback. No silent TCC reset, new permission, telemetry or updater request is introduced.

An explicit local paste test writes one documented sample to the clipboard and checks only the dedicated app-owned test editor. It never reads an external editor, existing clipboard, key, dictionary, recording or archive. It does not restore the old clipboard or set Last Draft. Sample receipt/result stays session-only and is neither logged nor persisted. Exact editor/window focus, clipboard ownership, current permission and cancellation are checked before posting; changing apps/windows or closing setup cancels remaining work. As with ordinary paste, macOS offers no atomic focus/clipboard/event transaction and an already-posted event cannot be recalled. Coordinator reservation excludes simultaneous recording, provider testing, recovery and draft delivery. Deferred setup never implicitly sends a provider request.

## Approved Homebrew Pilot Exception

On 2026-10-23 the maintainer approved explicit non-notarized ad-hoc distribution through
GitHub Releases and `sichgeis/homebrew-tap` under the Homebrew feature contract.
This exception does not change Developer ID distribution-mode requirements.
Downloads keep quarantine and require user/IT approval where macOS demands it;
no recipe hook bypasses security checks, resets permissions or accesses keys.
Exact versioned HTTPS assets and SHA-256 protect byte consistency, not independent
publisher authentication. GitHub/Homebrew see ordinary user-initiated connection
metadata; BabbelStream adds no updater requests or telemetry. Artifacts include no
provider keys or company configuration. Ordinary cask removal preserves local data;
no zap deletion is supplied. Public rollout requires the documented pilot evidence.

## Explicit Local Model Setup And Inference

The approved local feature permits user-confirmed downloads of pinned model
assets from Hugging Face and its HTTPS CDN. Show source, size and license before
retrieval; use no credentials/cookies, reject downgrade/credential-bearing
redirects, verify length/SHA-256 and prepare in private staging before activation.
Only a successful prepared model can be applied. The next explicit setup cleans
owned incomplete staging directories after an interrupted app exit; removal
never touches recordings, dictionary, archive, keys or other data.

Applied local mode bypasses Keychain reads, cloud transcription, Mini hedging,
cloud cleanup and personal fallback. Optional local cleanup follows its separate contract. A bundled native helper loads exact local files
under OS-enforced network denial; library output is discarded, results remain
in the private bounded pipe, and failure messages are reviewed categories only.
Cancellation discards late output and retains stopped audio under the existing
Failed Recordings policy. Model assets persist until removal; successful audio
and default transcript retention remain unchanged. No telemetry or permission is
added. The first pilot enables only Parakeet; other runtime builds are deferred.

## Optional Local Cleanup

Local cleanup receives transcript and capped personal dictionary through private stdin. It has OS network denial, no API key, no retained prompt/transcript/cache history and no content logging. Model setup only contacts the disclosed Hugging Face HTTPS source/CDN. Weights remain in the private managed model directory until removal. Cancellation kills its owned child; failure retains raw text and stopped audio under existing recovery rules. No permissions or retention defaults change.
