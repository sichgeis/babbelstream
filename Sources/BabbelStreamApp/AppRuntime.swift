import AppKit
import BabbelStreamCore
import OSLog

/// OS integration used by the coordinator; checks supply an isolated runtime.
@MainActor
protocol AppRuntime: AnyObject {
    var temporaryAudioDirectories: [URL] { get }
    func frontmostTarget() -> TextInsertionTarget?
    func observeActivations(_ handler: @escaping @MainActor (TextInsertionTarget) -> Void)
    func recordDiagnostic(_ message: String)
}

@MainActor
final class MacOSAppRuntime: AppRuntime {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.sichgeis.babbelstream", category: "Diagnostics")
    private var observer: NSObjectProtocol?
    var temporaryAudioDirectories: [URL] { AudioTempFileStore.recoverySearchDirectories() }

    func frontmostTarget() -> TextInsertionTarget? {
        guard let application = NSWorkspace.shared.frontmostApplication else { return nil }
        return TextInsertionTarget(processIdentifier: application.processIdentifier, localizedName: application.localizedName, bundleIdentifier: application.bundleIdentifier)
    }

    func observeActivations(_ handler: @escaping @MainActor (TextInsertionTarget) -> Void) {
        if let observer { NSWorkspace.shared.notificationCenter.removeObserver(observer) }
        observer = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { notification in
            guard let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            let target = TextInsertionTarget(processIdentifier: application.processIdentifier, localizedName: application.localizedName, bundleIdentifier: application.bundleIdentifier)
            Task { @MainActor in handler(target) }
        }
    }

    func recordDiagnostic(_ message: String) { logger.info("\(message, privacy: .public)") }

    deinit {
        MainActor.assumeIsolated {
            if let observer { NSWorkspace.shared.notificationCenter.removeObserver(observer) }
        }
    }
}
