import Foundation

public enum DictationDraftFormatter {
    public static func textWithTrailingSeparator(_ text: String) -> String {
        guard !text.isEmpty,
              text.last?.isWhitespace == false
        else {
            return text
        }

        return text + " "
    }
}

public enum TextInsertionPayload {
    public static func validated(_ text: String) throws -> String {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw TextInsertionError.emptyText
        }

        return text
    }
}
