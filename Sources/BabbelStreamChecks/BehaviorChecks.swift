import BabbelStreamCore
import Foundation

func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fatalError(message)
    }
}

func runBehaviorChecks() async throws {
let configuration = ProviderConfiguration()
let tempDirectory = AudioTempFileStore.temporaryDirectory()
let deterministicAudioURL = try AudioTempFileStore.makeTemporaryAudioURL(
    id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
)

check(ProjectDefaults.cleanupEnabledByDefault, "Cleanup should be enabled by default.")
check(!ProjectDefaults.autoSendEnabledByDefault, "MVP must not auto-send messages.")
check(!ProjectDefaults.transcriptHistoryEnabledByDefault, "MVP must not persist transcript history.")
check(!ProjectDefaults.dictationArchiveEnabledByDefault, "Dictation archive must be disabled by default.")
check(!ProjectDefaults.archiveRawTranscriptEnabledByDefault, "Raw transcript archiving must be disabled by default.")
check(!ProjectDefaults.debugPersistenceEnabledByDefault, "Debug persistence must be opt-in.")
check(ProjectDefaults.maxAudioDurationSeconds == 600, "Max recording duration should be 10 minutes.")
check(ProjectDefaults.audioFileExtension == "m4a", "MS1 should record m4a files.")
check(ProjectDefaults.defaultTranscriptionModel == "gpt-4o-transcribe", "Unexpected default STT model.")
check(ProjectDefaults.defaultCleanupModel == "gpt-4o-mini", "Unexpected default cleanup model.")
check(ProjectDefaults.minConfigurableAudioDurationSeconds == 5, "Unexpected minimum recording duration.")
check(ProjectDefaults.maxConfigurableAudioDurationSeconds == 600, "Unexpected maximum configurable recording duration.")
check(ProjectDefaults.defaultTranscriptionResponseFormat == "json", "Transcription should default to JSON responses.")
check(
    AudioLevelNormalizer.normalizedPower(decibels: -80) == 0,
    "Audio below the metering floor should render as silence."
)
check(
    AudioLevelNormalizer.normalizedPower(decibels: -30) == 0.5,
    "Audio power should normalize linearly across the visible metering range."
)
check(
    AudioLevelNormalizer.normalizedPower(decibels: 2) == 1,
    "Audio above full scale should remain bounded."
)
check(
    AudioLevelNormalizer.normalizedPower(decibels: .nan) == 0,
    "Invalid audio meter values should safely render as silence."
)
check(
    ProjectDefaults.providerConnectionTimeoutSeconds == 15,
    "Provider connection recovery should use the documented 15-second bound."
)
check(ProjectDefaults.transcriptionHedgeDelaySeconds == 10, "Slow primary transcription should hedge after 10 seconds.")
check(ProjectDefaults.transcriptionOverallTimeoutSeconds == 75, "Transcription should have one 75-second deadline.")
check(ProjectDefaults.fallbackTranscriptionModel == "gpt-4o-mini-transcribe", "Unexpected transcription fallback model.")
check(ProjectDefaults.hybridHotkeyHoldThresholdSeconds == 0.5, "Hybrid hotkey should use the documented 0.5-second threshold.")
check(
    HybridDictationHotkeyPolicy.releaseAction(pressDuration: 0) == .latchHandsFree,
    "An immediate release should latch hands-free recording."
)
check(
    HybridDictationHotkeyPolicy.releaseAction(pressDuration: 0.499) == .latchHandsFree,
    "A release below the hold threshold should latch hands-free recording."
)
check(
    HybridDictationHotkeyPolicy.releaseAction(pressDuration: 0.5) == .stopAndProcess,
    "The exact hold threshold should preserve push-to-talk behavior."
)
check(
    HybridDictationHotkeyPolicy.releaseAction(pressDuration: 1.0) == .stopAndProcess,
    "A release above the hold threshold should stop and process."
)
check(
    HybridDictationHotkeyPolicy.releaseAction(pressDuration: -1) == .latchHandsFree,
    "Invalid negative press durations should normalize safely."
)
check(
    DictationHUDPresentation.phase(
        isRecording: false,
        isProcessing: true,
        canCancel: true,
        status: "Trying Mini transcription",
        lastResult: "",
        hasError: false
    ) == .tryingMini,
    "The active Mini hedge should be named in the HUD."
)
check(
    DictationHUDPresentation.phase(
        isRecording: false,
        isProcessing: false,
        canCancel: false,
        status: "Recording saved",
        lastResult: "Recording retained for recovery.",
        hasError: true
    ) == .recordingSaved,
    "Recording recovery should take precedence over a generic HUD error."
)
check(
    DictationHUDPresentation.phase(
        isRecording: false,
        isProcessing: false,
        canCancel: false,
        status: "Ready",
        lastResult: "Draft inserted. Review it before sending.",
        hasError: false
    ) == .pasted,
    "Successful insertion should retain the concise Pasted HUD state."
)
check(DictationHUDPhase.tryingMini.displayName == "Trying Mini", "Mini HUD copy should stay compact.")
check(BuildMetadata.gitCommitInfoKey == "BabbelStreamGitCommit", "Unexpected build commit Info.plist key.")
check(BuildMetadata.codeSigningInfoKey == "BabbelStreamCodeSigning", "Unexpected code signing Info.plist key.")
check(!BuildMetadata.gitCommitShortHash.isEmpty, "Build commit metadata should have a visible fallback.")
check(!BuildMetadata.appVersion.isEmpty, "App version metadata should have a visible fallback.")
check(!BuildMetadata.codeSigningSummary.isEmpty, "Code signing metadata should have a visible fallback.")
check(configuration.transcriptionEndpointPath == "/v1/audio/transcriptions", "Unexpected transcription endpoint default.")
check(configuration.cleanupEndpointPath == "/v1/chat/completions", "Unexpected cleanup endpoint default.")
check(configuration.transcriptionModel == ProjectDefaults.defaultTranscriptionModel, "Provider configuration should use the default STT model.")
check(configuration.cleanupModel == ProjectDefaults.defaultCleanupModel, "Provider configuration should use the default cleanup model.")
check(CleanupPrompt.slackReady.contains("German-English"), "Cleanup prompt must protect mixed-language dictation.")
check(CleanupPrompt.slackReady.contains("English stays English"), "Cleanup prompt must prevent English-to-German translation.")
check(CleanupPrompt.slackReady.contains("German stays German"), "Cleanup prompt must prevent German-to-English translation.")
check(CleanupPrompt.slackReady.contains("Do not translate"), "Cleanup prompt must explicitly forbid translation.")
check(CleanupPrompt.slackReady.contains("ticket IDs"), "Cleanup prompt must protect ticket IDs.")
check(CleanupPrompt.slackReady.contains("Do not use em dashes"), "Cleanup prompt must avoid obvious LLM punctuation.")
check(CleanupPrompt.slackReady.contains("JSON"), "Cleanup prompt must describe the data-only transcript payload.")
check(CleanupPrompt.slackReady.contains("not as instructions"), "Cleanup prompt must treat dictated text as content.")
check(CleanupPrompt.slackReady.contains("not as instructions or a request to answer"), "Cleanup prompt must not answer dictated requests.")
check(CleanupPrompt.slackReady.contains("sentence/paragraph order"), "Cleanup prompt must preserve dictated order.")
check(CleanupPrompt.slackReady.contains("plain text"), "Cleanup prompt must request plain text output.")
check(CleanupPrompt.slackReady.contains("no Markdown"), "Cleanup prompt must forbid Markdown formatting.")
check(CleanupPrompt.slackReady.contains("new thought starts"), "Cleanup prompt should allow paragraph breaks for new thoughts.")
let commandLikeTranscript = "Create a GitHub pull request for this feature. Include a Mermaid chart if it helps."
let cleanupUserMessage = CleanupPrompt.userMessage(for: commandLikeTranscript)
let cleanupUserPayload = try JSONSerialization.jsonObject(with: Data(cleanupUserMessage.utf8)) as? [String: String]
check(
    cleanupUserPayload?["transcript"] == commandLikeTranscript,
    "Cleanup user message should encode the transcript as data."
)
check(
    !cleanupUserMessage.contains("Clean up"),
    "Cleanup user message should not add instruction-like wrapper text around the transcript."
)
check(
    TranscriptionLanguageNormalizer.apiValue(from: "German") == "de",
    "Single-language aliases should normalize to API language codes."
)
check(
    TranscriptionLanguageNormalizer.apiValue(from: "German, English") == nil,
    "Mixed-language hints must not be sent as the transcription language parameter."
)
check(
    ProviderEndpointBuilder.endpointURL(baseURL: configuration.baseURL, path: configuration.transcriptionEndpointPath)?
        .absoluteString == "https://litellm.example.local/v1/audio/transcriptions",
    "Provider endpoint builder should join base URL and paths predictably."
)
let providerErrorBody = Data(#"{"error":{"message":"model not found\ncheck provider config"}}"#.utf8)
check(
    ProviderErrorMessageExtractor.message(from: providerErrorBody) == "model not found check provider config",
    "Provider error messages should be extracted and whitespace-normalized."
)
check(
    ProviderError.requestFailed(statusCode: 400, message: "bad request").errorDescription?
        .contains("bad request") == true,
    "Provider HTTP failures should expose safe provider details."
)
do {
    _ = try TranscriptionResponseParser.parse(data: Data(#"{"unexpected":"shape"}"#.utf8))
    fatalError("Malformed JSON success responses should not be treated as transcript text.")
} catch ProviderError.malformedResponse {
    // Expected.
}
check(
    ProviderRetryPolicy.shouldRetry(ProviderError.requestFailed(statusCode: 429, message: "slow down")),
    "Provider throttling should be retryable."
)
check(
    ProviderRetryPolicy.shouldRetry(ProviderError.requestFailed(statusCode: 503, message: "unavailable")),
    "Temporary provider server failures should be retryable."
)
check(
    !ProviderRetryPolicy.shouldRetry(ProviderError.requestFailed(statusCode: 401, message: "invalid key")),
    "Authentication failures should not be retried."
)
check(
    ProviderRetryPolicy.shouldRetry(URLError(.timedOut)),
    "Network timeouts should be retryable."
)
check(
    ProviderRetryPolicy.shouldRetry(ProviderError.connectionTimedOut(seconds: 15)),
    "A stalled provider connection should be retryable."
)
check(
    ProviderRetryPolicy.retryReason(for: ProviderError.connectionTimedOut(seconds: 15)) == .connectionTimeout,
    "Connection timeouts should have a privacy-safe retry reason."
)
check(
    ProviderRetryPolicy.isCancellation(URLError(.cancelled)),
    "URLSession cancellation should be treated as task cancellation."
)
check(ProviderRetryPolicy.maximumRetryCount == 3, "Provider retries should stay locally bounded.")
let emptyDictionary = PersonalDictionary()
check(emptyDictionary.isEmpty, "Personal dictionary should default to empty.")
check(
    DictionaryPromptBuilder.cleanupContext(for: emptyDictionary) == nil,
    "Empty dictionaries should not add cleanup prompt context."
)
let sampleDictionary = PersonalDictionary(
    vocabulary: [
        PersonalVocabularyEntry(term: "LiteLLM"),
        PersonalVocabularyEntry(term: "IgnoredTerm", enabled: false)
    ],
    corrections: [
        PersonalCorrectionEntry(from: "light LM", to: "LiteLLM"),
        PersonalCorrectionEntry(from: "ignored", to: "Ignored", enabled: false)
    ]
)
let dictionaryContext = DictionaryPromptBuilder.cleanupContext(for: sampleDictionary) ?? ""
check(dictionaryContext.contains("LiteLLM"), "Dictionary prompt should include enabled vocabulary.")
check(dictionaryContext.contains("light LM => LiteLLM"), "Dictionary prompt should include enabled corrections.")
check(!dictionaryContext.contains("IgnoredTerm"), "Dictionary prompt should omit disabled vocabulary.")
check(!dictionaryContext.contains("ignored => Ignored"), "Dictionary prompt should omit disabled corrections.")
let limitedDictionary = PersonalDictionary(
    vocabulary: [
        PersonalVocabularyEntry(term: "ShortTerm"),
        PersonalVocabularyEntry(term: String(repeating: "LongDictionaryTerm", count: 20))
    ],
    corrections: [
        PersonalCorrectionEntry(from: "wrong short", to: "ShortTerm")
    ]
)
let limitedContext = DictionaryPromptBuilder.cleanupContextDetails(for: limitedDictionary, maxCharacters: 360)
check(limitedContext?.includedVocabularyCount == 1, "Dictionary prompt should include entries within the local limit.")
check(limitedContext?.wasTruncated == true, "Dictionary prompt should report skipped entries when the context is capped.")
check(
    (limitedContext?.text.count ?? 0) <= 860,
    "Dictionary prompt should stay bounded even after adding the truncation note."
)
let parsedDictionary = try PersonalDictionaryTextCodec.dictionary(
    vocabularyText: "Hypatos\nLiteLLM\nlitellm\n",
    correctionsText: "light LM => LiteLLM\nprompting service => prompting-service\n"
)
check(parsedDictionary.vocabulary.count == 2, "Vocabulary parsing should remove duplicate terms case-insensitively.")
check(parsedDictionary.corrections.count == 2, "Correction parsing should parse wrong-to-right pairs.")
var trainerDictionary = PersonalDictionary()
let trainerCreated = try PersonalDictionaryTextCodec.upsertCorrection(
    from: "David",
    to: "Dawid",
    in: &trainerDictionary
)
check(trainerCreated, "Teaching a new correction should create a dictionary correction.")
check(trainerDictionary.enabledCorrections.count == 1, "New taught corrections should be enabled.")
let trainerUpdated = try PersonalDictionaryTextCodec.upsertCorrection(
    from: "david",
    to: "dawid",
    in: &trainerDictionary
)
check(!trainerUpdated, "Teaching the same correction with different casing should update instead of duplicating.")
check(trainerDictionary.corrections.count == 1, "Taught corrections should de-duplicate case-insensitively.")
let trainerPreferredTextUpdated = try PersonalDictionaryTextCodec.upsertCorrection(
    from: "David",
    to: "Dávid",
    in: &trainerDictionary
)
check(!trainerPreferredTextUpdated, "Teaching a new preferred spelling for the same wrong form should update in place.")
check(trainerDictionary.corrections.count == 1, "One wrong form should not produce conflicting correction hints.")
check(trainerDictionary.corrections[0].to == "Dávid", "The latest explicit preferred spelling should win.")
trainerDictionary.corrections[0].enabled = false
let trainerReenabled = try PersonalDictionaryTextCodec.upsertCorrection(
    from: "David",
    to: "Dawid",
    in: &trainerDictionary
)
check(!trainerReenabled, "Teaching a disabled correction should re-enable the existing entry.")
check(trainerDictionary.enabledCorrections.count == 1, "Disabled taught corrections should be re-enabled.")
let metadataDictionary = PersonalDictionary(
    vocabulary: [
        PersonalVocabularyEntry(term: "LiteLLM", notes: "Keep exact casing"),
        PersonalVocabularyEntry(term: "DisabledTerm", notes: "Keep for later", enabled: false)
    ],
    corrections: [
        PersonalCorrectionEntry(from: "light LM", to: "LiteLLM"),
        PersonalCorrectionEntry(from: "disabled wrong", to: "DisabledTerm", enabled: false)
    ]
)
let metadataPreservingEdit = try PersonalDictionaryTextCodec.dictionary(
    vocabularyText: "LiteLLM",
    correctionsText: "light LM => LiteLLM",
    preserving: metadataDictionary
)
check(
    metadataPreservingEdit.vocabulary.first?.notes == "Keep exact casing",
    "Bulk editing should preserve notes on retained vocabulary."
)
check(
    metadataPreservingEdit.vocabulary.contains { $0.term == "DisabledTerm" && !$0.enabled },
    "Bulk editing should preserve disabled vocabulary that is hidden from the text editor."
)
check(
    metadataPreservingEdit.corrections.contains { $0.from == "disabled wrong" && !$0.enabled },
    "Bulk editing should preserve disabled corrections that are hidden from the text editor."
)
do {
    _ = try PersonalDictionaryTextCodec.dictionary(vocabularyText: "", correctionsText: "missing separator")
    fatalError("Invalid correction lines should fail validation.")
} catch PersonalDictionaryError.invalidCorrectionLine(_) {
    // Expected.
}
let dictionaryStoreURL = FileManager.default.temporaryDirectory
    .appendingPathComponent("BabbelStreamChecks", isDirectory: true)
    .appendingPathComponent("personal-dictionary-check.json")
let dictionaryStore = JSONPersonalDictionaryStore(fileURL: dictionaryStoreURL)
try? FileManager.default.removeItem(at: dictionaryStoreURL)
let missingDictionary = try dictionaryStore.load()
check(missingDictionary == PersonalDictionary(), "Missing dictionary files should load as empty.")
try dictionaryStore.save(sampleDictionary)
let reloadedDictionary = try dictionaryStore.load()
check(reloadedDictionary == sampleDictionary, "Personal dictionary JSON should round-trip.")
try? FileManager.default.removeItem(at: dictionaryStoreURL)
check(
    DictationDraftFormatter.textWithTrailingSeparator("First sentence.") == "First sentence. ",
    "Inserted dictation drafts should receive one trailing separator."
)
check(
    DictationDraftFormatter.textWithTrailingSeparator("Already spaced ") == "Already spaced ",
    "Dictation drafts should not receive duplicate trailing separators."
)
let preservedInsertionPayload = try TextInsertionPayload.validated("First sentence. ")
check(
    preservedInsertionPayload == "First sentence. ",
    "Text insertion must preserve the intentional trailing separator."
)
do {
    _ = try TextInsertionPayload.validated("   ")
    fatalError("Whitespace-only insertion payloads should be rejected.")
} catch TextInsertionError.emptyText {
    // Expected.
}
let capturedInsertionTarget = TextInsertionTarget(
    processIdentifier: 1234,
    localizedName: "Slack",
    bundleIdentifier: "com.tinyspeck.slackmacgap"
)
check(
    capturedInsertionTarget.displayName == "Slack",
    "Paste-target summaries should use the captured application name."
)
check(
    TextInsertionTarget(processIdentifier: 1234, localizedName: nil).displayName == "previous app",
    "Paste-target summaries should have a safe fallback when the application name is unavailable."
)
check(
    TextInsertionTargetPolicy.applicationMatches(
        capturedInsertionTarget,
        frontmostProcessIdentifier: 1234
    ),
    "The application-level target check should match the captured process."
)
check(
    !TextInsertionTargetPolicy.applicationMatches(
        capturedInsertionTarget,
        frontmostProcessIdentifier: 5678
    ),
    "Insertion should be blocked after focus moves to another application."
)
check(
    !TextInsertionTargetPolicy.applicationMatches(nil, frontmostProcessIdentifier: 1234),
    "Insertion should be blocked when no target was captured."
)
let launchAtLoginCheckRoot = FileManager.default.temporaryDirectory
    .appendingPathComponent("BabbelStreamLaunchAtLoginChecks-\(UUID().uuidString)", isDirectory: true)
let legacyLaunchAgentURL = launchAtLoginCheckRoot.appendingPathComponent("legacy.plist")
try FileManager.default.createDirectory(at: launchAtLoginCheckRoot, withIntermediateDirectories: true)
defer { try? FileManager.default.removeItem(at: launchAtLoginCheckRoot) }
try Data("legacy launch agent".utf8).write(to: legacyLaunchAgentURL)
let enabledSystemLoginItem = FakeSystemLoginItemService(status: .notRegistered)
let migratingLaunchAtLoginService = LaunchAtLoginService(
    systemService: enabledSystemLoginItem,
    legacyLaunchAgentURL: legacyLaunchAgentURL
)
try migratingLaunchAtLoginService.migrateLegacyRegistrationIfNeeded()
check(
    enabledSystemLoginItem.registerCallCount == 1,
    "Legacy launch-at-login intent should register the supported system login item."
)
check(
    migratingLaunchAtLoginService.snapshot.systemStatus == .enabled,
    "Successful migration should report the system login item as enabled."
)
check(
    !FileManager.default.fileExists(atPath: legacyLaunchAgentURL.path),
    "The legacy LaunchAgent should be removed only after system registration succeeds."
)
try Data("legacy launch agent".utf8).write(to: legacyLaunchAgentURL)
let approvalRequiredSystemLoginItem = FakeSystemLoginItemService(status: .requiresApproval)
approvalRequiredSystemLoginItem.registrationError = LoginItemCheckError.denied
let approvalRequiredLaunchAtLoginService = LaunchAtLoginService(
    systemService: approvalRequiredSystemLoginItem,
    legacyLaunchAgentURL: legacyLaunchAgentURL
)
do {
    try approvalRequiredLaunchAtLoginService.migrateLegacyRegistrationIfNeeded()
    fatalError("A login item awaiting approval should not complete legacy migration.")
} catch LaunchAtLoginError.approvalRequired {
    // Expected.
}
check(
    FileManager.default.fileExists(atPath: legacyLaunchAgentURL.path),
    "Failed system registration must preserve the working legacy LaunchAgent."
)
check(
    approvalRequiredLaunchAtLoginService.snapshot.isEnabled,
    "A preserved legacy LaunchAgent should keep launch-at-login intent enabled."
)
check(
    approvalRequiredLaunchAtLoginService.snapshot.requiresApproval,
    "The launch-at-login snapshot should expose pending system approval."
)
let presenceDefaults = UserDefaults(suiteName: "com.sichgeis.babbelstream.checks")!
presenceDefaults.removePersistentDomain(forName: "com.sichgeis.babbelstream.checks")
let apiKeyPresenceStore = UserDefaultsAPIKeyPresenceStore(
    userDefaults: presenceDefaults,
    key: "api-key-presence-check"
)
check(!apiKeyPresenceStore.hasSavedAPIKey, "API key presence should default to false without Keychain access.")
apiKeyPresenceStore.hasSavedAPIKey = true
check(apiKeyPresenceStore.hasSavedAPIKey, "API key presence should persist as a non-secret UserDefaults hint.")
try AppSettingsValidator.validate(AppSettings())
var loopbackHTTPSettings = AppSettings()
loopbackHTTPSettings.providerConfiguration.baseURL = URL(string: "http://127.0.0.1:4000")!
try AppSettingsValidator.validate(loopbackHTTPSettings)
check(
    ProviderTransportPolicy.isLoopback(URL(string: "http://localhost:4000")!),
    "Localhost should be recognized as an allowed loopback development endpoint."
)
check(
    ProviderTransportPolicy.isLoopback(URL(string: "http://[::1]:4000")!),
    "IPv6 loopback should be recognized as an allowed development endpoint."
)
do {
    var insecureSettings = AppSettings()
    insecureSettings.providerConfiguration.baseURL = URL(string: "http://provider.example.com")!
    try AppSettingsValidator.validate(insecureSettings)
    fatalError("Remote plain HTTP provider URLs should fail settings validation.")
} catch SettingsValidationError.insecureBaseURL {
    // Expected.
}
do {
    var credentialURLSettings = AppSettings()
    credentialURLSettings.providerConfiguration.baseURL = URL(string: "https://user:secret@provider.example.com")!
    try AppSettingsValidator.validate(credentialURLSettings)
    fatalError("Provider credentials in the base URL should fail settings validation.")
} catch SettingsValidationError.ambiguousBaseURL {
    // Expected.
}
do {
    var queryURLSettings = AppSettings()
    queryURLSettings.providerConfiguration.baseURL = URL(string: "https://provider.example.com?token=secret")!
    try AppSettingsValidator.validate(queryURLSettings)
    fatalError("Provider query parameters in the base URL should fail settings validation.")
} catch SettingsValidationError.ambiguousBaseURL {
    // Expected.
}
do {
    var invalidPathSettings = AppSettings()
    invalidPathSettings.providerConfiguration.transcriptionEndpointPath = "v1/audio/transcriptions"
    try AppSettingsValidator.validate(invalidPathSettings)
    fatalError("Endpoint paths without a leading slash should fail settings validation.")
} catch SettingsValidationError.invalidEndpointPath {
    // Expected.
}
do {
    var invalidDurationSettings = AppSettings()
    invalidDurationSettings.maxAudioDurationSeconds = 601
    try AppSettingsValidator.validate(invalidDurationSettings)
    fatalError("Recording duration above the 10-minute cap should fail settings validation.")
} catch SettingsValidationError.invalidMaxAudioDuration {
    // Expected.
}
do {
    var invalidLanguageSettings = AppSettings()
    invalidLanguageSettings.transcriptionLanguage = "German, English"
    try AppSettingsValidator.validate(invalidLanguageSettings)
    fatalError("Mixed-language free-form hints should fail settings validation.")
} catch SettingsValidationError.invalidTranscriptionLanguage {
    // Expected.
}
var usageSnapshot = UsageSnapshot()
usageSnapshot.recordDictation(duration: 90)
usageSnapshot.recordCleanupRequest()
usageSnapshot.recordTranscriptionFailure()
usageSnapshot.recordCleanupFallback()
check(usageSnapshot.totalDictations == 1, "Usage counters should track dictation attempts.")
check(usageSnapshot.totalRecordedMinutes == 1.5, "Usage counters should track recorded minutes locally.")
check(usageSnapshot.cleanupRequests == 1, "Usage counters should track cleanup requests.")
check(usageSnapshot.transcriptionFailures == 1, "Usage counters should track transcription failures.")
check(usageSnapshot.cleanupFallbacks == 1, "Usage counters should track cleanup fallbacks.")
let usageDefaults = UserDefaults(suiteName: "com.sichgeis.babbelstream.usage-checks")!
usageDefaults.removePersistentDomain(forName: "com.sichgeis.babbelstream.usage-checks")
let usageTracker = UserDefaultsUsageTracker(userDefaults: usageDefaults, key: "usage-check")
usageTracker.save(usageSnapshot)
check(usageTracker.load() == usageSnapshot, "Usage counters should persist as local UserDefaults data.")
usageTracker.reset()
check(usageTracker.load() == UsageSnapshot(), "Usage counters should reset locally.")
try runArchiveChecks()
try runRecoveryStoreChecks()
let diagnosticsText = PrivacyDiagnosticsBuilder.redactSecrets(
    in: "api key: sk-testSecret123456789 Authorization: Bearer secret-token"
)
check(!diagnosticsText.contains("sk-testSecret"), "Diagnostics redaction should remove OpenAI-style API keys.")
check(!diagnosticsText.contains("secret-token"), "Diagnostics redaction should remove bearer tokens.")
check(
    AudioTempFileStore.isUnderSystemTemporaryDirectory(tempDirectory),
    "Audio temp directory should stay under the system temp directory."
)
check(
    AudioTempFileStore.isUnderSystemTemporaryDirectory(deterministicAudioURL),
    "Audio temp files should stay under the system temp directory."
)
check(
    deterministicAudioURL.pathExtension == ProjectDefaults.audioFileExtension,
    "Audio temp files should use the configured audio extension."
)

try Data("delete-check".utf8).write(to: deterministicAudioURL)
check(FileManager.default.fileExists(atPath: deterministicAudioURL.path), "Delete-check temp file should exist before deletion.")
let multipart = try MultipartFormDataBuilder.build(
    fields: [
        "model": configuration.transcriptionModel,
        "response_format": ProjectDefaults.defaultTranscriptionResponseFormat
    ],
    fileFieldName: "file",
    fileURL: deterministicAudioURL,
    boundary: "babbelstream-check-boundary"
)
check(multipart.contentType.contains("multipart/form-data"), "Multipart content type should be form-data.")
check(multipart.body.count > 0, "Multipart body should not be empty.")
try await runTranscriptionRetryCheck(audioURL: deterministicAudioURL)
try await runTranscriptionConnectionTimeoutCheck(audioURL: deterministicAudioURL)
try await runTranscriptionCancellationCheck(audioURL: deterministicAudioURL)
try await runHedgedTranscriptionChecks()
_ = try AudioTempFileStore.deleteTemporaryAudio(at: deterministicAudioURL)
check(!FileManager.default.fileExists(atPath: deterministicAudioURL.path), "Delete-check temp file should be deleted.")
let retainedRecording = RecordedAudio(
    temporaryFileURL: deterministicAudioURL,
    duration: 1,
    byteCount: 12,
    createdAt: Date(),
    deletedAt: nil
)
check(!retainedRecording.wasDeleted, "Retained recordings should report that temp audio still needs cleanup.")
}

func runTranscriptionRetryCheck(audioURL: URL) async throws {
    let attempts = LockedAttemptCounter()
    let events = LockedProviderEventRecorder()
    StubURLProtocol.handler = { request in
        let attempt = attempts.increment()
        let statusCode = attempt == 1 ? 503 : 200
        let body = attempt == 1
            ? Data(#"{"error":{"message":"temporary outage"}}"#.utf8)
            : Data(#"{"text":"retry succeeded"}"#.utf8)
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "application/json"]
        )!
        return (response, body)
    }
    defer {
        StubURLProtocol.handler = nil
    }

    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [StubURLProtocol.self]
    let provider = OpenAICompatibleTranscriptionProvider(
        urlSession: URLSession(configuration: configuration)
    )
    var settings = AppSettings()
    settings.providerConfiguration.baseURL = URL(string: "https://provider.example.com")!

    let transcript = try await provider.transcribe(
        TranscriptionRequest(
            audioURL: audioURL,
            settings: settings,
            apiKey: "test-key",
            retryCount: 1,
            onEvent: { event in events.record(event) }
        )
    )
    check(transcript == "retry succeeded", "Transcription should return the successful retry response.")
    check(attempts.value == 2, "One configured retry should make at most two transcription attempts.")
    let recordedEvents = events.values
    check(recordedEvents.count == 8, "Transcription should report the full request lifecycle.")
    check(isPreparedEvent(recordedEvents[0], includesAudio: true), "Transcription should report privacy-safe byte counts.")
    check(recordedEvents[1] == .attemptStarted(attempt: 1, totalAttempts: 2), "The first attempt should be reported.")
    check(recordedEvents[2] == .responseReceived(attempt: 1, statusCode: 503, responseBytes: 40), "The retryable response should include status and byte count.")
    check(isFailedEvent(recordedEvents[3], attempt: 1, category: .httpStatus(503), willRetry: true), "The first failure should be categorized as retryable.")
    check(recordedEvents[4] == .retryScheduled(nextAttempt: 2, totalAttempts: 2, reason: .httpStatus(503)), "The retry reason should be reported.")
    check(recordedEvents[5] == .attemptStarted(attempt: 2, totalAttempts: 2), "The second attempt should be reported.")
    check(recordedEvents[6] == .responseReceived(attempt: 2, statusCode: 200, responseBytes: 26), "The successful response should include status and byte count.")
    check(isSucceededEvent(recordedEvents[7], attempt: 2), "Terminal success should include elapsed time.")
}

func runTranscriptionConnectionTimeoutCheck(audioURL: URL) async throws {
    let attempts = LockedAttemptCounter()
    let events = LockedProviderEventRecorder()
    ConnectionStallURLProtocol.attempts = attempts
    defer {
        ConnectionStallURLProtocol.attempts = nil
    }

    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [ConnectionStallURLProtocol.self]
    let provider = OpenAICompatibleTranscriptionProvider(
        urlSession: URLSession(configuration: configuration),
        connectionTimeoutSeconds: 0.05
    )
    var settings = AppSettings()
    settings.providerConfiguration.baseURL = URL(string: "https://provider.example.com")!
    settings.providerConfiguration.timeoutSeconds = 1

    let transcript = try await provider.transcribe(
        TranscriptionRequest(
            audioURL: audioURL,
            settings: settings,
            apiKey: "test-key",
            retryCount: 1,
            onEvent: { event in events.record(event) }
        )
    )
    check(transcript == "connection retry succeeded", "A stalled connection should recover on retry.")
    check(attempts.value == 2, "A connection stall should consume only one bounded retry.")
    let recordedEvents = events.values
    check(recordedEvents.count == 7, "Connection recovery should report the full request lifecycle.")
    check(isPreparedEvent(recordedEvents[0], includesAudio: true), "Connection recovery should retain request byte metadata.")
    check(recordedEvents[1] == .attemptStarted(attempt: 1, totalAttempts: 2), "The stalled attempt should be reported.")
    check(isFailedEvent(recordedEvents[2], attempt: 1, category: .connectionTimeout, willRetry: true), "The stall should be categorized as a connection timeout.")
    check(recordedEvents[3] == .retryScheduled(nextAttempt: 2, totalAttempts: 2, reason: .connectionTimeout), "The connection retry reason should be reported.")
    check(recordedEvents[4] == .attemptStarted(attempt: 2, totalAttempts: 2), "The recovery attempt should be reported.")
    check(recordedEvents[5] == .responseReceived(attempt: 2, statusCode: 200, responseBytes: 37), "The recovery response should include status and byte count.")
    check(isSucceededEvent(recordedEvents[6], attempt: 2), "Connection recovery success should include elapsed time.")
}

func isPreparedEvent(_ event: ProviderRequestEvent, includesAudio: Bool) -> Bool {
    guard case let .requestPrepared(requestBytes, audioBytes, preparationMilliseconds) = event else { return false }
    return requestBytes > 0 && preparationMilliseconds >= 0 && (audioBytes != nil) == includesAudio
}

func isFailedEvent(
    _ event: ProviderRequestEvent,
    attempt: Int,
    category: ProviderFailureCategory,
    willRetry: Bool
) -> Bool {
    guard case let .attemptFailed(actualAttempt, _, duration, actualCategory, actualWillRetry) = event else {
        return false
    }
    return actualAttempt == attempt && duration >= 0 && actualCategory == category && actualWillRetry == willRetry
}

func isSucceededEvent(_ event: ProviderRequestEvent, attempt: Int) -> Bool {
    guard case let .attemptSucceeded(actualAttempt, _, duration) = event else { return false }
    return actualAttempt == attempt && duration >= 0
}

func runTranscriptionCancellationCheck(audioURL: URL) async throws {
    let attempts = LockedAttemptCounter()
    ConnectionStallURLProtocol.attempts = attempts
    ConnectionStallURLProtocol.alwaysStall = true
    defer {
        ConnectionStallURLProtocol.attempts = nil
        ConnectionStallURLProtocol.alwaysStall = false
    }

    let configuration = URLSessionConfiguration.ephemeral
    configuration.protocolClasses = [ConnectionStallURLProtocol.self]
    let provider = OpenAICompatibleTranscriptionProvider(
        urlSession: URLSession(configuration: configuration),
        connectionTimeoutSeconds: 1
    )
    var settings = AppSettings()
    settings.providerConfiguration.baseURL = URL(string: "https://provider.example.com")!
    settings.providerConfiguration.timeoutSeconds = 2

    let task = Task {
        try await provider.transcribe(
            TranscriptionRequest(audioURL: audioURL, settings: settings, apiKey: "test-key", retryCount: 1)
        )
    }
    try await Task.sleep(nanoseconds: 30_000_000)
    task.cancel()

    do {
        _ = try await task.value
        fatalError("A canceled transcription should not complete or retry.")
    } catch is CancellationError {
        // Expected.
    }
    check(attempts.value == 1, "Cancellation should prevent further transcription attempts.")
}

func runHedgedTranscriptionChecks() async throws {
    let fallbackStarts = LockedAttemptCounter()
    let primaryResult = try await HedgedTranscriptionRunner.run(
        hedgeDelaySeconds: 0.05,
        deadlineSeconds: 0.2,
        shouldHedgeAfterError: ProviderRetryPolicy.shouldRetry,
        primary: {
            try await Task.sleep(nanoseconds: 2_000_000)
            return "primary"
        },
        fallback: {
            _ = fallbackStarts.increment()
            return "fallback"
        }
    )
    check(primaryResult.winningRole == .primary, "Fast primary transcription should win.")
    check(!primaryResult.hedgeStarted, "Fast primary transcription should not start Mini.")
    check(fallbackStarts.value == 0, "Mini should not be called before the hedge delay.")

    let hedgeResult = try await HedgedTranscriptionRunner.run(
        hedgeDelaySeconds: 0.01,
        deadlineSeconds: 0.2,
        shouldHedgeAfterError: ProviderRetryPolicy.shouldRetry,
        primary: {
            try await Task.sleep(nanoseconds: 100_000_000)
            return "slow primary"
        },
        fallback: {
            try await Task.sleep(nanoseconds: 2_000_000)
            return "fast fallback"
        }
    )
    check(hedgeResult.winningRole == .fallback, "Mini should win when primary remains slow.")
    check(hedgeResult.hedgeStarted, "Slow primary transcription should start the hedge.")

    let earlyFailureResult = try await HedgedTranscriptionRunner.run(
        hedgeDelaySeconds: 0.1,
        deadlineSeconds: 0.2,
        shouldHedgeAfterError: ProviderRetryPolicy.shouldRetry,
        primary: { throw URLError(.timedOut) },
        fallback: { "fallback after early failure" }
    )
    check(earlyFailureResult.winningRole == .fallback, "Retryable primary failure should start Mini immediately.")

    let permanentFallbackStarts = LockedAttemptCounter()
    do {
        _ = try await HedgedTranscriptionRunner.run(
            hedgeDelaySeconds: 0.1,
            deadlineSeconds: 0.2,
            shouldHedgeAfterError: ProviderRetryPolicy.shouldRetry,
            primary: { throw ProviderError.missingAPIKey },
            fallback: {
                _ = permanentFallbackStarts.increment()
                return "unexpected fallback"
            }
        )
        check(false, "Permanent primary failures should stop without a hedge.")
    } catch ProviderError.missingAPIKey {
        check(permanentFallbackStarts.value == 0, "Permanent primary failures must not submit audio to Mini.")
    }

    do {
        _ = try await HedgedTranscriptionRunner.run(
            hedgeDelaySeconds: 0.005,
            deadlineSeconds: 0.02,
            shouldHedgeAfterError: ProviderRetryPolicy.shouldRetry,
            primary: {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                return "late primary"
            },
            fallback: {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                return "late fallback"
            }
        )
        check(false, "Hedged transcription should enforce its overall deadline.")
    } catch let error as HedgedTranscriptionError {
        check(error == .deadlineExceeded(seconds: 1), "Deadline errors should remain bounded and categorized.")
    }
}

func runRecoveryStoreChecks() throws {
    let fileManager = FileManager.default
    let root = fileManager.temporaryDirectory
        .appendingPathComponent("BabbelStreamRecoveryChecks-\(UUID().uuidString)", isDirectory: true)
    let recoveryURL = root.appendingPathComponent("Recovery", isDirectory: true)
    let sourceURL = root.appendingPathComponent("source.m4a")
    try fileManager.createDirectory(at: root, withIntermediateDirectories: true)
    try Data("recovery-audio-fixture".utf8).write(to: sourceURL)
    defer { try? fileManager.removeItem(at: root) }

    let store = FileDictationRecoveryStore(recoveryDirectoryURL: recoveryURL)
    let recordedAt = Date(timeIntervalSince1970: 1_752_000_000)
    let recording = RecordedAudio(
        temporaryFileURL: sourceURL,
        duration: 42,
        byteCount: Int64((try Data(contentsOf: sourceURL)).count),
        createdAt: recordedAt,
        deletedAt: nil
    )
    let settings = AppSettings()
    let item = try store.adopt(recording, target: nil, settings: settings)

    check(!fileManager.fileExists(atPath: sourceURL.path), "Recovery adoption should remove the original only after copying it.")
    let storedAudioURL = try store.audioURL(for: item)
    check(fileManager.fileExists(atPath: storedAudioURL.path), "Recovery adoption should preserve the recording.")
    let storedAudioPermissions = try fileManager.attributesOfItem(atPath: storedAudioURL.path)[.posixPermissions] as? NSNumber
    check(
        storedAudioPermissions?.intValue == 0o600,
        "Recovery audio should be readable only by the current user."
    )

    let processingSnapshot = try store.loadSnapshot(markProcessingAsInterrupted: false)
    check(processingSnapshot.recordings.count == 1, "Recovery snapshots should load stored metadata.")
    check(processingSnapshot.recordings.first?.id == item.id, "Recovery snapshots should retain stable identifiers.")
    check(processingSnapshot.recordings.first?.state == .processing, "New recovery items should remain in processing state.")
    let interruptedSnapshot = try store.loadSnapshot(markProcessingAsInterrupted: true)
    check(interruptedSnapshot.recordings.first?.state == .interrupted, "Startup should mark in-flight work as interrupted.")

    let interrupted = interruptedSnapshot.recordings[0]
    let retrying = try store.update(
        interrupted,
        state: .processing,
        failureCategory: nil,
        incrementRetryCount: true
    )
    check(retrying.retryCount == 1, "Recovery retry attempts should be counted.")

    let exportURL = root.appendingPathComponent("exported.m4a")
    try store.exportAudio(for: retrying, to: exportURL)
    check(fileManager.fileExists(atPath: exportURL.path), "Recovery audio should export without deleting the stored item.")
    check(fileManager.fileExists(atPath: storedAudioURL.path), "Export should retain the recovery recording.")

    try store.delete(retrying)
    let emptySnapshot = try store.loadSnapshot(markProcessingAsInterrupted: false)
    check(emptySnapshot.recordings.isEmpty, "Explicit delete should remove one recovery item.")
}

func runArchiveChecks() throws {
    let settingsDefaults = UserDefaults(suiteName: "com.sichgeis.babbelstream.settings-checks")!
    settingsDefaults.removePersistentDomain(forName: "com.sichgeis.babbelstream.settings-checks")
    let settingsStore = UserDefaultsSettingsStore(userDefaults: settingsDefaults)
    let archiveSettings = AppSettings(dictationArchiveEnabled: true, archiveRawTranscriptEnabled: true)
    try settingsStore.save(archiveSettings)
    check(settingsStore.load().dictationArchiveEnabled, "Archive enabled setting should persist.")
    check(
        settingsStore.load().archiveRawTranscriptEnabled,
        "Raw transcript archive setting should persist when archive is enabled."
    )

    let disabledArchiveSettings = AppSettings(dictationArchiveEnabled: false, archiveRawTranscriptEnabled: true)
    check(
        !disabledArchiveSettings.archiveRawTranscriptEnabled,
        "Raw transcript archiving should be ineffective when archive is disabled."
    )
    check(DictationWordCounter.count(in: "hello world") == 2, "Word counter should count simple English words.")
    check(DictationWordCounter.count(in: "Kannst du bitte testen") == 4, "Word counter should count simple German words.")
    check(
        DictationWordCounter.count(in: "Hallo team please review") == 4,
        "Word counter should count mixed-language words."
    )
    check(DictationWordCounter.count(in: "   ") == 0, "Word counter should return zero for blank text.")

    var archiveCalendar = Calendar(identifier: .gregorian)
    archiveCalendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let archiveRootURL = FileManager.default.temporaryDirectory
        .appendingPathComponent("BabbelStreamChecks", isDirectory: true)
        .appendingPathComponent("ArchiveChecks", isDirectory: true)
    let archiveURL = archiveRootURL.appendingPathComponent("Archive", isDirectory: true)
    let siblingURL = archiveRootURL.appendingPathComponent("keep.txt")
    try? FileManager.default.removeItem(at: archiveRootURL)
    try FileManager.default.createDirectory(at: archiveRootURL, withIntermediateDirectories: true)
    try Data("keep".utf8).write(to: siblingURL)

    let archiveStore = JSONLDictationArchiveStore(archiveDirectoryURL: archiveURL, calendar: archiveCalendar)
    let firstArchiveEntry = makeFirstArchiveEntry()
    try archiveStore.append(firstArchiveEntry)

    let firstArchiveFile = archiveURL
        .appendingPathComponent("2026-07", isDirectory: true)
        .appendingPathComponent("2026-07-07")
        .appendingPathExtension("jsonl")
    let firstArchiveFileText = try String(contentsOf: firstArchiveFile, encoding: .utf8)
    check(!firstArchiveFileText.contains("rawTranscriptText"), "Archive entries should omit raw transcript text unless enabled.")

    let archiveFileHandle = try FileHandle(forWritingTo: firstArchiveFile)
    try archiveFileHandle.seekToEnd()
    try archiveFileHandle.write(contentsOf: Data("{damaged archive line}\n".utf8))
    try archiveFileHandle.close()

    let secondArchiveEntry = makeSecondArchiveEntry()
    try archiveStore.append(secondArchiveEntry)
    let archiveSnapshot = try archiveStore.loadMonth(DictationArchiveMonth(year: 2026, month: 7)!)
    check(
        archiveSnapshot.entries == [firstArchiveEntry, secondArchiveEntry],
        "Archive JSONL entries should round-trip in timestamp order."
    )
    check(archiveSnapshot.readWarnings.count == 1, "Archive loading should report damaged JSONL lines.")
    check(archiveSnapshot.readWarnings[0].line == 2, "Archive recovery should identify the damaged line.")
    check(archiveSnapshot.dailySummaries.count == 1, "Archive monthly aggregation should group same-day entries.")
    check(archiveSnapshot.dailySummaries[0].entryCount == 2, "Archive daily aggregation should count entries.")
    check(
        archiveSnapshot.totalRawWordCount == firstArchiveEntry.rawWordCount + secondArchiveEntry.rawWordCount,
        "Archive monthly aggregation should total raw words."
    )
    check(
        archiveSnapshot.totalFinalWordCount == firstArchiveEntry.finalWordCount + secondArchiveEntry.finalWordCount,
        "Archive monthly aggregation should total final words."
    )

    let archiveMarkdown = archiveStore.markdownExport(for: archiveSnapshot)
    check(archiveMarkdown.contains("# BabbelStream Archive 2026-07"), "Archive Markdown export should name the month.")
    check(archiveMarkdown.contains(firstArchiveEntry.finalDraftText), "Archive Markdown export should include final draft contents.")
    check(archiveMarkdown.contains(secondArchiveEntry.finalDraftText), "Archive Markdown export should include all final draft contents.")
    check(
        archiveMarkdown.contains("Skipped damaged entries: 1"),
        "Archive exports should disclose recovered damaged entries."
    )
    check(
        archiveMarkdown.range(of: firstArchiveEntry.finalDraftText)!.lowerBound
            < archiveMarkdown.range(of: secondArchiveEntry.finalDraftText)!.lowerBound,
        "Archive Markdown export should preserve timestamp order."
    )

    try archiveStore.clearArchive()
    check(!FileManager.default.fileExists(atPath: archiveURL.path), "Archive clear should remove the archive directory.")
    check(FileManager.default.fileExists(atPath: siblingURL.path), "Archive clear should not remove sibling files.")
    try? FileManager.default.removeItem(at: archiveRootURL)
}

func makeFirstArchiveEntry() -> DictationArchiveEntry {
    let rawTranscript = "hello world"
    let finalDraft = "Hello world."
    let startedAt = ISO8601DateFormatter().date(from: "2026-07-07T10:00:00Z")!

    return DictationArchiveEntry(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000101")!,
        startedAt: startedAt,
        completedAt: startedAt.addingTimeInterval(3),
        audioDurationSeconds: 3,
        activeAppName: "Slack",
        activeAppBundleIdentifier: "com.tinyspeck.slackmacgap",
        cleanupEnabled: true,
        cleanupFallbackUsed: false,
        insertionOutcome: .directAccessibilityInsertion,
        transcriptionProviderLabel: "example / gpt-4o-transcribe",
        cleanupProviderLabel: "example / gpt-4o-mini",
        transcriptionLanguage: nil,
        rawWordCount: DictationWordCounter.count(in: rawTranscript),
        finalWordCount: DictationWordCounter.count(in: finalDraft),
        finalDraftText: finalDraft,
        rawTranscriptText: nil
    )
}

func makeSecondArchiveEntry() -> DictationArchiveEntry {
    let rawTranscript = "Kannst du bitte testen"
    let finalDraft = "Kannst du bitte testen?"
    let startedAt = ISO8601DateFormatter().date(from: "2026-07-07T11:00:00Z")!

    return DictationArchiveEntry(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000102")!,
        startedAt: startedAt,
        completedAt: startedAt.addingTimeInterval(4),
        audioDurationSeconds: 4,
        activeAppName: "TextEdit",
        activeAppBundleIdentifier: "com.apple.TextEdit",
        cleanupEnabled: false,
        cleanupFallbackUsed: false,
        insertionOutcome: .copiedForManualPaste,
        transcriptionProviderLabel: "example / gpt-4o-transcribe",
        cleanupProviderLabel: nil,
        transcriptionLanguage: "de",
        rawWordCount: DictationWordCounter.count(in: rawTranscript),
        finalWordCount: DictationWordCounter.count(in: finalDraft),
        finalDraftText: finalDraft,
        rawTranscriptText: rawTranscript
    )
}
