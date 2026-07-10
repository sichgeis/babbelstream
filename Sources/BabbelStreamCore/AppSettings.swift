import Foundation

public struct AppSettings: Equatable, Sendable {
    public var providerConfiguration: ProviderConfiguration
    public var cleanupEnabled: Bool
    public var transcriptionResponseFormat: String
    public var transcriptionLanguage: String
    public var transcriptionPrompt: String
    public var maxAudioDurationSeconds: TimeInterval
    public var dictationArchiveEnabled: Bool
    public var archiveRawTranscriptEnabled: Bool

    public init(
        providerConfiguration: ProviderConfiguration = ProviderConfiguration(),
        cleanupEnabled: Bool = ProjectDefaults.cleanupEnabledByDefault,
        transcriptionResponseFormat: String = ProjectDefaults.defaultTranscriptionResponseFormat,
        transcriptionLanguage: String = "",
        transcriptionPrompt: String = "",
        maxAudioDurationSeconds: TimeInterval = ProjectDefaults.maxAudioDurationSeconds,
        dictationArchiveEnabled: Bool = ProjectDefaults.dictationArchiveEnabledByDefault,
        archiveRawTranscriptEnabled: Bool = ProjectDefaults.archiveRawTranscriptEnabledByDefault
    ) {
        self.providerConfiguration = providerConfiguration
        self.cleanupEnabled = cleanupEnabled
        self.transcriptionResponseFormat = transcriptionResponseFormat
        self.transcriptionLanguage = transcriptionLanguage
        self.transcriptionPrompt = transcriptionPrompt
        self.maxAudioDurationSeconds = maxAudioDurationSeconds
        self.dictationArchiveEnabled = dictationArchiveEnabled
        self.archiveRawTranscriptEnabled = dictationArchiveEnabled && archiveRawTranscriptEnabled
    }
}

public enum SettingsValidationError: Error, Equatable, LocalizedError, Sendable {
    case invalidBaseURL
    case insecureBaseURL
    case ambiguousBaseURL
    case missingTranscriptionModel
    case missingCleanupModel
    case missingTranscriptionPath
    case missingCleanupPath
    case invalidEndpointPath
    case invalidTranscriptionLanguage
    case invalidTimeout
    case invalidMaxAudioDuration

    public var errorDescription: String? {
        switch self {
        case .invalidBaseURL:
            "Provider base URL must include a valid http or https host."
        case .insecureBaseURL:
            "Provider base URL must use https. Plain http is allowed only for local development endpoints."
        case .ambiguousBaseURL:
            "Provider base URL must not contain credentials, a query, or a fragment. Store credentials in Keychain and configure endpoint paths separately."
        case .missingTranscriptionModel:
            "Transcription model is required."
        case .missingCleanupModel:
            "Cleanup model is required."
        case .missingTranscriptionPath:
            "Transcription endpoint path is required."
        case .missingCleanupPath:
            "Cleanup endpoint path is required."
        case .invalidEndpointPath:
            "Provider endpoint paths must start with / and produce valid URLs."
        case .invalidTranscriptionLanguage:
            "Transcription language must be a single ISO 639-1 code like de or en. Leave it empty for mixed German-English dictation and put free-form hints in the prompt."
        case .invalidTimeout:
            "Timeout must be at least 1 second."
        case .invalidMaxAudioDuration:
            "Max recording duration must be between 5 seconds and 10 minutes."
        }
    }
}

public enum AppSettingsValidator {
    public static func validate(_ settings: AppSettings) throws {
        let configuration = settings.providerConfiguration
        let scheme = configuration.baseURL.scheme?.lowercased()

        guard (scheme == "https" || scheme == "http"), configuration.baseURL.host?.isEmpty == false else {
            throw SettingsValidationError.invalidBaseURL
        }
        guard configuration.baseURL.user == nil,
              configuration.baseURL.password == nil,
              configuration.baseURL.query == nil,
              configuration.baseURL.fragment == nil
        else {
            throw SettingsValidationError.ambiguousBaseURL
        }
        if scheme == "http", !ProviderTransportPolicy.isLoopback(configuration.baseURL) {
            throw SettingsValidationError.insecureBaseURL
        }
        guard !configuration.transcriptionModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SettingsValidationError.missingTranscriptionModel
        }
        guard !configuration.cleanupModel.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SettingsValidationError.missingCleanupModel
        }
        guard !configuration.transcriptionEndpointPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SettingsValidationError.missingTranscriptionPath
        }
        guard !configuration.cleanupEndpointPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SettingsValidationError.missingCleanupPath
        }
        guard configuration.transcriptionEndpointPath.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("/"),
              configuration.cleanupEndpointPath.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("/"),
              ProviderEndpointBuilder.endpointURL(
                baseURL: configuration.baseURL,
                path: configuration.transcriptionEndpointPath
              ) != nil,
              ProviderEndpointBuilder.endpointURL(
                baseURL: configuration.baseURL,
                path: configuration.cleanupEndpointPath
              ) != nil
        else {
            throw SettingsValidationError.invalidEndpointPath
        }
        guard TranscriptionLanguageNormalizer.isValidForSettings(settings.transcriptionLanguage) else {
            throw SettingsValidationError.invalidTranscriptionLanguage
        }
        guard configuration.timeoutSeconds >= 1 else {
            throw SettingsValidationError.invalidTimeout
        }
        guard settings.maxAudioDurationSeconds >= ProjectDefaults.minConfigurableAudioDurationSeconds,
              settings.maxAudioDurationSeconds <= ProjectDefaults.maxConfigurableAudioDurationSeconds
        else {
            throw SettingsValidationError.invalidMaxAudioDuration
        }
    }
}

public enum ProviderTransportPolicy {
    public static func isLoopback(_ url: URL) -> Bool {
        guard var host = url.host?.lowercased(), !host.isEmpty else {
            return false
        }

        if host.hasPrefix("["), host.hasSuffix("]") {
            host.removeFirst()
            host.removeLast()
        }

        return host == "localhost"
            || host.hasSuffix(".localhost")
            || host == "127.0.0.1"
            || host == "::1"
    }
}

public enum TranscriptionLanguageNormalizer {
    private static let aliases = [
        "deutsch": "de",
        "german": "de",
        "englisch": "en",
        "english": "en"
    ]

    public static func apiValue(from value: String) -> String? {
        let normalized = value
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
        guard !normalized.isEmpty else {
            return nil
        }

        let languageCode = aliases[normalized] ?? normalized
        guard languageCode.range(of: #"^[a-z]{2}$"#, options: .regularExpression) != nil else {
            return nil
        }

        return languageCode
    }

    public static func isValidForSettings(_ value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty || apiValue(from: trimmed) != nil
    }
}

public protocol SettingsStore: AnyObject {
    func load() -> AppSettings
    func save(_ settings: AppSettings) throws
}

public final class UserDefaultsSettingsStore: SettingsStore {
    private enum Key {
        static let baseURL = "provider.baseURL"
        static let transcriptionEndpointPath = "provider.transcriptionEndpointPath"
        static let cleanupEndpointPath = "provider.cleanupEndpointPath"
        static let transcriptionModel = "provider.transcriptionModel"
        static let cleanupModel = "provider.cleanupModel"
        static let timeoutSeconds = "provider.timeoutSeconds"
        static let retryCount = "provider.retryCount"
        static let cleanupEnabled = "cleanup.enabled"
        static let transcriptionResponseFormat = "transcription.responseFormat"
        static let transcriptionLanguage = "transcription.language"
        static let transcriptionPrompt = "transcription.prompt"
        static let maxAudioDurationSeconds = "recording.maxAudioDurationSeconds"
        static let dictationArchiveEnabled = "dictationArchive.enabled"
        static let archiveRawTranscriptEnabled = "dictationArchive.rawTranscriptEnabled"
    }

    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    public func load() -> AppSettings {
        let defaults = AppSettings()
        let defaultConfiguration = defaults.providerConfiguration
        let baseURLString = userDefaults.string(forKey: Key.baseURL)
            ?? defaultConfiguration.baseURL.absoluteString
        let baseURL = URL(string: baseURLString) ?? defaultConfiguration.baseURL

        let timeout = userDefaults.object(forKey: Key.timeoutSeconds) as? Double
            ?? defaultConfiguration.timeoutSeconds
        let retryCount = userDefaults.object(forKey: Key.retryCount) as? Int
            ?? defaultConfiguration.retryCount

        let configuration = ProviderConfiguration(
            baseURL: baseURL,
            transcriptionEndpointPath: userDefaults.string(forKey: Key.transcriptionEndpointPath)
                ?? defaultConfiguration.transcriptionEndpointPath,
            cleanupEndpointPath: userDefaults.string(forKey: Key.cleanupEndpointPath)
                ?? defaultConfiguration.cleanupEndpointPath,
            transcriptionModel: userDefaults.string(forKey: Key.transcriptionModel)
                ?? defaultConfiguration.transcriptionModel,
            cleanupModel: userDefaults.string(forKey: Key.cleanupModel)
                ?? defaultConfiguration.cleanupModel,
            timeoutSeconds: timeout,
            retryCount: retryCount
        )

        let dictationArchiveEnabled = userDefaults.object(forKey: Key.dictationArchiveEnabled) as? Bool
            ?? defaults.dictationArchiveEnabled
        let archiveRawTranscriptEnabled = dictationArchiveEnabled
            && (userDefaults.object(forKey: Key.archiveRawTranscriptEnabled) as? Bool
                ?? defaults.archiveRawTranscriptEnabled)

        return AppSettings(
            providerConfiguration: configuration,
            cleanupEnabled: userDefaults.object(forKey: Key.cleanupEnabled) as? Bool
                ?? defaults.cleanupEnabled,
            transcriptionResponseFormat: userDefaults.string(forKey: Key.transcriptionResponseFormat)
                ?? defaults.transcriptionResponseFormat,
            transcriptionLanguage: userDefaults.string(forKey: Key.transcriptionLanguage)
                ?? defaults.transcriptionLanguage,
            transcriptionPrompt: userDefaults.string(forKey: Key.transcriptionPrompt)
                ?? defaults.transcriptionPrompt,
            maxAudioDurationSeconds: userDefaults.object(forKey: Key.maxAudioDurationSeconds) as? Double
                ?? defaults.maxAudioDurationSeconds,
            dictationArchiveEnabled: dictationArchiveEnabled,
            archiveRawTranscriptEnabled: archiveRawTranscriptEnabled
        )
    }

    public func save(_ settings: AppSettings) throws {
        try AppSettingsValidator.validate(settings)

        let configuration = settings.providerConfiguration
        userDefaults.set(configuration.baseURL.absoluteString, forKey: Key.baseURL)
        userDefaults.set(configuration.transcriptionEndpointPath, forKey: Key.transcriptionEndpointPath)
        userDefaults.set(configuration.cleanupEndpointPath, forKey: Key.cleanupEndpointPath)
        userDefaults.set(configuration.transcriptionModel, forKey: Key.transcriptionModel)
        userDefaults.set(configuration.cleanupModel, forKey: Key.cleanupModel)
        userDefaults.set(configuration.timeoutSeconds, forKey: Key.timeoutSeconds)
        userDefaults.set(configuration.retryCount, forKey: Key.retryCount)
        userDefaults.set(settings.cleanupEnabled, forKey: Key.cleanupEnabled)
        userDefaults.set(settings.transcriptionResponseFormat, forKey: Key.transcriptionResponseFormat)
        userDefaults.set(settings.transcriptionLanguage, forKey: Key.transcriptionLanguage)
        userDefaults.set(settings.transcriptionPrompt, forKey: Key.transcriptionPrompt)
        userDefaults.set(settings.maxAudioDurationSeconds, forKey: Key.maxAudioDurationSeconds)
        userDefaults.set(settings.dictationArchiveEnabled, forKey: Key.dictationArchiveEnabled)
        userDefaults.set(settings.archiveRawTranscriptEnabled, forKey: Key.archiveRawTranscriptEnabled)
    }
}
