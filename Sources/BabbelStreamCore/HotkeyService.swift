import Carbon.HIToolbox
import Foundation

@MainActor
public protocol HotkeyService: AnyObject {
    var isRegistered: Bool { get }
    var onPressed: (() -> Void)? { get set }
    var onReleased: (() -> Void)? { get set }
    var onCancel: (() -> Void)? { get set }

    func register() throws
    func setCancelEnabled(_ isEnabled: Bool) throws
    func unregister()
}

public enum HotkeyError: Error, Equatable, LocalizedError, Sendable {
    case couldNotInstallHandler(OSStatus)
    case couldNotRegister(OSStatus)
    case couldNotRegisterCancel(OSStatus)

    public var errorDescription: String? {
        switch self {
        case let .couldNotInstallHandler(status):
            "Could not install hotkey handler: \(status)."
        case let .couldNotRegister(status):
            "Could not register \(ProjectDefaults.fixedHotkeyDescription): \(status)."
        case let .couldNotRegisterCancel(status):
            "Could not register Escape for canceling the active dictation: \(status)."
        }
    }
}

@MainActor
public final class CarbonHotkeyService: HotkeyService {
    public var onPressed: (() -> Void)?
    public var onReleased: (() -> Void)?
    public var onCancel: (() -> Void)?

    private var hotkeyRef: EventHotKeyRef?
    private var cancelHotkeyRef: EventHotKeyRef?
    private var eventHandlerRef: EventHandlerRef?

    public var isRegistered: Bool {
        hotkeyRef != nil
    }

    public init() {}

    deinit {
        MainActor.assumeIsolated {
            unregister()
        }
    }

    public func register() throws {
        guard !isRegistered else {
            return
        }

        try installHandlerIfNeeded()

        let hotkeyID = EventHotKeyID(
            signature: FourCharCode("BBST"),
            id: 1
        )
        var newHotkeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(kVK_Space),
            UInt32(controlKey | optionKey),
            hotkeyID,
            GetApplicationEventTarget(),
            0,
            &newHotkeyRef
        )

        guard status == noErr, let newHotkeyRef else {
            throw HotkeyError.couldNotRegister(status)
        }

        hotkeyRef = newHotkeyRef
    }

    public func unregister() {
        if let hotkeyRef {
            UnregisterEventHotKey(hotkeyRef)
            self.hotkeyRef = nil
        }

        if let cancelHotkeyRef {
            UnregisterEventHotKey(cancelHotkeyRef)
            self.cancelHotkeyRef = nil
        }

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
    }

    public func setCancelEnabled(_ isEnabled: Bool) throws {
        if !isEnabled {
            if let cancelHotkeyRef {
                UnregisterEventHotKey(cancelHotkeyRef)
                self.cancelHotkeyRef = nil
            }
            return
        }

        guard cancelHotkeyRef == nil else {
            return
        }

        try installHandlerIfNeeded()
        let cancelHotkeyID = EventHotKeyID(
            signature: FourCharCode("BBST"),
            id: 2
        )
        var newCancelHotkeyRef: EventHotKeyRef?
        let status = RegisterEventHotKey(
            UInt32(kVK_Escape),
            0,
            cancelHotkeyID,
            GetApplicationEventTarget(),
            0,
            &newCancelHotkeyRef
        )
        guard status == noErr, let newCancelHotkeyRef else {
            throw HotkeyError.couldNotRegisterCancel(status)
        }

        cancelHotkeyRef = newCancelHotkeyRef
    }

    private func installHandlerIfNeeded() throws {
        guard eventHandlerRef == nil else {
            return
        }

        var eventTypes = [
            EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyPressed)
            ),
            EventTypeSpec(
                eventClass: OSType(kEventClassKeyboard),
                eventKind: UInt32(kEventHotKeyReleased)
            )
        ]

        let userData = UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque())
        var handlerRef: EventHandlerRef?
        let status = InstallEventHandler(
            GetApplicationEventTarget(),
            carbonHotkeyEventHandler,
            eventTypes.count,
            &eventTypes,
            userData,
            &handlerRef
        )

        guard status == noErr, let handlerRef else {
            throw HotkeyError.couldNotInstallHandler(status)
        }

        eventHandlerRef = handlerRef
    }

    fileprivate func handle(eventKind: UInt32, hotkeyID: UInt32) {
        switch (hotkeyID, eventKind) {
        case (1, UInt32(kEventHotKeyPressed)):
            onPressed?()
        case (1, UInt32(kEventHotKeyReleased)):
            onReleased?()
        case (2, UInt32(kEventHotKeyPressed)):
            onCancel?()
        default:
            return
        }
    }
}

private func FourCharCode(_ string: String) -> UInt32 {
    var result: UInt32 = 0

    for scalar in string.unicodeScalars.prefix(4) {
        result = (result << 8) + UInt32(scalar.value)
    }

    return result
}

private let carbonHotkeyEventHandler: EventHandlerUPP = { _, event, userData in
    guard let event, let userData else {
        return noErr
    }

    let service = Unmanaged<CarbonHotkeyService>
        .fromOpaque(userData)
        .takeUnretainedValue()
    let eventKind = GetEventKind(event)
    var hotkeyID = EventHotKeyID()
    let parameterStatus = GetEventParameter(
        event,
        EventParamName(kEventParamDirectObject),
        EventParamType(typeEventHotKeyID),
        nil,
        MemoryLayout<EventHotKeyID>.size,
        nil,
        &hotkeyID
    )
    guard parameterStatus == noErr else {
        return noErr
    }

    Task { @MainActor in
        service.handle(eventKind: eventKind, hotkeyID: hotkeyID.id)
    }

    return noErr
}
