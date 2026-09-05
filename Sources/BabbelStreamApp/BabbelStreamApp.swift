import AppKit

package enum BabbelStreamApplicationMain {
    @MainActor
    package static func main() {
        let application = NSApplication.shared
        let appDelegate = AppDelegate()
        application.delegate = appDelegate
        application.setActivationPolicy(.accessory)
        application.run()
        _ = appDelegate
    }
}
