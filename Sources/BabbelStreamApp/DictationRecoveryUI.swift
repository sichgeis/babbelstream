import AppKit
import BabbelStreamCore
import SwiftUI
import UniformTypeIdentifiers

@MainActor
final class DictationRecoveryWindowController {
    private let appState: AppState
    private var windowController: NSWindowController?

    init(appState: AppState) {
        self.appState = appState
    }

    func show() {
        let controller = windowController ?? makeWindowController()
        windowController = controller
        appState.loadRecoveryRecordings()
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func makeWindowController() -> NSWindowController {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 620),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "\(ProjectDefaults.appName) Failed Recordings"
        window.minSize = NSSize(width: 620, height: 500)
        if AppWindowLaunchMode.requested == .failedRecordings {
            window.sharingType = .readOnly
        }
        window.contentViewController = NSHostingController(
            rootView: DictationRecoveryView()
                .environmentObject(appState)
        )
        window.setDialogInitialContentSize(NSSize(width: 720, height: 620))
        window.isReleasedWhenClosed = false
        window.center()
        return NSWindowController(window: window)
    }
}

struct DictationRecoveryView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        AppDialogScaffold(maxContentWidth: 660) {
            Section("Recovery") {
                Text("BabbelStream keeps stopped audio here only when processing did not complete normally. Retry uses the currently applied provider settings and copies the result instead of pasting into the old target.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                LabeledContent("Saved recordings", value: "\(appState.recoverySnapshot.recordings.count)")
                LabeledContent(
                    "Disk usage",
                    value: ByteCountFormatter.string(
                        fromByteCount: appState.recoverySnapshot.totalByteCount,
                        countStyle: .file
                    )
                )
            }

            if appState.recoverySnapshot.recordings.isEmpty {
                Section("Recordings") {
                    Label("No Failed Recordings", systemImage: "waveform.badge.checkmark")
                    Text("Successful dictations delete their safeguarded audio automatically.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(appState.recoverySnapshot.recordings) { recording in
                    recordingSection(recording)
                }
            }

            Section("Storage") {
                AppLongValue(label: "Recovery folder", value: appState.recoveryDirectoryPath)
                Text("Audio files are local M4A recordings with user-only permissions. They are not included in diagnostics or the text archive and are not deleted automatically after failure.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button {
                    appState.revealRecoveryFolder()
                } label: {
                    Label("Reveal Folder", systemImage: "folder")
                }
            }
        } status: {
            if let error = appState.recoveryErrorMessage {
                Text(error).foregroundStyle(.red)
            } else {
                Text(appState.recoveryStatusMessage).foregroundStyle(.secondary)
            }
        } actions: {
            Button {
                NSApp.keyWindow?.performClose(nil)
            } label: {
                Label("Close", systemImage: "xmark")
            }
            Button(role: .destructive) {
                confirmDeleteAll()
            } label: {
                Label("Delete All", systemImage: "trash")
            }
            .disabled(appState.recoverySnapshot.recordings.isEmpty || appState.isProcessing)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func recordingSection(_ recording: DictationRecoveryRecording) -> some View {
        Section(Self.timestampFormatter.string(from: recording.recordedAt)) {
            LabeledContent("Status", value: recording.state.displayName)
            LabeledContent("Duration", value: durationText(recording.durationSeconds))
            LabeledContent("Size", value: ByteCountFormatter.string(fromByteCount: recording.byteCount, countStyle: .file))
            LabeledContent("Original target", value: recording.targetApplicationName ?? "Unknown")
            LabeledContent("Provider", value: "\(recording.providerHost) / \(recording.primaryModel)")
            LabeledContent("Retries", value: "\(recording.retryCount)")

            HStack {
                Button {
                    Task { @MainActor in
                        await appState.retryRecoveryRecording(recording)
                    }
                } label: {
                    Label("Retry and Copy", systemImage: "arrow.clockwise")
                }
                .disabled(!appState.canStart)

                Button {
                    saveAudio(recording)
                } label: {
                    Label("Save Audio As…", systemImage: "square.and.arrow.down")
                }
                .disabled(appState.isProcessing)

                Button(role: .destructive) {
                    confirmDelete(recording)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
                .disabled(appState.isProcessing)
            }
        }
    }

    private func saveAudio(_ recording: DictationRecoveryRecording) {
        let panel = NSSavePanel()
        panel.title = "Save Failed Recording"
        panel.nameFieldStringValue = "BabbelStream-\(Self.fileTimestampFormatter.string(from: recording.recordedAt)).m4a"
        panel.allowedContentTypes = [.mpeg4Audio]
        guard panel.runModal() == .OK, let destination = panel.url else {
            return
        }
        appState.exportRecoveryRecording(recording, to: destination)
    }

    private func confirmDelete(_ recording: DictationRecoveryRecording) {
        let alert = NSAlert()
        alert.messageText = "Delete failed recording?"
        alert.informativeText = "This permanently removes the local audio. It cannot be retried afterward."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Delete Recording")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        appState.deleteRecoveryRecording(recording)
    }

    private func confirmDeleteAll() {
        let alert = NSAlert()
        alert.messageText = "Delete all failed recordings?"
        alert.informativeText = "This permanently removes every locally retained recovery recording."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Delete All")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        appState.deleteAllRecoveryRecordings()
    }

    private func durationText(_ duration: TimeInterval) -> String {
        let seconds = Int(duration.rounded())
        return seconds >= 60 ? String(format: "%d:%02d", seconds / 60, seconds % 60) : "\(seconds)s"
    }

    private static let timestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    private static let fileTimestampFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }()
}
