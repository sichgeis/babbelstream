import Foundation

public enum PersonalOpenAIFallbackPolicy {
    public static let displayName = "Personal OpenAI"

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
        if case ProviderError.connectionTimedOut = error {
            return true
        }
        if case let ProviderError.requestFailed(statusCode, _) = error {
            return [502, 503, 504].contains(statusCode)
        }

        guard let urlError = error as? URLError else {
            return false
        }

        return [
            .timedOut,
            .cannotFindHost,
            .cannotConnectToHost,
            .networkConnectionLost,
            .dnsLookupFailed,
            .notConnectedToInternet,
            .resourceUnavailable
        ].contains(urlError.code)
    }
}
