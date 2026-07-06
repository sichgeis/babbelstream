import Foundation

public enum ProjectDefaults {
    public static let appName = "BabbelStream"
    public static let audioTempDirectoryName = "BabbelStream"
    public static let audioFileExtension = "m4a"
    public static let maxAudioDurationSeconds: TimeInterval = 600
    public static let minConfigurableAudioDurationSeconds: TimeInterval = 5
    public static let maxConfigurableAudioDurationSeconds: TimeInterval = 600
    public static let defaultTranscriptionModel = "gpt-4o-transcribe"
    public static let defaultCleanupModel = "gpt-4o-mini"
    public static let defaultTranscriptionResponseFormat = "json"
    public static let fixedHotkeyDescription = "Control + Option + Space"
    public static let cleanupEnabledByDefault = true
    public static let autoSendEnabledByDefault = false
    public static let transcriptHistoryEnabledByDefault = false
    public static let debugPersistenceEnabledByDefault = false
}

public struct ProviderConfiguration: Equatable, Sendable {
    public var baseURL: URL
    public var transcriptionEndpointPath: String
    public var cleanupEndpointPath: String
    public var transcriptionModel: String
    public var cleanupModel: String
    public var timeoutSeconds: TimeInterval
    public var retryCount: Int

    public init(
        baseURL: URL = URL(string: "https://litellm.example.local")!,
        transcriptionEndpointPath: String = "/v1/audio/transcriptions",
        cleanupEndpointPath: String = "/v1/chat/completions",
        transcriptionModel: String = ProjectDefaults.defaultTranscriptionModel,
        cleanupModel: String = ProjectDefaults.defaultCleanupModel,
        timeoutSeconds: TimeInterval = 30,
        retryCount: Int = 1
    ) {
        self.baseURL = baseURL
        self.transcriptionEndpointPath = transcriptionEndpointPath
        self.cleanupEndpointPath = cleanupEndpointPath
        self.transcriptionModel = transcriptionModel
        self.cleanupModel = cleanupModel
        self.timeoutSeconds = timeoutSeconds
        self.retryCount = retryCount
    }
}

public enum CleanupPrompt {
    public static let slackReady = """
    You clean up dictated Slack messages for a technical work context.

    Rules:
    - Preserve the speaker's meaning and tone.
    - Preserve the language of the transcript exactly: English stays English, German stays German, and mixed German-English stays mixed.
    - Do not translate English to German or German to English.
    - If a sentence, clause, or phrase is in English, keep it in English.
    - If a sentence, clause, or phrase is in German, keep it in German.
    - If unsure about a language choice, keep the original wording rather than translating.
    - Preserve technical terms, product names, personal names, acronyms, code symbols, URLs, file paths, repository names, and ticket IDs.
    - Remove filler words and obvious false starts.
    - Add punctuation and paragraph breaks only where they improve readability.
    - Do not add greetings, sign-offs, facts, promises, or corporate polish.
    - Return only the final message text.
    """
}
