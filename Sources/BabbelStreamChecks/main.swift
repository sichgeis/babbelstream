import BabbelStreamCore
import Foundation

func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fatalError(message)
    }
}

let configuration = ProviderConfiguration()
let tempDirectory = AudioTempFileStore.temporaryDirectory()
let deterministicAudioURL = try AudioTempFileStore.makeTemporaryAudioURL(
    id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
)

check(ProjectDefaults.cleanupEnabledByDefault, "Cleanup should be enabled by default.")
check(!ProjectDefaults.autoSendEnabledByDefault, "MVP must not auto-send messages.")
check(!ProjectDefaults.transcriptHistoryEnabledByDefault, "MVP must not persist transcript history.")
check(!ProjectDefaults.debugPersistenceEnabledByDefault, "Debug persistence must be opt-in.")
check(ProjectDefaults.maxAudioDurationSeconds == 600, "Max recording duration should be 10 minutes.")
check(ProjectDefaults.audioFileExtension == "m4a", "MS1 should record m4a files.")
check(ProjectDefaults.defaultTranscriptionModel == "gpt-4o-transcribe", "Unexpected default STT model.")
check(ProjectDefaults.defaultCleanupModel == "gpt-4o-mini", "Unexpected default cleanup model.")
check(ProjectDefaults.minConfigurableAudioDurationSeconds == 5, "Unexpected minimum recording duration.")
check(ProjectDefaults.maxConfigurableAudioDurationSeconds == 600, "Unexpected maximum configurable recording duration.")
check(ProjectDefaults.defaultTranscriptionResponseFormat == "json", "Transcription should default to JSON responses.")
check(configuration.transcriptionEndpointPath == "/v1/audio/transcriptions", "Unexpected transcription endpoint default.")
check(configuration.cleanupEndpointPath == "/v1/chat/completions", "Unexpected cleanup endpoint default.")
check(configuration.transcriptionModel == ProjectDefaults.defaultTranscriptionModel, "Provider configuration should use the default STT model.")
check(configuration.cleanupModel == ProjectDefaults.defaultCleanupModel, "Provider configuration should use the default cleanup model.")
check(CleanupPrompt.slackReady.contains("German-English"), "Cleanup prompt must protect mixed-language dictation.")
check(CleanupPrompt.slackReady.contains("English stays English"), "Cleanup prompt must prevent English-to-German translation.")
check(CleanupPrompt.slackReady.contains("German stays German"), "Cleanup prompt must prevent German-to-English translation.")
check(CleanupPrompt.slackReady.contains("Do not translate"), "Cleanup prompt must explicitly forbid translation.")
check(CleanupPrompt.slackReady.contains("ticket IDs"), "Cleanup prompt must protect ticket IDs.")
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
let launchAgentPlist = LaunchAtLoginService.launchAgentPropertyList(
    appURL: URL(fileURLWithPath: "/Applications/BabbelStream.app")
)
check(
    launchAgentPlist["Label"] as? String == LaunchAtLoginService.defaultLabel,
    "Launch-at-login should use the stable BabbelStream LaunchAgent label."
)
check(
    launchAgentPlist["RunAtLoad"] as? Bool == true,
    "Launch-at-login should run BabbelStream at user login."
)
check(
    launchAgentPlist["ProgramArguments"] as? [String] == [
        "/usr/bin/open",
        "/Applications/BabbelStream.app"
    ],
    "Launch-at-login should open the configured app bundle path."
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

print("BabbelStream scaffold checks passed.")
