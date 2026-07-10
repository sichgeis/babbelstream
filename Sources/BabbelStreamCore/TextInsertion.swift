import AppKit
import ApplicationServices
import Foundation

public enum TextInsertionResult: Equatable, Sendable {
    case insertedDirectly
    case pasteShortcutPosted
    case copiedForManualPaste
    case copiedBecauseTargetChanged
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
    func captureTarget() -> TextInsertionTarget?
    func insertText(_ text: String, target: TextInsertionTarget?) async throws -> TextInsertionResult
    func copyText(_ text: String) throws
}

public final class AccessibilityElementReference: @unchecked Sendable {
    fileprivate let element: AXUIElement

    fileprivate init(element: AXUIElement) {
        self.element = element
    }
}

public struct TextInsertionTarget: Equatable, Sendable {
    public let processIdentifier: pid_t
    public let localizedName: String?
    public let bundleIdentifier: String?
    public let focusedElementReference: AccessibilityElementReference?

    public init(
        processIdentifier: pid_t,
        localizedName: String?,
        bundleIdentifier: String? = nil,
        focusedElementReference: AccessibilityElementReference? = nil
    ) {
        self.processIdentifier = processIdentifier
        self.localizedName = localizedName
        self.bundleIdentifier = bundleIdentifier
        self.focusedElementReference = focusedElementReference
    }

    public var displayName: String {
        localizedName?.isEmpty == false ? localizedName! : "previous app"
    }

    public static func == (lhs: TextInsertionTarget, rhs: TextInsertionTarget) -> Bool {
        guard lhs.processIdentifier == rhs.processIdentifier,
              lhs.localizedName == rhs.localizedName,
              lhs.bundleIdentifier == rhs.bundleIdentifier
        else {
            return false
        }

        switch (lhs.focusedElementReference, rhs.focusedElementReference) {
        case (nil, nil):
            return true
        case let (lhs?, rhs?):
            return CFEqual(lhs.element, rhs.element)
        default:
            return false
        }
    }
}

public enum TextInsertionTargetPolicy {
    public static func applicationMatches(
        _ target: TextInsertionTarget?,
        frontmostProcessIdentifier: pid_t?
    ) -> Bool {
        guard let target, let frontmostProcessIdentifier else {
            return false
        }

        return target.processIdentifier == frontmostProcessIdentifier
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

    public func captureTarget() -> TextInsertionTarget? {
        guard let application = NSWorkspace.shared.frontmostApplication else {
            return nil
        }

        let focusedElementReference = currentFocusedElement().map {
            AccessibilityElementReference(element: $0)
        }
        return TextInsertionTarget(
            processIdentifier: application.processIdentifier,
            localizedName: application.localizedName,
            bundleIdentifier: application.bundleIdentifier,
            focusedElementReference: focusedElementReference
        )
    }

    public func insertText(_ text: String, target: TextInsertionTarget?) async throws -> TextInsertionResult {
        try Task.checkCancellation()
        let insertionText = try TextInsertionPayload.validated(text)

        guard accessibilityPermissionStatus() == .trusted else {
            _ = try writeToClipboard(insertionText)
            return .copiedForManualPaste
        }

        guard targetIsStillFocused(target) else {
            try Task.checkCancellation()
            _ = try writeToClipboard(insertionText)
            return .copiedBecauseTargetChanged
        }

        try Task.checkCancellation()
        if !shouldSkipDirectAccessibilityInsertion(for: target),
           insertDirectlyIntoFocusedElement(insertionText, target: target) {
            return .insertedDirectly
        }

        _ = try writeToClipboard(insertionText)
        guard targetIsStillFocused(target) else {
            try Task.checkCancellation()
            return .copiedBecauseTargetChanged
        }
        await sleep(seconds: 0.15)
        try Task.checkCancellation()
        guard targetIsStillFocused(target) else {
            return .copiedBecauseTargetChanged
        }

        guard await postPasteShortcut() else {
            return .copiedAfterPasteShortcutFailure
        }

        return .pasteShortcutPosted
    }

    public func copyText(_ text: String) throws {
        let insertionText = try TextInsertionPayload.validated(text)

        _ = try writeToClipboard(insertionText)
    }

    private func writeToClipboard(_ text: String) throws -> Int {
        pasteboard.clearContents()
        guard pasteboard.setString(text, forType: .string) else {
            throw TextInsertionError.pasteboardUnavailable
        }

        return pasteboard.changeCount
    }

    private func targetIsStillFocused(_ target: TextInsertionTarget?) -> Bool {
        let frontmostProcessIdentifier = NSWorkspace.shared.frontmostApplication?.processIdentifier
        guard TextInsertionTargetPolicy.applicationMatches(
            target,
            frontmostProcessIdentifier: frontmostProcessIdentifier
        ), let target
        else {
            return false
        }

        guard let capturedElement = target.focusedElementReference else {
            return true
        }
        guard let focusedElement = currentFocusedElement() else {
            return false
        }

        return CFEqual(capturedElement.element, focusedElement)
    }

    private func currentFocusedElement() -> AXUIElement? {
        let systemWideElement = AXUIElementCreateSystemWide()
        var focusedElement: CFTypeRef?
        let copyResult = AXUIElementCopyAttributeValue(
            systemWideElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )

        guard copyResult == .success, let focusedElement else {
            return nil
        }

        guard CFGetTypeID(focusedElement) == AXUIElementGetTypeID() else {
            return nil
        }

        return (focusedElement as! AXUIElement)
    }

    private func insertDirectlyIntoFocusedElement(_ text: String, target: TextInsertionTarget?) -> Bool {
        guard targetIsStillFocused(target),
              let element = target?.focusedElementReference?.element ?? currentFocusedElement()
        else {
            return false
        }
        var selectedTextIsSettable = DarwinBoolean(false)
        let settableResult = AXUIElementIsAttributeSettable(
            element,
            kAXSelectedTextAttribute as CFString,
            &selectedTextIsSettable
        )

        guard settableResult == .success, selectedTextIsSettable.boolValue else {
            return false
        }

        let setResult = AXUIElementSetAttributeValue(
            element,
            kAXSelectedTextAttribute as CFString,
            text as CFTypeRef
        )

        return setResult == .success
    }

    private func shouldSkipDirectAccessibilityInsertion(for target: TextInsertionTarget?) -> Bool {
        guard let bundleIdentifier = target?.bundleIdentifier?.lowercased() else {
            return false
        }

        return Self.richEmailEditorBundleIdentifiers.contains(bundleIdentifier)
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
        await sleep(seconds: 0.08)
        keyUp.post(tap: .cghidEventTap)
        return true
    }

    private func sleep(seconds: TimeInterval) async {
        let nanoseconds = UInt64(max(seconds, 0) * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanoseconds)
    }

    private static let richEmailEditorBundleIdentifiers: Set<String> = [
        "com.apple.mail",
        "com.microsoft.outlook"
    ]
}
