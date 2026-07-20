import Foundation
import ServiceManagement

public enum SystemLoginItemStatus: Equatable, Sendable {
    case notRegistered
    case enabled
    case requiresApproval
    case notFound
}

public protocol SystemLoginItemService: AnyObject {
    var status: SystemLoginItemStatus { get }

    func register() throws
    func unregister() throws
    func openSystemSettings()
}

public final class ServiceManagementLoginItemService: SystemLoginItemService {
    private let service: SMAppService

    public init(service: SMAppService = .mainApp) {
        self.service = service
    }

    public var status: SystemLoginItemStatus {
        switch service.status {
        case .notRegistered:
            .notRegistered
        case .enabled:
            .enabled
        case .requiresApproval:
            .requiresApproval
        case .notFound:
            .notFound
        @unknown default:
            .notFound
        }
    }

    public func register() throws {
        try service.register()
    }

    public func unregister() throws {
        try service.unregister()
    }

    public func openSystemSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}

public struct LaunchAtLoginSnapshot: Equatable, Sendable {
    public let systemStatus: SystemLoginItemStatus
    public let legacyLaunchAgentExists: Bool

    public init(
        systemStatus: SystemLoginItemStatus,
        legacyLaunchAgentExists: Bool
    ) {
        self.systemStatus = systemStatus
        self.legacyLaunchAgentExists = legacyLaunchAgentExists
    }

    public var isEnabled: Bool {
        systemStatus == .enabled || legacyLaunchAgentExists
    }

    public var requiresApproval: Bool {
        systemStatus == .requiresApproval
    }

    public var displayName: String {
        switch systemStatus {
        case .enabled:
            "Enabled"
        case .requiresApproval:
            legacyLaunchAgentExists ? "Legacy enabled; system approval required" : "Approval required"
        case .notRegistered:
            legacyLaunchAgentExists ? "Legacy enabled" : "Disabled"
        case .notFound:
            legacyLaunchAgentExists ? "Legacy enabled; system service unavailable" : "Unavailable"
        }
    }
}

public enum LaunchAtLoginError: Error, LocalizedError, Sendable {
    case registrationFailed(String)
    case unregistrationFailed(String)
    case approvalRequired
    case serviceUnavailable
    case legacyRemovalFailed(String)

    public var errorDescription: String? {
        switch self {
        case let .registrationFailed(message):
            "Could not enable launch at login: \(message)"
        case let .unregistrationFailed(message):
            "Could not disable launch at login: \(message)"
        case .approvalRequired:
            "Launch at login requires approval in System Settings > General > Login Items."
        case .serviceUnavailable:
            "macOS could not find BabbelStream's launch-at-login service."
        case let .legacyRemovalFailed(message):
            "The system login item is enabled, but the legacy LaunchAgent could not be removed: \(message)"
        }
    }
}

public protocol LaunchAtLoginManaging: AnyObject {
    var snapshot: LaunchAtLoginSnapshot { get }

    func migrateLegacyRegistrationIfNeeded() throws
    func enable() throws
    func disable() throws
    func openSystemSettings()
}

public final class LaunchAtLoginService: LaunchAtLoginManaging {
    public static let defaultLabel = "com.sichgeis.babbelstream.loginitem"

    private let systemService: SystemLoginItemService
    private let legacyLaunchAgentURL: URL
    private let fileManager: FileManager

    public convenience init() {
        self.init(
            systemService: ServiceManagementLoginItemService(),
            legacyLaunchAgentURL: Self.defaultLegacyLaunchAgentURL()
        )
    }

    public init(
        systemService: SystemLoginItemService,
        legacyLaunchAgentURL: URL,
        fileManager: FileManager = .default
    ) {
        self.systemService = systemService
        self.legacyLaunchAgentURL = legacyLaunchAgentURL
        self.fileManager = fileManager
    }

    public var snapshot: LaunchAtLoginSnapshot {
        LaunchAtLoginSnapshot(
            systemStatus: systemService.status,
            legacyLaunchAgentExists: fileManager.fileExists(atPath: legacyLaunchAgentURL.path)
        )
    }

    public func migrateLegacyRegistrationIfNeeded() throws {
        guard snapshot.legacyLaunchAgentExists else {
            return
        }

        if systemService.status != .enabled {
            try registerSystemService()
        }

        try removeLegacyLaunchAgent()
    }

    public func enable() throws {
        if systemService.status != .enabled {
            try registerSystemService()
        }

        if snapshot.legacyLaunchAgentExists {
            try removeLegacyLaunchAgent()
        }
    }

    public func disable() throws {
        switch systemService.status {
        case .enabled, .requiresApproval:
            do {
                try systemService.unregister()
            } catch {
                throw LaunchAtLoginError.unregistrationFailed(error.localizedDescription)
            }
        case .notRegistered:
            break
        case .notFound:
            guard snapshot.legacyLaunchAgentExists else {
                throw LaunchAtLoginError.serviceUnavailable
            }
        }

        if snapshot.legacyLaunchAgentExists {
            try removeLegacyLaunchAgent()
        }
    }

    public func openSystemSettings() {
        systemService.openSystemSettings()
    }

    private func registerSystemService() throws {
        guard systemService.status != .notFound else {
            throw LaunchAtLoginError.serviceUnavailable
        }

        do {
            try systemService.register()
        } catch {
            if systemService.status == .requiresApproval {
                throw LaunchAtLoginError.approvalRequired
            }
            throw LaunchAtLoginError.registrationFailed(error.localizedDescription)
        }

        switch systemService.status {
        case .enabled:
            return
        case .requiresApproval:
            throw LaunchAtLoginError.approvalRequired
        case .notFound:
            throw LaunchAtLoginError.serviceUnavailable
        case .notRegistered:
            throw LaunchAtLoginError.registrationFailed("macOS did not register the login item.")
        }
    }

    private func removeLegacyLaunchAgent() throws {
        guard fileManager.fileExists(atPath: legacyLaunchAgentURL.path) else {
            return
        }

        do {
            try fileManager.removeItem(at: legacyLaunchAgentURL)
        } catch {
            throw LaunchAtLoginError.legacyRemovalFailed(error.localizedDescription)
        }
    }

    private static func defaultLegacyLaunchAgentURL(fileManager: FileManager = .default) -> URL {
        fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("LaunchAgents", isDirectory: true)
            .appendingPathComponent(defaultLabel)
            .appendingPathExtension("plist")
    }
}
