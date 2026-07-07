import Foundation

public struct PersonalDictionary: Codable, Equatable, Sendable {
    public static let currentVersion = 1

    public var version: Int
    public var vocabulary: [PersonalVocabularyEntry]
    public var corrections: [PersonalCorrectionEntry]

    public init(
        version: Int = PersonalDictionary.currentVersion,
        vocabulary: [PersonalVocabularyEntry] = [],
        corrections: [PersonalCorrectionEntry] = []
    ) {
        self.version = version
        self.vocabulary = vocabulary
        self.corrections = corrections
    }

    public var enabledVocabulary: [PersonalVocabularyEntry] {
        vocabulary.filter(\.enabled)
    }

    public var enabledCorrections: [PersonalCorrectionEntry] {
        corrections.filter(\.enabled)
    }

    public var isEmpty: Bool {
        enabledVocabulary.isEmpty && enabledCorrections.isEmpty
    }
}

public struct PersonalVocabularyEntry: Codable, Equatable, Sendable {
    public var term: String
    public var notes: String?
    public var enabled: Bool

    public init(term: String, notes: String? = nil, enabled: Bool = true) {
        self.term = term
        self.notes = notes
        self.enabled = enabled
    }
}

public struct PersonalCorrectionEntry: Codable, Equatable, Sendable {
    public var from: String
    public var to: String
    public var enabled: Bool

    public init(from: String, to: String, enabled: Bool = true) {
        self.from = from
        self.to = to
        self.enabled = enabled
    }
}

public enum PersonalDictionaryError: Error, Equatable, LocalizedError, Sendable {
    case emptyVocabularyTerm
    case emptyCorrectionValue
    case invalidCorrectionLine(Int)

    public var errorDescription: String? {
        switch self {
        case .emptyVocabularyTerm:
            "Vocabulary terms must not be empty."
        case .emptyCorrectionValue:
            "Correction pairs must include both a wrong and corrected value."
        case let .invalidCorrectionLine(line):
            "Correction line \(line) must use the format wrong => correct."
        }
    }
}

public protocol PersonalDictionaryStore: AnyObject {
    var fileURL: URL { get }
    func load() throws -> PersonalDictionary
    func save(_ dictionary: PersonalDictionary) throws
}

public final class JSONPersonalDictionaryStore: PersonalDictionaryStore {
    public let fileURL: URL

    private let fileManager: FileManager
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        fileURL: URL = PersonalDictionaryPaths.defaultFileURL(),
        fileManager: FileManager = .default
    ) {
        self.fileURL = fileURL
        self.fileManager = fileManager

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        self.encoder = encoder
        self.decoder = JSONDecoder()
    }

    public func load() throws -> PersonalDictionary {
        guard fileManager.fileExists(atPath: fileURL.path) else {
            return PersonalDictionary()
        }

        let data = try Data(contentsOf: fileURL)
        return try decoder.decode(PersonalDictionary.self, from: data)
    }

    public func save(_ dictionary: PersonalDictionary) throws {
        try PersonalDictionaryValidator.validate(dictionary)
        try fileManager.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        let data = try encoder.encode(dictionary)
        try data.write(to: fileURL, options: .atomic)
    }
}

public enum PersonalDictionaryPaths {
    public static func defaultFileURL(fileManager: FileManager = .default) -> URL {
        let applicationSupportURL = fileManager.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")

        return applicationSupportURL
            .appendingPathComponent(ProjectDefaults.appName, isDirectory: true)
            .appendingPathComponent("personal-dictionary.json")
    }
}

public enum PersonalDictionaryValidator {
    public static func validate(_ dictionary: PersonalDictionary) throws {
        for entry in dictionary.vocabulary where entry.term.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            throw PersonalDictionaryError.emptyVocabularyTerm
        }

        for correction in dictionary.corrections {
            let from = correction.from.trimmingCharacters(in: .whitespacesAndNewlines)
            let to = correction.to.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !from.isEmpty, !to.isEmpty else {
                throw PersonalDictionaryError.emptyCorrectionValue
            }
        }
    }
}

public enum PersonalDictionaryTextCodec {
    @discardableResult
    public static func upsertCorrection(
        from wrong: String,
        to correct: String,
        in dictionary: inout PersonalDictionary
    ) throws -> Bool {
        let from = wrong.trimmingCharacters(in: .whitespacesAndNewlines)
        let to = correct.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !from.isEmpty, !to.isEmpty else {
            throw PersonalDictionaryError.emptyCorrectionValue
        }

        let key = correctionKey(from: from, to: to)
        for index in dictionary.corrections.indices {
            guard correctionKey(
                from: dictionary.corrections[index].from,
                to: dictionary.corrections[index].to
            ) == key else {
                continue
            }

            dictionary.corrections[index].from = from
            dictionary.corrections[index].to = to
            dictionary.corrections[index].enabled = true
            return false
        }

        dictionary.corrections.append(PersonalCorrectionEntry(from: from, to: to))
        return true
    }

    public static func vocabularyText(from dictionary: PersonalDictionary) -> String {
        dictionary.vocabulary
            .filter(\.enabled)
            .map(\.term)
            .joined(separator: "\n")
    }

    public static func correctionsText(from dictionary: PersonalDictionary) -> String {
        dictionary.corrections
            .filter(\.enabled)
            .map { "\($0.from) => \($0.to)" }
            .joined(separator: "\n")
    }

    public static func dictionary(
        vocabularyText: String,
        correctionsText: String,
        preserving existing: PersonalDictionary = PersonalDictionary()
    ) throws -> PersonalDictionary {
        let vocabulary = parseVocabulary(vocabularyText, preserving: existing.vocabulary)
        let corrections = try parseCorrections(correctionsText, preserving: existing.corrections)
        return PersonalDictionary(vocabulary: vocabulary, corrections: corrections)
    }

    private static func parseVocabulary(
        _ text: String,
        preserving existing: [PersonalVocabularyEntry]
    ) -> [PersonalVocabularyEntry] {
        let existingByKey = vocabularyByKey(existing)

        return text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .uniquedByNormalizedKey()
            .map { term in
                var entry = existingByKey[normalizedKey(term)] ?? PersonalVocabularyEntry(term: term)
                entry.term = term
                entry.enabled = true
                return entry
            }
    }

    private static func parseCorrections(
        _ text: String,
        preserving existing: [PersonalCorrectionEntry]
    ) throws -> [PersonalCorrectionEntry] {
        let existingByKey = correctionsByKey(existing)
        var parsed: [PersonalCorrectionEntry] = []
        var seenKeys = Set<String>()

        for (index, rawLine) in text.components(separatedBy: .newlines).enumerated() {
            let line = rawLine.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !line.isEmpty else {
                continue
            }

            guard let separatorRange = line.range(of: "=>") else {
                throw PersonalDictionaryError.invalidCorrectionLine(index + 1)
            }

            let from = line[..<separatorRange.lowerBound].trimmingCharacters(in: .whitespacesAndNewlines)
            let to = line[separatorRange.upperBound...].trimmingCharacters(in: .whitespacesAndNewlines)
            guard !from.isEmpty, !to.isEmpty else {
                throw PersonalDictionaryError.emptyCorrectionValue
            }

            let key = correctionKey(from: from, to: to)
            guard !seenKeys.contains(key) else {
                continue
            }

            var correction = existingByKey[key] ?? PersonalCorrectionEntry(from: from, to: to)
            correction.from = from
            correction.to = to
            correction.enabled = true
            parsed.append(correction)
            seenKeys.insert(key)
        }

        return parsed
    }

    private static func normalizedKey(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private static func correctionKey(from: String, to: String) -> String {
        "\(normalizedKey(from))=>\(normalizedKey(to))"
    }

    private static func vocabularyByKey(_ entries: [PersonalVocabularyEntry]) -> [String: PersonalVocabularyEntry] {
        var result: [String: PersonalVocabularyEntry] = [:]
        for entry in entries {
            result[normalizedKey(entry.term)] = entry
        }
        return result
    }

    private static func correctionsByKey(_ entries: [PersonalCorrectionEntry]) -> [String: PersonalCorrectionEntry] {
        var result: [String: PersonalCorrectionEntry] = [:]
        for entry in entries {
            result[correctionKey(from: entry.from, to: entry.to)] = entry
        }
        return result
    }
}

public enum DictionaryPromptBuilder {
    public struct Context: Equatable, Sendable {
        public let text: String
        public let includedVocabularyCount: Int
        public let includedCorrectionsCount: Int
        public let skippedVocabularyCount: Int
        public let skippedCorrectionsCount: Int

        public var wasTruncated: Bool {
            skippedVocabularyCount > 0 || skippedCorrectionsCount > 0
        }
    }

    public static func cleanupSystemPrompt(
        basePrompt: String = CleanupPrompt.slackReady,
        dictionary: PersonalDictionary
    ) -> String {
        guard let context = cleanupContextDetails(for: dictionary) else {
            return basePrompt
        }

        return "\(basePrompt)\n\n\(context.text)"
    }

    public static func cleanupContext(for dictionary: PersonalDictionary) -> String? {
        cleanupContextDetails(for: dictionary)?.text
    }

    public static func cleanupContextDetails(
        for dictionary: PersonalDictionary,
        maxCharacters: Int = ProjectDefaults.maxPersonalDictionaryPromptCharacters
    ) -> Context? {
        guard !dictionary.isEmpty else {
            return nil
        }

        var lines = [
            "Personal dictionary context:",
            "- Use these entries as spelling and terminology hints while cleaning the transcript.",
            "- Preserve exact spelling and casing when the transcript likely refers to one of these entries.",
            "- Treat correction hints as wrong => preferred wording, without changing the speaker's meaning or language."
        ]

        var includedVocabularyCount = 0
        var includedCorrectionsCount = 0
        var skippedVocabularyCount = 0
        var skippedCorrectionsCount = 0

        let vocabulary = dictionary.enabledVocabulary.map(\.term)
        if !vocabulary.isEmpty {
            if appendLine("Preferred vocabulary:", to: &lines, maxCharacters: maxCharacters) {
                for term in vocabulary {
                    if appendLine("- \(term)", to: &lines, maxCharacters: maxCharacters) {
                        includedVocabularyCount += 1
                    } else {
                        skippedVocabularyCount += 1
                    }
                }
            } else {
                skippedVocabularyCount = vocabulary.count
            }
        }

        let corrections = dictionary.enabledCorrections
        if !corrections.isEmpty {
            if appendLine("Correction hints:", to: &lines, maxCharacters: maxCharacters) {
                for correction in corrections {
                    if appendLine("- \(correction.from) => \(correction.to)", to: &lines, maxCharacters: maxCharacters) {
                        includedCorrectionsCount += 1
                    } else {
                        skippedCorrectionsCount += 1
                    }
                }
            } else {
                skippedCorrectionsCount = corrections.count
            }
        }

        if skippedVocabularyCount > 0 || skippedCorrectionsCount > 0 {
            _ = appendLine(
                "Some personal dictionary entries were omitted because the dictionary prompt context reached its local size limit.",
                to: &lines,
                maxCharacters: maxCharacters + 500
            )
        }

        return Context(
            text: lines.joined(separator: "\n"),
            includedVocabularyCount: includedVocabularyCount,
            includedCorrectionsCount: includedCorrectionsCount,
            skippedVocabularyCount: skippedVocabularyCount,
            skippedCorrectionsCount: skippedCorrectionsCount
        )
    }

    private static func appendLine(_ line: String, to lines: inout [String], maxCharacters: Int) -> Bool {
        let currentLength = lines.joined(separator: "\n").count
        let separatorLength = lines.isEmpty ? 0 : 1
        guard currentLength + separatorLength + line.count <= maxCharacters else {
            return false
        }

        lines.append(line)
        return true
    }
}

private extension Array where Element == String {
    func uniquedByNormalizedKey() -> [String] {
        var seen = Set<String>()
        var result: [String] = []

        for value in self {
            let key = value.lowercased()
            guard !seen.contains(key) else {
                continue
            }

            result.append(value)
            seen.insert(key)
        }

        return result
    }
}
