import AppKit
import BabbelStreamCore
import SwiftUI

@main
enum BabbelStreamMain {
    @MainActor
    static func main() {
        let application = NSApplication.shared
        let appDelegate = AppDelegate()
        application.delegate = appDelegate
        application.setActivationPolicy(.accessory)
        application.run()
        _ = appDelegate
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let appState = AppState()
    private var statusBarController: StatusBarController?
    private var settingsWindowController: SettingsWindowController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        installMainMenu()
        let settingsWindowController = SettingsWindowController(appState: appState)
        self.settingsWindowController = settingsWindowController
        statusBarController = StatusBarController(
            appState: appState,
            settingsWindowController: settingsWindowController
        )
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

@MainActor
final class StatusBarController: NSObject, NSMenuDelegate {
    private let appState: AppState
    private let settingsWindowController: SettingsWindowController
    private let statusItem: NSStatusItem
    private let menu = NSMenu()

    init(
        appState: AppState,
        settingsWindowController: SettingsWindowController
    ) {
        self.appState = appState
        self.settingsWindowController = settingsWindowController
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
        let symbolName: String
        if appState.isRecording {
            symbolName = "mic.fill"
        } else if appState.isProcessing {
            symbolName = "waveform"
        } else {
            symbolName = "mic"
        }

        statusItem.button?.image = NSImage(
            systemSymbolName: symbolName,
            accessibilityDescription: ProjectDefaults.appName
        )
        statusItem.button?.toolTip = "\(ProjectDefaults.appName): \(appState.status)"
    }

    private func rebuildMenu() {
        menu.removeAllItems()

        addStatusSection()
        menu.addItem(.separator())
        addDictationActions()
        menu.addItem(.separator())
        addPermissionActions()
        menu.addItem(.separator())
        addDiagnosticsSubmenu()
        menu.addItem(.separator())
        addAppActions()
    }

    private func addStatusSection() {
        addInfo(appState.status)
        addInfo("Hotkey: \(ProjectDefaults.fixedHotkeyDescription)")
        addInfo(appState.hotkeyStatus)
        addInfo("Microphone: \(appState.microphonePermissionStatus.displayName)")
        addInfo("Accessibility: \(appState.accessibilityPermissionStatus.displayName)")
        if let pasteTargetSummary = appState.pasteTargetSummary {
            addInfo("Paste target: \(pasteTargetSummary)")
        }

        if appState.isRecording {
            addInfo("Elapsed: \(elapsedText)")
        }

        addInfo(appState.lastResult)

        if let warningMessage = appState.warningMessage {
            addInfo("Warning: \(warningMessage)")
        }
        if let errorMessage = appState.errorMessage {
            addInfo("Error: \(errorMessage)")
        }

        if appState.canUseLatestDraft {
            addInfo("Last raw transcript: \(appState.latestRawTranscriptSummary)")
            addInfo("Last final draft: \(appState.latestFinalDraftSummary)")
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
            "Start Dictation",
            action: #selector(startDictation),
            enabled: appState.canStart
        )
        addAction(
            "Stop + Transcribe",
            action: #selector(stopActiveRecording),
            enabled: appState.canStop
        )
        addAction(
            "Cancel Recording",
            action: #selector(cancelRecording),
            enabled: appState.canStop
        )

        addAction(
            "Start Local Test Recording",
            action: #selector(startLocalTestRecording),
            enabled: appState.canStart
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

    private func addPermissionActions() {
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
        addAction(
            "Refresh Permissions",
            action: #selector(refreshPermissions),
            enabled: true
        )

        if appState.microphonePermissionStatus == .denied || appState.microphonePermissionStatus == .restricted {
            addAction(
                "Open Microphone Settings",
                action: #selector(openMicrophoneSettings),
                enabled: true
            )
        }

        if appState.accessibilityPermissionStatus == .notTrusted {
            addAction(
                "Open Accessibility Settings",
                action: #selector(openAccessibilitySettings),
                enabled: true
            )
        }
    }

    private func addAppActions() {
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

        parent.submenu = submenu
        menu.addItem(parent)
    }

    private var elapsedText: String {
        "\(Int(appState.elapsedSeconds.rounded(.down)))s / \(Int(ProjectDefaults.maxAudioDurationSeconds))s"
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

    @objc private func refreshPermissions() {
        appState.refreshPermissionStatuses()
        rebuildMenu()
    }

    @objc private func openMicrophoneSettings() {
        appState.openMicrophonePrivacySettings()
    }

    @objc private func openAccessibilitySettings() {
        appState.openAccessibilityPrivacySettings()
    }

    @objc private func openSettings() {
        settingsWindowController.show()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

@MainActor
final class SettingsWindowController {
    private let appState: AppState
    private var windowController: NSWindowController?

    init(appState: AppState) {
        self.appState = appState
    }

    func show() {
        let controller = windowController ?? makeWindowController()
        windowController = controller
        controller.showWindow(nil)
        controller.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    private func makeWindowController() -> NSWindowController {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 620),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "\(ProjectDefaults.appName) Settings"
        window.contentViewController = NSHostingController(
            rootView: SettingsView()
                .environmentObject(appState)
        )
        window.isReleasedWhenClosed = false
        window.center()

        return NSWindowController(window: window)
    }
}

struct DiagnosticEvent: Identifiable {
    let id = UUID()
    let timestamp: Date
    let message: String

    var displayText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"

        return "\(formatter.string(from: timestamp)) \(message)"
    }
}

@MainActor
final class AppState: ObservableObject {
    enum RecordingMode {
        case none
        case dictation
        case test
    }

    @Published var status = "Ready"
    @Published var microphonePermissionStatus: MicrophonePermissionStatus = .unknown
    @Published var accessibilityPermissionStatus: AccessibilityPermissionStatus = .notTrusted
    @Published var elapsedSeconds: TimeInterval = 0
    @Published var isRecording = false
    @Published var isProcessing = false
    @Published var recordingMode: RecordingMode = .none
    @Published var cleanupEnabled: Bool
    @Published var lastResult = "No dictation yet."
    @Published var warningMessage: String?
    @Published var errorMessage: String?
    @Published var hotkeyStatus = "Hotkey not registered yet."
    @Published var hasAPIKey = false

    @Published var baseURLText: String
    @Published var transcriptionPathText: String
    @Published var cleanupPathText: String
    @Published var transcriptionModelText: String
    @Published var cleanupModelText: String
    @Published var timeoutText: String
    @Published var transcriptionLanguageText: String
    @Published var transcriptionPromptText: String
    @Published var apiKeyInput = ""
    @Published private(set) var diagnostics: [DiagnosticEvent] = []

    var onStateChanged: (() -> Void)?

    private let audioRecorder: AudioRecorder
    private let settingsStore: SettingsStore
    private let secretStore: SecretStore
    private let apiKeyPresenceStore: APIKeyPresenceStore
    private let transcriptionProvider: TranscriptionProvider
    private let cleanupProvider: CleanupProvider
    private let textInsertionService: TextInsertionService
    private let hotkeyService: HotkeyService

    private var appSettings: AppSettings
    private var recordingStartedAt: Date?
    private var elapsedTimer: Timer?
    private var latestRawTranscript: String?
    private var latestFinalDraft: String?
    private var latestPasteTarget: TextInsertionTarget?
    private var latestExternalPasteTarget: TextInsertionTarget?
    private var workspaceActivationObserver: NSObjectProtocol?
    private var shouldStopDictationAfterStart = false
    private var cachedAPIKey: String?

    init(
        audioRecorder: AudioRecorder = AVFoundationAudioRecorder(),
        settingsStore: SettingsStore = UserDefaultsSettingsStore(),
        secretStore: SecretStore = KeychainSecretStore(),
        apiKeyPresenceStore: APIKeyPresenceStore = UserDefaultsAPIKeyPresenceStore(),
        transcriptionProvider: TranscriptionProvider = OpenAICompatibleTranscriptionProvider(),
        cleanupProvider: CleanupProvider = OpenAICompatibleCleanupProvider(),
        textInsertionService: TextInsertionService = ClipboardTextInsertionService(),
        hotkeyService: HotkeyService = CarbonHotkeyService()
    ) {
        self.audioRecorder = audioRecorder
        self.settingsStore = settingsStore
        self.secretStore = secretStore
        self.apiKeyPresenceStore = apiKeyPresenceStore
        self.transcriptionProvider = transcriptionProvider
        self.cleanupProvider = cleanupProvider
        self.textInsertionService = textInsertionService
        self.hotkeyService = hotkeyService

        let loadedSettings = settingsStore.load()
        self.appSettings = loadedSettings
        self.cleanupEnabled = loadedSettings.cleanupEnabled
        self.baseURLText = loadedSettings.providerConfiguration.baseURL.absoluteString
        self.transcriptionPathText = loadedSettings.providerConfiguration.transcriptionEndpointPath
        self.cleanupPathText = loadedSettings.providerConfiguration.cleanupEndpointPath
        self.transcriptionModelText = loadedSettings.providerConfiguration.transcriptionModel
        self.cleanupModelText = loadedSettings.providerConfiguration.cleanupModel
        self.timeoutText = String(Int(loadedSettings.providerConfiguration.timeoutSeconds))
        self.transcriptionLanguageText = loadedSettings.transcriptionLanguage
        self.transcriptionPromptText = loadedSettings.transcriptionPrompt

        self.microphonePermissionStatus = audioRecorder.microphonePermissionStatus()
        self.accessibilityPermissionStatus = textInsertionService.accessibilityPermissionStatus()
        self.hasAPIKey = apiKeyPresenceStore.hasSavedAPIKey

        updateLatestExternalPasteTarget(from: NSWorkspace.shared.frontmostApplication)
        observeWorkspaceActivations()
        cleanupStaleTemporaryAudio()
        configureHotkey()
    }

    var menuBarSystemImage: String {
        if isRecording {
            return "mic.fill"
        }
        if isProcessing {
            return "waveform"
        }
        return "mic"
    }

    var canStart: Bool {
        !isRecording && !isProcessing
    }

    var canStop: Bool {
        isRecording && !isProcessing
    }

    var canUseLatestDraft: Bool {
        latestFinalDraft?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }

    var pasteTargetSummary: String? {
        (latestPasteTarget ?? latestExternalPasteTarget)?.displayName
    }

    var latestRawTranscriptSummary: String {
        guard let latestRawTranscript else {
            return "None"
        }

        return "\(latestRawTranscript.count) characters"
    }

    var latestFinalDraftSummary: String {
        guard let latestFinalDraft else {
            return "None"
        }

        return "\(latestFinalDraft.count) characters"
    }

    var diagnosticSummaries: [String] {
        diagnostics.suffix(10).map(\.displayText)
    }

    var providerDestinationSummary: String {
        "\(baseURLText)\(transcriptionPathText)"
    }

    private func observeWorkspaceActivations() {
        workspaceActivationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            guard let application = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else {
                return
            }

            let processIdentifier = application.processIdentifier
            let localizedName = application.localizedName
            let bundleIdentifier = application.bundleIdentifier

            Task { @MainActor [weak self] in
                self?.updateLatestExternalPasteTarget(
                    processIdentifier: processIdentifier,
                    localizedName: localizedName,
                    bundleIdentifier: bundleIdentifier
                )
            }
        }
    }

    private func captureCurrentPasteTarget() {
        updateLatestExternalPasteTarget(from: NSWorkspace.shared.frontmostApplication)
        latestPasteTarget = latestExternalPasteTarget
        notifyStateChanged()
    }

    private func updateLatestExternalPasteTarget(from application: NSRunningApplication?) {
        guard let application else {
            return
        }

        updateLatestExternalPasteTarget(
            processIdentifier: application.processIdentifier,
            localizedName: application.localizedName,
            bundleIdentifier: application.bundleIdentifier
        )
    }

    private func updateLatestExternalPasteTarget(
        processIdentifier: pid_t,
        localizedName: String?,
        bundleIdentifier: String?
    ) {
        guard processIdentifier != ProcessInfo.processInfo.processIdentifier,
              bundleIdentifier != Bundle.main.bundleIdentifier
        else {
            return
        }

        latestExternalPasteTarget = TextInsertionTarget(
            processIdentifier: processIdentifier,
            localizedName: localizedName
        )
    }

    func refreshPermissionStatuses() {
        microphonePermissionStatus = audioRecorder.microphonePermissionStatus()
        accessibilityPermissionStatus = textInsertionService.accessibilityPermissionStatus()
        notifyStateChanged()
    }

    func requestMicrophonePermission() async {
        guard canStart else {
            return
        }

        microphonePermissionStatus = await audioRecorder.requestMicrophonePermission()
        if microphonePermissionStatus.canRecord {
            status = "Ready"
            errorMessage = nil
        } else {
            status = "Microphone unavailable"
            errorMessage = microphoneGuidance(for: microphonePermissionStatus)
        }
        recordDiagnostic("microphone permission: \(microphonePermissionStatus.displayName)")
    }

    func requestAccessibilityPermission() {
        textInsertionService.requestAccessibilityPermission()
        refreshPermissionStatuses()

        if accessibilityPermissionStatus == .trusted {
            errorMessage = nil
            lastResult = "Accessibility is allowed."
        } else {
            errorMessage = "Accessibility is still not allowed for this app instance. If System Settings already shows it enabled, remove and re-add BabbelStream after rebuilding."
        }
        recordDiagnostic("accessibility permission: \(accessibilityPermissionStatus.displayName)")
    }

    func startDictation() async {
        await startRecording(mode: .dictation)
    }

    func startTestRecording() async {
        await startRecording(mode: .test)
    }

    func stopActiveRecording() async {
        switch recordingMode {
        case .dictation:
            await stopAndProcessDictation()
        case .test:
            await stopTestRecording()
        case .none:
            return
        }
    }

    func cancelRecording() async {
        guard isRecording || recordingStartedAt != nil else {
            return
        }

        stopElapsedTimer()
        isProcessing = true

        do {
            try await audioRecorder.cancel()
            resetRecordingState()
            status = "Ready"
            errorMessage = nil
            warningMessage = nil
            lastResult = "Recording canceled; temporary file deleted."
            recordDiagnostic("recording canceled; temporary audio deleted")
        } catch {
            resetRecordingState()
            status = "Cancel failed"
            errorMessage = error.localizedDescription
            lastResult = "Could not cancel recording safely."
            recordDiagnostic("recording cancel failed: \(diagnosticErrorCategory(error))")
        }

        isProcessing = false
        notifyStateChanged()
    }

    func saveSettings() {
        guard let baseURL = URL(string: baseURLText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            errorMessage = SettingsValidationError.invalidBaseURL.localizedDescription
            return
        }
        guard let timeout = TimeInterval(timeoutText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            errorMessage = SettingsValidationError.invalidTimeout.localizedDescription
            return
        }

        let rawLanguage = transcriptionLanguageText.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedLanguage = TranscriptionLanguageNormalizer.apiValue(from: rawLanguage) ?? rawLanguage
        let configuration = ProviderConfiguration(
            baseURL: baseURL,
            transcriptionEndpointPath: transcriptionPathText,
            cleanupEndpointPath: cleanupPathText,
            transcriptionModel: transcriptionModelText,
            cleanupModel: cleanupModelText,
            timeoutSeconds: timeout,
            retryCount: 1
        )
        let settings = AppSettings(
            providerConfiguration: configuration,
            cleanupEnabled: cleanupEnabled,
            transcriptionResponseFormat: ProjectDefaults.defaultTranscriptionResponseFormat,
            transcriptionLanguage: normalizedLanguage,
            transcriptionPrompt: transcriptionPromptText
        )

        do {
            try settingsStore.save(settings)

            let trimmedKey = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedKey.isEmpty {
                try secretStore.saveAPIKey(trimmedKey)
                cachedAPIKey = trimmedKey
                apiKeyInput = ""
                apiKeyPresenceStore.hasSavedAPIKey = true
            }

            appSettings = settings
            transcriptionLanguageText = normalizedLanguage
            hasAPIKey = apiKeyPresenceStore.hasSavedAPIKey
            warningMessage = nil
            errorMessage = nil
            lastResult = "Settings saved. Provider: \(providerDestinationSummary)"
            recordDiagnostic("settings saved")
        } catch {
            errorMessage = error.localizedDescription
            recordDiagnostic("settings save failed: \(diagnosticErrorCategory(error))")
        }
    }

    func deleteAPIKey() {
        do {
            try secretStore.deleteAPIKey()
            cachedAPIKey = nil
            apiKeyInput = ""
            apiKeyPresenceStore.hasSavedAPIKey = false
            hasAPIKey = false
            lastResult = "API key deleted from Keychain."
            recordDiagnostic("api key deleted")
        } catch {
            errorMessage = error.localizedDescription
            recordDiagnostic("api key delete failed: \(diagnosticErrorCategory(error))")
        }
    }

    func setCleanupEnabled(_ isEnabled: Bool) {
        cleanupEnabled = isEnabled
        var updatedSettings = appSettings
        updatedSettings.cleanupEnabled = isEnabled
        do {
            try settingsStore.save(updatedSettings)
            appSettings = updatedSettings
            recordDiagnostic("cleanup \(isEnabled ? "enabled" : "disabled")")
        } catch {
            errorMessage = error.localizedDescription
            recordDiagnostic("cleanup toggle failed: \(diagnosticErrorCategory(error))")
        }
    }

    func copyLatestDraft() {
        guard let latestFinalDraft else {
            return
        }

        do {
            try textInsertionService.copyText(latestFinalDraft)
            lastResult = "Latest draft copied to clipboard."
            recordDiagnostic("latest draft copied")
        } catch {
            errorMessage = error.localizedDescription
            recordDiagnostic("latest draft copy failed: \(diagnosticErrorCategory(error))")
        }
    }

    func retryPasteLatestDraft() async {
        guard let latestFinalDraft else {
            return
        }

        if latestPasteTarget == nil {
            latestPasteTarget = latestExternalPasteTarget
        }
        await insertFinalDraft(latestFinalDraft)
    }

    func openMicrophonePrivacySettings() {
        openSystemSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")
    }

    func openAccessibilityPrivacySettings() {
        openSystemSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }

    private func recordDiagnostic(_ message: String) {
        diagnostics.append(DiagnosticEvent(timestamp: Date(), message: message))
        if diagnostics.count > 50 {
            diagnostics.removeFirst(diagnostics.count - 50)
        }
        onStateChanged?()
    }

    private func notifyStateChanged() {
        onStateChanged?()
    }

    private func configureHotkey() {
        hotkeyService.onPressed = { [weak self] in
            Task { @MainActor in
                guard let self else {
                    return
                }
                await self.handleDictationHotkeyPressed()
            }
        }
        hotkeyService.onReleased = { [weak self] in
            Task { @MainActor in
                guard let self else {
                    return
                }
                await self.handleDictationHotkeyReleased()
            }
        }

        do {
            try hotkeyService.register()
            hotkeyStatus = "\(ProjectDefaults.fixedHotkeyDescription) registered."
        } catch {
            hotkeyStatus = error.localizedDescription
        }
    }

    private func handleDictationHotkeyPressed() async {
        recordDiagnostic("hotkey pressed")
        guard canStart else {
            recordDiagnostic("hotkey press ignored: busy")
            return
        }

        shouldStopDictationAfterStart = false
        await startRecording(mode: .dictation)

        guard shouldStopDictationAfterStart else {
            return
        }

        shouldStopDictationAfterStart = false
        if recordingMode == .dictation {
            await stopAndProcessDictation()
        }
    }

    private func handleDictationHotkeyReleased() async {
        recordDiagnostic("hotkey released")
        if recordingMode == .dictation {
            await stopAndProcessDictation()
            return
        }

        if isProcessing {
            shouldStopDictationAfterStart = true
            lastResult = "Release received; stopping as soon as recording starts."
            recordDiagnostic("hotkey release queued until recording starts")
        }
    }

    private func startRecording(mode: RecordingMode) async {
        guard canStart else {
            recordDiagnostic("recording start ignored: busy")
            return
        }

        if mode == .dictation {
            captureCurrentPasteTarget()
        }
        cleanupStaleTemporaryAudio()
        isProcessing = true
        warningMessage = nil
        errorMessage = nil
        latestRawTranscript = nil
        latestFinalDraft = nil
        lastResult = "Preparing recording..."

        let newStatus = await audioRecorder.requestMicrophonePermission()
        microphonePermissionStatus = newStatus

        guard newStatus.canRecord else {
            status = "Microphone unavailable"
            lastResult = "Recording not started."
            errorMessage = microphoneGuidance(for: newStatus)
            isProcessing = false
            recordDiagnostic("recording not started: microphone \(newStatus.displayName)")
            return
        }

        do {
            try await audioRecorder.start(maxDuration: ProjectDefaults.maxAudioDurationSeconds)
            recordingStartedAt = Date()
            elapsedSeconds = 0
            recordingMode = mode
            isRecording = true
            status = mode == .dictation ? "Recording dictation" : "Recording test"
            lastResult = mode == .dictation
                ? "Speak, then release \(ProjectDefaults.fixedHotkeyDescription) or click Stop."
                : "Test recording only; no transcription will run."
            startElapsedTimer()
            recordDiagnostic("recording started: \(mode == .dictation ? "dictation" : "local test")")
        } catch {
            status = "Recording failed"
            lastResult = "Recording not started."
            errorMessage = error.localizedDescription
            recordDiagnostic("recording start failed: \(diagnosticErrorCategory(error))")
        }

        isProcessing = false
        notifyStateChanged()
    }

    private func stopAndProcessDictation(autoStopped: Bool = false) async {
        guard isRecording || recordingStartedAt != nil else {
            return
        }

        isProcessing = true
        stopElapsedTimer()

        do {
            let recording = try await audioRecorder.stop(deleteTemporaryFile: false)
            resetRecordingState()
            elapsedSeconds = recording.duration
            recordDiagnostic("recording stopped: dictation, \(formatDuration(recording.duration))")
            try await processRecording(recording, autoStopped: autoStopped)
        } catch {
            resetRecordingState()
            status = "Dictation failed"
            errorMessage = error.localizedDescription
            lastResult = "Could not finish dictation safely."
            recordDiagnostic("dictation failed: \(diagnosticErrorCategory(error))")
        }

        isProcessing = false
        notifyStateChanged()
    }

    private func stopTestRecording(autoStopped: Bool = false) async {
        guard isRecording || recordingStartedAt != nil else {
            return
        }

        isProcessing = true
        stopElapsedTimer()

        do {
            let recording = try await audioRecorder.stop(deleteTemporaryFile: true)
            resetRecordingState()
            elapsedSeconds = recording.duration
            status = "Ready"
            errorMessage = nil
            warningMessage = nil
            lastResult = resultMessage(for: recording, autoStopped: autoStopped)
            recordDiagnostic("local test stopped: \(formatDuration(recording.duration)); temp audio deleted")
        } catch {
            resetRecordingState()
            status = "Stop failed"
            errorMessage = error.localizedDescription
            lastResult = "Could not finish test recording safely."
            recordDiagnostic("local test stop failed: \(diagnosticErrorCategory(error))")
        }

        isProcessing = false
        notifyStateChanged()
    }

    private func processRecording(_ recording: RecordedAudio, autoStopped: Bool) async throws {
        defer {
            _ = try? AudioTempFileStore.deleteTemporaryAudio(at: recording.temporaryFileURL)
        }

        if !TranscriptionLanguageNormalizer.isValidForSettings(appSettings.transcriptionLanguage) {
            warningMessage = "Language setting ignored. Use a single code like de or en, or leave it empty for mixed German-English."
            recordDiagnostic("transcription language ignored: invalid language setting")
        }

        let apiKey = try loadAPIKeyForDictation()
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            recordDiagnostic("transcription not started: missing API key")
            throw ProviderError.missingAPIKey
        }

        status = autoStopped ? "Max reached; transcribing" : "Transcribing"
        lastResult = "Sending audio to \(appSettings.providerConfiguration.baseURL.host ?? appSettings.providerConfiguration.baseURL.absoluteString)."
        recordDiagnostic("transcription started")

        let rawTranscript = try await transcriptionProvider.transcribe(
            TranscriptionRequest(
                audioURL: recording.temporaryFileURL,
                settings: appSettings,
                apiKey: apiKey
            )
        )
        latestRawTranscript = rawTranscript
        recordDiagnostic("transcription succeeded: \(rawTranscript.count) characters")

        let finalDraft: String
        if cleanupEnabled {
            status = "Cleaning up"
            recordDiagnostic("cleanup started")
            do {
                finalDraft = try await cleanupProvider.cleanup(
                    CleanupRequest(
                        transcript: rawTranscript,
                        settings: appSettings,
                        apiKey: apiKey
                    )
                )
                warningMessage = nil
                recordDiagnostic("cleanup succeeded: \(finalDraft.count) characters")
            } catch {
                finalDraft = rawTranscript
                warningMessage = "Cleanup failed; using raw transcript. \(error.localizedDescription)"
                recordDiagnostic("cleanup failed; using raw transcript: \(diagnosticErrorCategory(error))")
            }
        } else {
            finalDraft = rawTranscript
            warningMessage = nil
            recordDiagnostic("cleanup skipped")
        }

        latestFinalDraft = finalDraft
        await insertFinalDraft(finalDraft)
    }

    private func loadAPIKeyForDictation() throws -> String {
        if let cachedAPIKey {
            return cachedAPIKey
        }

        guard let apiKey = try secretStore.readAPIKey() else {
            apiKeyPresenceStore.hasSavedAPIKey = false
            hasAPIKey = false
            return ""
        }

        cachedAPIKey = apiKey
        apiKeyPresenceStore.hasSavedAPIKey = true
        hasAPIKey = true

        do {
            try secretStore.saveAPIKey(apiKey)
            recordDiagnostic("api key keychain item refreshed")
        } catch {
            recordDiagnostic("api key keychain refresh skipped: \(diagnosticErrorCategory(error))")
        }

        return apiKey
    }

    private func insertFinalDraft(_ finalDraft: String) async {
        status = "Pasting draft"
        let pasteTarget = latestPasteTarget ?? latestExternalPasteTarget

        do {
            let insertionResult = try await textInsertionService.insertText(finalDraft, target: pasteTarget)
            accessibilityPermissionStatus = textInsertionService.accessibilityPermissionStatus()

            switch insertionResult {
            case .insertedDirectly:
                status = "Ready"
                lastResult = "Draft inserted. Review it before sending."
                errorMessage = nil
                warningMessage = nil
                recordDiagnostic("paste succeeded: direct accessibility insertion")
            case .pasteShortcutPosted:
                status = "Ready"
                lastResult = "Paste shortcut sent; draft is also on the clipboard."
                errorMessage = nil
                warningMessage = "If the draft did not appear, press Cmd+V in the target field."
                recordDiagnostic("paste shortcut posted; clipboard fallback retained")
            case .copiedForManualPaste:
                status = "Copied"
                lastResult = "Draft copied to clipboard. Paste manually with Cmd+V."
                errorMessage = "Accessibility is not allowed, so BabbelStream could not paste automatically."
                recordDiagnostic("paste fallback: copied for manual paste")
            case .copiedAfterPasteShortcutFailure:
                status = "Copied"
                lastResult = "Draft copied to clipboard after paste shortcut failed."
                errorMessage = "BabbelStream could not post Cmd+V. Paste manually with Cmd+V."
                recordDiagnostic("paste shortcut failed; clipboard fallback retained")
            }
        } catch {
            do {
                try textInsertionService.copyText(finalDraft)
                status = "Copied"
                lastResult = "Draft copied to clipboard after paste failed. Paste manually with Cmd+V."
                errorMessage = error.localizedDescription
                recordDiagnostic("paste failed; copied fallback: \(diagnosticErrorCategory(error))")
            } catch {
                status = "Paste failed"
                lastResult = "Draft is only available in memory for this app session."
                errorMessage = error.localizedDescription
                recordDiagnostic("paste and copy failed: \(diagnosticErrorCategory(error))")
            }
        }
        notifyStateChanged()
    }

    private func startElapsedTimer() {
        stopElapsedTimer()

        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateElapsedTime()
            }
        }
    }

    private func stopElapsedTimer() {
        elapsedTimer?.invalidate()
        elapsedTimer = nil
    }

    private func updateElapsedTime() {
        guard let recordingStartedAt else {
            return
        }

        elapsedSeconds = Date().timeIntervalSince(recordingStartedAt)

        if elapsedSeconds >= ProjectDefaults.maxAudioDurationSeconds, !isProcessing {
            Task {
                switch recordingMode {
                case .dictation:
                    await stopAndProcessDictation(autoStopped: true)
                case .test:
                    await stopTestRecording(autoStopped: true)
                case .none:
                    break
                }
            }
        }
    }

    private func resetRecordingState() {
        isRecording = false
        recordingStartedAt = nil
        recordingMode = .none
        shouldStopDictationAfterStart = false
    }

    private func cleanupStaleTemporaryAudio() {
        do {
            let deletedCount = try staleTemporaryAudioDirectories()
                .reduce(into: 0) { count, directory in
                    count += try AudioTempFileStore.deleteStaleTemporaryAudioFiles(in: directory)
                }

            if deletedCount > 0 {
                lastResult = "Cleaned up \(deletedCount) stale temporary recording(s)."
                recordDiagnostic("stale temp audio cleaned: \(deletedCount) file(s)")
            }
        } catch {
            warningMessage = "Could not clean up stale temporary recordings. \(error.localizedDescription)"
            recordDiagnostic("stale temp audio cleanup failed: \(diagnosticErrorCategory(error))")
        }
    }

    private func staleTemporaryAudioDirectories() -> [URL] {
        var directories = [AudioTempFileStore.temporaryDirectory()]

        if let tempPath = ProcessInfo.processInfo.environment["TMPDIR"], !tempPath.isEmpty {
            let tempDirectory = URL(fileURLWithPath: tempPath, isDirectory: true)
                .appendingPathComponent(ProjectDefaults.audioTempDirectoryName, isDirectory: true)

            if !directories.contains(tempDirectory) {
                directories.append(tempDirectory)
            }
        }

        return directories
    }

    private func resultMessage(for recording: RecordedAudio, autoStopped: Bool) -> String {
        let prefix = autoStopped ? "Maximum duration reached." : "Recording stopped."
        let deletionText = recording.wasDeleted ? "Temporary file deleted." : "Temporary file was not deleted."

        return "\(prefix) \(formatDuration(recording.duration)), \(formatByteCount(recording.byteCount)). \(deletionText)"
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        String(format: "%.1fs", duration)
    }

    private func formatByteCount(_ byteCount: Int64) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file

        return formatter.string(fromByteCount: byteCount)
    }

    private func microphoneGuidance(for status: MicrophonePermissionStatus) -> String? {
        switch status {
        case .authorized:
            nil
        case .notDetermined:
            "Microphone permission has not been requested yet."
        case .denied:
            "Microphone access is denied. Enable BabbelStream in System Settings > Privacy & Security > Microphone."
        case .restricted:
            "Microphone access is restricted by this Mac's policy."
        case .unknown:
            "Microphone permission state is unknown."
        }
    }

    private func openSystemSettings(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            return
        }

        NSWorkspace.shared.open(url)
    }
}

private func diagnosticErrorCategory(_ error: Error) -> String {
    if let providerError = error as? ProviderError {
        switch providerError {
        case .missingAPIKey:
            return "ProviderError.missingAPIKey"
        case .invalidEndpointURL:
            return "ProviderError.invalidEndpointURL"
        case .emptyAudioFile:
            return "ProviderError.emptyAudioFile"
        case let .requestFailed(statusCode, _):
            return "ProviderError.requestFailed(HTTP \(statusCode))"
        case .malformedResponse:
            return "ProviderError.malformedResponse"
        case .emptyTranscript:
            return "ProviderError.emptyTranscript"
        case .emptyCleanupOutput:
            return "ProviderError.emptyCleanupOutput"
        }
    }

    if let audioError = error as? AudioRecordingError {
        switch audioError {
        case .microphonePermissionDenied:
            return "AudioRecordingError.microphonePermissionDenied"
        case .alreadyRecording:
            return "AudioRecordingError.alreadyRecording"
        case .notRecording:
            return "AudioRecordingError.notRecording"
        case .couldNotCreateTempDirectory:
            return "AudioRecordingError.couldNotCreateTempDirectory"
        case .couldNotStartRecording:
            return "AudioRecordingError.couldNotStartRecording"
        case .missingRecordingFile:
            return "AudioRecordingError.missingRecordingFile"
        case .couldNotReadRecordingMetadata:
            return "AudioRecordingError.couldNotReadRecordingMetadata"
        case .couldNotDeleteTemporaryFile:
            return "AudioRecordingError.couldNotDeleteTemporaryFile"
        }
    }

    if let insertionError = error as? TextInsertionError {
        switch insertionError {
        case .emptyText:
            return "TextInsertionError.emptyText"
        case .pasteboardUnavailable:
            return "TextInsertionError.pasteboardUnavailable"
        case .pasteEventFailed:
            return "TextInsertionError.pasteEventFailed"
        }
    }

    if let secretError = error as? SecretStoreError {
        switch secretError {
        case let .keychainError(status):
            return "SecretStoreError.keychainStatus(\(status))"
        case .invalidSecretData:
            return "SecretStoreError.invalidSecretData"
        }
    }

    if let validationError = error as? SettingsValidationError {
        switch validationError {
        case .invalidBaseURL:
            return "SettingsValidationError.invalidBaseURL"
        case .missingTranscriptionModel:
            return "SettingsValidationError.missingTranscriptionModel"
        case .missingCleanupModel:
            return "SettingsValidationError.missingCleanupModel"
        case .missingTranscriptionPath:
            return "SettingsValidationError.missingTranscriptionPath"
        case .missingCleanupPath:
            return "SettingsValidationError.missingCleanupPath"
        case .invalidTranscriptionLanguage:
            return "SettingsValidationError.invalidTranscriptionLanguage"
        case .invalidTimeout:
            return "SettingsValidationError.invalidTimeout"
        }
    }

    return String(describing: type(of: error))
}

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Form {
            Section("Provider") {
                Text("Audio is sent to:")
                    .foregroundStyle(.secondary)
                Text(appState.providerDestinationSummary)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)

                TextField("Base URL", text: $appState.baseURLText)
                TextField("Transcription path", text: $appState.transcriptionPathText)
                TextField("Transcription model", text: $appState.transcriptionModelText)
                TextField("Cleanup path", text: $appState.cleanupPathText)
                TextField("Cleanup model", text: $appState.cleanupModelText)
                TextField("Timeout seconds", text: $appState.timeoutText)
            }

            Section("Transcription Hints") {
                TextField("Language code, optional (blank = auto)", text: $appState.transcriptionLanguageText)
                TextField("Transcription prompt, optional", text: $appState.transcriptionPromptText, axis: .vertical)
                    .lineLimit(2...4)
            }

            Section("API Key") {
                SecureField(
                    appState.hasAPIKey ? "API key saved in Keychain" : "Paste API key",
                    text: $appState.apiKeyInput
                )
                LabeledContent("Keychain", value: appState.hasAPIKey ? "Saved" : "Missing")

                HStack {
                    Button("Save Settings") {
                        appState.saveSettings()
                    }
                    Button("Delete API Key") {
                        appState.deleteAPIKey()
                    }
                    .disabled(!appState.hasAPIKey)
                }
            }

            Section("Behavior") {
                Toggle(
                    "Cleanup enabled",
                    isOn: Binding(
                        get: { appState.cleanupEnabled },
                        set: { appState.setCleanupEnabled($0) }
                    )
                )
                LabeledContent("Hotkey", value: ProjectDefaults.fixedHotkeyDescription)
                LabeledContent("Max duration", value: "\(Int(ProjectDefaults.maxAudioDurationSeconds))s")
                LabeledContent("Auto-send", value: ProjectDefaults.autoSendEnabledByDefault ? "On" : "Off")
                LabeledContent("History", value: ProjectDefaults.transcriptHistoryEnabledByDefault ? "On" : "Off")
            }

            Section("Permissions") {
                LabeledContent("Microphone", value: appState.microphonePermissionStatus.displayName)
                LabeledContent("Accessibility", value: appState.accessibilityPermissionStatus.displayName)

                HStack {
                    Button("Request Accessibility") {
                        appState.requestAccessibilityPermission()
                    }
                    Button("Refresh") {
                        appState.refreshPermissionStatuses()
                    }
                }
            }

            Section("Latest Draft") {
                LabeledContent("Raw transcript", value: appState.latestRawTranscriptSummary)
                LabeledContent("Final draft", value: appState.latestFinalDraftSummary)

                HStack {
                    Button("Copy Last Draft") {
                        appState.copyLatestDraft()
                    }
                    .disabled(!appState.canUseLatestDraft)

                    Button("Retry Paste Last Draft") {
                        Task {
                            await appState.retryPasteLatestDraft()
                        }
                    }
                    .disabled(!appState.canUseLatestDraft || appState.isProcessing)
                }
            }

            Section("Diagnostics") {
                if appState.diagnosticSummaries.isEmpty {
                    Text("No events yet.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(appState.diagnosticSummaries, id: \.self) { line in
                        Text(line)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                    }
                }
            }
        }
        .onAppear {
            appState.refreshPermissionStatuses()
        }
        .padding(24)
        .frame(width: 560)
    }
}
