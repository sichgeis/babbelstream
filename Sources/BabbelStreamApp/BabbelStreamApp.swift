import AppKit
import BabbelStreamCore
import SwiftUI

@main
struct BabbelStreamApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra(ProjectDefaults.appName, systemImage: appState.menuBarSystemImage) {
            StatusMenuView()
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    enum RecordingMode {
        case none
        case dictation
        case test
    }

    @Published var status = "Ready"
    @Published var microphonePermissionStatus: MicrophonePermissionStatus = .unknown
    @Published var accessibilityPermissionStatus: AccessibilityPermissionStatus = .notTrusted
    @Published var elapsedSeconds: TimeInterval = 0
    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var recordingMode: RecordingMode = .none
    @Published var cleanupEnabled: Bool
    @Published var lastResult = "No dictation yet."
    @Published var warningMessage: String?
    @Published var errorMessage: String?
    @Published var hotkeyStatus = "Hotkey not registered yet."
    @Published var hasAPIKey = false

    @Published var baseURLText: String
    @Published var transcriptionPathText: String
    @Published var cleanupPathText: String
    @Published var transcriptionModelText: String
    @Published var cleanupModelText: String
    @Published var timeoutText: String
    @Published var transcriptionLanguageText: String
    @Published var transcriptionPromptText: String
    @Published var apiKeyInput = ""

    private let audioRecorder: AudioRecorder
    private let settingsStore: SettingsStore
    private let secretStore: SecretStore
    private let transcriptionProvider: TranscriptionProvider
    private let cleanupProvider: CleanupProvider
    private let textInsertionService: TextInsertionService
    private let hotkeyService: HotkeyService

    private var appSettings: AppSettings
    private var recordingStartedAt: Date?
    private var elapsedTimer: Timer?
    private var latestRawTranscript: String?
    private var latestFinalDraft: String?

    init(
        audioRecorder: AudioRecorder = AVFoundationAudioRecorder(),
        settingsStore: SettingsStore = UserDefaultsSettingsStore(),
        secretStore: SecretStore = KeychainSecretStore(),
        transcriptionProvider: TranscriptionProvider = OpenAICompatibleTranscriptionProvider(),
        cleanupProvider: CleanupProvider = OpenAICompatibleCleanupProvider(),
        textInsertionService: TextInsertionService = ClipboardTextInsertionService(),
        hotkeyService: HotkeyService = CarbonHotkeyService()
    ) {
        self.audioRecorder = audioRecorder
        self.settingsStore = settingsStore
        self.secretStore = secretStore
        self.transcriptionProvider = transcriptionProvider
        self.cleanupProvider = cleanupProvider
        self.textInsertionService = textInsertionService
        self.hotkeyService = hotkeyService

        let loadedSettings = settingsStore.load()
        self.appSettings = loadedSettings
        self.cleanupEnabled = loadedSettings.cleanupEnabled
        self.baseURLText = loadedSettings.providerConfiguration.baseURL.absoluteString
        self.transcriptionPathText = loadedSettings.providerConfiguration.transcriptionEndpointPath
        self.cleanupPathText = loadedSettings.providerConfiguration.cleanupEndpointPath
        self.transcriptionModelText = loadedSettings.providerConfiguration.transcriptionModel
        self.cleanupModelText = loadedSettings.providerConfiguration.cleanupModel
        self.timeoutText = String(Int(loadedSettings.providerConfiguration.timeoutSeconds))
        self.transcriptionLanguageText = loadedSettings.transcriptionLanguage
        self.transcriptionPromptText = loadedSettings.transcriptionPrompt

        self.microphonePermissionStatus = audioRecorder.microphonePermissionStatus()
        self.accessibilityPermissionStatus = textInsertionService.accessibilityPermissionStatus()
        self.hasAPIKey = ((try? secretStore.readAPIKey()) ?? nil) != nil

        configureHotkey()
    }

    var menuBarSystemImage: String {
        if isRecording {
            return "mic.fill"
        }
        if isProcessing {
            return "waveform"
        }
        return "mic"
    }

    var canStart: Bool {
        !isRecording && !isProcessing
    }

    var canStop: Bool {
        isRecording && !isProcessing
    }

    var canUseLatestDraft: Bool {
        latestFinalDraft?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    var providerDestinationSummary: String {
        "\(baseURLText)\(transcriptionPathText)"
    }

    func refreshPermissionStatuses() {
        microphonePermissionStatus = audioRecorder.microphonePermissionStatus()
        accessibilityPermissionStatus = textInsertionService.accessibilityPermissionStatus()
    }

    func requestMicrophonePermission() async {
        guard canStart else {
            return
        }

        microphonePermissionStatus = await audioRecorder.requestMicrophonePermission()
        if microphonePermissionStatus.canRecord {
            status = "Ready"
            errorMessage = nil
        } else {
            status = "Microphone unavailable"
            errorMessage = microphoneGuidance(for: microphonePermissionStatus)
        }
    }

    func requestAccessibilityPermission() {
        textInsertionService.requestAccessibilityPermission()
        accessibilityPermissionStatus = textInsertionService.accessibilityPermissionStatus()
    }

    func startDictation() async {
        await startRecording(mode: .dictation)
    }

    func startTestRecording() async {
        await startRecording(mode: .test)
    }

    func stopActiveRecording() async {
        switch recordingMode {
        case .dictation:
            await stopAndProcessDictation()
        case .test:
            await stopTestRecording()
        case .none:
            return
        }
    }

    func cancelRecording() async {
        guard isRecording || recordingStartedAt != nil else {
            return
        }

        stopElapsedTimer()
        isProcessing = true

        do {
            try await audioRecorder.cancel()
            resetRecordingState()
            status = "Ready"
            errorMessage = nil
            warningMessage = nil
            lastResult = "Recording canceled; temporary file deleted."
        } catch {
            resetRecordingState()
            status = "Cancel failed"
            errorMessage = error.localizedDescription
            lastResult = "Could not cancel recording safely."
        }

        isProcessing = false
    }

    func saveSettings() {
        guard let baseURL = URL(string: baseURLText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            errorMessage = SettingsValidationError.invalidBaseURL.localizedDescription
            return
        }
        guard let timeout = TimeInterval(timeoutText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            errorMessage = SettingsValidationError.invalidTimeout.localizedDescription
            return
        }

        let configuration = ProviderConfiguration(
            baseURL: baseURL,
            transcriptionEndpointPath: transcriptionPathText,
            cleanupEndpointPath: cleanupPathText,
            transcriptionModel: transcriptionModelText,
            cleanupModel: cleanupModelText,
            timeoutSeconds: timeout,
            retryCount: 1
        )
        let settings = AppSettings(
            providerConfiguration: configuration,
            cleanupEnabled: cleanupEnabled,
            transcriptionResponseFormat: ProjectDefaults.defaultTranscriptionResponseFormat,
            transcriptionLanguage: transcriptionLanguageText,
            transcriptionPrompt: transcriptionPromptText
        )

        do {
            try settingsStore.save(settings)

            let trimmedKey = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedKey.isEmpty {
                try secretStore.saveAPIKey(trimmedKey)
                apiKeyInput = ""
            }

            appSettings = settings
            hasAPIKey = ((try? secretStore.readAPIKey()) ?? nil) != nil
            warningMessage = nil
            errorMessage = nil
            lastResult = "Settings saved. Provider: \(providerDestinationSummary)"
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteAPIKey() {
        do {
            try secretStore.deleteAPIKey()
            apiKeyInput = ""
            hasAPIKey = false
            lastResult = "API key deleted from Keychain."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func setCleanupEnabled(_ isEnabled: Bool) {
        cleanupEnabled = isEnabled
        var updatedSettings = appSettings
        updatedSettings.cleanupEnabled = isEnabled
        do {
            try settingsStore.save(updatedSettings)
            appSettings = updatedSettings
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func copyLatestDraft() {
        guard let latestFinalDraft else {
            return
        }

        do {
            try textInsertionService.copyText(latestFinalDraft)
            lastResult = "Latest draft copied to clipboard."
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func retryPasteLatestDraft() async {
        guard let latestFinalDraft else {
            return
        }

        await insertFinalDraft(latestFinalDraft)
    }

    func openMicrophonePrivacySettings() {
        openSystemSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")
    }

    func openAccessibilityPrivacySettings() {
        openSystemSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }

    private func configureHotkey() {
        hotkeyService.onPressed = { [weak self] in
            Task { @MainActor in
                guard let self, self.canStart else {
                    return
                }
                await self.startDictation()
            }
        }
        hotkeyService.onReleased = { [weak self] in
            Task { @MainActor in
                guard let self, self.recordingMode == .dictation else {
                    return
                }
                await self.stopAndProcessDictation()
            }
        }

        do {
            try hotkeyService.register()
            hotkeyStatus = "\(ProjectDefaults.fixedHotkeyDescription) registered."
        } catch {
            hotkeyStatus = error.localizedDescription
        }
    }

    private func startRecording(mode: RecordingMode) async {
        guard canStart else {
            return
        }

        isProcessing = true
        warningMessage = nil
        errorMessage = nil
        latestRawTranscript = nil
        latestFinalDraft = nil
        lastResult = "Preparing recording..."

        let newStatus = await audioRecorder.requestMicrophonePermission()
        microphonePermissionStatus = newStatus

        guard newStatus.canRecord else {
            status = "Microphone unavailable"
            lastResult = "Recording not started."
            errorMessage = microphoneGuidance(for: newStatus)
            isProcessing = false
            return
        }

        do {
            try await audioRecorder.start(maxDuration: ProjectDefaults.maxAudioDurationSeconds)
            recordingStartedAt = Date()
            elapsedSeconds = 0
            recordingMode = mode
            isRecording = true
            status = mode == .dictation ? "Recording dictation" : "Recording test"
            lastResult = mode == .dictation
                ? "Speak, then release \(ProjectDefaults.fixedHotkeyDescription) or click Stop."
                : "Test recording only; no transcription will run."
            startElapsedTimer()
        } catch {
            status = "Recording failed"
            lastResult = "Recording not started."
            errorMessage = error.localizedDescription
        }

        isProcessing = false
    }

    private func stopAndProcessDictation(autoStopped: Bool = false) async {
        guard isRecording || recordingStartedAt != nil else {
            return
        }

        isProcessing = true
        stopElapsedTimer()

        do {
            let recording = try await audioRecorder.stop(deleteTemporaryFile: false)
            resetRecordingState()
            elapsedSeconds = recording.duration
            try await processRecording(recording, autoStopped: autoStopped)
        } catch {
            resetRecordingState()
            status = "Dictation failed"
            errorMessage = error.localizedDescription
            lastResult = "Could not finish dictation safely."
        }

        isProcessing = false
    }

    private func stopTestRecording(autoStopped: Bool = false) async {
        guard isRecording || recordingStartedAt != nil else {
            return
        }

        isProcessing = true
        stopElapsedTimer()

        do {
            let recording = try await audioRecorder.stop(deleteTemporaryFile: true)
            resetRecordingState()
            elapsedSeconds = recording.duration
            status = "Ready"
            errorMessage = nil
            warningMessage = nil
            lastResult = resultMessage(for: recording, autoStopped: autoStopped)
        } catch {
            resetRecordingState()
            status = "Stop failed"
            errorMessage = error.localizedDescription
            lastResult = "Could not finish test recording safely."
        }

        isProcessing = false
    }

    private func processRecording(_ recording: RecordedAudio, autoStopped: Bool) async throws {
        defer {
            _ = try? AudioTempFileStore.deleteTemporaryAudio(at: recording.temporaryFileURL)
        }

        let apiKey = try secretStore.readAPIKey() ?? ""
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw ProviderError.missingAPIKey
        }

        status = autoStopped ? "Max reached; transcribing" : "Transcribing"
        lastResult = "Sending audio to \(appSettings.providerConfiguration.baseURL.host ?? appSettings.providerConfiguration.baseURL.absoluteString)."

        let rawTranscript = try await transcriptionProvider.transcribe(
            TranscriptionRequest(
                audioURL: recording.temporaryFileURL,
                settings: appSettings,
                apiKey: apiKey
            )
        )
        latestRawTranscript = rawTranscript

        let finalDraft: String
        if cleanupEnabled {
            status = "Cleaning up"
            do {
                finalDraft = try await cleanupProvider.cleanup(
                    CleanupRequest(
                        transcript: rawTranscript,
                        settings: appSettings,
                        apiKey: apiKey
                    )
                )
                warningMessage = nil
            } catch {
                finalDraft = rawTranscript
                warningMessage = "Cleanup failed; using raw transcript. \(error.localizedDescription)"
            }
        } else {
            finalDraft = rawTranscript
            warningMessage = nil
        }

        latestFinalDraft = finalDraft
        await insertFinalDraft(finalDraft)
    }

    private func insertFinalDraft(_ finalDraft: String) async {
        status = "Pasting draft"

        do {
            let insertionResult = try await textInsertionService.insertText(finalDraft)
            accessibilityPermissionStatus = textInsertionService.accessibilityPermissionStatus()

            switch insertionResult {
            case .pasted:
                status = "Ready"
                lastResult = "Draft pasted. Review it before sending."
                errorMessage = nil
            case .copiedForManualPaste:
                status = "Copied"
                lastResult = "Draft copied to clipboard. Paste manually with Cmd+V."
                errorMessage = "Accessibility is not allowed, so BabbelStream could not paste automatically."
            }
        } catch {
            do {
                try textInsertionService.copyText(finalDraft)
                status = "Copied"
                lastResult = "Draft copied to clipboard after paste failed. Paste manually with Cmd+V."
                errorMessage = error.localizedDescription
            } catch {
                status = "Paste failed"
                lastResult = "Draft is only available in memory for this app session."
                errorMessage = error.localizedDescription
            }
        }
    }

    private func startElapsedTimer() {
        stopElapsedTimer()

        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateElapsedTime()
            }
        }
    }

    private func stopElapsedTimer() {
        elapsedTimer?.invalidate()
        elapsedTimer = nil
    }

    private func updateElapsedTime() {
        guard let recordingStartedAt else {
            return
        }

        elapsedSeconds = Date().timeIntervalSince(recordingStartedAt)

        if elapsedSeconds >= ProjectDefaults.maxAudioDurationSeconds, !isProcessing {
            Task {
                switch recordingMode {
                case .dictation:
                    await stopAndProcessDictation(autoStopped: true)
                case .test:
                    await stopTestRecording(autoStopped: true)
                case .none:
                    break
                }
            }
        }
    }

    private func resetRecordingState() {
        isRecording = false
        recordingStartedAt = nil
        recordingMode = .none
    }

    private func resultMessage(for recording: RecordedAudio, autoStopped: Bool) -> String {
        let prefix = autoStopped ? "Maximum duration reached." : "Recording stopped."
        let deletionText = recording.wasDeleted ? "Temporary file deleted." : "Temporary file was not deleted."

        return "\(prefix) \(formatDuration(recording.duration)), \(formatByteCount(recording.byteCount)). \(deletionText)"
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        String(format: "%.1fs", duration)
    }

    private func formatByteCount(_ byteCount: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file

        return formatter.string(fromByteCount: byteCount)
    }

    private func microphoneGuidance(for status: MicrophonePermissionStatus) -> String? {
        switch status {
        case .authorized:
            nil
        case .notDetermined:
            "Microphone permission has not been requested yet."
        case .denied:
            "Microphone access is denied. Enable BabbelStream in System Settings > Privacy & Security > Microphone."
        case .restricted:
            "Microphone access is restricted by this Mac's policy."
        case .unknown:
            "Microphone permission state is unknown."
        }
    }

    private func openSystemSettings(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            return
        }

        NSWorkspace.shared.open(url)
    }
}

struct StatusMenuView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(appState.status)
                .font(.headline)

            Text("Hotkey: \(ProjectDefaults.fixedHotkeyDescription)")
                .font(.subheadline)
            Text(appState.hotkeyStatus)
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Microphone: \(appState.microphonePermissionStatus.displayName)")
                .font(.caption)
            Text("Accessibility: \(appState.accessibilityPermissionStatus.displayName)")
                .font(.caption)

            if appState.isRecording {
                Text("Elapsed: \(elapsedText)")
                    .font(.system(.body, design: .monospaced))
            }

            Text(appState.lastResult)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let warningMessage = appState.warningMessage {
                Text(warningMessage)
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let errorMessage = appState.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            Toggle(
                "Cleanup",
                isOn: Binding(
                    get: { appState.cleanupEnabled },
                    set: { appState.setCleanupEnabled($0) }
                )
            )

            Button("Start Dictation") {
                Task {
                    await appState.startDictation()
                }
            }
            .disabled(!appState.canStart)

            Button("Stop + Transcribe") {
                Task {
                    await appState.stopActiveRecording()
                }
            }
            .disabled(!appState.canStop)

            Button("Cancel Recording") {
                Task {
                    await appState.cancelRecording()
                }
            }
            .disabled(!appState.canStop)

            Divider()

            Button("Start Local Test Recording") {
                Task {
                    await appState.startTestRecording()
                }
            }
            .disabled(!appState.canStart)

            Button("Copy Last Draft") {
                appState.copyLatestDraft()
            }
            .disabled(!appState.canUseLatestDraft)

            Button("Retry Paste Last Draft") {
                Task {
                    await appState.retryPasteLatestDraft()
                }
            }
            .disabled(!appState.canUseLatestDraft || appState.isProcessing)

            Divider()

            Button("Request Microphone Permission") {
                Task {
                    await appState.requestMicrophonePermission()
                }
            }
            .disabled(!appState.canStart || appState.microphonePermissionStatus == .authorized)

            Button("Request Accessibility Permission") {
                appState.requestAccessibilityPermission()
            }

            if appState.microphonePermissionStatus == .denied || appState.microphonePermissionStatus == .restricted {
                Button("Open Microphone Settings") {
                    appState.openMicrophonePrivacySettings()
                }
            }

            if appState.accessibilityPermissionStatus == .notTrusted {
                Button("Open Accessibility Settings") {
                    appState.openAccessibilityPrivacySettings()
                }
            }

            Divider()

            Button("Settings...") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .onAppear {
            appState.refreshPermissionStatuses()
        }
        .padding()
        .frame(minWidth: 320, alignment: .leading)
    }

    private var elapsedText: String {
        "\(Int(appState.elapsedSeconds.rounded(.down)))s / \(Int(ProjectDefaults.maxAudioDurationSeconds))s"
    }
}

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Form {
            Section("Provider") {
                Text("Audio is sent to:")
                    .foregroundStyle(.secondary)
                Text(appState.providerDestinationSummary)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)

                TextField("Base URL", text: $appState.baseURLText)
                TextField("Transcription path", text: $appState.transcriptionPathText)
                TextField("Transcription model", text: $appState.transcriptionModelText)
                TextField("Cleanup path", text: $appState.cleanupPathText)
                TextField("Cleanup model", text: $appState.cleanupModelText)
                TextField("Timeout seconds", text: $appState.timeoutText)
            }

            Section("Transcription Hints") {
                TextField("Language, optional", text: $appState.transcriptionLanguageText)
                TextField("Prompt, optional", text: $appState.transcriptionPromptText, axis: .vertical)
                    .lineLimit(2...4)
            }

            Section("API Key") {
                SecureField(
                    appState.hasAPIKey ? "API key saved in Keychain" : "Paste API key",
                    text: $appState.apiKeyInput
                )
                LabeledContent("Keychain", value: appState.hasAPIKey ? "Saved" : "Missing")

                HStack {
                    Button("Save Settings") {
                        appState.saveSettings()
                    }
                    Button("Delete API Key") {
                        appState.deleteAPIKey()
                    }
                    .disabled(!appState.hasAPIKey)
                }
            }

            Section("Behavior") {
                Toggle(
                    "Cleanup enabled",
                    isOn: Binding(
                        get: { appState.cleanupEnabled },
                        set: { appState.setCleanupEnabled($0) }
                    )
                )
                LabeledContent("Hotkey", value: ProjectDefaults.fixedHotkeyDescription)
                LabeledContent("Max duration", value: "\(Int(ProjectDefaults.maxAudioDurationSeconds))s")
                LabeledContent("Auto-send", value: ProjectDefaults.autoSendEnabledByDefault ? "On" : "Off")
                LabeledContent("History", value: ProjectDefaults.transcriptHistoryEnabledByDefault ? "On" : "Off")
            }
        }
        .padding(24)
        .frame(width: 560)
    }
}
