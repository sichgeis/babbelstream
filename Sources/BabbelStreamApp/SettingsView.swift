import AppKit
import BabbelStreamCore
import SwiftUI

struct SettingsView: View {
    private enum Tab: String, CaseIterable {
        case general
        case provider
        case writing
        case archive
        case diagnostics
    }

    @EnvironmentObject private var appState: AppState
    @State private var selectedTab: Tab

    let onShowOnboarding: () -> Void

    init(initialTab: String? = nil, onShowOnboarding: @escaping () -> Void = {}) {
        self.onShowOnboarding = onShowOnboarding
        let tabArgument = CommandLine.arguments.first { $0.hasPrefix("--settings-tab=") }
        let tabName = tabArgument?.split(separator: "=", maxSplits: 1).last.map(String.init)
        _selectedTab = State(initialValue: Tab(rawValue: initialTab ?? tabName ?? "") ?? .general)
    }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Settings section", selection: $selectedTab) {
                ForEach(Tab.allCases, id: \.self) { tab in
                    Text(tab.rawValue.capitalized).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .fixedSize()
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)

            Group {
                switch selectedTab {
                case .general:
                    SettingsGeneralPane(onShowSetup: { selectedTab = .provider }, onShowOnboarding: onShowOnboarding)
                case .provider: SettingsProviderPane()
                case .writing: SettingsWritingPane()
                case .archive: SettingsArchivePane()
                case .diagnostics: SettingsDiagnosticsPane()
                }
            }

            Divider()
            settingsFooter
        }
        .background(AppFormBackground())
        .onReceive(NotificationCenter.default.publisher(for: .showProviderSetup)) { _ in selectedTab = .provider }
        .onAppear {
            appState.refreshPermissionStatuses()
            if appState.needsConnectionSetup,
               !CommandLine.arguments.contains(where: { $0.hasPrefix("--settings-tab=") }) {
                selectedTab = .provider
            }
        }
        .frame(minWidth: 700, idealWidth: 760, minHeight: 560, idealHeight: 640)
    }

    private var settingsFooter: some View {
        AppDialogFooter {
            Group {
                if let settingsErrorMessage = appState.settingsErrorMessage {
                    Text(settingsErrorMessage)
                        .foregroundStyle(.red)
                } else if appState.hasUnsavedSettingsChanges {
                    Text("Unsaved changes are not used for dictation until applied.")
                        .foregroundStyle(.orange)
                } else if !appState.settingsFeedbackMessage.isEmpty {
                    Text(appState.settingsFeedbackMessage)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Settings are up to date.")
                        .foregroundStyle(.secondary)
                }
            }
        } actions: {
            Button {
                appState.saveSettings()
            } label: {
                Label("Apply Settings", systemImage: "checkmark")
            }
            .keyboardShortcut(.defaultAction)
            .disabled(!appState.hasUnsavedSettingsChanges || appState.localModels.isBusy)
        }
    }
}

private struct SettingsPane<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        AppGroupedForm(maxContentWidth: .infinity) {
            content
        }
    }
}

private struct SettingsGeneralPane: View {
    @EnvironmentObject private var appState: AppState
    let onShowSetup: () -> Void
    let onShowOnboarding: () -> Void

    var body: some View {
        SettingsPane {
            AppFormSection("Readiness") {
                AppLabeledContent("Microphone", value: appState.microphonePermissionStatus.displayName)
                AppLabeledContent("Accessibility", value: appState.accessibilityPermissionStatus.displayName)
                AppLabeledContent("Primary connection", value: appState.connectionReadinessSummary)
                AppLabeledContent(
                    "Personal fallback",
                    value: appState.personalOpenAIFallbackReadinessSummary
                )
                AppLabeledContent("Launch at login", value: appState.launchAtLoginStatusSummary)
                AppLongValue(label: "Active provider", value: appState.activeProviderDestinationSummary)
                HStack(spacing: 8) {
                    Button("Set Up BabbelStream…", action: onShowOnboarding)
                    Button("Review Provider Setup…", action: onShowSetup)
                }

                if appState.microphonePermissionStatus != .authorized
                    || appState.accessibilityPermissionStatus != .trusted
                    || appState.launchAtLoginRequiresApproval {
                    HStack(spacing: 8) {
                        if appState.microphonePermissionStatus != .authorized {
                            Button("Request Microphone") {
                                Task { await appState.requestMicrophonePermission() }
                            }
                            Button("Microphone Settings…") { appState.openMicrophonePrivacySettings() }
                        }
                        if appState.accessibilityPermissionStatus != .trusted {
                            Button("Accessibility Settings…") { appState.openAccessibilityPrivacySettings() }
                        }
                        if appState.launchAtLoginRequiresApproval {
                            Button("Open Login Items") {
                                appState.openLoginItemsSettings()
                            }
                        }
                    }
                }
            }

            AppFormSection("Behavior") {
                Toggle(
                    "Cleanup enabled",
                    isOn: Binding(
                        get: { !appState.isLocalTranscriptionApplied && appState.cleanupEnabled },
                        set: { appState.setCleanupEnabled($0) }
                    )
                )
                .disabled(appState.isLocalTranscriptionApplied)
                Toggle(
                    "Launch at login",
                    isOn: Binding(
                        get: { appState.launchAtLoginEnabled },
                        set: { appState.setLaunchAtLoginEnabled($0) }
                    )
                )
                AppFormTextField("Max recording minutes", text: $appState.maxAudioDurationMinutesText)
                AppLabeledContent("Hybrid hotkey", value: ProjectDefaults.fixedHotkeyDescription)
                AppLabeledContent("Shortcut behavior", value: ProjectDefaults.hybridHotkeyUsageDescription)
            }

            AppFormSection("Safety") {
                AppLabeledContent("Saved max duration", value: formatSettingsDuration(appState.maxAudioDurationSeconds))
                AppLabeledContent("Auto-send", value: ProjectDefaults.autoSendEnabledByDefault ? "On" : "Off")
                AppLabeledContent("Default transcript history", value: ProjectDefaults.transcriptHistoryEnabledByDefault ? "On" : "Off")
            }
        }
    }

    private func formatSettingsDuration(_ duration: TimeInterval) -> String {
        let totalSeconds = Int(duration.rounded(.down))
        guard totalSeconds >= 60, totalSeconds % 60 == 0 else {
            return "\(totalSeconds)s"
        }

        return "\(totalSeconds / 60) min"
    }
}

private struct SettingsProviderPane: View {
    @EnvironmentObject private var appState: AppState
    @State private var showTestConfirmation = false
    @State private var showAdvanced = false

    var body: some View {
        SettingsPane {
            AppFormSection("Active Destinations") {
                AppLongValue(label: "Transcription", value: appState.providerDestinationSummary)
                AppLongValue(label: "Cleanup", value: appState.cleanupDestinationSummary)
                if appState.isPersonalOpenAIFallbackApplied {
                    AppLongValue(
                        label: "Personal fallback",
                        value: appState.personalOpenAIFallbackDestinationSummary
                    )
                }
                AppLabeledContent(
                    "Applied provider mode",
                    value: appState.isLocalTranscriptionApplied ? "On this Mac" : appState.isPersonalOpenAIDirectModeApplied
                        ? "Personal OpenAI now"
                        : "Primary first"
                )

                if appState.hasUnsavedConfigurationChanges {
                    AppLongValue(
                        label: "Edited transcription",
                        value: appState.editedProviderDestinationSummary,
                        isPending: true
                    )
                    AppLongValue(
                        label: "Edited cleanup",
                        value: appState.editedCleanupDestinationSummary,
                        isPending: true
                    )
                }
            }

            AppFormSection("Transcription") {
                Picker("Run transcription", selection: $appState.transcriptionBackend) {
                    Text("Remote provider").tag(TranscriptionBackend.remote)
                    Text("On this Mac").tag(.local as TranscriptionBackend)
                }
                .pickerStyle(.segmented)
                Text("Selection takes effect after Apply Settings. Local dictation uses no key, cloud fallback or cleanup.")
                    .font(.caption).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if appState.transcriptionBackend == .local {
                LocalModelsPane(controller: appState.localModels, selected: $appState.localModel,
                                canManage: appState.canStart)
            } else {
            AppFormSection("Provider Mode") {
                Toggle(
                    "Enable personal OpenAI fallback",
                    isOn: Binding(
                        get: { appState.personalOpenAIFallbackEnabled },
                        set: { appState.setPersonalOpenAIFallbackEnabledDraft($0) }
                    )
                )
                Toggle(
                    "Use personal OpenAI now (skip primary)",
                    isOn: Binding(
                        get: { appState.personalOpenAIDirectModeEnabled },
                        set: { appState.setPersonalOpenAIDirectModeEnabledDraft($0) }
                    )
                )
                .disabled(!appState.personalOpenAIFallbackEnabled)
                Text(appState.personalOpenAIDirectModeEnabled
                    ? "After Apply, every new dictation goes directly to personal OpenAI. LiteLLM and its Mini hedge are skipped. The HUD turns purple while this mode is active."
                    : "Leave this off for primary-first behavior with automatic personal fallback only after an eligible outage.")
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(.secondary)
                if appState.personalOpenAIFallbackEnabled {
                    Text("Work audio and text may be sent to https://api.openai.com with personal API charges. A separate per-user key is required; review the fallback details below before Apply.")
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(.secondary)
                }
            }

            AppFormSection("Connection Setup") {
                AppLabeledContent("Primary connection", value: appState.connectionReadinessSummary)
                Text("1. Confirm your authorized destination. 2. Enter your own revocable API key. 3. Apply, then test if desired.")
                    .font(.callout)
                Menu("Connection Preset") {
                    Button("Custom compatible provider") { appState.selectConnectionPreset(.custom) }
                    Button("Official OpenAI") { appState.selectConnectionPreset(.officialOpenAI) }
                }
                AppFormFieldGroup {
                    AppFormTextField("Provider base URL", text: $appState.baseURLText)
                    Text("Ask IT for your approved company URL and per-user key. A company preset is not available yet. Existing saved configuration is retained; presets leave models unchanged.")
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(.secondary)
                }
                AppFormFieldGroup {
                    AppFormSecureField(
                        appState.hasAPIKey ? "Saved in your Keychain; re-enter to replace or approve a new origin" : "Paste your per-user API key",
                        text: $appState.apiKeyInput
                    )
                    Text("Keys stay in your macOS Keychain. Changing origin requires explicit key entry for that destination; never distribute a shared master key.")
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(.secondary)
                }
                HStack(spacing: 8) {
                    Button("Test Saved Connection…") { showTestConfirmation = true }
                        .disabled(!appState.canTestSavedConnection)
                    if appState.isConnectionTesting {
                        Button("Cancel Test") { appState.cancelConnectionTest() }
                    }
                    Button("Delete Primary Key", role: .destructive) { appState.deleteAPIKey() }
                        .disabled(!appState.hasAPIKey)
                }
                Text(appState.connectionTestFeedback)
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(.secondary)
                if appState.hasUnsavedSettingsChanges {
                    Text("Apply edited settings and keys before testing. The test uses only the saved primary connection.")
                        .font(.caption)
                        .fixedSize(horizontal: false, vertical: true)
                        .foregroundStyle(.secondary)
                }
            }

            DisclosureGroup("Advanced: Endpoints, Models And Timeouts", isExpanded: $showAdvanced) {
                VStack(alignment: .leading, spacing: 16) {
                    AppFormSection("Endpoint Paths") {
                        AppFormTextField("Transcription path", text: $appState.transcriptionPathText)
                        AppFormTextField("Cleanup path", text: $appState.cleanupPathText)
                    }
                    AppFormSection("Models And Timeouts") {
                        AppLabeledContent("Primary transcription") {
                            Picker("Primary transcription model", selection: $appState.transcriptionModelText) {
                                ForEach(ProjectDefaults.supportedTranscriptionModels, id: \.self) { model in
                                    Text(model).tag(model)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                        }
                        Text("GPT Transcribe is the default. Choose a GPT-4o model only when your provider requires it.")
                            .font(.caption)
                            .fixedSize(horizontal: false, vertical: true)
                            .foregroundStyle(.secondary)
                        AppLabeledContent("Model routing") {
                            Picker("Model routing", selection: $appState.transcriptionModelRouting) {
                                ForEach(TranscriptionModelRouting.allCases, id: \.rawValue) { routing in
                                    Text(routing.displayName).tag(routing)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                        }
                        Text(appState.transcriptionModelRouting.helpText)
                            .font(.caption)
                            .fixedSize(horizontal: false, vertical: true)
                            .foregroundStyle(.secondary)
                        AppLabeledContent("Effective primary model", value: appState.effectiveTranscriptionModel)
                        AppLabeledContent("Effective fallback model", value: appState.effectiveFallbackTranscriptionModel)
                        AppFormTextField("Cleanup model", text: $appState.cleanupModelText)
                        AppLabeledContent("Mini hedge delay", value: "\(Int(ProjectDefaults.transcriptionHedgeDelaySeconds))s")
                        AppLabeledContent("Overall transcription deadline", value: "\(Int(ProjectDefaults.transcriptionOverallTimeoutSeconds))s")
                        AppFormTextField("Cleanup timeout (seconds)", text: $appState.timeoutText)
                        AppLabeledContent("Connection watchdog", value: appState.providerConnectionTimeoutSummary)
                        AppLabeledContent("Transcription requests", value: "Primary + one bounded Mini hedge")
                        AppLabeledContent("Personal fallback limit", value: "One sequential request")
                        Text("If primary transcription is still pending after 10 seconds, BabbelStream may send the same safeguarded audio once to Mini. The first valid result wins and both requests share one 75-second deadline. This rare recovery path may incur two transcription charges. Authentication and configuration failures do not hedge.")
                            .font(.caption)
                            .fixedSize(horizontal: false, vertical: true)
                            .foregroundStyle(.secondary)
                    }

                }
                .padding(.top, 12)
            }

            AppFormSection("Personal OpenAI Fallback") {
                AppLongValue(
                    label: "Transcription",
                    value: appState.personalOpenAIFallbackDestinationSummary
                )
                AppLongValue(
                    label: "Cleanup",
                    value: appState.personalOpenAIFallbackCleanupDestinationSummary
                )
                AppFormSecureField(
                    appState.hasPersonalOpenAIFallbackAPIKey
                        ? "Personal OpenAI key saved in Keychain"
                        : "Paste personal OpenAI API key",
                    text: $appState.personalOpenAIFallbackAPIKeyInput
                )
                AppLabeledContent(
                    "Personal Keychain item",
                    value: appState.hasPersonalOpenAIFallbackAPIKey ? "Saved" : "Missing"
                )
                Text("When the primary connection cannot be reached or returns gateway/service-unavailable HTTP 502, 503, or 504, BabbelStream may send the safeguarded audio, transcript cleanup, and personal dictionary context to your personal OpenAI account. This can expose work content outside the company provider and incur personal API charges. Invalid credentials, rate limits, model errors, and other HTTP failures never trigger this fallback.")
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(.secondary)

                Button(role: .destructive) {
                    appState.deletePersonalOpenAIFallbackAPIKey()
                } label: {
                    Label("Delete Personal OpenAI Key", systemImage: "trash")
                }
                .disabled(!appState.hasPersonalOpenAIFallbackAPIKey)
            }
            }
        }
        .alert("Test saved transcription connection?", isPresented: $showTestConfirmation) {
            Button("Send Synthetic Test") { Task { await appState.testSavedConnection() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(appState.connectionTestDisclosure)
        }
    }
}

private struct SettingsWritingPane: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        SettingsPane {
            AppFormSection("Transcription Hints") {
                AppFormFieldGroup {
                    AppFormTextField("Language code", text: $appState.transcriptionLanguageText)
                    Text("Optional. Leave blank to detect the spoken language.")
                        .font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                AppFormFieldGroup {
                    AppFormTextField("Transcription prompt", text: $appState.transcriptionPromptText, axis: .vertical)
                        .lineLimit(2...4)
                    Text(appState.isLocalTranscriptionApplied ? "Remote-only hint. Local vocabulary integration is not enabled in this pilot." : "Optional context to help transcription, such as technical terms.")
                        .font(.caption).foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            AppFormSection("Personal Dictionary") {
                AppLabeledContent("Cleanup context", value: appState.personalDictionarySummary)
                AppLabeledContent(
                    "Prompt limit",
                    value: "\(ProjectDefaults.maxPersonalDictionaryPromptCharacters) characters"
                )
                Button {
                    appState.openTeachCorrection()
                } label: {
                    Label("Teach Correction...", systemImage: "text.badge.plus")
                }
            }
        }
    }
}

private struct SettingsArchivePane: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        SettingsPane {
            AppFormSection("Dictation Archive") {
                Toggle(
                    "Archive completed dictations",
                    isOn: Binding(
                        get: { appState.dictationArchiveEnabled },
                        set: { appState.setDictationArchiveEnabled($0) }
                    )
                )
                Toggle(
                    "Store raw transcript in archive",
                    isOn: Binding(
                        get: { appState.archiveRawTranscriptEnabled },
                        set: { appState.setArchiveRawTranscriptEnabled($0) }
                    )
                )
                .disabled(!appState.dictationArchiveEnabled)
                Text("When enabled, BabbelStream writes work text to local daily files on this Mac. Audio is never archived.")
                    .font(.caption)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(.secondary)
                AppLongValue(label: "Archive folder", value: appState.archiveDirectoryPath)
            }
        }
    }
}

private struct SettingsDiagnosticsPane: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        SettingsPane {
            AppFormSection("Usage") {
                AppLabeledContent("Dictations", value: "\(appState.usageSnapshot.totalDictations)")
                AppLabeledContent("Recorded", value: appState.usageRecordedMinutesSummary)
                AppLabeledContent("Cleanup requests", value: "\(appState.usageSnapshot.cleanupRequests)")
                AppLabeledContent("Transcription failures", value: "\(appState.usageSnapshot.transcriptionFailures)")
                AppLabeledContent("Cleanup fallbacks", value: "\(appState.usageSnapshot.cleanupFallbacks)")
                Button {
                    appState.resetUsageCounters()
                } label: {
                    Label("Reset Usage Counters", systemImage: "arrow.counterclockwise")
                }
            }

            AppFormSection("Permissions") {
                AppLabeledContent("Microphone", value: appState.microphonePermissionStatus.displayName)
                AppLabeledContent("Accessibility", value: appState.accessibilityPermissionStatus.displayName)

                HStack(spacing: 8) {
                    Button {
                        appState.requestAccessibilityPermission()
                    } label: {
                        Label("Request Accessibility", systemImage: "hand.raised")
                    }
                    Button {
                        appState.refreshPermissionStatuses()
                    } label: {
                        Label("Refresh", systemImage: "arrow.clockwise")
                    }
                }
            }

            AppFormSection("Latest Draft") {
                AppLabeledContent("Raw transcript", value: appState.latestRawTranscriptSummary)
                AppLabeledContent("Final draft", value: appState.latestFinalDraftSummary)

                HStack(spacing: 8) {
                    Button {
                        appState.copyLatestDraft()
                    } label: {
                        Label("Copy Last Draft", systemImage: "doc.on.doc")
                    }
                    .disabled(!appState.canUseLatestDraft)

                    Button {
                        Task {
                            await appState.retryPasteLatestDraft()
                        }
                    } label: {
                        Label("Paste Last Draft", systemImage: "doc.on.clipboard")
                    }
                    .disabled(!appState.canUseLatestDraft || appState.isProcessing)
                }
            }

            AppFormSection("Diagnostics") {
                AppLabeledContent("Version", value: BuildMetadata.appVersion)
                AppLabeledContent("Build commit", value: BuildMetadata.gitCommitShortHash)
                AppLabeledContent("Bundle build", value: BuildMetadata.bundleBuildNumber)
                AppLabeledContent("Build mode", value: BuildMetadata.buildMode)
                AppLongValue(label: "App bundle", value: appState.appBundlePath)
                AppLabeledContent("Bundle ID", value: appState.appBundleIdentifier)
                AppLabeledContent("Code signing", value: appState.codeSigningSummary)
                AppLabeledContent("Last failure", value: appState.lastFailureCategory)
                Button {
                    appState.copyDiagnosticsReport()
                } label: {
                    Label("Copy Diagnostics", systemImage: "doc.on.doc")
                }

                if let accessibilityTroubleshootingSummary = appState.accessibilityTroubleshootingSummary {
                    Text(accessibilityTroubleshootingSummary)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }

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
    }
}

struct PersonalDictionaryView: View {
    let store: PersonalDictionaryStore
    let onTeachCorrection: () -> Void

    @State private var loadedDictionary = PersonalDictionary()
    @State private var vocabularyText = ""
    @State private var correctionsText = ""
    @State private var statusMessage = ""
    @State private var errorMessage: String?

    var body: some View {
        AppDialogScaffold(maxContentWidth: 680) {
            AppFormSection("Vocabulary") {
                Text("Add one preferred term per line. BabbelStream uses enabled entries as cleanup context.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $vocabularyText)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 140)
            }

            AppFormSection("Corrections") {
                Text("Use one mapping per line in the form heard text => preferred spelling.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextEditor(text: $correctionsText)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 140)
            }

            AppFormSection("Storage") {
                AppLongValue(label: "Dictionary file", value: store.fileURL.path)
                Button {
                    onTeachCorrection()
                } label: {
                    Label("Teach Correction...", systemImage: "text.badge.plus")
                }
            }
        } status: {
            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            } else if !statusMessage.isEmpty {
                Text(statusMessage)
                    .foregroundStyle(.secondary)
            } else {
                Text("Edit explicit local vocabulary and correction hints.")
                    .foregroundStyle(.secondary)
            }
        } actions: {
            Button {
                NSApp.keyWindow?.performClose(nil)
            } label: {
                Label("Close", systemImage: "xmark")
            }
            Button {
                load()
            } label: {
                Label("Reload", systemImage: "arrow.clockwise")
            }
            Button {
                save()
            } label: {
                Label("Save", systemImage: "checkmark")
            }
            .keyboardShortcut(.defaultAction)
        }
        .onAppear {
            load()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func load() {
        do {
            let dictionary = try store.load()
            loadedDictionary = dictionary
            vocabularyText = PersonalDictionaryTextCodec.vocabularyText(from: dictionary)
            correctionsText = PersonalDictionaryTextCodec.correctionsText(from: dictionary)
            errorMessage = nil
            statusMessage = dictionary.isEmpty
                ? "Dictionary is empty."
                : "Loaded \(dictionary.enabledVocabulary.count) terms and \(dictionary.enabledCorrections.count) corrections."
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = ""
        }
    }

    private func save() {
        do {
            let dictionary = try PersonalDictionaryTextCodec.dictionary(
                vocabularyText: vocabularyText,
                correctionsText: correctionsText,
                preserving: loadedDictionary
            )
            try store.save(dictionary)
            loadedDictionary = dictionary
            errorMessage = nil
            statusMessage = "Saved \(dictionary.enabledVocabulary.count) terms and \(dictionary.enabledCorrections.count) corrections."
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = ""
        }
    }
}

struct TeachCorrectionView: View {
    let store: PersonalDictionaryStore

    @EnvironmentObject private var appState: AppState
    @State private var wrongText = ""
    @State private var preferredText = ""
    @State private var statusMessage = ""
    @State private var errorMessage: String?

    var body: some View {
        AppDialogScaffold(maxContentWidth: 520) {
            AppFormSection("Correction") {
                AppFormTextField("Wrong / heard as", text: $wrongText)
                AppFormTextField("Preferred spelling", text: $preferredText)
                Text("Used as a cleanup hint, not transcript history.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            AppFormSection("Recent Examples") {
                AppLabeledContent("Raw transcript", value: appState.latestRawTranscriptSummary)
                AppLabeledContent("Final draft", value: appState.latestFinalDraftSummary)

                HStack(spacing: 8) {
                    Button("Use Raw As Wrong") {
                        wrongText = appState.latestRawTranscriptForCorrection
                    }
                    .disabled(appState.latestRawTranscriptForCorrection.isEmpty)

                    Button("Use Final As Preferred") {
                        preferredText = appState.latestFinalDraftForCorrection
                    }
                    .disabled(appState.latestFinalDraftForCorrection.isEmpty)
                }
            }

        } status: {
            if let errorMessage {
                Text(errorMessage)
                    .foregroundStyle(.red)
            } else if !statusMessage.isEmpty {
                Text(statusMessage)
                    .foregroundStyle(.secondary)
            } else {
                Text("Corrections are stored locally and used only as cleanup hints.")
                    .foregroundStyle(.secondary)
            }
        } actions: {
            Button {
                NSApp.keyWindow?.performClose(nil)
            } label: {
                Label("Close", systemImage: "xmark")
            }
            Button {
                clear()
            } label: {
                Label("Clear", systemImage: "xmark.circle")
            }
            Button {
                save()
            } label: {
                Label("Save Correction", systemImage: "checkmark")
            }
            .keyboardShortcut(.defaultAction)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func save() {
        do {
            var dictionary = try store.load()
            let created = try PersonalDictionaryTextCodec.upsertCorrection(
                from: wrongText,
                to: preferredText,
                in: &dictionary
            )
            try store.save(dictionary)
            let wrong = wrongText.trimmingCharacters(in: .whitespacesAndNewlines)
            let preferred = preferredText.trimmingCharacters(in: .whitespacesAndNewlines)
            errorMessage = nil
            statusMessage = created
                ? "Added correction: \(wrong) => \(preferred)"
                : "Updated existing correction: \(wrong) => \(preferred)"
        } catch {
            errorMessage = error.localizedDescription
            statusMessage = ""
        }
    }

    private func clear() {
        wrongText = ""
        preferredText = ""
        errorMessage = nil
        statusMessage = ""
    }
}
