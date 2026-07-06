import Carbon.HIToolbox
import Foundation

@MainActor
public protocol HotkeyService: AnyObject {
    var isRegistered: Bool { get }
    var onPressed: (() -> Void)? { get set }
    var onReleased: (() -> Void)? { get set }

    func register() throws
    func unregister()
}

public enum HotkeyError: Error, Equatable, LocalizedError, Sendable {
    case couldNotInstallHandler(OSStatus)
    case couldNotRegister(OSStatus)

    public var errorDescription: String? {
        switch self {
        case let .couldNotInstallHandler(status):
            "Could not install hotkey handler: \(status)."
        case let .couldNotRegister(status):
            "Could not register \(ProjectDefaults.fixedHotkeyDescription): \(status)."
        }
    }
}

@MainActor
public final class CarbonHotkeyService: HotkeyService {
    public var onPressed: (() -> Void)?
    public var onReleased: (() -> Void)?

    private var hotkeyRef: EventHotKeyRef?
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

        if let eventHandlerRef {
            RemoveEventHandler(eventHandlerRef)
            self.eventHandlerRef = nil
        }
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
            { _, event, userData in
                guard let event, let userData else {
                    return noErr
                }

                let service = Unmanaged<CarbonHotkeyService>
                    .fromOpaque(userData)
                    .takeUnretainedValue()
                let eventKind = GetEventKind(event)

                Task { @MainActor in
                    switch eventKind {
                    case UInt32(kEventHotKeyPressed):
                        service.onPressed?()
                    case UInt32(kEventHotKeyReleased):
                        service.onReleased?()
                    default:
                        break
                    }
                }

                return noErr
            },
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
}

private func FourCharCode(_ string: String) -> UInt32 {
    var result: UInt32 = 0

    for scalar in string.unicodeScalars.prefix(4) {
        result = (result << 8) + UInt32(scalar.value)
    }

    return result
}
