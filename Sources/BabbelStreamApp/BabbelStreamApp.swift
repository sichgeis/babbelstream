import AppKit
import BabbelStreamCore

package enum BabbelStreamApplicationMain {
    @MainActor
    package static func main() {
        // Check older installed copies too, before any shared stores or cleanup exist.
        let otherCopies = NSRunningApplication.runningApplications(withBundleIdentifier: "com.sichgeis.babbelstream")
        guard !otherCopies.contains(where: { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }) else { return }
        let instance: SingleInstanceLock
        do {
            let support = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            instance = try SingleInstanceLock(directory: support.appendingPathComponent("BabbelStream"))
        } catch SingleInstanceError.alreadyRunning {
            return
        } catch {
            let alert = NSAlert()
            alert.messageText = "BabbelStream could not start safely"
            alert.informativeText = "The single-instance safeguard is unavailable. Quit other copies and check access to this user's Application Support folder, then reopen the app."
            alert.runModal()
            return
        }
        let application = NSApplication.shared
        let appDelegate = AppDelegate()
        application.delegate = appDelegate
        application.setActivationPolicy(.accessory)
        withExtendedLifetime((instance, appDelegate)) {
            application.run()
        }
    }
}
