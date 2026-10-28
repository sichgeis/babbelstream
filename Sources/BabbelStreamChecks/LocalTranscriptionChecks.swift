import Foundation
import CryptoKit
import BabbelStreamCore
@testable import BabbelStreamApplication

struct FixtureModelDownloader: LocalModelDownloading {
    var corrupt = false
    var delay = false
    func download(_ url: URL, to destination: URL, expectedBytes: Int64,
                  progress: @escaping @Sendable (Int64) -> Void) async throws {
        if delay { try await Task.sleep(nanoseconds: 30_000_000_000) }
        try Data((corrupt ? "wrong-fixture" : "model-fixture").utf8).write(to: destination)
        progress(expectedBytes)
    }
}

@MainActor
final class FixtureLocalSpeechRuntime: LocalSpeechRuntime {
    nonisolated let supportedModels: Set<LocalModelID> = [.parakeetUltra]
    var calls = 0
    var fail = false
    var action: (() async throws -> String)?
    func prepare(model: LocalModelID, directory: URL) async throws {}
    func transcribe(model: LocalModelID, directory: URL, audio: URL, language: String) async throws -> String {
        calls += 1
        if fail { throw LocalModelError.inferenceFailed }
        if let action { return try await action() }
        return "Hallo local fixture"
    }
}

func fixtureModelManifest() -> LocalModelManifest {
    let data = Data("model-fixture".utf8)
    let hash = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    return LocalModelManifest(id: .parakeetUltra, repository: "example/synthetic-model",
        revision: String(repeating: "a", count: 40),
        files: [LocalModelFile(path: "weights.bin", bytes: Int64(data.count), sha256: hash)])
}

private func localCheck(_ condition: Bool, _ message: String) { check(condition, message) }

@MainActor
func runLocalTranscriptionChecks() async throws {
    localCheck(LocalModelCatalog.manifests.count == 3, "Ship exactly three pinned model manifests.")
    for manifest in LocalModelCatalog.manifests { try manifest.validate() }
    localCheck(LocalModelDownloadPolicy.permits(URL(string: "https://cdn.example.com/file?signature=fixture")!), "HTTPS CDN URLs are allowed without credentials.")
    for value in ["http://cdn.example.com/file", "https://user:password@cdn.example.com/file", "file:///tmp/model"] {
        localCheck(!LocalModelDownloadPolicy.permits(URL(string: value)!), "Insecure or credential-bearing model downloads are rejected.")
    }
    let processRoot = FileManager.default.temporaryDirectory.appendingPathComponent("LocalProcessChecks-\(UUID())")
    try FileManager.default.createDirectory(at: processRoot, withIntermediateDirectories: true)
    defer { try? FileManager.default.removeItem(at: processRoot) }
    let helper = processRoot.appendingPathComponent("synthetic-helper")
    try Data("#!/bin/sh\nexit 1\n".utf8).write(to: helper)
    try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: helper.path)
    let fixtureRuntime = BundledLocalSpeechRuntime(executable: helper, supportedModels: [.parakeetUltra])
    do { try await fixtureRuntime.prepare(model: .parakeetUltra, directory: processRoot); fatalError("Early helper exit accepted.") }
    catch LocalModelError.inferenceFailed {}
    try Data("#!/bin/sh\nexec /bin/sleep 30\n".utf8).write(to: helper)
    let process = Task { try await fixtureRuntime.prepare(model: .parakeetUltra, directory: processRoot) }
    try await Task.sleep(nanoseconds: 100_000_000)
    let cancelStarted = Date()
    process.cancel()
    do { try await process.value; fatalError("Native process cancellation must throw.") } catch is CancellationError {}
    localCheck(Date().timeIntervalSince(cancelStarted) < 3, "Cancellation must reap the native helper promptly.")
    let model = fixtureModelManifest()
    let root = FileManager.default.temporaryDirectory.appendingPathComponent("LocalModelChecks-\(UUID())")
    defer { try? FileManager.default.removeItem(at: root) }
    let store = LocalModelStore(root: root, downloader: FixtureModelDownloader())
    localCheck(!(await store.isInstalled(model)), "Absent model is not ready.")
    try await store.install(model, progress: { _ in }, prepare: { _ in })
    localCheck(await store.isInstalled(model), "A verified prepared model is activated.")
    let directory = await store.directory(model)
    try await store.verify(model, at: directory)
    // Same-length corruption defeats a mere existence/size readiness check.
    try Data("model-fixturX".utf8).write(to: directory.appendingPathComponent("weights.bin"))
    do { try await store.verify(model, at: directory); fatalError("Corrupt model must fail before native execution.") }
    catch LocalModelError.integrityFailed {}
    try FileManager.default.removeItem(at: directory.appendingPathComponent("weights.bin"))
    let other = root.appendingPathComponent("fixture-outside-model")
    try Data("model-fixture".utf8).write(to: other)
    try FileManager.default.createSymbolicLink(at: directory.appendingPathComponent("weights.bin"), withDestinationURL: other)
    do { try await store.verify(model, at: directory); fatalError("Symlinked model file accepted.") }
    catch LocalModelError.integrityFailed {}
    try await store.remove(model)
    localCheck(FileManager.default.fileExists(atPath: other.path), "Removal never follows a model symlink into another file.")
    try FileManager.default.removeItem(at: other)
    localCheck(!(await store.isInstalled(model)), "Removal invalidates readiness.")
    let corrupt = LocalModelStore(root: root, downloader: FixtureModelDownloader(corrupt: true))
    do { try await corrupt.install(model, progress: { _ in }, prepare: { _ in }); fatalError("Corrupt download activated.") }
    catch LocalModelError.integrityFailed {}
    localCheck(try FileManager.default.contentsOfDirectory(atPath: root.path).isEmpty, "Failure removes staging data.")
    do {
        let bad = LocalModelManifest(id: .parakeetUltra, repository: model.repository, revision: model.revision,
            files: [LocalModelFile(path: "../escape", bytes: 1, sha256: String(repeating: "a", count: 64))])
        try bad.validate(); fatalError("Path traversal accepted.")
    } catch LocalModelError.invalidManifest {}
    let slow = LocalModelStore(root: root, downloader: FixtureModelDownloader(delay: true))
    let download = Task { try await slow.install(model, progress: { _ in }, prepare: { _ in }) }
    for _ in 0..<100 {
        if (try? FileManager.default.contentsOfDirectory(atPath: root.path).isEmpty) == false { break }
        await Task.yield()
    }
    download.cancel()
    do { try await download.value; fatalError("Canceled download must throw.") } catch is CancellationError {}
    localCheck(!(await slow.isInstalled(model)), "Canceled download cannot become ready.")

    let domain = "LocalSettingsChecks-\(UUID())"
    let defaults = UserDefaults(suiteName: domain)!
    defer { defaults.removePersistentDomain(forName: domain) }
    let settingsStore = UserDefaultsSettingsStore(userDefaults: defaults)
    localCheck(settingsStore.load().transcriptionBackend == .remote, "Existing installs stay remote.")
    var settings = settingsStore.load()
    settings.transcriptionBackend = .local
    settings.personalOpenAIFallbackEnabled = true
    settings.personalOpenAIDirectModeEnabled = true
    try settingsStore.save(settings)
    localCheck(settingsStore.load() == settings, "Local selection round-trips without destroying remote preferences.")
    localCheck(!settings.effectiveCleanupEnabled && !PersonalOpenAIFallbackPolicy.shouldUsePersonalOpenAIDirectly(settings), "Local mode excludes cleanup and direct personal routing.")
    defaults.set("future-backend", forKey: "transcription.backend")
    defaults.set("future-model", forKey: "transcription.localModel")
    localCheck(settingsStore.load().transcriptionBackend == .local && settingsStore.load().localModel == .unavailable,
        "Unknown saved selection fails closed without silently routing to cloud or substituting another model.")
    // Local mode must not require valid inactive remote endpoints/models.
    settings.providerConfiguration.transcriptionModel = "inactive-remote-model"
    try AppSettingsValidator.validate(settings)

    do {
        let runtime = FixtureLocalSpeechRuntime()
        let f = try CoordinatorFixture(hasPrimaryKey: false, localRuntime: runtime, localManifests: [model])
        defer { try? f.dispose() }
        try await f.app.localModels.store.install(model, progress: { _ in }, prepare: { _ in })
        await f.app.localModels.refresh()
        f.app.transcriptionBackend = .local
        f.app.personalOpenAIFallbackEnabled = true
        f.app.personalOpenAIDirectModeEnabled = true
        f.app.saveSettings()
        localCheck(f.app.settingsErrorMessage == nil && !f.app.needsConnectionSetup, "Prepared local mode applies without any key.")
        await f.app.startDictation()
        localCheck(f.app.hudDetail.contains("On this Mac"), "Recording HUD must disclose local execution.")
        // Apply remote settings during recording. The operation remains local.
        f.app.transcriptionBackend = .remote
        f.app.personalOpenAIFallbackEnabled = false
        f.app.personalOpenAIDirectModeEnabled = false
        f.app.saveSettings()
        await f.app.stopActiveRecording()
        localCheck(runtime.calls == 1 && f.insertion.inserted == ["Hallo local fixture "], "Operation snapshots local mode and delivers one unsent draft.")
        localCheck(f.secret.reads == 0 && f.personalSecret.reads == 0, "Local dictation must never read a key.")
        localCheck(f.transcription.requests.isEmpty && f.mini.requests.isEmpty && f.cleanup.requests.isEmpty, "Local dictation makes zero cloud, hedge or cleanup requests.")
        localCheck(try f.recovery.loadSnapshot().recordings.isEmpty, "Successful local dictation deletes recovery audio.")
        f.app.transcriptionBackend = .local; f.app.saveSettings()
        runtime.fail = true
        await f.app.startDictation(); await f.app.stopActiveRecording()
        let item = try f.recovery.loadSnapshot().recordings.first!
        localCheck(f.insertion.inserted.count == 1 && f.app.latestFinalDraftForCorrection == "Hallo local fixture", "Failure preserves Last Draft without another insertion.")
        runtime.fail = false
        await f.app.retryRecoveryRecording(item)
        localCheck(f.insertion.inserted.count == 1 && f.insertion.copied == ["Hallo local fixture "], "Local retry copies without historical auto-paste.")
        localCheck(f.app.canStart && f.secret.reads == 0, "Recovery releases local ownership without key access.")
    }
    do {
        let runtime = FixtureLocalSpeechRuntime()
        let f = try CoordinatorFixture(hasPrimaryKey: false, localRuntime: runtime, localManifests: [model])
        defer { try? f.dispose() }
        try await f.app.localModels.store.install(model, progress: { _ in }, prepare: { _ in })
        await f.app.localModels.refresh()
        f.app.transcriptionBackend = .local; f.app.saveSettings()
        runtime.action = {
            // Simulate a native provider that delivers a late completion after cancellation.
            try? await Task.sleep(nanoseconds: 30_000_000_000)
            return "late output"
        }
        await f.app.startDictation()
        let processing = Task { await f.app.stopActiveRecording() }
        for _ in 0..<500 {
            if runtime.calls > 0 { break }
            try await Task.sleep(nanoseconds: 1_000_000)
        }
        localCheck(runtime.calls == 1, "Cancellation fixture reached inference.")
        await f.app.cancelRecording()
        await processing.value
        localCheck(f.insertion.inserted.isEmpty && f.app.canStart, "Canceled local completion never pastes and releases ownership.")
        localCheck(try f.recovery.loadSnapshot().recordings.count == 1, "Processing cancellation retains stopped audio.")
        localCheck(f.secret.reads == 0 && f.transcription.requests.isEmpty, "Cancellation never activates cloud fallback.")
    }
    do {
        let runtime = FixtureLocalSpeechRuntime()
        let f = try CoordinatorFixture(hasPrimaryKey: false, localRuntime: runtime, localManifests: [model])
        defer { try? f.dispose() }
        f.app.transcriptionBackend = .local; f.app.saveSettings()
        localCheck(f.app.settingsErrorMessage != nil, "Missing model prevents Apply.")
    }
}
