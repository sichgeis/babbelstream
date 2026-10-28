import Foundation

/// Enforce explicitly taught spellings after inference. Matches are literal whole
/// phrases; replacements never cascade and URL/path tokens remain untouched. The
/// same context budget decides which entries are eligible for prompt and policy.
public enum LocalCleanupDictionary {
    public static func apply(to text: String, dictionary: PersonalDictionary) -> String {
        guard let context = DictionaryPromptBuilder.cleanupContextDetails(for: dictionary) else { return text }
        let lines = Set(context.text.components(separatedBy: "\n"))
        var entries = dictionary.enabledCorrections.filter { lines.contains("- \($0.from) => \($0.to)") }
            .map { ($0.from, $0.to) }
        entries += dictionary.enabledVocabulary.filter { lines.contains("- \($0.term)") }.map { ($0.term, $0.term) }
        let ordered = entries.enumerated().sorted {
            $0.element.0.count == $1.element.0.count ? $0.offset < $1.offset : $0.element.0.count > $1.element.0.count
        }
        let full = NSRange(text.startIndex..., in: text)
        let protected = (try? NSRegularExpression(pattern: #"\S*[/\\@]\S*"#))?
            .matches(in: text, range: full).map(\.range) ?? []
        var edits: [(NSRange, String)] = []
        for entry in ordered.map(\.element) where !entry.0.isEmpty {
            let pattern = #"(?<![\p{L}\p{N}_])"# + NSRegularExpression.escapedPattern(for: entry.0) + #"(?![\p{L}\p{N}_])"#
            guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else { continue }
            for match in regex.matches(in: text, range: full) {
                guard !protected.contains(where: { NSIntersectionRange($0, match.range).length > 0 }),
                      !edits.contains(where: { NSIntersectionRange($0.0, match.range).length > 0 }) else { continue }
                edits.append((match.range, entry.1))
            }
        }
        let result = NSMutableString(string: text)
        for edit in edits.sorted(by: { $0.0.location > $1.0.location }) {
            result.replaceCharacters(in: edit.0, with: edit.1)
        }
        return result as String
    }
}
