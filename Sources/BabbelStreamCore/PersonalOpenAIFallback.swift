import Foundation

public enum PersonalOpenAIFallbackPolicy {
    public static let displayName = "Personal OpenAI"

    public static func shouldUsePersonalOpenAIDirectly(_ settings: AppSettings) -> Bool {
        settings.transcriptionBackend == .remote && settings.personalOpenAIFallbackEnabled && settings.personalOpenAIDirectModeEnabled
    }

    public static func settings(derivedFrom primary: AppSettings) -> AppSettings {
        var fallback = primary
        let officialDefaults = ProviderConfiguration()
        fallback.providerConfiguration.baseURL = ProjectDefaults.personalOpenAIFallbackBaseURL
        fallback.providerConfiguration.transcriptionEndpointPath = officialDefaults.transcriptionEndpointPath
        fallback.providerConfiguration.cleanupEndpointPath = officialDefaults.cleanupEndpointPath
        fallback.providerConfiguration.transcriptionModelRouting = .standardOpenAI
        fallback.providerConfiguration.cleanupModel = ProjectDefaults.defaultCleanupModel
        return fallback
    }

    public static func shouldFallback(after error: Error) -> Bool {
        if case let HedgedTranscriptionError.attemptsFailed(primary, mini) = error {
            return isReachabilityFailure(primary) && isReachabilityFailure(mini)
        }
        return isReachabilityFailure(.classify(error))
    }

    private static func isReachabilityFailure(_ category: ProviderFailureCategory) -> Bool {
        switch category {
        case .connectionTimeout:
            return true
        case let .httpStatus(status):
            return [502, 503, 504].contains(status)
        case let .urlError(code):
            let eligible: [URLError.Code] = [.timedOut, .cannotFindHost, .cannotConnectToHost,
                .networkConnectionLost, .dnsLookupFailed, .notConnectedToInternet, .resourceUnavailable]
            return eligible.contains { $0.rawValue == code }
        default:
            return false
        }
    }
}
