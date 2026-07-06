import Darwin
import Foundation

public enum LaunchAtLoginError: Error, LocalizedError, Sendable {
    case couldNotWriteLaunchAgent(String)
    case couldNotRemoveLaunchAgent(String)
    case launchctlFailed(command: String, status: Int32)

    public var errorDescription: String? {
        switch self {
        case let .couldNotWriteLaunchAgent(message):
            "Could not enable launch at login: \(message)"
        case let .couldNotRemoveLaunchAgent(message):
            "Could not disable launch at login: \(message)"
        case let .launchctlFailed(command, status):
            "launchctl \(command) failed with status \(status)."
        }
    }
}

public final class LaunchAtLoginService {
    public static let defaultLabel = "com.sichgeis.babbelstream.loginitem"

    private let label: String
    private let fileManager: FileManager

    public init(
        label: String = LaunchAtLoginService.defaultLabel,
        fileManager: FileManager = .default
    ) {
        self.label = label
        self.fileManager = fileManager
    }

    public var isEnabled: Bool {
        fileManager.fileExists(atPath: launchAgentURL.path)
    }

    public func enable(appURL: URL = Bundle.main.bundleURL) throws {
        do {
            try fileManager.createDirectory(
                at: launchAgentsDirectoryURL,
                withIntermediateDirectories: true
            )
            try launchAgentData(appURL: appURL).write(to: launchAgentURL, options: .atomic)
        } catch {
            throw LaunchAtLoginError.couldNotWriteLaunchAgent(error.localizedDescription)
        }

        _ = launchctlStatus(command: "bootout")
        try requireLaunchctlSuccess(command: "bootstrap")
    }

    public func disable() throws {
        _ = launchctlStatus(command: "bootout")

        guard fileManager.fileExists(atPath: launchAgentURL.path) else {
            return
        }

        do {
            try fileManager.removeItem(at: launchAgentURL)
        } catch {
            throw LaunchAtLoginError.couldNotRemoveLaunchAgent(error.localizedDescription)
        }
    }

    public static func launchAgentPropertyList(appURL: URL, label: String = defaultLabel) -> [String: Any] {
        [
            "Label": label,
            "ProgramArguments": [
                "/usr/bin/open",
                appURL.path
            ],
            "RunAtLoad": true,
            "StandardErrorPath": "/tmp/\(label).err",
            "StandardOutPath": "/tmp/\(label).out"
        ]
    }

    private var launchAgentsDirectoryURL: URL {
        fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent("Library", isDirectory: true)
            .appendingPathComponent("LaunchAgents", isDirectory: true)
    }

    private var launchAgentURL: URL {
        launchAgentsDirectoryURL
            .appendingPathComponent(label)
            .appendingPathExtension("plist")
    }

    private var launchctlDomain: String {
        "gui/\(getuid())"
    }

    private func launchAgentData(appURL: URL) throws -> Data {
        try PropertyListSerialization.data(
            fromPropertyList: Self.launchAgentPropertyList(appURL: appURL, label: label),
            format: .xml,
            options: 0
        )
    }

    @discardableResult
    private func launchctlStatus(command: String) -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/launchctl")
        process.arguments = [
            command,
            launchctlDomain,
            launchAgentURL.path
        ]

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return -1
        }

        return process.terminationStatus
    }

    private func requireLaunchctlSuccess(command: String) throws {
        let status = launchctlStatus(command: command)
        guard status == 0 else {
            throw LaunchAtLoginError.launchctlFailed(command: command, status: status)
        }
    }
}
