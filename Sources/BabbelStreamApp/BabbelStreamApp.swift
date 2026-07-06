import BabbelStreamCore
import AppKit
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
    @Published var cleanupEnabled = ProjectDefaults.cleanupEnabledByDefault
    @Published var providerConfiguration = ProviderConfiguration()
    @Published var status = "Ready"
    @Published var permissionStatus: MicrophonePermissionStatus = .unknown
    @Published var elapsedSeconds: TimeInterval = 0
    @Published var isRecording = false
    @Published var isBusy = false
    @Published var lastResult = "No recording yet."
    @Published var errorMessage: String?

    private let audioRecorder: AudioRecorder
    private var recordingStartedAt: Date?
    private var elapsedTimer: Timer?

    init(audioRecorder: AudioRecorder = AVFoundationAudioRecorder()) {
        self.audioRecorder = audioRecorder
        self.permissionStatus = audioRecorder.microphonePermissionStatus()
    }

    var menuBarSystemImage: String {
        isRecording ? "mic.fill" : "mic"
    }

    var canRequestMicrophonePermission: Bool {
        !isBusy && !isRecording && permissionStatus != .authorized
    }

    var canStartRecording: Bool {
        !isBusy && !isRecording && permissionStatus != .denied && permissionStatus != .restricted
    }

    var canStopRecording: Bool {
        !isBusy && isRecording
    }

    func refreshPermissionStatus() {
        permissionStatus = audioRecorder.microphonePermissionStatus()
    }

    func requestMicrophonePermission() async {
        guard canRequestMicrophonePermission else {
            return
        }

        isBusy = true
        errorMessage = nil

        let newStatus = await audioRecorder.requestMicrophonePermission()
        permissionStatus = newStatus
        status = newStatus.canRecord ? "Ready" : "Microphone unavailable"
        errorMessage = permissionGuidance(for: newStatus)
        isBusy = false
    }

    func startRecording() async {
        guard canStartRecording else {
            return
        }

        isBusy = true
        errorMessage = nil
        lastResult = "Preparing recording..."

        let newStatus = await audioRecorder.requestMicrophonePermission()
        permissionStatus = newStatus

        guard newStatus.canRecord else {
            status = "Microphone unavailable"
            lastResult = "Recording not started."
            errorMessage = permissionGuidance(for: newStatus)
            isBusy = false
            return
        }

        do {
            try await audioRecorder.start(maxDuration: ProjectDefaults.maxAudioDurationSeconds)
            recordingStartedAt = Date()
            elapsedSeconds = 0
            isRecording = true
            status = "Recording"
            lastResult = "Recording..."
            startElapsedTimer()
        } catch {
            status = "Recording failed"
            lastResult = "Recording not started."
            errorMessage = error.localizedDescription
        }

        isBusy = false
    }

    func stopRecording(autoStopped: Bool = false) async {
        guard isRecording || recordingStartedAt != nil else {
            return
        }

        isBusy = true
        stopElapsedTimer()

        do {
            let recording = try await audioRecorder.stop()
            elapsedSeconds = recording.duration
            isRecording = false
            recordingStartedAt = nil
            status = "Ready"
            errorMessage = nil
            lastResult = resultMessage(for: recording, autoStopped: autoStopped)
        } catch {
            isRecording = false
            recordingStartedAt = nil
            status = "Stop failed"
            lastResult = "Could not finish recording safely."
            errorMessage = error.localizedDescription
        }

        isBusy = false
    }

    func cancelRecording() async {
        guard isRecording || recordingStartedAt != nil else {
            return
        }

        isBusy = true
        stopElapsedTimer()

        do {
            try await audioRecorder.cancel()
            isRecording = false
            recordingStartedAt = nil
            elapsedSeconds = 0
            status = "Ready"
            errorMessage = nil
            lastResult = "Recording canceled; temporary file deleted."
        } catch {
            status = "Cancel failed"
            lastResult = "Could not cancel recording safely."
            errorMessage = error.localizedDescription
        }

        isBusy = false
    }

    func openMicrophonePrivacySettings() {
        guard let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone") else {
            return
        }

        NSWorkspace.shared.open(url)
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

        if elapsedSeconds >= ProjectDefaults.maxAudioDurationSeconds, !isBusy {
            Task {
                await stopRecording(autoStopped: true)
            }
        }
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

    private func permissionGuidance(for status: MicrophonePermissionStatus) -> String? {
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
}

struct StatusMenuView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(appState.status)
                .font(.headline)

            Text("Microphone: \(appState.permissionStatus.displayName)")
                .font(.subheadline)

            if appState.isRecording {
                Text("Elapsed: \(elapsedText)")
                    .font(.system(.body, design: .monospaced))
            }

            Text(appState.lastResult)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let errorMessage = appState.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Divider()

            Button("Request Microphone Permission") {
                Task {
                    await appState.requestMicrophonePermission()
                }
            }
            .disabled(!appState.canRequestMicrophonePermission)

            Button("Start Test Recording") {
                Task {
                    await appState.startRecording()
                }
            }
            .disabled(!appState.canStartRecording)

            Button("Stop Recording") {
                Task {
                    await appState.stopRecording()
                }
            }
            .disabled(!appState.canStopRecording)

            Button("Cancel") {
                Task {
                    await appState.cancelRecording()
                }
            }
            .disabled(!appState.canStopRecording)

            if appState.permissionStatus == .denied || appState.permissionStatus == .restricted {
                Button("Open Microphone Settings") {
                    appState.openMicrophonePrivacySettings()
                }
            }

            Divider()

            Toggle("Cleanup", isOn: $appState.cleanupEnabled)
                .disabled(true)
            Text("Transcription, cleanup, paste, and hotkeys start in later milestones.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

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
            appState.refreshPermissionStatus()
        }
        .padding()
        .frame(minWidth: 280, alignment: .leading)
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
                Text(appState.providerConfiguration.baseURL.absoluteString)
                Text(appState.providerConfiguration.transcriptionEndpointPath)
                Text(appState.providerConfiguration.cleanupEndpointPath)
            }

            Section("Defaults") {
                Toggle("Cleanup", isOn: $appState.cleanupEnabled)
                    .disabled(true)
                LabeledContent("Max duration", value: "\(Int(ProjectDefaults.maxAudioDurationSeconds))s")
                LabeledContent("Auto-send", value: ProjectDefaults.autoSendEnabledByDefault ? "On" : "Off")
                LabeledContent("History", value: ProjectDefaults.transcriptHistoryEnabledByDefault ? "On" : "Off")
            }

            Section("Milestone 1") {
                LabeledContent("Recording", value: "Local test only")
                LabeledContent("Temporary audio", value: "Deleted on stop/cancel")
                LabeledContent("Hotkey", value: "Not implemented")
                LabeledContent("Transcription", value: "Not implemented")
            }
        }
        .padding(24)
        .frame(width: 420)
    }
}
