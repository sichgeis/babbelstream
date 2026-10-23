import Foundation
import BabbelStreamCore
@testable import BabbelStreamApplication

@MainActor
func runConnectionSetupChecks() async throws {
    let wav = SyntheticConnectionAudio.wavData()
    check(wav.count == 8044 && String(decoding: wav.prefix(4), as: UTF8.self) == "RIFF", "Connection test must use the documented 250 ms PCM WAV.")
    check(wav.dropFirst(44).allSatisfy { $0 == 0 }, "Connection audio must contain synthetic silence only.")
    do {
        let f = try CoordinatorFixture(hasPrimaryKey: false, permissionsReady: false)
        defer { try? f.dispose() }
        check(f.app.needsConnectionSetup && f.app.connectionReadinessSummary == ConnectionVerificationState.incomplete.rawValue, "New users must see incomplete setup.")
        await f.app.testSavedConnection()
        check(f.transcription.requests.isEmpty && f.secret.reads == 0, "Incomplete setup must not submit a request or read a secret.")
        let original = f.settings.value
        let model = f.app.transcriptionModelText
        f.app.selectConnectionPreset(.officialOpenAI)
        check(f.app.baseURLText == "https://api.openai.com" && f.app.transcriptionModelText == model, "Explicit preset must stage only non-secret connection values.")
        check(f.settings.value == original && f.app.hasUnsavedSettingsChanges, "Preset must not silently apply.")
        check(!f.app.personalOpenAIFallbackEnabled, "Setup must not enable fallback for a new user.")
        f.app.selectConnectionPreset(.custom)
        check(f.app.baseURLText.contains("example.invalid"), "Custom preset must not invent a company endpoint.")
    }
    do {
        let f = try CoordinatorFixture()
        defer { try? f.dispose() }
        check(f.app.connectionVerification == .unverified && f.secret.reads == 0, "Saved presence must never imply tested credentials.")
        f.app.transcriptionPromptText = "private-fixture-hint-never-send-in-connection-test"
        f.app.transcriptionLanguageText = "de"
        await f.app.testSavedConnection()
        check(f.transcription.requests.isEmpty, "Edited unapplied settings must disable connection tests.")
        f.app.saveSettings()
        check(f.app.connectionTestDisclosure.contains("250 ms") && f.app.connectionTestDisclosure.contains("charge") && f.app.connectionTestDisclosure.contains("primary.example.invalid"), "Test disclosure must identify synthetic content, saved destination and possible cost.")
        f.transcription.action = { request in
            let bytes = try Data(contentsOf: request.audioURL)
            check(bytes == wav && request.retryCount == 0, "Test must send one bounded synthetic WAV request.")
            check(request.settings.transcriptionPrompt.isEmpty && request.settings.transcriptionLanguage.isEmpty, "Test must exclude user speech hints.")
            return "provider-output-is-discarded"
        }
        await f.app.testSavedConnection()
        check(f.app.connectionVerification == .verified && !f.app.isConnectionTesting, "Only a valid transcription response verifies the connection contract.")
        check(f.transcription.requests.count == 1 && f.mini.requests.isEmpty && f.cleanup.requests.isEmpty && f.personalSecret.reads == 0 && f.insertion.inserted.isEmpty, "Connection test must never hedge, cleanup, use fallback or deliver text.")
        check(!FileManager.default.fileExists(atPath: f.transcription.requests[0].audioURL.path), "Synthetic test audio must be removed at completion.")
        check(f.app.latestFinalDraftSummary == "None" && f.app.usageSnapshot.totalDictations == 0, "Test must not retain provider output as a draft or a dictation.")
        f.app.timeoutText = "35"
        f.app.saveSettings()
        check(f.app.connectionVerification == .unverified, "Apply must invalidate prior connection evidence.")
    }
    for failure in [URLError(.notConnectedToInternet) as Error, ProviderError.requestFailed(statusCode: 401, message: "private-provider-body") as Error, ProviderError.emptyTranscript as Error] {
        let f = try CoordinatorFixture()
        defer { try? f.dispose() }
        f.transcription.action = { _ in throw failure }
        await f.app.testSavedConnection()
        if failure is URLError {
            check(f.app.connectionVerification == .unavailable, "An outage must be distinct from incomplete or verified setup.")
        } else if case ProviderError.emptyTranscript = failure {
            check(f.app.connectionVerification == .verified && f.app.connectionTestFeedback.contains("empty text"), "Valid empty transcript is expected for silence and must be described honestly.")
        } else {
            check(f.app.connectionVerification == .unverified, "Authentication failures must not verify the connection.")
        }
        check(!f.app.connectionTestFeedback.contains("private-provider-body") && f.mini.requests.isEmpty && f.personalSecret.reads == 0, "Failure feedback must be content-free and never switch providers.")
    }
    do {
        let f = try CoordinatorFixture()
        defer { try? f.dispose() }
        f.transcription.action = { _ in
            try? await Task.sleep(nanoseconds: 500_000_000)
            return "late fixture"
        }
        let test = Task { await f.app.testSavedConnection() }
        for _ in 0..<100 where f.transcription.requests.isEmpty {
            try await Task.sleep(nanoseconds: 1_000_000)
        }
        check(f.app.isConnectionTesting && !f.app.canStart, "An explicit test must own its operation until completion/cancellation.")
        f.app.timeoutText = "35"
        f.app.saveSettings() // Invalidates generation and cancels even a provider that ignores cancellation.
        await test.value
        check(f.app.connectionVerification == .unverified && !f.app.isConnectionTesting, "Stale completion after Apply must never mark changed settings verified.")
        check(!FileManager.default.fileExists(atPath: f.transcription.requests[0].audioURL.path), "Canceled test must remove synthetic audio.")
    }
}
