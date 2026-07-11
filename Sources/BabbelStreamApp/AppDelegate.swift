import AppKit
import BabbelStreamCore

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let personalDictionaryStore = JSONPersonalDictionaryStore()
    private let dictationArchiveStore = JSONLDictationArchiveStore()
    private lazy var appState = AppState(
        personalDictionaryStore: personalDictionaryStore,
        dictationArchiveStore: dictationArchiveStore
    )
    private var statusBarController: StatusBarController?
    private var settingsWindowController: SettingsWindowController?
    private var dictationArchiveWindowController: DictationArchiveWindowController?
    private var personalDictionaryWindowController: PersonalDictionaryWindowController?
    private var teachCorrectionWindowController: TeachCorrectionWindowController?
    private var dictationStatusHUDController: DictationStatusHUDController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        installMainMenu()
        let appState = appState
        let settingsWindowController = SettingsWindowController(appState: appState)
        let dictationArchiveWindowController = DictationArchiveWindowController(appState: appState)
        let teachCorrectionWindowController = TeachCorrectionWindowController(
            store: personalDictionaryStore,
            appState: appState
        )
        let personalDictionaryWindowController = PersonalDictionaryWindowController(
            store: personalDictionaryStore,
            onTeachCorrection: { [weak teachCorrectionWindowController] in
                teachCorrectionWindowController?.show()
            }
        )
        self.settingsWindowController = settingsWindowController
        self.dictationArchiveWindowController = dictationArchiveWindowController
        self.personalDictionaryWindowController = personalDictionaryWindowController
        self.teachCorrectionWindowController = teachCorrectionWindowController
        appState.onTeachCorrectionRequested = { [weak teachCorrectionWindowController] in
            teachCorrectionWindowController?.show()
        }
        statusBarController = StatusBarController(
            appState: appState,
            settingsWindowController: settingsWindowController,
            dictationArchiveWindowController: dictationArchiveWindowController,
            personalDictionaryWindowController: personalDictionaryWindowController,
            teachCorrectionWindowController: teachCorrectionWindowController
        )
        dictationStatusHUDController = DictationStatusHUDController(appState: appState)

        switch AppWindowLaunchMode.requested {
        case .settings:
            settingsWindowController.show()
        case .personalDictionary:
            personalDictionaryWindowController.show()
        case .teachCorrection:
            teachCorrectionWindowController.show()
        case .dictationArchive:
            dictationArchiveWindowController.show()
        case nil:
            break
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        appState.prepareForTermination()
    }

    private func installMainMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu(title: ProjectDefaults.appName)
        appMenu.addItem(
            withTitle: "Quit \(ProjectDefaults.appName)",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        editMenu.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(
            withTitle: "Select All",
            action: #selector(NSText.selectAll(_:)),
            keyEquivalent: "a"
        )
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        NSApp.mainMenu = mainMenu
    }
}
