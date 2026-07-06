import BabbelStreamCore

// This target intentionally avoids XCTest/Testing imports because the current
// CLT-only environment does not expose either module to SwiftPM. Run
// `swift run BabbelStreamChecks` for executable scaffold checks.
struct ProjectDefaultsTests {
    func mvpDefaultsFavorReviewAndPrivacy() {
        precondition(ProjectDefaults.cleanupEnabledByDefault)
        precondition(!ProjectDefaults.autoSendEnabledByDefault)
        precondition(!ProjectDefaults.transcriptHistoryEnabledByDefault)
        precondition(!ProjectDefaults.debugPersistenceEnabledByDefault)
    }

    func defaultProviderShapeIsOpenAICompatible() {
        let configuration = ProviderConfiguration()

        precondition(configuration.transcriptionEndpointPath == "/v1/audio/transcriptions")
        precondition(configuration.cleanupEndpointPath == "/v1/chat/completions")
        precondition(configuration.retryCount == 1)
    }

    func cleanupPromptProtectsTechnicalMixedLanguageDictation() {
        let prompt = CleanupPrompt.slackReady

        precondition(prompt.contains("German-English"))
        precondition(prompt.contains("ticket IDs"))
        precondition(prompt.contains("Return only the final message text"))
    }
}
