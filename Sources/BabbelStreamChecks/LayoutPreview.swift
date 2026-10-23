import AppKit
import BabbelStreamCore
@testable import BabbelStreamApplication

/// Explicit visual QA entry point: actual windows, isolated stores and fake OS adapters.
/// It never constructs AppDelegate or any production-store/native-recording adapter.
@MainActor
func runLayoutPreview() throws {
    let application = NSApplication.shared
    let incomplete = CommandLine.arguments.contains("--preview-incomplete")
    let delegate = LayoutPreviewDelegate(fixture: try CoordinatorFixture(hasPrimaryKey: !incomplete, permissionsReady: !incomplete))
    application.delegate = delegate
    application.setActivationPolicy(.regular)
    application.run()
    _ = delegate
}

@MainActor
private final class LayoutPreviewDelegate: NSObject, NSApplicationDelegate {
    let fixture: CoordinatorFixture
    var controller: AnyObject?
    var settingsController: SettingsWindowController?

    init(fixture: CoordinatorFixture) {
        self.fixture = fixture
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if CommandLine.arguments.contains("--preview-dark") {
            NSApp.appearance = NSAppearance(named: .darkAqua)
        } else if CommandLine.arguments.contains("--preview-high-contrast") {
            NSApp.appearance = NSAppearance(named: .accessibilityHighContrastAqua)
        }
        let menu = NSMenu()
        let item = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit Layout Preview", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        item.submenu = appMenu
        menu.addItem(item)
        NSApp.mainMenu = menu
        switch AppWindowLaunchMode.requested {
        case .onboarding:
            let settings = SettingsWindowController(appState: fixture.app)
            settingsController = settings
            let window = OnboardingWindowController(appState: fixture.app, store: fixture.onboarding, testInsertion: fixture.insertion, showProvider: { settings.showProviderSetup() })
            controller = window
            window.show(repairOnly: CommandLine.arguments.contains("--preview-repair"))
        case .personalDictionary:
            let window = PersonalDictionaryWindowController(store: JSONPersonalDictionaryStore(fileURL: fixture.root.appendingPathComponent("dictionary.json")), onTeachCorrection: {})
            controller = window; window.show()
        case .teachCorrection:
            let window = TeachCorrectionWindowController(store: JSONPersonalDictionaryStore(fileURL: fixture.root.appendingPathComponent("dictionary.json")), appState: fixture.app)
            controller = window; window.show()
        case .failedRecordings:
            let window = DictationRecoveryWindowController(appState: fixture.app)
            controller = window; window.show()
        case .dictationArchive:
            let window = DictationArchiveWindowController(appState: fixture.app)
            controller = window; window.show()
        default:
            let window = SettingsWindowController(appState: fixture.app)
            controller = window; window.show()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        try? fixture.dispose()
    }
}
