import Foundation
import BabbelStreamCore
@testable import BabbelStreamApplication

final class MemorySettings: SettingsStore {
    var value: AppSettings
    init(_ value: AppSettings) { self.value = value }
    func load() -> AppSettings { value }
    func save(_ settings: AppSettings) throws { value = settings }
}

final class FixtureSecret: SecretStore {
    var reads = 0
    func readAPIKey() throws -> String? { reads += 1; return "synthetic-key-not-a-credential" }
    func saveAPIKey(_ apiKey: String) throws {}
    func deleteAPIKey() throws {}
}

final class MemoryKeyPresence: APIKeyPresenceStore { var hasSavedAPIKey = true }
final class MemoryUsage: UsageTracker {
    var value = UsageSnapshot()
    func load() -> UsageSnapshot { value }
    func save(_ snapshot: UsageSnapshot) { value = snapshot }
    func reset() { value = UsageSnapshot() }
}
final class FixtureLogin: LaunchAtLoginManaging {
    var snapshot: LaunchAtLoginSnapshot { LaunchAtLoginSnapshot(systemStatus: .notRegistered, legacyLaunchAgentExists: false) }
    func migrateLegacyRegistrationIfNeeded() throws {}
    func enable() throws {}
    func disable() throws {}
    func openSystemSettings() {}
}

@MainActor
final class FixtureRuntime: AppRuntime {
    let temporaryAudioDirectories: [URL]
    init(root: URL) { temporaryAudioDirectories = [root] }
    func frontmostTarget() -> TextInsertionTarget? { TextInsertionTarget(processIdentifier: 123, localizedName: "Fixture", bundleIdentifier: "example.fixture") }
    func observeActivations(_ handler: @escaping @MainActor (TextInsertionTarget) -> Void) {}
    func recordDiagnostic(_ message: String) {}
}

@MainActor
final class FixtureHotkey: HotkeyService {
    var isRegistered = false
    var onPressed: (() -> Void)?
    var onReleased: (() -> Void)?
    var onCancel: (() -> Void)?
    var cancelEnabled = false
    func register() throws { isRegistered = true }
    func setCancelEnabled(_ isEnabled: Bool) throws { cancelEnabled = isEnabled }
    func unregister() { isRegistered = false }
}

@MainActor
final class FixtureRecorder: AudioRecorder {
    let root: URL
    var isRecording = false
    var currentLevel: Float { 0 }
    var failStopOwnership = false
    var audio: RecordedAudio?
    init(root: URL) { self.root = root }
    func microphonePermissionStatus() -> MicrophonePermissionStatus { .authorized }
    func requestMicrophonePermission() async -> MicrophonePermissionStatus { .authorized }
    func start(maxDuration: TimeInterval) async throws {
        let url = root.appendingPathComponent("\(UUID()).m4a")
        let bytes = Data("synthetic-audio-fixture".utf8)
        try bytes.write(to: url)
        audio = RecordedAudio(temporaryFileURL: url, duration: 3, byteCount: Int64(bytes.count), createdAt: Date(), deletedAt: nil)
        isRecording = true
    }
    func stop(deleteTemporaryFile: Bool) async throws -> RecordedAudio {
        if failStopOwnership { throw AudioRecordingError.couldNotSafeguardStop }
        guard let audio else { throw AudioRecordingError.notRecording }
        if deleteTemporaryFile { _ = try AudioTempFileStore.deleteTemporaryAudio(at: audio.temporaryFileURL) }
        else { _ = try StoppedAudioOwnership.mark(audio) }
        isRecording = false
        return audio
    }
    func cancel() async throws { try cancelImmediately() }
    func cancelImmediately() throws {
        if isRecording, let audio { _ = try AudioTempFileStore.deleteTemporaryAudio(at: audio.temporaryFileURL) }
        isRecording = false
    }
}

@MainActor
final class FixtureTranscriber: TranscriptionProvider {
    var requests: [TranscriptionRequest] = []
    var action: ((TranscriptionRequest) async throws -> String)?
    func transcribe(_ request: TranscriptionRequest) async throws -> String {
        requests.append(request)
        return try await action?(request) ?? "raw fixture"
    }
}

@MainActor
final class FixtureCleanup: CleanupProvider {
    var requests: [CleanupRequest] = []
    var fail = false
    func cleanup(_ request: CleanupRequest) async throws -> String {
        requests.append(request)
        if fail { throw ProviderError.malformedResponse }
        return "clean fixture"
    }
}

@MainActor
final class FixtureInsertion: TextInsertionService {
    var inserted: [String] = []
    var copied: [String] = []
    var failCopy = false
    var result = TextInsertionResult.insertedDirectly
    func accessibilityPermissionStatus() -> AccessibilityPermissionStatus { .trusted }
    func requestAccessibilityPermission() {}
    func captureTarget() -> TextInsertionTarget? { TextInsertionTarget(processIdentifier: 123, localizedName: "Fixture", bundleIdentifier: "example.fixture") }
    func insertText(_ text: String, target: TextInsertionTarget?) async throws -> TextInsertionResult { inserted.append(text); return result }
    func copyText(_ text: String) throws {
        if failCopy { throw TextInsertionError.pasteboardUnavailable }
        copied.append(text)
    }
}

@MainActor
final class CoordinatorFixture {
    let root: URL
    let app: AppState
    let fm = RecoveryFaultFileManager()
    let recorder: FixtureRecorder
    let transcription = FixtureTranscriber()
    let mini = FixtureTranscriber()
    let cleanup = FixtureCleanup()
    let insertion = FixtureInsertion()
    let secret = FixtureSecret()
    let personalSecret = FixtureSecret()
    let hotkey = FixtureHotkey()
    let recovery: FileDictationRecoveryStore
    let settings: MemorySettings

    init(cleanupEnabled: Bool = true) throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent("BabbelStreamCoordinatorChecks-\(UUID())")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        recorder = FixtureRecorder(root: root)
        var initial = AppSettings(cleanupEnabled: cleanupEnabled)
        initial.providerConfiguration.baseURL = URL(string: "https://primary.example.invalid")!
        settings = MemorySettings(initial)
        recovery = FileDictationRecoveryStore(recoveryDirectoryURL: root.appendingPathComponent("Recovery"), fileManager: fm, temporaryDirectories: [root])
        app = AppState(
            audioRecorder: recorder, settingsStore: settings, secretStore: secret,
            apiKeyPresenceStore: MemoryKeyPresence(), personalOpenAIFallbackSecretStore: personalSecret,
            personalOpenAIFallbackAPIKeyPresenceStore: MemoryKeyPresence(),
            transcriptionProvider: transcription, fallbackTranscriptionProvider: mini, cleanupProvider: cleanup,
            textInsertionService: insertion, hotkeyService: hotkey, launchAtLoginService: FixtureLogin(),
            personalDictionaryStore: JSONPersonalDictionaryStore(fileURL: root.appendingPathComponent("dictionary.json")),
            usageTracker: MemoryUsage(), dictationArchiveStore: JSONLDictationArchiveStore(archiveDirectoryURL: root.appendingPathComponent("Archive")),
            dictationRecoveryStore: recovery, runtime: FixtureRuntime(root: root)
        )
    }

    func dispose() throws {
        app.prepareForTermination()
        try FileManager.default.removeItem(at: root)
    }

    func createFailedRecording() async throws -> DictationRecoveryRecording {
        cleanup.fail = true
        await app.startDictation()
        await app.stopActiveRecording()
        cleanup.fail = false
        let snapshot = try recovery.loadSnapshot()
        check(snapshot.recordings.count == 1, "Cleanup failure should create one recoverable fixture.")
        return snapshot.recordings[0]
    }
}
