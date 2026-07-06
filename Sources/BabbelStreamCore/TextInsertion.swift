import AppKit
import ApplicationServices
import Foundation

public enum TextInsertionResult: Equatable, Sendable {
    case pasted
    case copiedForManualPaste
}

public enum TextInsertionError: Error, Equatable, LocalizedError, Sendable {
    case emptyText
    case pasteboardUnavailable
    case pasteEventFailed

    public var errorDescription: String? {
        switch self {
        case .emptyText:
            "There is no text to insert."
        case .pasteboardUnavailable:
            "The system clipboard is unavailable."
        case .pasteEventFailed:
            "Could not post the paste shortcut."
        }
    }
}

@MainActor
public protocol TextInsertionService: AnyObject {
    func accessibilityPermissionStatus() -> AccessibilityPermissionStatus
    func requestAccessibilityPermission()
    func insertText(_ text: String) async throws -> TextInsertionResult
    func copyText(_ text: String) throws
}

public enum AccessibilityPermissionStatus: String, Equatable, Sendable {
    case trusted
    case notTrusted

    public var displayName: String {
        switch self {
        case .trusted:
            "Allowed"
        case .notTrusted:
            "Not allowed"
        }
    }
}

@MainActor
public final class ClipboardTextInsertionService: TextInsertionService {
    private let pasteboard: NSPasteboard
    private let restoreDelaySeconds: TimeInterval

    public init(
        pasteboard: NSPasteboard = .general,
        restoreDelaySeconds: TimeInterval = ProjectDefaults.defaultPasteRestoreDelaySeconds
    ) {
        self.pasteboard = pasteboard
        self.restoreDelaySeconds = restoreDelaySeconds
    }

    public func accessibilityPermissionStatus() -> AccessibilityPermissionStatus {
        AXIsProcessTrusted() ? .trusted : .notTrusted
    }

    public func requestAccessibilityPermission() {
        let options = [
            "AXTrustedCheckOptionPrompt": true
        ] as CFDictionary
        _ = AXIsProcessTrustedWithOptions(options)
    }

    public func insertText(_ text: String) async throws -> TextInsertionResult {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            throw TextInsertionError.emptyText
        }

        let snapshot = ClipboardSnapshot.capture(from: pasteboard)
        let writtenChangeCount = try writeToClipboard(trimmedText)

        guard accessibilityPermissionStatus() == .trusted else {
            return .copiedForManualPaste
        }

        guard postPasteShortcut() else {
            return .copiedForManualPaste
        }

        await restoreClipboard(snapshot, ifCurrentChangeCountIs: writtenChangeCount)
        return .pasted
    }

    public func copyText(_ text: String) throws {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            throw TextInsertionError.emptyText
        }

        _ = try writeToClipboard(trimmedText)
    }

    private func writeToClipboard(_ text: String) throws -> Int {
        pasteboard.clearContents()
        guard pasteboard.setString(text, forType: .string) else {
            throw TextInsertionError.pasteboardUnavailable
        }

        return pasteboard.changeCount
    }

    private func postPasteShortcut() -> Bool {
        let keyCodeForV: CGKeyCode = 9
        let source = CGEventSource(stateID: .combinedSessionState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCodeForV, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCodeForV, keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand

        guard let keyDown, let keyUp else {
            return false
        }

        keyDown.post(tap: .cghidEventTap)
        keyUp.post(tap: .cghidEventTap)
        return true
    }

    private func restoreClipboard(
        _ snapshot: ClipboardSnapshot,
        ifCurrentChangeCountIs expectedChangeCount: Int
    ) async {
        let delay = UInt64(max(restoreDelaySeconds, 0) * 1_000_000_000)
        try? await Task.sleep(nanoseconds: delay)

        guard pasteboard.changeCount == expectedChangeCount else {
            return
        }

        snapshot.restore(to: pasteboard)
    }
}

public struct ClipboardSnapshot {
    private let items: [NSPasteboardItem]
    private let stringFallback: String?

    public static func capture(from pasteboard: NSPasteboard) -> ClipboardSnapshot {
        let copiedItems = pasteboard.pasteboardItems?.compactMap { item in
            item.copy() as? NSPasteboardItem
        } ?? []

        return ClipboardSnapshot(
            items: copiedItems,
            stringFallback: pasteboard.string(forType: .string)
        )
    }

    public func restore(to pasteboard: NSPasteboard) {
        pasteboard.clearContents()

        if !items.isEmpty {
            pasteboard.writeObjects(items)
        } else if let stringFallback {
            pasteboard.setString(stringFallback, forType: .string)
        }
    }
}
