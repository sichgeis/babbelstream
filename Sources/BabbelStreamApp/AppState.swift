import AppKit
import BabbelStreamCore
import OSLog
import SwiftUI

struct DiagnosticEvent: Identifiable {
    let id = UUID()
    let timestamp: Date
    let message: String
    let operationID: UUID?
    let elapsedMilliseconds: Int?

    var displayText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"

        let operation = operationID.map { " [\($0.uuidString.prefix(8))]" } ?? ""
        let elapsed = elapsedMilliseconds.map { " +\($0)ms" } ?? ""
        return "\(formatter.string(from: timestamp))\(operation)\(elapsed) \(message)"
    }
}

@MainActor
final class AppState: ObservableObject {
    private static let diagnosticsLogger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.sichgeis.babbelstream",
        category: "Diagnostics"
    )
    enum RecordingMode {
        case none
        case dictation
        case test
    }

    private struct PreparedDraft {
        let rawTranscript: String
        let finalDraft: String
        let cleanupWasEnabled: Bool
        let cleanupFallbackUsed: Bool
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
    @Published var launchAtLoginEnabled = false
    @Published var usageSnapshot: UsageSnapshot
    @Published var personalDictionarySummary = "Not loaded yet."
    @Published var lastFailureCategory = "None"
    @Published var dictationArchiveEnabled: Bool
    @Published var archiveRawTranscriptEnabled: Bool
    @Published var archiveMonthText: String
    @Published var archiveSnapshot: DictationArchiveMonthSnapshot
    @Published var archiveStatusMessage = "Archive not loaded yet."
    @Published var archiveErrorMessage: String?
    @Published private(set) var recoverySnapshot = DictationRecoverySnapshot(recordings: [])
    @Published private(set) var recoveryStatusMessage = "No failed recordings."
    @Published private(set) var recoveryErrorMessage: String?

    @Published var baseURLText: String
    @Published var transcriptionPathText: String
    @Published var cleanupPathText: String
    @Published var transcriptionModelText: String
    @Published var cleanupModelText: String
    @Published var timeoutText: String
    @Published var maxAudioDurationMinutesText: String
    @Published var transcriptionLanguageText: String
    @Published var transcriptionPromptText: String
    @Published var apiKeyInput = ""
    @Published var settingsFeedbackMessage = ""
    @Published var settingsErrorMessage: String?
    @Published private(set) var transcriptionProgressDetail: String?
    @Published private(set) var diagnostics: [DiagnosticEvent] = []

    var onStateChanged: (() -> Void)?
    var onTeachCorrectionRequested: (() -> Void)?

    private let audioRecorder: AudioRecorder
    private let settingsStore: SettingsStore
    private let secretStore: SecretStore
    private let apiKeyPresenceStore: APIKeyPresenceStore
    private let transcriptionProvider: TranscriptionProvider
    private let fallbackTranscriptionProvider: TranscriptionProvider
    private let cleanupProvider: CleanupProvider
    private let textInsertionService: TextInsertionService
    private let hotkeyService: HotkeyService
    private let launchAtLoginService: LaunchAtLoginService
    private let personalDictionaryStore: PersonalDictionaryStore
    private let usageTracker: UsageTracker
    private let dictationArchiveStore: DictationArchiveStore
    private let dictationRecoveryStore: DictationRecoveryStore

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
    private var activeDictationSettings: AppSettings?
    private var processingTask: Task<Void, Never>?
    private var retainedTemporaryAudioURL: URL?
    private var activeRecoveryRecording: DictationRecoveryRecording?
    private var stateChangeObservers: [UUID: () -> Void] = [:]
    private var activeDiagnosticOperationID: UUID?
    private var activeDiagnosticOperationStartedAt: ContinuousClock.Instant?
    private var lastCompletedDiagnosticOperationID: UUID?

    init(
        audioRecorder: AudioRecorder = AVFoundationAudioRecorder(),
        settingsStore: SettingsStore = UserDefaultsSettingsStore(),
        secretStore: SecretStore = KeychainSecretStore(),
        apiKeyPresenceStore: APIKeyPresenceStore = UserDefaultsAPIKeyPresenceStore(),
        transcriptionProvider: TranscriptionProvider = OpenAICompatibleTranscriptionProvider(),
        fallbackTranscriptionProvider: TranscriptionProvider = OpenAICompatibleTranscriptionProvider(
            urlSession: URLSession(configuration: .ephemeral)
        ),
        cleanupProvider: CleanupProvider = OpenAICompatibleCleanupProvider(),
        textInsertionService: TextInsertionService = ClipboardTextInsertionService(),
        hotkeyService: HotkeyService = CarbonHotkeyService(),
        launchAtLoginService: LaunchAtLoginService = LaunchAtLoginService(),
        personalDictionaryStore: PersonalDictionaryStore = JSONPersonalDictionaryStore(),
        usageTracker: UsageTracker = UserDefaultsUsageTracker(),
        dictationArchiveStore: DictationArchiveStore = JSONLDictationArchiveStore(),
        dictationRecoveryStore: DictationRecoveryStore = FileDictationRecoveryStore()
    ) {
        self.audioRecorder = audioRecorder
        self.settingsStore = settingsStore
        self.secretStore = secretStore
        self.apiKeyPresenceStore = apiKeyPresenceStore
        self.transcriptionProvider = transcriptionProvider
        self.fallbackTranscriptionProvider = fallbackTranscriptionProvider
        self.cleanupProvider = cleanupProvider
        self.textInsertionService = textInsertionService
        self.hotkeyService = hotkeyService
        self.launchAtLoginService = launchAtLoginService
        self.personalDictionaryStore = personalDictionaryStore
        self.usageTracker = usageTracker
        self.dictationArchiveStore = dictationArchiveStore
        self.dictationRecoveryStore = dictationRecoveryStore

        let loadedSettings = settingsStore.load()
        let loadedUsageSnapshot = usageTracker.load()
        let currentArchiveMonth = DictationArchiveMonth.current()
        self.appSettings = loadedSettings
        self.usageSnapshot = loadedUsageSnapshot
        self.cleanupEnabled = loadedSettings.cleanupEnabled
        self.dictationArchiveEnabled = loadedSettings.dictationArchiveEnabled
        self.archiveRawTranscriptEnabled = loadedSettings.archiveRawTranscriptEnabled
        self.archiveMonthText = currentArchiveMonth.directoryName
        self.archiveSnapshot = DictationArchiveMonthSnapshot(month: currentArchiveMonth, entries: [])
        self.baseURLText = loadedSettings.providerConfiguration.baseURL.absoluteString
        self.transcriptionPathText = loadedSettings.providerConfiguration.transcriptionEndpointPath
        self.cleanupPathText = loadedSettings.providerConfiguration.cleanupEndpointPath
        self.transcriptionModelText = loadedSettings.providerConfiguration.transcriptionModel
        self.cleanupModelText = loadedSettings.providerConfiguration.cleanupModel
        self.timeoutText = String(Int(loadedSettings.providerConfiguration.timeoutSeconds))
        self.maxAudioDurationMinutesText = Self.durationMinutesText(for: loadedSettings.maxAudioDurationSeconds)
        self.transcriptionLanguageText = loadedSettings.transcriptionLanguage
        self.transcriptionPromptText = loadedSettings.transcriptionPrompt

        self.microphonePermissionStatus = audioRecorder.microphonePermissionStatus()
        self.accessibilityPermissionStatus = textInsertionService.accessibilityPermissionStatus()
        self.hasAPIKey = apiKeyPresenceStore.hasSavedAPIKey
        self.launchAtLoginEnabled = launchAtLoginService.isEnabled

        updateLatestExternalPasteTarget(from: NSWorkspace.shared.frontmostApplication)
        observeWorkspaceActivations()
        cleanupStaleTemporaryAudio()
        loadRecoveryRecordings(markProcessingAsInterrupted: true)
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

    var canCancel: Bool {
        isRecording || processingTask != nil
    }

    var currentAudioLevel: Float {
        audioRecorder.currentLevel
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

    var latestRawTranscriptForCorrection: String {
        latestRawTranscript ?? ""
    }

    var latestFinalDraftForCorrection: String {
        latestFinalDraft ?? ""
    }

    var diagnosticSummaries: [String] {
        diagnostics.suffix(10).map(\.displayText)
    }

    var diagnosticReportSummaries: [String] {
        let operationID = activeDiagnosticOperationID ?? lastCompletedDiagnosticOperationID
        guard let operationID else {
            return diagnostics.map(\.displayText)
        }
        return diagnostics.filter { $0.operationID == operationID }.map(\.displayText)
    }

    var providerDestinationSummary: String {
        effectiveDestination(
            baseURL: appSettings.providerConfiguration.baseURL,
            path: appSettings.providerConfiguration.transcriptionEndpointPath
        )
    }

    var cleanupDestinationSummary: String {
        effectiveDestination(
            baseURL: appSettings.providerConfiguration.baseURL,
            path: appSettings.providerConfiguration.cleanupEndpointPath
        )
    }

    var providerConnectionTimeoutSummary: String {
        Self.secondsLabel(ProjectDefaults.providerConnectionTimeoutSeconds)
    }

    var editedProviderDestinationSummary: String {
        "\(baseURLText.trimmingCharacters(in: .whitespacesAndNewlines))\(transcriptionPathText.trimmingCharacters(in: .whitespacesAndNewlines))"
    }

    var editedCleanupDestinationSummary: String {
        "\(baseURLText.trimmingCharacters(in: .whitespacesAndNewlines))\(cleanupPathText.trimmingCharacters(in: .whitespacesAndNewlines))"
    }

    var hasUnsavedSettingsChanges: Bool {
        hasUnsavedConfigurationChanges
            || !apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var hasUnsavedConfigurationChanges: Bool {
        guard let draft = try? settingsFromDraft() else {
            return true
        }

        return draft != appSettings
    }

    var maxAudioDurationSeconds: TimeInterval {
        appSettings.maxAudioDurationSeconds
    }

    var usageSummary: String {
        "\(usageSnapshot.totalDictations) dictations, \(formatDuration(usageSnapshot.totalRecordedSeconds)) recorded"
    }

    var usageRecordedMinutesSummary: String {
        String(format: "%.1f min", usageSnapshot.totalRecordedMinutes)
    }

    var archiveDirectoryPath: String {
        dictationArchiveStore.archiveDirectoryURL.path
    }

    var recoveryDirectoryPath: String {
        dictationRecoveryStore.recoveryDirectoryURL.path
    }

    var recoverySummary: String {
        "\(recoverySnapshot.recordings.count) recording\(recoverySnapshot.recordings.count == 1 ? "" : "s"), \(ByteCountFormatter.string(fromByteCount: recoverySnapshot.totalByteCount, countStyle: .file))"
    }

    var appBundlePath: String {
        Bundle.main.bundleURL.path
    }

    var appBundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "unknown"
    }

    var codeSigningSummary: String {
        BuildMetadata.codeSigningSummary
    }

    var usesAdHocCodeSigning: Bool {
        codeSigningSummary == "ad-hoc"
    }

    var accessibilityTroubleshootingSummary: String? {
        guard accessibilityPermissionStatus != .trusted else {
            return nil
        }

        if usesAdHocCodeSigning {
            return "This build is ad-hoc signed. macOS may keep showing an enabled Accessibility row for an older rebuild while the running app is not trusted. Create the local signing identity, reinstall, then remove and re-add the current app in Accessibility."
        }

        if appBundlePath != "/Applications/\(ProjectDefaults.appName).app" {
            return "This instance is running from \(appBundlePath). Accessibility must be enabled for the exact app bundle that is running."
        }

        return "If System Settings already shows this app enabled, remove and re-add /Applications/\(ProjectDefaults.appName).app in Accessibility, then restart the app."
    }

    var archiveSummary: String {
        "\(archiveSnapshot.entries.count) entries, \(archiveSnapshot.totalFinalWordCount) final words"
    }

    var hudDetail: String {
        if isRecording {
            let target = pasteTargetSummary ?? "unverified target"
            let settings = activeDictationSettings ?? appSettings
            let provider = settings.providerConfiguration.baseURL.host
                ?? settings.providerConfiguration.baseURL.absoluteString
            let cancelGuidance = warningMessage?.contains("Escape") == true
                ? "use HUD Cancel"
                : "Escape cancels"
            return "Target: \(target) • release to transcribe via \(provider) • \(cancelGuidance) • \(formatDuration(elapsedSeconds))"
        }
        if status == "Cleaning up" {
            return "Formatting the transcript. The original target will be verified before paste."
        }
        if (status == "Transcribing" || status == "Retrying transcription"),
           let transcriptionProgressDetail {
            return transcriptionProgressDetail
        }
        if status == "Pasting draft" {
            return "Verifying the original application before inserting into its focused field."
        }

        return errorMessage ?? warningMessage ?? lastResult
    }

    @discardableResult
    func addStateChangeObserver(_ observer: @escaping () -> Void) -> UUID {
        let id = UUID()
        stateChangeObservers[id] = observer
        return id
    }

    func removeStateChangeObserver(_ id: UUID) {
        stateChangeObservers[id] = nil
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
        if let capturedTarget = textInsertionService.captureTarget(),
           capturedTarget.processIdentifier != ProcessInfo.processInfo.processIdentifier,
           capturedTarget.bundleIdentifier != Bundle.main.bundleIdentifier {
            latestPasteTarget = capturedTarget
        } else {
            latestPasteTarget = latestExternalPasteTarget
        }
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
            localizedName: localizedName,
            bundleIdentifier: bundleIdentifier
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
            errorMessage = accessibilityTroubleshootingSummary
                ?? "Accessibility is still not allowed for this app instance."
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
        if let processingTask {
            status = "Canceling dictation"
            lastResult = "Cancel requested. Stopping provider work and deleting temporary audio."
            recordDiagnostic("processing cancellation requested")
            processingTask.cancel()
            await processingTask.value
            completeDiagnosticOperation()
            notifyStateChanged()
            return
        }

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
            completeDiagnosticOperation()
        } catch {
            resetRecordingState()
            status = "Cancel failed"
            errorMessage = error.localizedDescription
            lastResult = "Could not cancel recording safely."
            recordDiagnostic("recording cancel failed: \(diagnosticErrorCategory(error))")
            completeDiagnosticOperation()
        }

        isProcessing = false
        setCancelHotkeyEnabled(false)
        notifyStateChanged()
    }

    func saveSettings() {
        do {
            let settings = try settingsFromDraft()

            let trimmedKey = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmedKey.isEmpty {
                try secretStore.saveAPIKey(trimmedKey)
                cachedAPIKey = trimmedKey
                apiKeyInput = ""
                apiKeyPresenceStore.hasSavedAPIKey = true
            }

            try settingsStore.save(settings)

            appSettings = settings
            dictationArchiveEnabled = settings.dictationArchiveEnabled
            archiveRawTranscriptEnabled = settings.archiveRawTranscriptEnabled
            transcriptionLanguageText = settings.transcriptionLanguage
            maxAudioDurationMinutesText = Self.durationMinutesText(for: settings.maxAudioDurationSeconds)
            hasAPIKey = apiKeyPresenceStore.hasSavedAPIKey
            warningMessage = nil
            errorMessage = nil
            settingsErrorMessage = nil
            settingsFeedbackMessage = "Settings applied. New dictations will use the saved destinations below."
            lastResult = "Settings saved. Provider: \(providerDestinationSummary)"
            recordDiagnostic("settings saved")
        } catch {
            errorMessage = error.localizedDescription
            settingsErrorMessage = error.localizedDescription
            settingsFeedbackMessage = ""
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
            settingsErrorMessage = nil
            settingsFeedbackMessage = "API key deleted from Keychain."
            lastResult = "API key deleted from Keychain."
            recordDiagnostic("api key deleted")
        } catch {
            errorMessage = error.localizedDescription
            settingsErrorMessage = error.localizedDescription
            settingsFeedbackMessage = ""
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

    func setDictationArchiveEnabled(_ isEnabled: Bool) {
        var updatedSettings = appSettings
        updatedSettings.dictationArchiveEnabled = isEnabled
        if !isEnabled {
            updatedSettings.archiveRawTranscriptEnabled = false
        }

        do {
            try applySavedArchiveSettings(
                updatedSettings,
                statusMessage: isEnabled
                    ? "Archive enabled. Completed dictations will be stored locally."
                    : "Archive disabled. Completed dictations will not be stored.",
                diagnosticMessage: "dictation archive \(isEnabled ? "enabled" : "disabled")"
            )
            if isEnabled {
                loadArchiveMonth()
            } else {
                notifyStateChanged()
            }
        } catch {
            errorMessage = error.localizedDescription
            recordDiagnostic("archive toggle failed: \(diagnosticErrorCategory(error))")
        }
    }

    func setArchiveRawTranscriptEnabled(_ isEnabled: Bool) {
        var updatedSettings = appSettings
        updatedSettings.archiveRawTranscriptEnabled = dictationArchiveEnabled && isEnabled

        do {
            try applySavedArchiveSettings(
                updatedSettings,
                statusMessage: updatedSettings.archiveRawTranscriptEnabled
                    ? "Raw transcript archiving enabled."
                    : "Raw transcript archiving disabled.",
                diagnosticMessage: "raw transcript archive \(updatedSettings.archiveRawTranscriptEnabled ? "enabled" : "disabled")"
            )
            notifyStateChanged()
        } catch {
            errorMessage = error.localizedDescription
            recordDiagnostic("raw transcript archive toggle failed: \(diagnosticErrorCategory(error))")
        }
    }

    private func applySavedArchiveSettings(
        _ settings: AppSettings,
        statusMessage: String,
        diagnosticMessage: String
    ) throws {
        try settingsStore.save(settings)
        appSettings = settings
        dictationArchiveEnabled = settings.dictationArchiveEnabled
        archiveRawTranscriptEnabled = settings.archiveRawTranscriptEnabled
        archiveStatusMessage = statusMessage
        archiveErrorMessage = nil
        lastResult = statusMessage
        recordDiagnostic(diagnosticMessage)
    }

    func setLaunchAtLoginEnabled(_ isEnabled: Bool) {
        do {
            if isEnabled {
                try launchAtLoginService.enable()
            } else {
                try launchAtLoginService.disable()
            }

            launchAtLoginEnabled = launchAtLoginService.isEnabled
            errorMessage = nil
            lastResult = isEnabled
                ? "BabbelStream will launch when you log in."
                : "BabbelStream will no longer launch at login."
            recordDiagnostic("launch at login \(launchAtLoginEnabled ? "enabled" : "disabled")")
        } catch {
            launchAtLoginEnabled = launchAtLoginService.isEnabled
            errorMessage = error.localizedDescription
            recordDiagnostic("launch at login update failed: \(diagnosticErrorCategory(error))")
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

    func copyDiagnosticsReport() {
        let report = PrivacyDiagnosticsBuilder.redactSecrets(in: diagnosticsReport())
        do {
            try textInsertionService.copyText(report)
            lastResult = "Diagnostics copied to clipboard."
            recordDiagnostic("privacy-safe diagnostics copied")
        } catch {
            errorMessage = error.localizedDescription
            recordDiagnostic("diagnostics copy failed: \(diagnosticErrorCategory(error))")
        }
    }

    func resetUsageCounters() {
        usageTracker.reset()
        usageSnapshot = UsageSnapshot()
        lastResult = "Usage counters reset."
        recordDiagnostic("usage counters reset")
        notifyStateChanged()
    }

    func loadArchiveMonth() {
        guard let month = DictationArchiveMonth(string: archiveMonthText) else {
            archiveErrorMessage = "Use a month in YYYY-MM format."
            archiveStatusMessage = "Archive month could not be loaded."
            recordDiagnostic("archive month load failed: invalid month")
            notifyStateChanged()
            return
        }

        do {
            let snapshot = try dictationArchiveStore.loadMonth(month)
            archiveSnapshot = snapshot
            archiveMonthText = month.directoryName
            archiveErrorMessage = nil
            let recoverySuffix = snapshot.readWarnings.isEmpty
                ? ""
                : " Skipped \(snapshot.readWarnings.count) damaged entr\(snapshot.readWarnings.count == 1 ? "y" : "ies")."
            archiveStatusMessage = "Loaded \(snapshot.entries.count) archive entr\(snapshot.entries.count == 1 ? "y" : "ies").\(recoverySuffix)"
            recordDiagnostic(
                "archive month loaded: \(month.directoryName), \(snapshot.entries.count) entries, \(snapshot.readWarnings.count) skipped"
            )
        } catch {
            archiveErrorMessage = error.localizedDescription
            archiveStatusMessage = "Archive month could not be loaded."
            recordDiagnostic("archive month load failed: \(diagnosticErrorCategory(error))")
        }

        notifyStateChanged()
    }

    func copyArchiveMarkdownExport() {
        guard let month = DictationArchiveMonth(string: archiveMonthText) else {
            archiveErrorMessage = "Use a month in YYYY-MM format."
            archiveStatusMessage = "Archive export could not be prepared."
            recordDiagnostic("archive export failed: invalid month")
            notifyStateChanged()
            return
        }

        do {
            let snapshot = try dictationArchiveStore.loadMonth(month)
            let markdown = dictationArchiveStore.markdownExport(for: snapshot)
            try textInsertionService.copyText(markdown)
            archiveSnapshot = snapshot
            archiveMonthText = month.directoryName
            archiveErrorMessage = nil
            archiveStatusMessage = snapshot.readWarnings.isEmpty
                ? "Archive Markdown export copied."
                : "Archive Markdown export copied with \(snapshot.readWarnings.count) damaged entr\(snapshot.readWarnings.count == 1 ? "y" : "ies") skipped."
            lastResult = "Archive Markdown export copied."
            recordDiagnostic("archive export copied: \(month.directoryName), \(snapshot.entries.count) entries")
        } catch {
            archiveErrorMessage = error.localizedDescription
            archiveStatusMessage = "Archive export could not be copied."
            recordDiagnostic("archive export failed: \(diagnosticErrorCategory(error))")
        }

        notifyStateChanged()
    }

    func revealArchiveFolder() {
        let fileManager = FileManager.default
        let archiveURL = dictationArchiveStore.archiveDirectoryURL
        let fallbackURL = archiveURL.deletingLastPathComponent()

        if fileManager.fileExists(atPath: archiveURL.path) {
            NSWorkspace.shared.open(archiveURL)
            archiveStatusMessage = "Archive folder opened."
        } else if fileManager.fileExists(atPath: fallbackURL.path) {
            NSWorkspace.shared.open(fallbackURL)
            archiveStatusMessage = "Archive folder does not exist yet. Opened BabbelStream support folder."
        } else {
            NSWorkspace.shared.open(fallbackURL.deletingLastPathComponent())
            archiveStatusMessage = "Archive folder does not exist yet."
        }
        archiveErrorMessage = nil
        recordDiagnostic("archive folder reveal requested")
        notifyStateChanged()
    }

    func clearArchive() {
        do {
            try dictationArchiveStore.clearArchive()
            let month = DictationArchiveMonth(string: archiveMonthText) ?? DictationArchiveMonth.current()
            archiveSnapshot = DictationArchiveMonthSnapshot(month: month, entries: [])
            archiveErrorMessage = nil
            archiveStatusMessage = "Archive cleared."
            lastResult = "Dictation archive cleared."
            recordDiagnostic("dictation archive cleared")
        } catch {
            archiveErrorMessage = error.localizedDescription
            archiveStatusMessage = "Archive could not be cleared."
            recordDiagnostic("archive clear failed: \(diagnosticErrorCategory(error))")
        }

        notifyStateChanged()
    }

    func openTeachCorrection() {
        onTeachCorrectionRequested?()
    }

    func retryPasteLatestDraft() async {
        guard let latestFinalDraft else {
            return
        }

        captureCurrentPasteTarget()
        do {
            _ = try await insertFinalDraft(latestFinalDraft)
        } catch {
            status = "Ready"
            lastResult = "Paste retry canceled."
            recordDiagnostic("paste retry canceled")
        }
    }

    func openMicrophonePrivacySettings() {
        openSystemSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Microphone")
    }

    func openAccessibilityPrivacySettings() {
        openSystemSettings("x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")
    }

    func prepareForTermination() {
        stopElapsedTimer()
        processingTask?.cancel()
        setCancelHotkeyEnabled(false)

        do {
            try audioRecorder.cancelImmediately()
        } catch {
            recordDiagnostic("termination recording cleanup failed: \(diagnosticErrorCategory(error))")
        }

        if let retainedTemporaryAudioURL {
            recordDiagnostic("termination left unsafeguarded temporary audio for startup recovery attention")
            self.retainedTemporaryAudioURL = retainedTemporaryAudioURL
        }
        resetRecordingState()
    }

    private func recordDiagnostic(_ message: String) {
        Self.diagnosticsLogger.info("\(message, privacy: .public)")
        let elapsedMilliseconds = activeDiagnosticOperationStartedAt.map { self.elapsedMilliseconds(since: $0) }
        diagnostics.append(DiagnosticEvent(
            timestamp: Date(),
            message: message,
            operationID: activeDiagnosticOperationID,
            elapsedMilliseconds: elapsedMilliseconds
        ))
        if diagnostics.count > 50 {
            diagnostics.removeFirst(diagnostics.count - 50)
        }
        notifyStateChanged()
    }

    private func diagnosticsReport() -> String {
        let lines = [
            "\(ProjectDefaults.appName) diagnostics",
            "version: \(BuildMetadata.appVersion)",
            "build commit: \(BuildMetadata.gitCommitShortHash)",
            "bundle path: \(appBundlePath)",
            "bundle identifier: \(appBundleIdentifier)",
            "code signing: \(codeSigningSummary)",
            "status: \(status)",
            "last failure category: \(lastFailureCategory)",
            "transcription destination: \(providerDestinationSummary)",
            "cleanup destination: \(cleanupDestinationSummary)",
            "transcription model: \(appSettings.providerConfiguration.transcriptionModel)",
            "fallback transcription model: \(ProjectDefaults.fallbackTranscriptionModel)",
            "transcription hedge delay seconds: \(String(format: "%.1f", ProjectDefaults.transcriptionHedgeDelaySeconds))",
            "transcription overall deadline seconds: \(String(format: "%.1f", ProjectDefaults.transcriptionOverallTimeoutSeconds))",
            "cleanup model: \(appSettings.providerConfiguration.cleanupModel)",
            "cleanup timeout seconds: \(String(format: "%.1f", appSettings.providerConfiguration.timeoutSeconds))",
            "connection timeout seconds: \(String(format: "%.1f", ProjectDefaults.providerConnectionTimeoutSeconds))",
            "max recording minutes: \(Self.durationMinutesText(for: appSettings.maxAudioDurationSeconds))",
            "cleanup enabled: \(appSettings.cleanupEnabled)",
            "api key saved: \(hasAPIKey)",
            "microphone: \(microphonePermissionStatus.displayName)",
            "accessibility: \(accessibilityPermissionStatus.displayName)",
            "launch at login: \(launchAtLoginEnabled)",
            "personal dictionary: \(personalDictionarySummary)",
            "archive enabled: \(dictationArchiveEnabled)",
            "archive raw transcript enabled: \(dictationArchiveEnabled && archiveRawTranscriptEnabled)",
            "archive path: \(archiveDirectoryPath)",
            "archive loaded month: \(archiveSnapshot.month.directoryName)",
            "archive loaded entries: \(archiveSnapshot.entries.count)",
            "failed recordings: \(recoverySnapshot.recordings.count)",
            "failed recording bytes: \(recoverySnapshot.totalByteCount)",
            "usage dictations: \(usageSnapshot.totalDictations)",
            "usage recorded seconds: \(String(format: "%.1f", usageSnapshot.totalRecordedSeconds))",
            "cleanup requests: \(usageSnapshot.cleanupRequests)",
            "transcription failures: \(usageSnapshot.transcriptionFailures)",
            "cleanup fallbacks: \(usageSnapshot.cleanupFallbacks)",
            "recent events:",
            diagnosticReportSummaries.joined(separator: "\n")
        ]

        return lines.joined(separator: "\n")
    }

    private func settingsFromDraft() throws -> AppSettings {
        guard let baseURL = URL(string: baseURLText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw SettingsValidationError.invalidBaseURL
        }
        guard let timeout = TimeInterval(timeoutText.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            throw SettingsValidationError.invalidTimeout
        }
        guard let maxAudioDurationMinutes = TimeInterval(
            maxAudioDurationMinutesText.trimmingCharacters(in: .whitespacesAndNewlines)
        ) else {
            throw SettingsValidationError.invalidMaxAudioDuration
        }

        let rawLanguage = transcriptionLanguageText.trimmingCharacters(in: .whitespacesAndNewlines)
        let normalizedLanguage = TranscriptionLanguageNormalizer.apiValue(from: rawLanguage) ?? rawLanguage
        let configuration = ProviderConfiguration(
            baseURL: baseURL,
            transcriptionEndpointPath: transcriptionPathText,
            cleanupEndpointPath: cleanupPathText,
            transcriptionModel: transcriptionModelText,
            cleanupModel: cleanupModelText,
            timeoutSeconds: timeout
        )
        let settings = AppSettings(
            providerConfiguration: configuration,
            cleanupEnabled: cleanupEnabled,
            transcriptionResponseFormat: ProjectDefaults.defaultTranscriptionResponseFormat,
            transcriptionLanguage: normalizedLanguage,
            transcriptionPrompt: transcriptionPromptText,
            maxAudioDurationSeconds: maxAudioDurationMinutes * 60,
            dictationArchiveEnabled: dictationArchiveEnabled,
            archiveRawTranscriptEnabled: dictationArchiveEnabled && archiveRawTranscriptEnabled
        )
        try AppSettingsValidator.validate(settings)

        return settings
    }

    private func effectiveDestination(baseURL: URL, path: String) -> String {
        ProviderEndpointBuilder.endpointURL(baseURL: baseURL, path: path)?.absoluteString
            ?? "Invalid saved destination"
    }

    private static func durationMinutesText(for duration: TimeInterval) -> String {
        let minutes = duration / 60
        if minutes.rounded(.towardZero) == minutes {
            return "\(Int(minutes))"
        }

        return String(format: "%.1f", minutes)
    }

    private func notifyStateChanged() {
        onStateChanged?()
        for observer in stateChangeObservers.values {
            observer()
        }
    }

    private func validateSettingsBeforeDictation() -> Bool {
        do {
            try AppSettingsValidator.validate(appSettings)
            return true
        } catch {
            status = "Settings invalid"
            lastResult = "Dictation not started."
            errorMessage = error.localizedDescription
            lastFailureCategory = diagnosticErrorCategory(error)
            recordDiagnostic("dictation not started: invalid settings \(lastFailureCategory)")
            notifyStateChanged()
            return false
        }
    }

    private func saveUsageSnapshot() {
        usageTracker.save(usageSnapshot)
        notifyStateChanged()
    }

    private func handleProviderEvent(
        _ event: ProviderRequestEvent,
        stage: String,
        settings: AppSettings
    ) {
        let overallTimeout = settings.providerConfiguration.timeoutSeconds
        let connectionTimeout = min(ProjectDefaults.providerConnectionTimeoutSeconds, overallTimeout)

        switch event {
        case let .requestPrepared(requestBytes, audioBytes, preparationMilliseconds):
            let audioDetail = audioBytes.map { ", audio \($0) bytes" } ?? ""
            recordDiagnostic("\(stage) request prepared in \(preparationMilliseconds) ms: \(requestBytes) bytes\(audioDetail)")
        case let .attemptStarted(attempt, totalAttempts):
            if stage.hasPrefix("transcription") {
                status = stage.contains("fallback") ? "Trying Mini transcription" : "Transcribing"
                transcriptionProgressDetail = "Attempt \(attempt) of \(totalAttempts) • connection timeout \(Self.secondsLabel(connectionTimeout)) • overall timeout \(Self.secondsLabel(overallTimeout)) • Escape cancels"
            }
            recordDiagnostic("\(stage) attempt \(attempt)/\(totalAttempts) started")
        case let .responseReceived(attempt, statusCode, responseBytes):
            recordDiagnostic("\(stage) attempt \(attempt) response: HTTP \(statusCode), \(responseBytes) bytes")
        case let .attemptSucceeded(attempt, totalAttempts, durationMilliseconds):
            recordDiagnostic("\(stage) attempt \(attempt)/\(totalAttempts) succeeded in \(durationMilliseconds) ms")
        case let .attemptFailed(attempt, totalAttempts, durationMilliseconds, category, willRetry):
            recordDiagnostic("\(stage) attempt \(attempt)/\(totalAttempts) failed in \(durationMilliseconds) ms: \(category.displayName), retry \(willRetry ? "yes" : "no")")
        case let .retryScheduled(nextAttempt, totalAttempts, reason):
            status = "Retrying transcription"
            transcriptionProgressDetail = "Retrying after \(reason.displayName) • attempt \(nextAttempt) of \(totalAttempts) starts shortly • Escape cancels"
            recordDiagnostic(
                "\(stage) retry scheduled: attempt \(nextAttempt)/\(totalAttempts), \(reason.displayName)"
            )
        }
    }

    private static func secondsLabel(_ seconds: TimeInterval) -> String {
        if seconds.rounded(.towardZero) == seconds {
            return "\(Int(seconds))s"
        }
        return String(format: "%.1fs", seconds)
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
        hotkeyService.onCancel = { [weak self] in
            Task { @MainActor in
                guard let self else {
                    return
                }
                await self.cancelRecording()
            }
        }

        do {
            try hotkeyService.register()
            hotkeyStatus = "\(ProjectDefaults.fixedHotkeyDescription) registered."
        } catch {
            hotkeyStatus = error.localizedDescription
        }
    }

    private func setCancelHotkeyEnabled(_ isEnabled: Bool) {
        do {
            try hotkeyService.setCancelEnabled(isEnabled)
        } catch {
            if isEnabled {
                warningMessage = combinedWarning(
                    warningMessage,
                    "Escape could not be registered for this dictation. Use Cancel in the status HUD or menu."
                )
            }
            recordDiagnostic(
                "cancel hotkey \(isEnabled ? "registration" : "removal") failed: \(diagnosticErrorCategory(error))"
            )
        }
    }

    private func handleDictationHotkeyPressed() async {
        guard canStart else {
            recordDiagnostic("hotkey press ignored: busy")
            return
        }

        activeDiagnosticOperationID = UUID()
        activeDiagnosticOperationStartedAt = ContinuousClock.now
        recordDiagnostic("hotkey pressed")

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

        if mode == .dictation, activeDiagnosticOperationID == nil {
            activeDiagnosticOperationID = UUID()
            activeDiagnosticOperationStartedAt = ContinuousClock.now
            recordDiagnostic("dictation started from app control")
        }

        if mode == .dictation, !validateSettingsBeforeDictation() {
            return
        }

        let settingsSnapshot = appSettings

        if mode == .dictation {
            captureCurrentPasteTarget()
        }
        cleanupStaleTemporaryAudio()
        isProcessing = true
        warningMessage = nil
        errorMessage = nil
        lastResult = "Preparing recording..."

        let newStatus = await audioRecorder.requestMicrophonePermission()
        microphonePermissionStatus = newStatus

        guard newStatus.canRecord else {
            status = "Microphone unavailable"
            lastResult = "Recording not started."
            errorMessage = microphoneGuidance(for: newStatus)
            isProcessing = false
            recordDiagnostic("recording not started: microphone \(newStatus.displayName)")
            completeDiagnosticOperation()
            return
        }

        do {
            try await audioRecorder.start(maxDuration: settingsSnapshot.maxAudioDurationSeconds)
            recordingStartedAt = Date()
            elapsedSeconds = 0
            recordingMode = mode
            activeDictationSettings = mode == .dictation ? settingsSnapshot : nil
            isRecording = true
            setCancelHotkeyEnabled(true)
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
            completeDiagnosticOperation()
        }

        isProcessing = false
        notifyStateChanged()
    }

    private func stopAndProcessDictation(autoStopped: Bool = false) async {
        if let processingTask {
            await processingTask.value
            return
        }

        guard isRecording || recordingStartedAt != nil else {
            return
        }

        let task = Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            await self.performStopAndProcessDictation(autoStopped: autoStopped)
        }
        processingTask = task
        await task.value
        processingTask = nil
        notifyStateChanged()
    }

    private func performStopAndProcessDictation(autoStopped: Bool) async {
        guard isRecording || recordingStartedAt != nil else {
            return
        }

        isProcessing = true
        stopElapsedTimer()

        do {
            let settingsSnapshot = activeDictationSettings ?? appSettings
            recordDiagnostic("recording stop started")
            let stopStartedAt = ContinuousClock.now
            let recording = try await audioRecorder.stop(deleteTemporaryFile: false)
            recordDiagnostic("recording stop completed in \(elapsedMilliseconds(since: stopStartedAt)) ms")
            retainedTemporaryAudioURL = recording.temporaryFileURL
            resetRecordingState()
            elapsedSeconds = recording.duration
            recordDiagnostic("recording stopped: dictation, \(formatDuration(recording.duration))")
            let recoveryRecording = try dictationRecoveryStore.adopt(
                recording,
                target: latestPasteTarget ?? latestExternalPasteTarget,
                settings: settingsSnapshot
            )
            activeRecoveryRecording = recoveryRecording
            retainedTemporaryAudioURL = nil
            let safeguardedRecording = RecordedAudio(
                temporaryFileURL: try dictationRecoveryStore.audioURL(for: recoveryRecording),
                duration: recording.duration,
                byteCount: recording.byteCount,
                createdAt: recording.createdAt,
                deletedAt: nil
            )
            recordDiagnostic("recording safeguarded for processing: \(recording.byteCount) bytes")
            refreshRecoveryRecordings()
            try await processRecording(safeguardedRecording, settings: settingsSnapshot, autoStopped: autoStopped)
        } catch {
            resetRecordingState()
            transcriptionProgressDetail = nil
            if ProviderRetryPolicy.isCancellation(error) {
                status = "Ready"
                errorMessage = nil
                lastResult = retainedTemporaryAudioURL == nil
                    ? "Processing canceled; recording saved in Failed Recordings."
                    : "Dictation canceled. Temporary audio cleanup needs attention."
                lastFailureCategory = "None"
                recordDiagnostic("dictation processing canceled")
            } else {
                status = "Dictation failed"
                errorMessage = error.localizedDescription
                lastResult = activeRecoveryRecording == nil
                    ? "Could not finish dictation safely."
                    : "Recording saved in Failed Recordings."
                lastFailureCategory = diagnosticErrorCategory(error)
                recordDiagnostic("dictation failed: \(lastFailureCategory)")
            }
        }

        isProcessing = false
        setCancelHotkeyEnabled(false)
        activeRecoveryRecording = nil
        completeDiagnosticOperation()
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
        setCancelHotkeyEnabled(false)
        notifyStateChanged()
    }

    private func processRecording(
        _ recording: RecordedAudio,
        settings: AppSettings,
        autoStopped: Bool
    ) async throws {
        do {
            let cleanupFallbackUsed = try await processRecordedAudio(
                recording,
                settings: settings,
                autoStopped: autoStopped
            )
            if cleanupFallbackUsed {
                preserveActiveRecoveryRecording(state: .cleanupFailed, failureCategory: lastFailureCategory)
                status = "Cleanup failed"
                lastResult = "Raw draft delivered; recording saved in Failed Recordings."
            } else {
                deleteActiveRecoveryRecording()
            }
        } catch {
            let state: DictationRecoveryState = ProviderRetryPolicy.isCancellation(error)
                ? .processingCanceled
                : .transcriptionFailed
            preserveActiveRecoveryRecording(state: state, failureCategory: diagnosticErrorCategory(error))
            throw error
        }
    }

    private func processRecordedAudio(
        _ recording: RecordedAudio,
        settings: AppSettings,
        autoStopped: Bool
    ) async throws -> Bool {
        try Task.checkCancellation()

        if !TranscriptionLanguageNormalizer.isValidForSettings(settings.transcriptionLanguage) {
            warningMessage = "Language setting ignored. Use a single code like de or en, or leave it empty for mixed German-English."
            recordDiagnostic("transcription language ignored: invalid language setting")
        }

        let keyLoadStartedAt = ContinuousClock.now
        let apiKey = try loadAPIKeyForDictation()
        recordDiagnostic("api key loaded in \(elapsedMilliseconds(since: keyLoadStartedAt)) ms")
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            recordDiagnostic("transcription not started: missing API key")
            throw ProviderError.missingAPIKey
        }

        usageSnapshot.recordDictation(duration: recording.duration)
        saveUsageSnapshot()

        status = autoStopped ? "Max reached; transcribing" : "Transcribing"
        lastResult = "Sending audio to \(settings.providerConfiguration.baseURL.host ?? settings.providerConfiguration.baseURL.absoluteString)."
        transcriptionProgressDetail = nil
        recordDiagnostic("transcription started")

        let rawTranscript = try await transcribeRecording(
            at: recording.temporaryFileURL,
            settings: settings,
            apiKey: apiKey
        )
        let preparedDraft = try await prepareDraft(
            from: rawTranscript,
            settings: settings,
            apiKey: apiKey
        )

        try Task.checkCancellation()
        latestRawTranscript = preparedDraft.rawTranscript
        latestFinalDraft = preparedDraft.finalDraft
        if warningMessage == nil {
            lastFailureCategory = "None"
        }

        let insertionOutcome = try await insertFinalDraft(preparedDraft.finalDraft)
        appendDictationArchiveEntry(
            recording: recording,
            settings: settings,
            rawTranscript: preparedDraft.rawTranscript,
            finalDraft: preparedDraft.finalDraft,
            cleanupWasEnabled: preparedDraft.cleanupWasEnabled,
            cleanupFallbackUsed: preparedDraft.cleanupFallbackUsed,
            insertionOutcome: insertionOutcome
        )
        return preparedDraft.cleanupFallbackUsed
    }

    private func transcribeRecording(
        at audioURL: URL,
        settings: AppSettings,
        apiKey: String
    ) async throws -> String {
        var configuredPrimarySettings = settings
        configuredPrimarySettings.providerConfiguration.timeoutSeconds = ProjectDefaults.transcriptionOverallTimeoutSeconds
        let primarySettings = configuredPrimarySettings

        do {
            var configuredFallbackSettings = primarySettings
            configuredFallbackSettings.providerConfiguration.transcriptionModel = ProjectDefaults.fallbackTranscriptionModel
            let fallbackSettings = configuredFallbackSettings
            let result = try await HedgedTranscriptionRunner.run(
                shouldHedgeAfterError: ProviderRetryPolicy.shouldRetry,
                onHedgeStarted: { [weak self] in
                    await MainActor.run {
                        guard let self else { return }
                        self.status = "Trying Mini transcription"
                        self.recordDiagnostic("transcription hedge started: \(ProjectDefaults.fallbackTranscriptionModel)")
                    }
                },
                primary: { [transcriptionProvider] in
                    try await transcriptionProvider.transcribe(
                    TranscriptionRequest(
                        audioURL: audioURL,
                        settings: primarySettings,
                        apiKey: apiKey,
                        onEvent: { [weak self] event in
                            await self?.handleProviderEvent(
                                event,
                                stage: "transcription primary",
                                settings: primarySettings
                            )
                        }
                    )
                    )
                },
                fallback: { [fallbackTranscriptionProvider] in
                    try await fallbackTranscriptionProvider.transcribe(
                    TranscriptionRequest(
                        audioURL: audioURL,
                        settings: fallbackSettings,
                        apiKey: apiKey,
                        onEvent: { [weak self] event in
                            await self?.handleProviderEvent(
                                event,
                                stage: "transcription fallback",
                                settings: fallbackSettings
                            )
                        }
                    )
                    )
                }
            )

            transcriptionProgressDetail = nil
            recordDiagnostic("transcription succeeded via \(result.winningRole.rawValue): \(result.transcript.count) characters")
            try Task.checkCancellation()
            return result.transcript
        } catch {
            transcriptionProgressDetail = nil
            if ProviderRetryPolicy.isCancellation(error) {
                throw CancellationError()
            }
            usageSnapshot.recordTranscriptionFailure()
            saveUsageSnapshot()
            throw error
        }
    }

    private func prepareDraft(
        from rawTranscript: String,
        settings: AppSettings,
        apiKey: String
    ) async throws -> PreparedDraft {
        guard settings.cleanupEnabled else {
            warningMessage = nil
            recordDiagnostic("cleanup skipped")
            return PreparedDraft(
                rawTranscript: rawTranscript,
                finalDraft: rawTranscript,
                cleanupWasEnabled: false,
                cleanupFallbackUsed: false
            )
        }

        status = "Cleaning up"
        recordDiagnostic("cleanup started")
        usageSnapshot.recordCleanupRequest()
        saveUsageSnapshot()

        let personalDictionary = loadPersonalDictionaryForCleanup()
        let dictionaryWarning = warningMessage

        do {
            let finalDraft = try await cleanupProvider.cleanup(
                CleanupRequest(
                    transcript: rawTranscript,
                    settings: settings,
                    apiKey: apiKey,
                    personalDictionary: personalDictionary,
                    onEvent: { [weak self] event in
                        await self?.handleProviderEvent(event, stage: "cleanup", settings: settings)
                    }
                )
            )
            warningMessage = dictionaryWarning
            recordDiagnostic("cleanup succeeded: \(finalDraft.count) characters")
            return PreparedDraft(
                rawTranscript: rawTranscript,
                finalDraft: finalDraft,
                cleanupWasEnabled: true,
                cleanupFallbackUsed: false
            )
        } catch {
            if ProviderRetryPolicy.isCancellation(error) {
                throw CancellationError()
            }

            warningMessage = "Cleanup failed; using raw transcript. \(error.localizedDescription)"
            usageSnapshot.recordCleanupFallback()
            saveUsageSnapshot()
            lastFailureCategory = diagnosticErrorCategory(error)
            recordDiagnostic("cleanup failed; using raw transcript: \(lastFailureCategory)")
            return PreparedDraft(
                rawTranscript: rawTranscript,
                finalDraft: rawTranscript,
                cleanupWasEnabled: true,
                cleanupFallbackUsed: true
            )
        }
    }

    @discardableResult
    private func deleteRetainedTemporaryAudio(at url: URL) -> Bool {
        let startedAt = ContinuousClock.now
        do {
            _ = try AudioTempFileStore.deleteTemporaryAudio(at: url)
            if retainedTemporaryAudioURL == url {
                retainedTemporaryAudioURL = nil
            }
            recordDiagnostic("temporary audio deleted in \(elapsedMilliseconds(since: startedAt)) ms")
            return true
        } catch {
            warningMessage = combinedWarning(
                warningMessage,
                "Temporary audio could not be deleted. Quit and relaunch BabbelStream before continuing with sensitive dictation."
            )
            lastFailureCategory = diagnosticErrorCategory(error)
            recordDiagnostic("temporary audio deletion failed: \(lastFailureCategory)")
            return false
        }
    }

    private func preserveActiveRecoveryRecording(
        state: DictationRecoveryState,
        failureCategory: String?
    ) {
        guard let activeRecoveryRecording else {
            return
        }
        do {
            self.activeRecoveryRecording = try dictationRecoveryStore.update(
                activeRecoveryRecording,
                state: state,
                failureCategory: failureCategory,
                incrementRetryCount: false
            )
            recordDiagnostic("failed recording retained: \(state.rawValue)")
            refreshRecoveryRecordings()
        } catch {
            warningMessage = combinedWarning(
                warningMessage,
                "Recording audio still exists, but its recovery status could not be updated."
            )
            recordDiagnostic("failed recording metadata update failed: \(diagnosticErrorCategory(error))")
        }
    }

    private func deleteActiveRecoveryRecording() {
        guard let activeRecoveryRecording else {
            return
        }
        do {
            try dictationRecoveryStore.delete(activeRecoveryRecording)
            self.activeRecoveryRecording = nil
            recordDiagnostic("safeguarded recording deleted after successful processing")
            refreshRecoveryRecordings()
        } catch {
            warningMessage = combinedWarning(
                warningMessage,
                "Successful dictation audio could not be deleted. Remove it from Failed Recordings."
            )
            recordDiagnostic("safeguarded recording deletion failed: \(diagnosticErrorCategory(error))")
        }
    }

    private func loadRecoveryRecordings(markProcessingAsInterrupted: Bool) {
        do {
            recoverySnapshot = try dictationRecoveryStore.loadSnapshot(
                markProcessingAsInterrupted: markProcessingAsInterrupted
            )
            recoveryStatusMessage = recoverySnapshot.recordings.isEmpty
                ? "No failed recordings."
                : recoverySummary
            recoveryErrorMessage = nil
            if recoverySnapshot.recoveredMetadataCount > 0 {
                recordDiagnostic("failed recording metadata recovered: \(recoverySnapshot.recoveredMetadataCount)")
            }
        } catch {
            recoveryErrorMessage = error.localizedDescription
            recoveryStatusMessage = "Failed recordings could not be loaded."
            recordDiagnostic("failed recordings load failed: \(diagnosticErrorCategory(error))")
        }
    }

    private func refreshRecoveryRecordings() {
        loadRecoveryRecordings(markProcessingAsInterrupted: false)
        notifyStateChanged()
    }

    private func appendDictationArchiveEntry(
        recording: RecordedAudio,
        settings: AppSettings,
        rawTranscript: String,
        finalDraft: String,
        cleanupWasEnabled: Bool,
        cleanupFallbackUsed: Bool,
        insertionOutcome: DictationArchiveInsertionOutcome
    ) {
        guard settings.dictationArchiveEnabled else {
            return
        }

        let pasteTarget = latestPasteTarget ?? latestExternalPasteTarget
        let configuration = settings.providerConfiguration
        let entry = DictationArchiveEntry(
            startedAt: recording.createdAt,
            completedAt: Date(),
            audioDurationSeconds: recording.duration,
            activeAppName: pasteTarget?.localizedName,
            activeAppBundleIdentifier: pasteTarget?.bundleIdentifier,
            cleanupEnabled: cleanupWasEnabled,
            cleanupFallbackUsed: cleanupFallbackUsed,
            insertionOutcome: insertionOutcome,
            transcriptionProviderLabel: providerLabel(model: configuration.transcriptionModel, settings: settings),
            cleanupProviderLabel: cleanupWasEnabled
                ? providerLabel(model: configuration.cleanupModel, settings: settings)
                : nil,
            transcriptionLanguage: TranscriptionLanguageNormalizer.apiValue(from: settings.transcriptionLanguage),
            rawWordCount: DictationWordCounter.count(in: rawTranscript),
            finalWordCount: DictationWordCounter.count(in: finalDraft),
            finalDraftText: finalDraft,
            rawTranscriptText: settings.archiveRawTranscriptEnabled ? rawTranscript : nil
        )

        do {
            let startedAt = ContinuousClock.now
            try dictationArchiveStore.append(entry)
            recordDiagnostic("archive entry written in \(elapsedMilliseconds(since: startedAt)) ms: \(entry.finalWordCount) final words")
            if DictationArchiveMonth(string: archiveMonthText) == DictationArchiveMonth.containing(entry.startedAt) {
                loadArchiveMonth()
            }
        } catch {
            warningMessage = combinedWarning(
                warningMessage,
                "Dictation archive could not be written. \(error.localizedDescription)"
            )
            recordDiagnostic("archive write failed: \(diagnosticErrorCategory(error))")
            notifyStateChanged()
        }
    }

    private func providerLabel(model: String, settings: AppSettings) -> String {
        let configuration = settings.providerConfiguration
        let host = configuration.baseURL.host ?? configuration.baseURL.absoluteString
        return "\(host) / \(model)"
    }

    private func loadPersonalDictionaryForCleanup() -> PersonalDictionary {
        do {
            let dictionary = try personalDictionaryStore.load()
            if let context = DictionaryPromptBuilder.cleanupContextDetails(for: dictionary) {
                personalDictionarySummary = "\(context.includedVocabularyCount) terms, \(context.includedCorrectionsCount) corrections"
                if context.wasTruncated {
                    let skipped = context.skippedVocabularyCount + context.skippedCorrectionsCount
                    warningMessage = "Personal dictionary loaded, but \(skipped) entries were skipped because the prompt context is too large."
                    personalDictionarySummary += ", \(skipped) skipped"
                    recordDiagnostic("personal dictionary truncated: \(skipped) skipped")
                }
                recordDiagnostic(
                    "personal dictionary loaded: \(context.includedVocabularyCount) terms, \(context.includedCorrectionsCount) corrections"
                )
            } else {
                personalDictionarySummary = "0 terms, 0 corrections"
            }
            return dictionary
        } catch {
            warningMessage = "Personal dictionary could not be loaded; continuing without it."
            personalDictionarySummary = "Load failed"
            recordDiagnostic("personal dictionary load failed: \(diagnosticErrorCategory(error))")
            return PersonalDictionary()
        }
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

        return apiKey
    }

    private func insertFinalDraft(_ finalDraft: String) async throws -> DictationArchiveInsertionOutcome {
        status = "Pasting draft"
        let startedAt = ContinuousClock.now
        recordDiagnostic("paste started")
        let pasteTarget = latestPasteTarget ?? latestExternalPasteTarget
        let insertionText = DictationDraftFormatter.textWithTrailingSeparator(finalDraft)
        let priorWarning = warningMessage

        do {
            let insertionResult = try await textInsertionService.insertText(insertionText, target: pasteTarget)
            recordDiagnostic("paste operation completed in \(elapsedMilliseconds(since: startedAt)) ms")
            accessibilityPermissionStatus = textInsertionService.accessibilityPermissionStatus()
            let outcome = applySuccessfulInsertionResult(insertionResult, priorWarning: priorWarning)
            notifyStateChanged()
            return outcome
        } catch {
            if ProviderRetryPolicy.isCancellation(error) {
                throw CancellationError()
            }
            let outcome = copyAfterInsertionFailure(insertionText, originalError: error)
            notifyStateChanged()
            return outcome
        }
    }

    private func applySuccessfulInsertionResult(
        _ insertionResult: TextInsertionResult,
        priorWarning: String?
    ) -> DictationArchiveInsertionOutcome {
        switch insertionResult {
        case .insertedDirectly:
            status = "Ready"
            lastResult = "Draft inserted. Review it before sending."
            errorMessage = nil
            warningMessage = priorWarning
            recordDiagnostic("paste succeeded: direct accessibility insertion")
            return .directAccessibilityInsertion
        case .pasteShortcutPosted:
            status = "Ready"
            lastResult = "Paste shortcut sent; draft is also on the clipboard."
            errorMessage = nil
            warningMessage = combinedWarning(
                priorWarning,
                "If the draft did not appear, press Cmd+V in the target field."
            )
            recordDiagnostic("paste shortcut posted; clipboard fallback retained")
            return .pasteShortcutPosted
        case .copiedForManualPaste:
            status = "Copied"
            lastResult = "Draft copied to clipboard. Paste manually with Cmd+V."
            errorMessage = "Accessibility is not allowed, so BabbelStream could not paste automatically."
            warningMessage = priorWarning
            recordDiagnostic("paste fallback: copied for manual paste")
            return .copiedForManualPaste
        case .copiedBecauseTargetChanged:
            status = "Copied"
            lastResult = "The active application changed while processing. Draft copied; paste manually with Cmd+V."
            errorMessage = nil
            warningMessage = combinedWarning(
                priorWarning,
                "BabbelStream did not auto-paste because the original application is no longer active."
            )
            recordDiagnostic("paste prevented: target application changed")
            return .copiedBecauseTargetChanged
        case .copiedAfterPasteShortcutFailure:
            status = "Copied"
            lastResult = "Draft copied to clipboard after paste shortcut failed."
            errorMessage = "BabbelStream could not post Cmd+V. Paste manually with Cmd+V."
            warningMessage = priorWarning
            recordDiagnostic("paste shortcut failed; clipboard fallback retained")
            return .copiedAfterPasteShortcutFailure
        }
    }

    private func copyAfterInsertionFailure(
        _ insertionText: String,
        originalError: Error
    ) -> DictationArchiveInsertionOutcome {
        do {
            try textInsertionService.copyText(insertionText)
            status = "Copied"
            lastResult = "Draft copied to clipboard after paste failed. Paste manually with Cmd+V."
            errorMessage = originalError.localizedDescription
            recordDiagnostic("paste failed; copied fallback: \(diagnosticErrorCategory(originalError))")
            return .copiedAfterPasteFailure
        } catch {
            status = "Paste failed"
            lastResult = "Draft is only available in memory for this app session."
            errorMessage = error.localizedDescription
            recordDiagnostic("paste and copy failed: \(diagnosticErrorCategory(error))")
            return .memoryOnlyAfterPasteFailure
        }
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

        let maxDuration = activeDictationSettings?.maxAudioDurationSeconds ?? appSettings.maxAudioDurationSeconds
        if elapsedSeconds >= maxDuration, !isProcessing {
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
        activeDictationSettings = nil
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

    private func elapsedMilliseconds(since start: ContinuousClock.Instant) -> Int {
        let duration = start.duration(to: ContinuousClock.now).components
        return max(0, Int(duration.seconds * 1_000) + Int(duration.attoseconds / 1_000_000_000_000_000))
    }

    private func completeDiagnosticOperation() {
        guard let operationID = activeDiagnosticOperationID else {
            return
        }
        recordDiagnostic("dictation operation completed")
        lastCompletedDiagnosticOperationID = operationID
        activeDiagnosticOperationID = nil
        activeDiagnosticOperationStartedAt = nil
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

    private func combinedWarning(_ first: String?, _ second: String) -> String {
        guard let first, !first.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return second
        }

        return "\(first) \(second)"
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
        case .connectionTimedOut:
            return "ProviderError.connectionTimedOut"
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
        case .insecureBaseURL:
            return "SettingsValidationError.insecureBaseURL"
        case .ambiguousBaseURL:
            return "SettingsValidationError.ambiguousBaseURL"
        case .missingTranscriptionModel:
            return "SettingsValidationError.missingTranscriptionModel"
        case .missingCleanupModel:
            return "SettingsValidationError.missingCleanupModel"
        case .missingTranscriptionPath:
            return "SettingsValidationError.missingTranscriptionPath"
        case .missingCleanupPath:
            return "SettingsValidationError.missingCleanupPath"
        case .invalidEndpointPath:
            return "SettingsValidationError.invalidEndpointPath"
        case .invalidTranscriptionLanguage:
            return "SettingsValidationError.invalidTranscriptionLanguage"
        case .invalidTimeout:
            return "SettingsValidationError.invalidTimeout"
        case .invalidMaxAudioDuration:
            return "SettingsValidationError.invalidMaxAudioDuration"
        }
    }

    if let hotkeyError = error as? HotkeyError {
        switch hotkeyError {
        case .couldNotInstallHandler:
            return "HotkeyError.couldNotInstallHandler"
        case .couldNotRegister:
            return "HotkeyError.couldNotRegister"
        case .couldNotRegisterCancel:
            return "HotkeyError.couldNotRegisterCancel"
        }
    }

    if let launchAtLoginError = error as? LaunchAtLoginError {
        switch launchAtLoginError {
        case .couldNotWriteLaunchAgent:
            return "LaunchAtLoginError.couldNotWriteLaunchAgent"
        case .couldNotRemoveLaunchAgent:
            return "LaunchAtLoginError.couldNotRemoveLaunchAgent"
        case let .launchctlFailed(command, status):
            return "LaunchAtLoginError.launchctlFailed(\(command), \(status))"
        }
    }

    return String(describing: type(of: error))
}
