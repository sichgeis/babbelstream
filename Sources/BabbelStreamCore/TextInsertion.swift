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
    public let bundleIdentifier: String?

    public init(processIdentifier: pid_t, localizedName: String?, bundleIdentifier: String? = nil) {
        self.processIdentifier = processIdentifier
        self.localizedName = localizedName
        self.bundleIdentifier = bundleIdentifier
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
        let insertionText = try TextInsertionPayload.validated(text)

        guard accessibilityPermissionStatus() == .trusted else {
            _ = try writeToClipboard(insertionText)
            return .copiedForManualPaste
        }

        guard await prepareTargetForInsertion(target) else {
            _ = try writeToClipboard(insertionText)
            return .copiedAfterPasteShortcutFailure
        }

        if !shouldSkipDirectAccessibilityInsertion(for: target),
           insertDirectlyIntoFocusedElement(insertionText) {
            return .insertedDirectly
        }

        _ = try writeToClipboard(insertionText)
        guard await prepareTargetForInsertion(target) else {
            return .copiedAfterPasteShortcutFailure
        }
        await sleep(seconds: 0.15)

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

    private func prepareTargetForInsertion(_ target: TextInsertionTarget?) async -> Bool {
        guard let target,
              let application = NSRunningApplication(processIdentifier: target.processIdentifier),
              !application.isTerminated
        else {
            return true
        }

        if !application.isActive {
            application.activate(options: [.activateIgnoringOtherApps])
        }

        let didActivate = await waitForActivation(of: application, timeout: 1.0)
        await sleep(seconds: 0.1)
        return didActivate
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

    private func waitForActivation(
        of application: NSRunningApplication,
        timeout: TimeInterval
    ) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if application.isActive ||
                NSWorkspace.shared.frontmostApplication?.processIdentifier == application.processIdentifier {
                return true
            }

            await sleep(seconds: 0.05)
        }

        return application.isActive ||
            NSWorkspace.shared.frontmostApplication?.processIdentifier == application.processIdentifier
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
