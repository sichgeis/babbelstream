import BabbelStreamCore
import Foundation

struct SettingsDraft {
    var transcriptionBackend: TranscriptionBackend
    var localModel: LocalModelID
    var localCleanupEnabled: Bool
    var cleanupEnabled: Bool
    var personalOpenAIFallbackEnabled: Bool
    var personalOpenAIDirectModeEnabled: Bool
    var dictationArchiveEnabled: Bool
    var archiveRawTranscriptEnabled: Bool
    var baseURLText: String
    var transcriptionPathText: String
    var cleanupPathText: String
    var transcriptionModelText: String
    var transcriptionModelRouting: TranscriptionModelRouting
    var cleanupModelText: String
    var timeoutText: String
    var maxAudioDurationMinutesText: String
    var transcriptionLanguageText: String
    var transcriptionPromptText: String

    init(_ settings: AppSettings) {
        transcriptionBackend = settings.transcriptionBackend
        localModel = settings.localModel
        cleanupEnabled = settings.cleanupEnabled
        localCleanupEnabled = settings.localCleanupEnabled
        personalOpenAIFallbackEnabled = settings.personalOpenAIFallbackEnabled
        personalOpenAIDirectModeEnabled = settings.personalOpenAIDirectModeEnabled
        dictationArchiveEnabled = settings.dictationArchiveEnabled
        archiveRawTranscriptEnabled = settings.archiveRawTranscriptEnabled
        baseURLText = settings.providerConfiguration.baseURL.absoluteString
        transcriptionPathText = settings.providerConfiguration.transcriptionEndpointPath
        cleanupPathText = settings.providerConfiguration.cleanupEndpointPath
        transcriptionModelText = settings.providerConfiguration.transcriptionModel
        transcriptionModelRouting = settings.providerConfiguration.transcriptionModelRouting
        cleanupModelText = settings.providerConfiguration.cleanupModel
        timeoutText = String(Int(settings.providerConfiguration.timeoutSeconds))
        maxAudioDurationMinutesText = Self.durationMinutesText(for: settings.maxAudioDurationSeconds)
        transcriptionLanguageText = settings.transcriptionLanguage
        transcriptionPromptText = settings.transcriptionPrompt
    }

    func applying(to saved: AppSettings) throws -> AppSettings {
        var settings = saved
        guard let minutes = TimeInterval(maxAudioDurationMinutesText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw SettingsValidationError.invalidMaxAudioDuration
        }
        let language = transcriptionLanguageText.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.transcriptionBackend = transcriptionBackend
        settings.localModel = localModel
        settings.localCleanupEnabled = localCleanupEnabled
        settings.maxAudioDurationSeconds = minutes * 60
        settings.transcriptionLanguage = TranscriptionLanguageNormalizer.apiValue(from: language) ?? language
        settings.dictationArchiveEnabled = dictationArchiveEnabled
        settings.archiveRawTranscriptEnabled = dictationArchiveEnabled && archiveRawTranscriptEnabled

        if transcriptionBackend == .remote {
            guard let url = URL(string: baseURLText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                throw SettingsValidationError.invalidBaseURL
            }
            guard let timeout = TimeInterval(timeoutText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
                throw SettingsValidationError.invalidTimeout
            }
            settings.providerConfiguration = ProviderConfiguration(
                baseURL: url, transcriptionEndpointPath: transcriptionPathText, cleanupEndpointPath: cleanupPathText,
                transcriptionModel: transcriptionModelText, transcriptionModelRouting: transcriptionModelRouting,
                cleanupModel: cleanupModelText, timeoutSeconds: timeout)
            settings.personalOpenAIFallbackEnabled = personalOpenAIFallbackEnabled
            settings.personalOpenAIDirectModeEnabled = personalOpenAIFallbackEnabled && personalOpenAIDirectModeEnabled
            settings.cleanupEnabled = cleanupEnabled
            settings.transcriptionPrompt = transcriptionPromptText
            settings.transcriptionResponseFormat = ProjectDefaults.defaultTranscriptionResponseFormat
        }
        try AppSettingsValidator.validate(settings)
        return settings
    }

    static func durationMinutesText(for duration: TimeInterval) -> String {
        let minutes = duration / 60
        if minutes.rounded(.towardZero) == minutes {
            return "\(Int(minutes))"
        }

        return String(format: "%.1f", minutes)
    }
}
