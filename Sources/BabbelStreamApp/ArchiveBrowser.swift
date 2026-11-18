import AppKit
import BabbelStreamCore
import SwiftUI

@MainActor
final class ArchiveBrowser: ObservableObject {
    @Published var monthText: String
    @Published private(set) var snapshot: DictationArchiveMonthSnapshot
    @Published var statusMessage = "Archive not loaded yet."
    @Published var errorMessage: String?

    private let store: DictationArchiveStore
    private let clipboard: TextInsertionService
    var onAction: ((_ diagnostic: String, _ result: String?) -> Void)?

    init(store: DictationArchiveStore, clipboard: TextInsertionService) {
        self.store = store
        self.clipboard = clipboard
        let month = DictationArchiveMonth.current()
        monthText = month.directoryName
        snapshot = DictationArchiveMonthSnapshot(month: month, entries: [])
    }

    func loadMonth() {
        guard let month = DictationArchiveMonth(string: monthText) else {
            errorMessage = "Use a month in YYYY-MM format."
            statusMessage = "Archive month could not be loaded."
            onAction?("archive month load failed: invalid month", nil)
            return
        }

        do {
            let snapshot = try store.loadMonth(month)
            self.snapshot = snapshot
            monthText = month.directoryName
            errorMessage = nil
            let recoverySuffix = snapshot.readWarnings.isEmpty
                ? ""
                : " Skipped \(snapshot.readWarnings.count) damaged entr\(snapshot.readWarnings.count == 1 ? "y" : "ies")."
            statusMessage = "Loaded \(snapshot.entries.count) archive entr\(snapshot.entries.count == 1 ? "y" : "ies").\(recoverySuffix)"
            onAction?("archive month loaded: \(month.directoryName), \(snapshot.entries.count) entries, \(snapshot.readWarnings.count) skipped", nil)
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = "Archive month could not be loaded."
            onAction?("archive month load failed: \(String(describing: type(of: error)))", nil)
        }
    }

    func copyMarkdownExport() {
        guard let month = DictationArchiveMonth(string: monthText) else {
            errorMessage = "Use a month in YYYY-MM format."
            statusMessage = "Archive export could not be prepared."
            onAction?("archive export failed: invalid month", nil)
            return
        }

        do {
            let snapshot = try store.loadMonth(month)
            let markdown = store.markdownExport(for: snapshot)
            try clipboard.copyText(markdown)
            self.snapshot = snapshot
            monthText = month.directoryName
            errorMessage = nil
            statusMessage = snapshot.readWarnings.isEmpty
                ? "Archive Markdown export copied."
                : "Archive Markdown export copied with \(snapshot.readWarnings.count) damaged entr\(snapshot.readWarnings.count == 1 ? "y" : "ies") skipped."
            onAction?("archive export copied: \(month.directoryName), \(snapshot.entries.count) entries", "Archive Markdown export copied.")
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = "Archive export could not be copied."
            onAction?("archive export failed: \(String(describing: type(of: error)))", nil)
        }
    }

    func revealFolder() {
        let fileManager = FileManager.default
        let archiveURL = store.archiveDirectoryURL
        let fallbackURL = archiveURL.deletingLastPathComponent()

        if fileManager.fileExists(atPath: archiveURL.path) {
            NSWorkspace.shared.open(archiveURL)
            statusMessage = "Archive folder opened."
        } else if fileManager.fileExists(atPath: fallbackURL.path) {
            NSWorkspace.shared.open(fallbackURL)
            statusMessage = "Archive folder does not exist yet. Opened BabbelStream support folder."
        } else {
            NSWorkspace.shared.open(fallbackURL.deletingLastPathComponent())
            statusMessage = "Archive folder does not exist yet."
        }
        errorMessage = nil
        onAction?("archive folder reveal requested", nil)
    }

    func clear() {
        do {
            try store.clearArchive()
            let month = DictationArchiveMonth(string: monthText) ?? DictationArchiveMonth.current()
            snapshot = DictationArchiveMonthSnapshot(month: month, entries: [])
            errorMessage = nil
            statusMessage = "Archive cleared."
            onAction?("dictation archive cleared", "Dictation archive cleared.")
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = "Archive could not be cleared."
            onAction?("archive clear failed: \(String(describing: type(of: error)))", nil)
        }
    }
}
