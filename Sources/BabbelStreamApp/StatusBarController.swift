import AppKit
import BabbelStreamCore

@MainActor
final class StatusBarController: NSObject, NSMenuDelegate {
    private let appState: AppState
    private let settingsWindowController: SettingsWindowController
    private let dictationArchiveWindowController: DictationArchiveWindowController
    private let dictationRecoveryWindowController: DictationRecoveryWindowController
    private let personalDictionaryWindowController: PersonalDictionaryWindowController
    private let teachCorrectionWindowController: TeachCorrectionWindowController
    private let statusItem: NSStatusItem
    private let menu = NSMenu()

    init(
        appState: AppState,
        settingsWindowController: SettingsWindowController,
        dictationArchiveWindowController: DictationArchiveWindowController,
        dictationRecoveryWindowController: DictationRecoveryWindowController,
        personalDictionaryWindowController: PersonalDictionaryWindowController,
        teachCorrectionWindowController: TeachCorrectionWindowController
    ) {
        self.appState = appState
        self.settingsWindowController = settingsWindowController
        self.dictationArchiveWindowController = dictationArchiveWindowController
        self.dictationRecoveryWindowController = dictationRecoveryWindowController
        self.personalDictionaryWindowController = personalDictionaryWindowController
        self.teachCorrectionWindowController = teachCorrectionWindowController
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        super.init()

        menu.delegate = self
        statusItem.menu = menu
        refreshStatusItem()
        rebuildMenu()
        appState.onStateChanged = { [weak self] in
            self?.refreshStatusItem()
        }
    }

    func menuWillOpen(_ menu: NSMenu) {
        appState.refreshPermissionStatuses()
        rebuildMenu()
        refreshStatusItem()
    }

    private func refreshStatusItem() {
        statusItem.button?.image = NSImage(
            systemSymbolName: appState.menuBarSystemImage,
            accessibilityDescription: ProjectDefaults.appName
        )
        statusItem.button?.toolTip = "\(ProjectDefaults.appName): \(appState.status)"
    }

    private func rebuildMenu() {
        menu.removeAllItems()

        addStatusSection()
        menu.addItem(.separator())
        addDictationActions()
        if appState.microphonePermissionStatus != .authorized
            || appState.accessibilityPermissionStatus != .trusted {
            menu.addItem(.separator())
            addReadinessActions()
        }
        menu.addItem(.separator())
        addDiagnosticsSubmenu()
        menu.addItem(.separator())
        addAppActions()
    }

    private func addStatusSection() {
        addInfo(appState.status)
        if let pasteTargetSummary = appState.pasteTargetSummary {
            addInfo("Paste target: \(pasteTargetSummary)")
        }

        if appState.isRecording {
            addInfo("Elapsed: \(elapsedText)")
        }

        if appState.lastResult != "No dictation yet.", appState.lastResult != appState.status {
            addInfo(appState.lastResult)
        }

        if let warningMessage = appState.warningMessage {
            addInfo("Warning: \(warningMessage)")
        }
        if let errorMessage = appState.errorMessage {
            addInfo("Error: \(errorMessage)")
        }
    }

    private func addDictationActions() {
        let cleanupItem = addAction(
            "Cleanup",
            action: #selector(toggleCleanup),
            enabled: true
        )
        cleanupItem.state = appState.cleanupEnabled ? .on : .off

        addAction(
            "Start Hands-Free Dictation",
            action: #selector(startDictation),
            enabled: appState.canStart
        )
        addAction(
            appState.isHandsFreeRecording ? "Stop Hands-Free + Transcribe" : "Stop + Transcribe",
            action: #selector(stopActiveRecording),
            enabled: appState.canStop
        )
        addAction(
            "Cancel Active Operation",
            action: #selector(cancelRecording),
            enabled: appState.canCancel
        )

        addAction(
            "Copy Last Draft",
            action: #selector(copyLastDraft),
            enabled: appState.canUseLatestDraft
        )
        addAction(
            "Paste Last Draft",
            action: #selector(retryPasteLastDraft),
            enabled: appState.canUseLatestDraft && !appState.isProcessing
        )
    }

    private func addReadinessActions() {
        if appState.microphonePermissionStatus != .authorized {
            addAction(
                "Request Microphone Permission",
                action: #selector(requestMicrophonePermission),
                enabled: appState.canStart
            )
        }
        if appState.accessibilityPermissionStatus != .trusted {
            addAction(
                "Request Accessibility Permission",
                action: #selector(requestAccessibilityPermission),
                enabled: true
            )
        }
    }

    private func addAppActions() {
        addAction("Teach Correction...", action: #selector(openTeachCorrection), enabled: true)
        addAction("Personal Dictionary...", action: #selector(openPersonalDictionary), enabled: true)
        addAction("Dictation Archive...", action: #selector(openDictationArchive), enabled: true)
        addAction(
            "Failed Recordings... (\(appState.recoverySnapshot.recordings.count))",
            action: #selector(openFailedRecordings),
            enabled: true
        )
        addAction("Settings...", action: #selector(openSettings), enabled: true)
        addAction("Quit", action: #selector(quit), enabled: true)
    }

    @discardableResult
    private func addAction(
        _ title: String,
        action: Selector,
        enabled: Bool
    ) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: "")
        item.target = self
        item.isEnabled = enabled
        menu.addItem(item)

        return item
    }

    private func addInfo(_ title: String) {
        let item = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        item.isEnabled = false
        menu.addItem(item)
    }

    private func addDiagnosticsSubmenu() {
        let parent = NSMenuItem(title: "Diagnostics", action: nil, keyEquivalent: "")
        let submenu = NSMenu(title: "Diagnostics")
        let lines = appState.diagnosticSummaries

        if lines.isEmpty {
            let item = NSMenuItem(title: "No events yet.", action: nil, keyEquivalent: "")
            item.isEnabled = false
            submenu.addItem(item)
        } else {
            for line in lines {
                let item = NSMenuItem(title: line, action: nil, keyEquivalent: "")
                item.isEnabled = false
                submenu.addItem(item)
            }
        }

        submenu.addItem(.separator())
        let localTestItem = NSMenuItem(
            title: "Start Local Test Recording",
            action: #selector(startLocalTestRecording),
            keyEquivalent: ""
        )
        localTestItem.target = self
        localTestItem.isEnabled = appState.canStart
        submenu.addItem(localTestItem)

        let copyItem = NSMenuItem(title: "Copy Diagnostics", action: #selector(copyDiagnostics), keyEquivalent: "")
        copyItem.target = self
        submenu.addItem(copyItem)

        parent.submenu = submenu
        menu.addItem(parent)
    }

    private var elapsedText: String {
        "\(formatMenuDuration(appState.elapsedSeconds)) / \(formatMenuDuration(appState.maxAudioDurationSeconds))"
    }

    private func formatMenuDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration.rounded(.down))
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60

        if minutes > 0 {
            return String(format: "%d:%02d", minutes, seconds)
        }

        return "\(seconds)s"
    }

    @objc private func toggleCleanup() {
        appState.setCleanupEnabled(!appState.cleanupEnabled)
        rebuildMenu()
    }

    @objc private func startDictation() {
        Task { @MainActor in
            await appState.startDictation()
            rebuildMenu()
        }
    }

    @objc private func stopActiveRecording() {
        Task { @MainActor in
            await appState.stopActiveRecording()
            rebuildMenu()
        }
    }

    @objc private func cancelRecording() {
        Task { @MainActor in
            await appState.cancelRecording()
            rebuildMenu()
        }
    }

    @objc private func startLocalTestRecording() {
        Task { @MainActor in
            await appState.startTestRecording()
            rebuildMenu()
        }
    }

    @objc private func copyLastDraft() {
        appState.copyLatestDraft()
        rebuildMenu()
    }

    @objc private func copyDiagnostics() {
        appState.copyDiagnosticsReport()
        rebuildMenu()
    }

    @objc private func retryPasteLastDraft() {
        Task { @MainActor in
            await appState.retryPasteLatestDraft()
            rebuildMenu()
        }
    }

    @objc private func requestMicrophonePermission() {
        Task { @MainActor in
            await appState.requestMicrophonePermission()
            rebuildMenu()
        }
    }

    @objc private func requestAccessibilityPermission() {
        appState.requestAccessibilityPermission()
        rebuildMenu()
    }

    @objc private func openSettings() {
        settingsWindowController.show()
    }

    @objc private func openPersonalDictionary() {
        personalDictionaryWindowController.show()
    }

    @objc private func openDictationArchive() {
        dictationArchiveWindowController.show()
    }

    @objc private func openFailedRecordings() {
        dictationRecoveryWindowController.show()
    }

    @objc private func openTeachCorrection() {
        teachCorrectionWindowController.show()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
