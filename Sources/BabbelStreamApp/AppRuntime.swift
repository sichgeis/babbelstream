import Foundation
import BabbelStreamCore
import OSLog

/// OS integration used by the coordinator; checks supply an isolated runtime.
@MainActor
protocol AppRuntime: AnyObject {
    var temporaryAudioDirectories: [URL] { get }
    func recordDiagnostic(_ message: String)
}

@MainActor
final class MacOSAppRuntime: AppRuntime {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "com.sichgeis.babbelstream", category: "Diagnostics")
    var temporaryAudioDirectories: [URL] { AudioTempFileStore.recoverySearchDirectories() }

    func recordDiagnostic(_ message: String) { logger.info("\(message, privacy: .public)") }
}
