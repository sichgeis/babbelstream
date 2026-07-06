import AppKit
import ApplicationServices
import Foundation

public enum TextInsertionResult: Equatable, Sendable {
    case insertedDirectly
    case pasteShortcutPosted
    case copiedForManualPaste
    case copiedAfterPasteShortcutFailure
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
    func insertText(_ text: String, target: TextInsertionTarget?) async throws -> TextInsertionResult
    func copyText(_ text: String) throws
}

public struct TextInsertionTarget: Equatable, Sendable {
    public let processIdentifier: pid_t
    public let localizedName: String?

    public init(processIdentifier: pid_t, localizedName: String?) {
        self.processIdentifier = processIdentifier
        self.localizedName = localizedName
    }

    public var displayName: String {
        localizedName?.isEmpty == false ? localizedName! : "previous app"
    }
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

    public init(
        pasteboard: NSPasteboard = .general
    ) {
        self.pasteboard = pasteboard
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

    public func insertText(_ text: String, target: TextInsertionTarget?) async throws -> TextInsertionResult {
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else {
            throw TextInsertionError.emptyText
        }

        guard accessibilityPermissionStatus() == .trusted else {
            _ = try writeToClipboard(trimmedText)
            return .copiedForManualPaste
        }

        await prepareTargetForInsertion(target)

        if insertDirectlyIntoFocusedElement(trimmedText) {
            return .insertedDirectly
        }

        _ = try writeToClipboard(trimmedText)

        guard await postPasteShortcut() else {
            return .copiedAfterPasteShortcutFailure
        }

        return .pasteShortcutPosted
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

    private func prepareTargetForInsertion(_ target: TextInsertionTarget?) async {
        guard let target,
              let application = NSRunningApplication(processIdentifier: target.processIdentifier),
              !application.isTerminated
        else {
            return
        }

        if !application.isActive {
            application.activate(options: [.activateIgnoringOtherApps])
            await sleep(seconds: 0.25)
        }
    }

    private func insertDirectlyIntoFocusedElement(_ text: String) -> Bool {
        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElement: CFTypeRef?
        let copyResult = AXUIElementCopyAttributeValue(
            systemWideElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )

        guard copyResult == .success, let focusedElement else {
            return false
        }

        guard CFGetTypeID(focusedElement) == AXUIElementGetTypeID() else {
            return false
        }

        let element = focusedElement as! AXUIElement
        let setResult = AXUIElementSetAttributeValue(
            element,
            kAXSelectedTextAttribute as CFString,
            text as CFTypeRef
        )

        return setResult == .success
    }

    private func postPasteShortcut() async -> Bool {
        let keyCodeForV: CGKeyCode = 9
        let source = CGEventSource(stateID: .hidSystemState)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCodeForV, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCodeForV, keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand

        guard let keyDown, let keyUp else {
            return false
        }

        keyDown.post(tap: .cghidEventTap)
        await sleep(seconds: 0.05)
        keyUp.post(tap: .cghidEventTap)
        return true
    }

    private func sleep(seconds: TimeInterval) async {
        let nanoseconds = UInt64(max(seconds, 0) * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanoseconds)
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
