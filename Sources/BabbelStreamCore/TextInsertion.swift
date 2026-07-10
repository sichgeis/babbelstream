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

public struct AccessibilityElementFrame: Equatable, Sendable {
    public let x: Double
    public let y: Double
    public let width: Double
    public let height: Double

    public init(x: Double, y: Double, width: Double, height: Double) {
        self.x = x
        self.y = y
        self.width = width
        self.height = height
    }
}

public struct AccessibilityElementFingerprint: Equatable, Sendable {
    public let role: String?
    public let subrole: String?
    public let identifier: String?
    public let domIdentifier: String?
    public let frame: AccessibilityElementFrame?
    public let ancestorRoles: [String]

    public init(
        role: String?,
        subrole: String? = nil,
        identifier: String? = nil,
        domIdentifier: String? = nil,
        frame: AccessibilityElementFrame? = nil,
        ancestorRoles: [String] = []
    ) {
        self.role = role
        self.subrole = subrole
        self.identifier = identifier
        self.domIdentifier = domIdentifier
        self.frame = frame
        self.ancestorRoles = ancestorRoles
    }
}

public struct TextInsertionTarget: Equatable, Sendable {
    public let processIdentifier: pid_t
    public let localizedName: String?
    public let bundleIdentifier: String?
    public let focusedElementReference: AccessibilityElementReference?
    public let focusedElementFingerprint: AccessibilityElementFingerprint?

    public init(
        processIdentifier: pid_t,
        localizedName: String?,
        bundleIdentifier: String? = nil,
        focusedElementReference: AccessibilityElementReference? = nil,
        focusedElementFingerprint: AccessibilityElementFingerprint? = nil
    ) {
        self.processIdentifier = processIdentifier
        self.localizedName = localizedName
        self.bundleIdentifier = bundleIdentifier
        self.focusedElementReference = focusedElementReference
        self.focusedElementFingerprint = focusedElementFingerprint
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

    public static func replacementElementMatches(
        captured: AccessibilityElementFingerprint?,
        current: AccessibilityElementFingerprint?
    ) -> Bool {
        guard let captured, let current,
              let capturedRole = captured.role,
              !capturedRole.isEmpty,
              capturedRole == current.role,
              captured.subrole == current.subrole
        else {
            return false
        }

        guard captured.ancestorRoles == current.ancestorRoles,
              !captured.ancestorRoles.isEmpty
        else {
            return false
        }

        if let capturedDOMIdentifier = normalized(captured.domIdentifier),
           let currentDOMIdentifier = normalized(current.domIdentifier) {
            return capturedDOMIdentifier == currentDOMIdentifier
        }

        if let capturedIdentifier = normalized(captured.identifier),
           let currentIdentifier = normalized(current.identifier),
           capturedIdentifier == currentIdentifier {
            return true
        }

        guard let capturedFrame = captured.frame,
              let currentFrame = current.frame
        else {
            return false
        }

        return framesMatch(capturedFrame, currentFrame)
    }

    private static func normalized(_ value: String?) -> String? {
        guard let normalized = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !normalized.isEmpty
        else {
            return nil
        }
        return normalized
    }

    private static func framesMatch(
        _ captured: AccessibilityElementFrame,
        _ current: AccessibilityElementFrame
    ) -> Bool {
        abs(captured.x - current.x) <= 2
            && abs(captured.y - current.y) <= 2
            && abs(captured.width - current.width) <= 4
            && abs(captured.height - current.height) <= 4
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

        let focusedElement = currentFocusedElement()
        let focusedElementReference = focusedElement.map(AccessibilityElementReference.init)
        let focusedElementFingerprint = focusedElement.map(accessibilityFingerprint)
        return TextInsertionTarget(
            processIdentifier: application.processIdentifier,
            localizedName: application.localizedName,
            bundleIdentifier: application.bundleIdentifier,
            focusedElementReference: focusedElementReference,
            focusedElementFingerprint: focusedElementFingerprint
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
        guard let focusedElement = currentFocusedElement() else {
            return false
        }

        return targetIsStillFocused(target, focusedElement: focusedElement)
    }

    private func targetIsStillFocused(
        _ target: TextInsertionTarget?,
        focusedElement: AXUIElement
    ) -> Bool {
        let frontmostProcessIdentifier = NSWorkspace.shared.frontmostApplication?.processIdentifier
        guard TextInsertionTargetPolicy.applicationMatches(
            target,
            frontmostProcessIdentifier: frontmostProcessIdentifier
        ), let target
        else {
            return false
        }

        guard let capturedElement = target.focusedElementReference else {
            return false
        }

        if CFEqual(capturedElement.element, focusedElement) {
            return true
        }

        return TextInsertionTargetPolicy.replacementElementMatches(
            captured: target.focusedElementFingerprint,
            current: accessibilityFingerprint(for: focusedElement)
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

    private func accessibilityFingerprint(for element: AXUIElement) -> AccessibilityElementFingerprint {
        AccessibilityElementFingerprint(
            role: stringAttribute(kAXRoleAttribute as CFString, of: element),
            subrole: stringAttribute(kAXSubroleAttribute as CFString, of: element),
            identifier: stringAttribute(kAXIdentifierAttribute as CFString, of: element),
            domIdentifier: stringAttribute("AXDOMIdentifier" as CFString, of: element),
            frame: frame(of: element),
            ancestorRoles: ancestorRoles(of: element)
        )
    }

    private func stringAttribute(_ attribute: CFString, of element: AXUIElement) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute, &value) == .success,
              let string = value as? String
        else {
            return nil
        }

        let normalized = string.trimmingCharacters(in: .whitespacesAndNewlines)
        return normalized.isEmpty ? nil : normalized
    }

    private func frame(of element: AXUIElement) -> AccessibilityElementFrame? {
        var positionValue: CFTypeRef?
        var sizeValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            element,
            kAXPositionAttribute as CFString,
            &positionValue
        ) == .success,
            AXUIElementCopyAttributeValue(
                element,
                kAXSizeAttribute as CFString,
                &sizeValue
            ) == .success,
            let positionValue,
            let sizeValue,
            CFGetTypeID(positionValue) == AXValueGetTypeID(),
            CFGetTypeID(sizeValue) == AXValueGetTypeID()
        else {
            return nil
        }

        let positionAXValue = positionValue as! AXValue
        let sizeAXValue = sizeValue as! AXValue
        var position = CGPoint.zero
        var size = CGSize.zero
        guard AXValueGetValue(positionAXValue, .cgPoint, &position),
              AXValueGetValue(sizeAXValue, .cgSize, &size)
        else {
            return nil
        }

        return AccessibilityElementFrame(
            x: position.x,
            y: position.y,
            width: size.width,
            height: size.height
        )
    }

    private func ancestorRoles(of element: AXUIElement) -> [String] {
        var roles: [String] = []
        var currentElement = element

        for _ in 0..<6 {
            var parentValue: CFTypeRef?
            guard AXUIElementCopyAttributeValue(
                currentElement,
                kAXParentAttribute as CFString,
                &parentValue
            ) == .success,
                let parentValue,
                CFGetTypeID(parentValue) == AXUIElementGetTypeID()
            else {
                break
            }

            let parent = parentValue as! AXUIElement
            if let role = stringAttribute(kAXRoleAttribute as CFString, of: parent) {
                roles.append(role)
            }
            currentElement = parent
        }

        return roles
    }

    private func insertDirectlyIntoFocusedElement(_ text: String, target: TextInsertionTarget?) -> Bool {
        guard let focusedElement = currentFocusedElement(),
              targetIsStillFocused(target, focusedElement: focusedElement)
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
