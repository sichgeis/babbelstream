import Foundation

public enum DictationArchiveInsertionOutcome: String, Codable, Equatable, Sendable {
    case directAccessibilityInsertion
    case pasteShortcutPosted
    case copiedForManualPaste
    case copiedBecauseTargetChanged
    case copiedAfterPasteShortcutFailure
    case copiedAfterPasteFailure
    case memoryOnlyAfterPasteFailure

    public var displayName: String {
        switch self {
        case .directAccessibilityInsertion:
            "Direct Accessibility insertion"
        case .pasteShortcutPosted:
            "Paste shortcut posted"
        case .copiedForManualPaste:
            "Copied for manual paste"
        case .copiedBecauseTargetChanged:
            "Copied because target changed"
        case .copiedAfterPasteShortcutFailure:
            "Copied after paste shortcut failure"
        case .copiedAfterPasteFailure:
            "Copied after paste failure"
        case .memoryOnlyAfterPasteFailure:
            "Memory only after paste failure"
        }
    }
}

public struct DictationArchiveEntry: Codable, Equatable, Sendable, Identifiable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var id: UUID
    public var startedAt: Date
    public var completedAt: Date
    public var audioDurationSeconds: TimeInterval
    public var activeAppName: String?
    public var activeAppBundleIdentifier: String?
    public var cleanupEnabled: Bool
    public var cleanupFallbackUsed: Bool
    public var insertionOutcome: DictationArchiveInsertionOutcome
    public var transcriptionProviderLabel: String
    public var cleanupProviderLabel: String?
    public var transcriptionLanguage: String?
    public var rawWordCount: Int
    public var finalWordCount: Int
    public var finalDraftText: String
    public var rawTranscriptText: String?

    public init(
        schemaVersion: Int = DictationArchiveEntry.currentSchemaVersion,
        id: UUID = UUID(),
        startedAt: Date,
        completedAt: Date = Date(),
        audioDurationSeconds: TimeInterval,
        activeAppName: String? = nil,
        activeAppBundleIdentifier: String? = nil,
        cleanupEnabled: Bool,
        cleanupFallbackUsed: Bool,
        insertionOutcome: DictationArchiveInsertionOutcome,
        transcriptionProviderLabel: String,
        cleanupProviderLabel: String? = nil,
        transcriptionLanguage: String? = nil,
        rawWordCount: Int,
        finalWordCount: Int,
        finalDraftText: String,
        rawTranscriptText: String? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.id = id
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.audioDurationSeconds = audioDurationSeconds
        self.activeAppName = activeAppName
        self.activeAppBundleIdentifier = activeAppBundleIdentifier
        self.cleanupEnabled = cleanupEnabled
        self.cleanupFallbackUsed = cleanupFallbackUsed
        self.insertionOutcome = insertionOutcome
        self.transcriptionProviderLabel = transcriptionProviderLabel
        self.cleanupProviderLabel = cleanupProviderLabel
        self.transcriptionLanguage = transcriptionLanguage
        self.rawWordCount = max(0, rawWordCount)
        self.finalWordCount = max(0, finalWordCount)
        self.finalDraftText = finalDraftText
        self.rawTranscriptText = rawTranscriptText
    }
}

public struct DictationArchiveMonth: Equatable, Hashable, Sendable, Identifiable {
    public let year: Int
    public let month: Int

    public init?(year: Int, month: Int) {
        guard month >= 1, month <= 12 else {
            return nil
        }

        self.year = year
        self.month = month
    }

    public init?(string: String) {
        let parts = string.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: "-")
        guard parts.count == 2,
              parts[0].count == 4,
              let year = Int(parts[0]),
              let month = Int(parts[1])
        else {
            return nil
        }

        self.init(year: year, month: month)
    }

    public var id: String {
        directoryName
    }

    public var directoryName: String {
        String(format: "%04d-%02d", year, month)
    }

    public static func current(date: Date = Date(), calendar: Calendar = .current) -> DictationArchiveMonth {
        let components = calendar.dateComponents([.year, .month], from: date)
        return DictationArchiveMonth(
            year: components.year ?? 1970,
            month: components.month ?? 1
        )!
    }

    public static func containing(_ date: Date, calendar: Calendar = .current) -> DictationArchiveMonth {
        current(date: date, calendar: calendar)
    }
}

public struct DictationArchiveDaySummary: Equatable, Sendable, Identifiable {
    public let dateString: String
    public let entryCount: Int
    public let rawWordCount: Int
    public let finalWordCount: Int

    public var id: String {
        dateString
    }
}

public struct DictationArchiveMonthSnapshot: Equatable, Sendable {
    public let month: DictationArchiveMonth
    public let entries: [DictationArchiveEntry]
    public let dailySummaries: [DictationArchiveDaySummary]
    public let totalRawWordCount: Int
    public let totalFinalWordCount: Int

    public init(
        month: DictationArchiveMonth,
        entries: [DictationArchiveEntry],
        calendar: Calendar = .current
    ) {
        let sortedEntries = entries.sorted { lhs, rhs in
            if lhs.startedAt == rhs.startedAt {
                return lhs.id.uuidString < rhs.id.uuidString
            }

            return lhs.startedAt < rhs.startedAt
        }
        self.month = month
        self.entries = sortedEntries
        self.totalRawWordCount = sortedEntries.reduce(0) { $0 + $1.rawWordCount }
        self.totalFinalWordCount = sortedEntries.reduce(0) { $0 + $1.finalWordCount }

        var summariesByDay = [String: DictationArchiveDayAccumulator]()
        for entry in sortedEntries {
            let day = DictationArchiveDateFormatter.dayString(for: entry.startedAt, calendar: calendar)
            summariesByDay[day, default: DictationArchiveDayAccumulator()].add(entry)
        }

        self.dailySummaries = summariesByDay
            .map { day, accumulator in
                DictationArchiveDaySummary(
                    dateString: day,
                    entryCount: accumulator.entryCount,
                    rawWordCount: accumulator.rawWordCount,
                    finalWordCount: accumulator.finalWordCount
                )
            }
            .sorted { $0.dateString < $1.dateString }
    }
}

private struct DictationArchiveDayAccumulator {
    var entryCount = 0
    var rawWordCount = 0
    var finalWordCount = 0

    mutating func add(_ entry: DictationArchiveEntry) {
        entryCount += 1
        rawWordCount += entry.rawWordCount
        finalWordCount += entry.finalWordCount
    }
}

public enum DictationArchiveError: Error, Equatable, LocalizedError, Sendable {
    case unreadableLine(file: String, line: Int)

    public var errorDescription: String? {
        switch self {
        case let .unreadableLine(file, line):
            "Could not read archive entry \(line) in \(file)."
        }
    }
}

public protocol DictationArchiveStore: AnyObject {
    var archiveDirectoryURL: URL { get }

    func append(_ entry: DictationArchiveEntry) throws
    func loadMonth(_ month: DictationArchiveMonth) throws -> DictationArchiveMonthSnapshot
    func markdownExport(for snapshot: DictationArchiveMonthSnapshot) -> String
    func clearArchive() throws
}

public final class JSONLDictationArchiveStore: DictationArchiveStore {
    public let archiveDirectoryURL: URL

    private let fileManager: FileManager
    private let calendar: Calendar
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        archiveDirectoryURL: URL = DictationArchivePaths.defaultArchiveDirectoryURL(),
        fileManager: FileManager = .default,
        calendar: Calendar = .current
    ) {
        self.archiveDirectoryURL = archiveDirectoryURL
        self.fileManager = fileManager
        self.calendar = calendar

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    public func append(_ entry: DictationArchiveEntry) throws {
        let fileURL = dailyFileURL(for: entry.startedAt)
        try prepareDailyArchiveFile(at: fileURL)
        let data = try encoder.encode(entry) + Data("\n".utf8)
        try append(data, to: fileURL)
    }

    public func loadMonth(_ month: DictationArchiveMonth) throws -> DictationArchiveMonthSnapshot {
        let monthDirectoryURL = archiveDirectoryURL.appendingPathComponent(month.directoryName, isDirectory: true)
        guard fileManager.fileExists(atPath: monthDirectoryURL.path) else {
            return DictationArchiveMonthSnapshot(month: month, entries: [], calendar: calendar)
        }

        let entries = try archiveFileURLs(in: monthDirectoryURL)
            .flatMap { try archiveEntries(in: $0) }

        return DictationArchiveMonthSnapshot(month: month, entries: entries, calendar: calendar)
    }

    public func markdownExport(for snapshot: DictationArchiveMonthSnapshot) -> String {
        var lines = [
            "# BabbelStream Archive \(snapshot.month.directoryName)",
            "",
            "- Dictations: \(snapshot.entries.count)",
            "- Raw words: \(snapshot.totalRawWordCount)",
            "- Final words: \(snapshot.totalFinalWordCount)",
            "",
            "## Daily Totals",
            "",
            "| Date | Dictations | Raw words | Final words |",
            "| --- | ---: | ---: | ---: |"
        ]

        if snapshot.dailySummaries.isEmpty {
            lines.append("| \(snapshot.month.directoryName) | 0 | 0 | 0 |")
        } else {
            lines.append(
                contentsOf: snapshot.dailySummaries.map {
                    "| \($0.dateString) | \($0.entryCount) | \($0.rawWordCount) | \($0.finalWordCount) |"
                }
            )
        }

        lines.append(contentsOf: ["", "## Entries", ""])

        if snapshot.entries.isEmpty {
            lines.append("No archived dictations for this month.")
        } else {
            for entry in snapshot.entries {
                let timestamp = DictationArchiveDateFormatter.entryTimestampString(for: entry.startedAt)
                lines.append("### \(timestamp)\(appSuffix(for: entry))")
                lines.append("")
                lines.append("- Raw words: \(entry.rawWordCount)")
                lines.append("- Final words: \(entry.finalWordCount)")
                lines.append("- Duration: \(String(format: "%.1fs", entry.audioDurationSeconds))")
                lines.append("- Cleanup: \(cleanupSummary(for: entry))")
                lines.append("- Insertion: \(entry.insertionOutcome.displayName)")
                lines.append("")
                lines.append("```text")
                lines.append(fencedText(entry.finalDraftText))
                lines.append("```")
                if let rawTranscriptText = entry.rawTranscriptText,
                   !rawTranscriptText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    lines.append("")
                    lines.append("Raw transcript:")
                    lines.append("")
                    lines.append("```text")
                    lines.append(fencedText(rawTranscriptText))
                    lines.append("```")
                }
                lines.append("")
            }
        }

        return lines.joined(separator: "\n")
    }

    public func clearArchive() throws {
        guard fileManager.fileExists(atPath: archiveDirectoryURL.path) else {
            return
        }

        try fileManager.removeItem(at: archiveDirectoryURL)
    }

    private func dailyFileURL(for date: Date) -> URL {
        let month = DictationArchiveMonth.containing(date, calendar: calendar)
        let day = DictationArchiveDateFormatter.dayString(for: date, calendar: calendar)
        return archiveDirectoryURL
            .appendingPathComponent(month.directoryName, isDirectory: true)
            .appendingPathComponent(day)
            .appendingPathExtension("jsonl")
    }

    private func prepareDailyArchiveFile(at fileURL: URL) throws {
        try fileManager.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )

        guard !fileManager.fileExists(atPath: fileURL.path) else {
            return
        }

        fileManager.createFile(
            atPath: fileURL.path,
            contents: nil,
            attributes: [.posixPermissions: 0o600]
        )
    }

    private func append(_ data: Data, to fileURL: URL) throws {
        let handle = try FileHandle(forWritingTo: fileURL)
        defer {
            try? handle.close()
        }
        try handle.seekToEnd()
        try handle.write(contentsOf: data)
    }

    private func archiveFileURLs(in monthDirectoryURL: URL) throws -> [URL] {
        try fileManager
            .contentsOfDirectory(at: monthDirectoryURL, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "jsonl" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }

    private func archiveEntries(in fileURL: URL) throws -> [DictationArchiveEntry] {
        let data = try Data(contentsOf: fileURL)
        guard let text = String(data: data, encoding: .utf8) else {
            throw DictationArchiveError.unreadableLine(file: fileURL.lastPathComponent, line: 1)
        }

        return try text
            .split(separator: "\n", omittingEmptySubsequences: true)
            .enumerated()
            .map { lineIndex, line in
                do {
                    return try decoder.decode(DictationArchiveEntry.self, from: Data(line.utf8))
                } catch {
                    throw DictationArchiveError.unreadableLine(
                        file: fileURL.lastPathComponent,
                        line: lineIndex + 1
                    )
                }
            }
    }

    private func appSuffix(for entry: DictationArchiveEntry) -> String {
        guard let activeAppName = entry.activeAppName,
              !activeAppName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            return ""
        }

        return " - \(activeAppName)"
    }

    private func cleanupSummary(for entry: DictationArchiveEntry) -> String {
        if !entry.cleanupEnabled {
            return "Disabled"
        }

        return entry.cleanupFallbackUsed ? "Enabled, fallback used" : "Enabled"
    }

    private func fencedText(_ text: String) -> String {
        text.replacingOccurrences(of: "```", with: "'''")
    }
}

public enum DictationArchivePaths {
    public static func defaultArchiveDirectoryURL(fileManager: FileManager = .default) -> URL {
        let applicationSupportURL = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")

        return applicationSupportURL
            .appendingPathComponent(ProjectDefaults.appName, isDirectory: true)
            .appendingPathComponent("Archive", isDirectory: true)
    }
}

public enum DictationWordCounter {
    public static func count(in text: String) -> Int {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            return 0
        }

        var count = 0
        trimmed.enumerateSubstrings(in: trimmed.startIndex..<trimmed.endIndex, options: [.byWords, .localized]) {
            substring,
            _,
            _,
            _ in
            guard substring?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else {
                return
            }

            count += 1
        }

        return count
    }
}

private enum DictationArchiveDateFormatter {
    static func dayString(for date: Date, calendar: Calendar) -> String {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        return String(
            format: "%04d-%02d-%02d",
            components.year ?? 1970,
            components.month ?? 1,
            components.day ?? 1
        )
    }

    static func entryTimestampString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.string(from: date)
    }
}
