import AppKit
import BabbelStreamCore
import SwiftUI

@MainActor
final class DictationArchiveWindowController {
    private let appState: AppState
    private var windowController: NSWindowController?

    init(appState: AppState) {
        self.appState = appState
    }

    func show() {
        let controller = windowController ?? makeWindowController()
        windowController = controller
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        appState.loadArchiveMonth()
    }

    private func makeWindowController() -> NSWindowController {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 680, height: 640),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "\(ProjectDefaults.appName) Dictation Archive"
        window.contentViewController = NSHostingController(
            rootView: DictationArchiveView()
                .environmentObject(appState)
        )
        window.isReleasedWhenClosed = false
        window.center()

        return NSWindowController(window: window)
    }
}

struct DictationArchiveView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Form {
            Section("Month") {
                TextField("Month (YYYY-MM)", text: $appState.archiveMonthText)
                HStack {
                    Button("Reload") {
                        appState.loadArchiveMonth()
                    }
                    Button("Copy Markdown Export") {
                        appState.copyArchiveMarkdownExport()
                    }
                    Button("Reveal Folder") {
                        appState.revealArchiveFolder()
                    }
                    Button("Clear Archive") {
                        confirmClearArchive()
                    }
                }
            }

            Section("Summary") {
                LabeledContent("Entries", value: "\(appState.archiveSnapshot.entries.count)")
                LabeledContent("Raw words", value: "\(appState.archiveSnapshot.totalRawWordCount)")
                LabeledContent("Final words", value: "\(appState.archiveSnapshot.totalFinalWordCount)")
                LabeledContent("Archive", value: appState.dictationArchiveEnabled ? "Enabled" : "Disabled")

                if let archiveErrorMessage = appState.archiveErrorMessage {
                    Text(archiveErrorMessage)
                        .foregroundStyle(.red)
                } else {
                    Text(appState.archiveStatusMessage)
                        .foregroundStyle(.secondary)
                }
            }

            Section("Daily Totals") {
                if appState.archiveSnapshot.dailySummaries.isEmpty {
                    Text("No archived dictations for this month.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(appState.archiveSnapshot.dailySummaries) { summary in
                        LabeledContent(
                            summary.dateString,
                            value: "\(summary.entryCount) dictations, \(summary.rawWordCount) raw words, \(summary.finalWordCount) final words"
                        )
                    }
                }
            }

            if !appState.archiveSnapshot.readWarnings.isEmpty {
                Section("Recovery") {
                    Text("Valid entries were loaded. Damaged JSONL lines were skipped and remain in the local files for manual recovery.")
                        .foregroundStyle(.orange)
                    ForEach(appState.archiveSnapshot.readWarnings.prefix(8)) { warning in
                        LabeledContent(warning.fileName, value: "line \(warning.line)")
                    }
                }
            }

            Section("Storage") {
                Text(appState.archiveDirectoryPath)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
            }
        }
        .padding(24)
        .frame(width: 680)
    }

    private func confirmClearArchive() {
        let alert = NSAlert()
        alert.messageText = "Clear dictation archive?"
        alert.informativeText = "This deletes local archive files. Audio is not part of the archive."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Clear Archive")
        alert.addButton(withTitle: "Cancel")

        guard alert.runModal() == .alertFirstButtonReturn else {
            return
        }

        appState.clearArchive()
    }
}
