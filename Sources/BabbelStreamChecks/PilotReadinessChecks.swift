import Foundation
import BabbelStreamCore
@testable import BabbelStreamApplication

@MainActor
func runPilotReadinessChecks() async throws {
    let approved = URL(string: "https://primary.example.invalid/v1/audio/transcriptions")!
    for target in ["https://PRIMARY.example.invalid/other", "https://primary.example.invalid:443/v1"] {
        check(ProviderOrigin.permitsRedirect(from: approved, to: URL(string: target)), "Same origin must normalize host and default port.")
    }
    for target in ["http://primary.example.invalid/v1", "https://other.example.invalid/v1", "https://primary.example.invalid:444/v1", "https://user@primary.example.invalid/v1", "file:///tmp/fixture"] {
        check(!ProviderOrigin.permitsRedirect(from: approved, to: URL(string: target)), "Unapproved origins and transport downgrade must be rejected.")
    }
    check(!ProviderOrigin.permitsRedirect(from: nil, to: approved), "Missing original URL must fail closed.")

    for (body, mime) in [
        ("<html>upstream error</html>", "text/html"),
        ("<!DOCTYPE html>error", "text/plain"),
        ("{\"text\": broken", "application/json"),
        ("{\"text\": broken", "text/plain"),
        ("[]", "application/json"),
        ("\"scalar\"", "application/json"),
        ("not json", "application/json"),
        ("untyped text", ""),
        ("<html>error", "")
    ] {
        do {
            _ = try TranscriptionResponseParser.parse(data: Data(body.utf8), contentType: mime.isEmpty ? nil : mime)
            fatalError("Unsupported transcript response must fail closed.")
        } catch ProviderError.malformedResponse {}
    }
    let plain = try TranscriptionResponseParser.parse(data: Data("Hallo mixed English".utf8), contentType: "text/plain; charset=utf-8")
    check(plain == "Hallo mixed English", "Explicit plain text remains supported.")
    let json = try TranscriptionResponseParser.parse(data: Data(#"{"text":"valid"}"#.utf8), contentType: "application/json")
    check(json == "valid", "JSON transcript contract remains supported.")

    let receiver = try LoopbackHTTPFixture { _ in
        (200, ["Content-Type": "application/json"], Data(#"{"text":"redirected fixture"}"#.utf8))
    }
    defer { receiver.stop() }
    let receiverURL = receiver.baseURL.absoluteString
    let redirector = try LoopbackHTTPFixture { _ in
        (307, ["Location": receiverURL + "/unapproved"], Data())
    }
    defer { redirector.stop() }
    let audioRoot = FileManager.default.temporaryDirectory.appendingPathComponent("BabbelStreamRedirectChecks-\(UUID())")
    try FileManager.default.createDirectory(at: audioRoot, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: audioRoot) }
    let audioURL = audioRoot.appendingPathComponent("synthetic.wav")
    try Data("synthetic-audio-not-a-recording".utf8).write(to: audioURL)
    var redirectSettings = AppSettings()
    redirectSettings.providerConfiguration.baseURL = redirector.baseURL
    let session = URLSession(configuration: .ephemeral)
    defer { session.invalidateAndCancel() }
    do {
        _ = try await OpenAICompatibleTranscriptionProvider(urlSession: session).transcribe(TranscriptionRequest(audioURL: audioURL, settings: redirectSettings, apiKey: "fixture-not-a-real-key"))
        fatalError("Cross-origin audio redirect must fail.")
    } catch ProviderError.requestFailed(statusCode: 307, message: _) {}
    do {
        _ = try await OpenAICompatibleCleanupProvider(urlSession: session).cleanup(CleanupRequest(transcript: "synthetic fixture", settings: redirectSettings, apiKey: "fixture-not-a-real-key"))
        fatalError("Cross-origin cleanup redirect must fail.")
    } catch ProviderError.requestFailed(statusCode: 307, message: _) {}
    check(redirector.count == 2 && receiver.count == 0, "Actual transport must never deliver audio/text to an unapproved redirect origin.")

    let sameOrigin = try LoopbackHTTPFixture { request in
        if String(decoding: request.prefix(100), as: UTF8.self).contains(" /completed ") {
            return (200, ["Content-Type": "application/json"], Data(#"{"text":"same origin fixture"}"#.utf8))
        }
        return (307, ["Location": "/completed"], Data())
    }
    defer { sameOrigin.stop() }
    redirectSettings.providerConfiguration.baseURL = sameOrigin.baseURL
    let sameOriginResult = try await OpenAICompatibleTranscriptionProvider(urlSession: session).transcribe(TranscriptionRequest(audioURL: audioURL, settings: redirectSettings, apiKey: "fixture-not-a-real-key"))
    check(sameOriginResult == "same origin fixture" && sameOrigin.count == 2, "Real transport must preserve supported same-origin redirects.")

    var visibility = DictationHUDVisibilityPolicy()
    check(visibility.update(isActive: false, needsAttention: false) == .hide, "Startup must not show a completion.")
    check(visibility.update(isActive: true, needsAttention: false) == .showActive, "Active operation must show HUD.")
    check(visibility.update(isActive: false, needsAttention: false) == .beginCompletion(seconds: 1.5), "Completion owns one timer.")
    for _ in 0..<5 {
        check(visibility.update(isActive: false, needsAttention: false) == .keepCompletion, "Repeated completion notifications must not cancel or restart dismissal.")
    }
    check(visibility.update(isActive: false, needsAttention: true) == .beginCompletion(seconds: 6), "Late recovery warning may extend completion once.")
    check(visibility.update(isActive: false, needsAttention: true) == .keepCompletion, "Repeated warning must retain the original extended deadline.")
    visibility.completionExpired()
    check(visibility.update(isActive: false, needsAttention: true) == .hide, "Expired feedback must not be resurrected by idle updates.")
    check(visibility.update(isActive: true, needsAttention: false) == .showActive, "Next operation must replace completion.")

    let lockRoot = FileManager.default.temporaryDirectory.appendingPathComponent("BabbelStreamInstanceChecks-\(UUID())")
    defer { try? FileManager.default.removeItem(at: lockRoot) }
    var instance: SingleInstanceLock? = try SingleInstanceLock(directory: lockRoot)
    do {
        _ = try SingleInstanceLock(directory: lockRoot)
        fatalError("A second instance must not acquire the shared user lock.")
    } catch SingleInstanceError.alreadyRunning {}
    withExtendedLifetime(instance) {}
    instance = nil
    let replacement = try SingleInstanceLock(directory: lockRoot)
    withExtendedLifetime(replacement) {}

    do {
        let f = try CoordinatorFixture()
        defer { try? f.dispose() }
        check(f.secret.reads == 0, "Origin migration must not read legacy secrets at startup.")
        let originalOrigin = f.keyPresence.approvedOrigin
        f.app.baseURLText = "https://changed.example.invalid"
        f.app.saveSettings()
        check(f.app.settingsErrorMessage != nil, "Host changes must require explicit key replacement or reassociation.")
        check(f.settings.value.providerConfiguration.baseURL.host == "primary.example.invalid" && f.keyPresence.approvedOrigin == originalOrigin, "Rejected Apply must preserve saved configuration and credential binding.")
        f.app.apiKeyInput = "explicit-new-fixture-key"
        f.app.saveSettings()
        check(f.app.settingsErrorMessage == nil, "Explicit per-origin key approval should apply.")
        await f.app.startDictation()
        await f.app.stopActiveRecording()
        check(f.transcription.requests.first?.apiKey == "explicit-new-fixture-key", "New origin must receive only the explicitly supplied replacement key.")
    }
    do {
        let f = try CoordinatorFixture()
        defer { try? f.dispose() }
        f.settings.failSave = true
        f.app.baseURLText = "https://changed.example.invalid"
        f.app.apiKeyInput = "explicit-new-fixture-key"
        f.app.saveSettings()
        check(f.app.settingsErrorMessage != nil, "Settings persistence failure must be visible.")
        await f.app.startDictation()
        await f.app.stopActiveRecording()
        check(f.secret.reads == 0 && f.transcription.requests.isEmpty, "A partial key/settings update must not send the new key to the old destination.")
        check(!f.app.recoverySnapshot.recordings.isEmpty, "Credential boundary failures must retain stopped audio.")
    }
    do {
        let f = try CoordinatorFixture()
        defer { try? f.dispose() }
        f.app.status = "/Users/private-user/transcript-content"
        f.app.lastFailureCategory = "/Users/private-user/provider-body"
        f.app.cleanupModelText = "/Users/private-user/secret-model"
        f.app.saveSettings()
        let report = f.app.diagnosticsReport()
        check(!report.contains(f.root.path) && !report.contains("/Users/") && !report.contains("provider-body"), "Export allowlist must omit private paths and arbitrary errors/status.")
        check(!report.contains("synthetic-key") && report.contains("build commit:") && report.contains("primary origin:"), "Export must retain actionable content-free build/provider fields.")
    }
}
