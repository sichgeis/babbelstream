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
        appState.archiveBrowser.loadMonth()
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
        window.contentViewController = makeDialogHostingController(
            rootView: DictationArchiveView(browser: appState.archiveBrowser)
                .environmentObject(appState)
        )
        window.setDialogInitialContentSize(NSSize(width: 760, height: 640), minimum: NSSize(width: 680, height: 520))
        window.isReleasedWhenClosed = false
        window.center()

        return NSWindowController(window: window)
    }
}

struct DictationArchiveView: View {
    @ObservedObject var browser: ArchiveBrowser
    @EnvironmentObject private var appState: AppState

    var body: some View {
        AppDialogScaffold(maxContentWidth: 680) {
            AppFormSection("Month") {
                AppFormTextField("Month (YYYY-MM)", text: $browser.monthText)
                Text("Review local, text-only entries for one calendar month.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button {
                    browser.loadMonth()
                } label: {
                    Label("Reload Month", systemImage: "arrow.clockwise")
                }
            }

            AppFormSection("Summary") {
                AppLabeledContent("Entries", value: "\(browser.snapshot.entries.count)")
                AppLabeledContent("Raw words", value: "\(browser.snapshot.totalRawWordCount)")
                AppLabeledContent("Final words", value: "\(browser.snapshot.totalFinalWordCount)")
                AppLabeledContent("Archive", value: appState.settingsDraft.dictationArchiveEnabled ? "Enabled" : "Disabled")
            }

            AppFormSection("Daily Totals") {
                if browser.snapshot.dailySummaries.isEmpty {
                    Text("No archived dictations for this month.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(browser.snapshot.dailySummaries) { summary in
                        AppLabeledContent(
                            summary.dateString,
                            value: "\(summary.entryCount) dictations, \(summary.rawWordCount) raw words, \(summary.finalWordCount) final words"
                        )
                    }
                }
            }

            if !browser.snapshot.readWarnings.isEmpty {
                AppFormSection("Recovery") {
                    Text("Valid entries were loaded. Damaged JSONL lines were skipped and remain in the local files for manual recovery.")
                        .foregroundStyle(.orange)
                    ForEach(browser.snapshot.readWarnings.prefix(8)) { warning in
                        AppLabeledContent(warning.fileName, value: "line \(warning.line)")
                    }
                }
            }

            AppFormSection("Storage") {
                AppLongValue(label: "Archive folder", value: appState.archiveDirectoryPath)
                Text("Archive contents stay on this Mac. Audio is never stored here.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack {
                    Button {
                        browser.revealFolder()
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
            if let archiveErrorMessage = browser.errorMessage {
                Text(archiveErrorMessage)
                    .foregroundStyle(.red)
            } else if browser.statusMessage.isEmpty {
                Text("Archive review is local-only and never sends content to a provider.")
                    .foregroundStyle(.secondary)
            } else {
                Text(browser.statusMessage)
                    .foregroundStyle(.secondary)
            }
        } actions: {
            Button {
                NSApp.keyWindow?.performClose(nil)
            } label: {
                Label("Close", systemImage: "xmark")
            }
            Button {
                browser.copyMarkdownExport()
            } label: {
                Label("Copy Markdown Export", systemImage: "doc.on.doc")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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

        browser.clear()
    }
}
