import BabbelStreamCore

func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fatalError(message)
    }
}

let configuration = ProviderConfiguration()

check(ProjectDefaults.cleanupEnabledByDefault, "Cleanup should be enabled by default.")
check(!ProjectDefaults.autoSendEnabledByDefault, "MVP must not auto-send messages.")
check(!ProjectDefaults.transcriptHistoryEnabledByDefault, "MVP must not persist transcript history.")
check(!ProjectDefaults.debugPersistenceEnabledByDefault, "Debug persistence must be opt-in.")
check(configuration.transcriptionEndpointPath == "/v1/audio/transcriptions", "Unexpected transcription endpoint default.")
check(configuration.cleanupEndpointPath == "/v1/chat/completions", "Unexpected cleanup endpoint default.")
check(CleanupPrompt.slackReady.contains("German-English"), "Cleanup prompt must protect mixed-language dictation.")
check(CleanupPrompt.slackReady.contains("ticket IDs"), "Cleanup prompt must protect ticket IDs.")

print("BabbelStream scaffold checks passed.")
