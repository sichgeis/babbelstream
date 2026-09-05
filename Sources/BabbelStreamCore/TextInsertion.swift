import AppKit
import ApplicationServices
import Foundation

public enum TextInsertionResult: Equatable, Sendable {
    case insertedDirectly
    case pasteShortcutPosted
    case copiedForManualPaste
    case copiedBecauseTargetChanged
    case copiedAfterPasteShortcutFailure
    case clipboardChanged
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

public struct TextInsertionTarget: Equatable, Sendable {
    public let processIdentifier: pid_t
    public let localizedName: String?
    public let bundleIdentifier: String?

    public init(
        processIdentifier: pid_t,
        localizedName: String?,
        bundleIdentifier: String? = nil
    ) {
        self.processIdentifier = processIdentifier
        self.localizedName = localizedName
        self.bundleIdentifier = bundleIdentifier
    }

    public var displayName: String {
        guard let localizedName, !localizedName.isEmpty else {
            return "previous app"
        }

        return localizedName
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

public enum TextInsertionStrategyPolicy {
    public static func prefersPasteShortcut(forBundleIdentifier bundleIdentifier: String?) -> Bool {
        guard let bundleIdentifier = normalized(bundleIdentifier) else {
            return false
        }

        return clipboardPreferredBundleIdentifiers.contains(bundleIdentifier)
            || bundleIdentifier == chromeBundleIdentifierPrefix
            || bundleIdentifier.hasPrefix("\(chromeBundleIdentifierPrefix).")
    }

    private static func normalized(_ bundleIdentifier: String?) -> String? {
        guard let normalized = bundleIdentifier?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased(),
            !normalized.isEmpty
        else {
            return nil
        }

        return normalized
    }

    private static let chromeBundleIdentifierPrefix = "com.google.chrome"

    private static let clipboardPreferredBundleIdentifiers: Set<String> = [
        "com.apple.mail",
        "com.microsoft.outlook",
        "com.openai.chat",
        "com.openai.chatgpt",
        "com.openai.codex",
        "org.whispersystems.signal-desktop",
        "company.thebrowser.browser"
    ]
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
public protocol TextInsertionEnvironment: AnyObject {
    var clipboardChangeCount: Int { get }
    func accessibilityPermissionStatus() -> AccessibilityPermissionStatus
    func requestAccessibilityPermission()
    func captureTarget() -> TextInsertionTarget?
    func insertDirectlyIntoFocusedElement(_ text: String, target: TextInsertionTarget?) -> Bool
    func writeToClipboard(_ text: String) throws -> Int
    func waitForPastePreparation() async throws
    func postPasteShortcut() async -> Bool
}

@MainActor
public final class ClipboardTextInsertionService: TextInsertionService {
    private let environment: any TextInsertionEnvironment

    public init(pasteboard: NSPasteboard = .general) {
        environment = MacOSTextInsertionEnvironment(pasteboard: pasteboard)
    }

    public init(environment: any TextInsertionEnvironment) {
        self.environment = environment
    }

    public func accessibilityPermissionStatus() -> AccessibilityPermissionStatus {
        environment.accessibilityPermissionStatus()
    }

    public func requestAccessibilityPermission() { environment.requestAccessibilityPermission() }
    public func captureTarget() -> TextInsertionTarget? { environment.captureTarget() }

    public func insertText(_ text: String, target: TextInsertionTarget?) async throws -> TextInsertionResult {
        try Task.checkCancellation()
        let insertionText = try TextInsertionPayload.validated(text)
        guard accessibilityPermissionStatus() == .trusted else {
            _ = try environment.writeToClipboard(insertionText)
            return .copiedForManualPaste
        }
        guard targetIsStillFocused(target) else {
            _ = try environment.writeToClipboard(insertionText)
            return .copiedBecauseTargetChanged
        }
        if !TextInsertionStrategyPolicy.prefersPasteShortcut(forBundleIdentifier: target?.bundleIdentifier),
           environment.insertDirectlyIntoFocusedElement(insertionText, target: target) {
            return .insertedDirectly
        }
        let writtenChangeCount = try environment.writeToClipboard(insertionText)
        try await environment.waitForPastePreparation()
        try Task.checkCancellation()
        // Prefer this outcome if both clipboard and application changed: the draft
        // is no longer on the clipboard, so a "Copied" instruction would be false.
        guard environment.clipboardChangeCount == writtenChangeCount else { return .clipboardChanged }
        guard targetIsStillFocused(target) else { return .copiedBecauseTargetChanged }
        guard await environment.postPasteShortcut() else { return .copiedAfterPasteShortcutFailure }
        return .pasteShortcutPosted
    }

    public func copyText(_ text: String) throws {
        _ = try environment.writeToClipboard(TextInsertionPayload.validated(text))
    }

    private func targetIsStillFocused(_ target: TextInsertionTarget?) -> Bool {
        TextInsertionTargetPolicy.applicationMatches(target, frontmostProcessIdentifier: environment.captureTarget()?.processIdentifier)
    }
}

@MainActor
private final class MacOSTextInsertionEnvironment: TextInsertionEnvironment {
    private let pasteboard: NSPasteboard
    var clipboardChangeCount: Int { pasteboard.changeCount }

    func waitForPastePreparation() async throws {
        try await Task.sleep(nanoseconds: 150_000_000)
    }

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

        return TextInsertionTarget(
            processIdentifier: application.processIdentifier,
            localizedName: application.localizedName,
            bundleIdentifier: application.bundleIdentifier
        )
    }

    func writeToClipboard(_ text: String) throws -> Int {
        pasteboard.clearContents()
        guard pasteboard.setString(text, forType: .string) else {
            throw TextInsertionError.pasteboardUnavailable
        }

        return pasteboard.changeCount
    }

    private func targetIsStillFocused(_ target: TextInsertionTarget?) -> Bool {
        let frontmostProcessIdentifier = NSWorkspace.shared.frontmostApplication?.processIdentifier
        return TextInsertionTargetPolicy.applicationMatches(
            target,
            frontmostProcessIdentifier: frontmostProcessIdentifier
        )
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

    func insertDirectlyIntoFocusedElement(_ text: String, target: TextInsertionTarget?) -> Bool {
        guard targetIsStillFocused(target),
              let focusedElement = currentFocusedElement()
        else {
            return false
        }
        var selectedTextIsSettable = DarwinBoolean(false)
        let settableResult = AXUIElementIsAttributeSettable(
            focusedElement,
            kAXSelectedTextAttribute as CFString,
            &selectedTextIsSettable
        )

        guard settableResult == .success, selectedTextIsSettable.boolValue else {
            return false
        }

        let setResult = AXUIElementSetAttributeValue(
            focusedElement,
            kAXSelectedTextAttribute as CFString,
            text as CFTypeRef
        )

        return setResult == .success
    }

    func postPasteShortcut() async -> Bool {
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
}
