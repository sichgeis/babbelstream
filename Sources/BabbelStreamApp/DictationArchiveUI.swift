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
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 640),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "\(ProjectDefaults.appName) Dictation Archive"
        window.minSize = NSSize(width: 680, height: 520)
        if AppWindowLaunchMode.requested == .dictationArchive {
            window.sharingType = .readOnly
        }
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
        AppDialogScaffold(maxContentWidth: 680) {
            Section("Month") {
                TextField("Month (YYYY-MM)", text: $appState.archiveMonthText)
                Text("Review local, text-only entries for one calendar month.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button {
                    appState.loadArchiveMonth()
                } label: {
                    Label("Reload Month", systemImage: "arrow.clockwise")
                }
            }

            Section("Summary") {
                LabeledContent("Entries", value: "\(appState.archiveSnapshot.entries.count)")
                LabeledContent("Raw words", value: "\(appState.archiveSnapshot.totalRawWordCount)")
                LabeledContent("Final words", value: "\(appState.archiveSnapshot.totalFinalWordCount)")
                LabeledContent("Archive", value: appState.dictationArchiveEnabled ? "Enabled" : "Disabled")
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
                AppLongValue(label: "Archive folder", value: appState.archiveDirectoryPath)
                Text("Archive contents stay on this Mac. Audio is never stored here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Button {
                        appState.revealArchiveFolder()
                    } label: {
                        Label("Reveal Folder", systemImage: "folder")
                    }
                    Button(role: .destructive) {
                        confirmClearArchive()
                    } label: {
                        Label("Clear Archive", systemImage: "trash")
                    }
                }
            }
        } status: {
            if let archiveErrorMessage = appState.archiveErrorMessage {
                Text(archiveErrorMessage)
                    .foregroundStyle(.red)
            } else if appState.archiveStatusMessage.isEmpty {
                Text("Archive review is local-only and never sends content to a provider.")
                    .foregroundStyle(.secondary)
            } else {
                Text(appState.archiveStatusMessage)
                    .foregroundStyle(.secondary)
            }
        } actions: {
            Button {
                NSApp.keyWindow?.performClose(nil)
            } label: {
                Label("Close", systemImage: "xmark")
            }
            Button {
                appState.copyArchiveMarkdownExport()
            } label: {
                Label("Copy Markdown Export", systemImage: "doc.on.doc")
            }
        }
        .frame(minWidth: 680, idealWidth: 760, minHeight: 520, idealHeight: 640)
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
