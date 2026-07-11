import AppKit
import BabbelStreamCore
import SwiftUI

struct SettingsView: View {
    private enum Tab: String {
        case general
        case provider
        case writing
        case archive
        case diagnostics
    }

    @EnvironmentObject private var appState: AppState
    @State private var selectedTab: Tab

    init() {
        let tabArgument = CommandLine.arguments.first { $0.hasPrefix("--settings-tab=") }
        let tabName = tabArgument?.split(separator: "=", maxSplits: 1).last.map(String.init)
        _selectedTab = State(initialValue: Tab(rawValue: tabName ?? "") ?? .general)
    }

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $selectedTab) {
                SettingsGeneralPane()
                    .tabItem {
                        Label("General", systemImage: "gearshape")
                    }
                    .tag(Tab.general)

                SettingsProviderPane()
                    .tabItem {
                        Label("Provider", systemImage: "network")
                    }
                    .tag(Tab.provider)

                SettingsWritingPane()
                    .tabItem {
                        Label("Writing", systemImage: "text.bubble")
                    }
                    .tag(Tab.writing)

                SettingsArchivePane()
                    .tabItem {
                        Label("Archive", systemImage: "archivebox")
                    }
                    .tag(Tab.archive)

                SettingsDiagnosticsPane()
                    .tabItem {
                        Label("Diagnostics", systemImage: "stethoscope")
                    }
                    .tag(Tab.diagnostics)
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)

            Divider()
            settingsFooter
        }
        .onAppear {
            appState.refreshPermissionStatuses()
        }
        .frame(minWidth: 700, idealWidth: 760, minHeight: 560, idealHeight: 640)
    }

    private var settingsFooter: some View {
        HStack(spacing: 12) {
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
            .font(.caption)
            .lineLimit(2)

            Spacer()

            Button {
                appState.saveSettings()
            } label: {
                Label("Apply Settings", systemImage: "checkmark")
            }
            .keyboardShortcut(.defaultAction)
            .disabled(!appState.hasUnsavedSettingsChanges)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 14)
        .background(.bar)
    }
}

private struct SettingsPane<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        ScrollView {
            Form {
                content
            }
            .formStyle(.grouped)
            .padding(.vertical, 12)
            .frame(maxWidth: 680, alignment: .top)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    }
}

private struct SettingsGeneralPane: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        SettingsPane {
            Section("Behavior") {
                Toggle(
                    "Cleanup enabled",
                    isOn: Binding(
                        get: { appState.cleanupEnabled },
                        set: { appState.setCleanupEnabled($0) }
                    )
                )
                Toggle(
                    "Launch at login",
                    isOn: Binding(
                        get: { appState.launchAtLoginEnabled },
                        set: { appState.setLaunchAtLoginEnabled($0) }
                    )
                )
                TextField("Max recording minutes", text: $appState.maxAudioDurationMinutesText)
                LabeledContent("Hotkey", value: ProjectDefaults.fixedHotkeyDescription)
            }

            Section("Safety") {
                LabeledContent("Saved max duration", value: formatSettingsDuration(appState.maxAudioDurationSeconds))
                LabeledContent("Auto-send", value: ProjectDefaults.autoSendEnabledByDefault ? "On" : "Off")
                LabeledContent("Default transcript history", value: ProjectDefaults.transcriptHistoryEnabledByDefault ? "On" : "Off")
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

    var body: some View {
        SettingsPane {
            Section("Active Destinations") {
                SettingsLongValue(label: "Transcription", value: appState.providerDestinationSummary)
                SettingsLongValue(label: "Cleanup", value: appState.cleanupDestinationSummary)

                if appState.hasUnsavedConfigurationChanges {
                    SettingsLongValue(
                        label: "Edited transcription",
                        value: appState.editedProviderDestinationSummary,
                        isPending: true
                    )
                    SettingsLongValue(
                        label: "Edited cleanup",
                        value: appState.editedCleanupDestinationSummary,
                        isPending: true
                    )
                }
            }

            Section("Connection") {
                TextField("Base URL", text: $appState.baseURLText)
                TextField("Transcription path", text: $appState.transcriptionPathText)
                TextField("Cleanup path", text: $appState.cleanupPathText)
            }

            Section("Models And Timeouts") {
                TextField("Primary transcription model", text: $appState.transcriptionModelText)
                LabeledContent("Fallback model", value: ProjectDefaults.fallbackTranscriptionModel)
                TextField("Cleanup model", text: $appState.cleanupModelText)
                LabeledContent(
                    "Timeout per transcription model",
                    value: "\(Int(ProjectDefaults.transcriptionAttemptTimeoutSeconds))s"
                )
                TextField("Cleanup timeout (seconds)", text: $appState.timeoutText)
                LabeledContent("Connection watchdog", value: appState.providerConnectionTimeoutSummary)
                LabeledContent("Transcription attempts", value: "2 (primary + fallback)")
                Text("If the primary transcription model has a transient failure, BabbelStream sends the same temporary audio once to the fallback model. Each model has a 30-second limit. Authentication and configuration failures do not fall back.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("API Key") {
                SecureField(
                    appState.hasAPIKey ? "API key saved in Keychain" : "Paste API key",
                    text: $appState.apiKeyInput
                )
                LabeledContent("Keychain", value: appState.hasAPIKey ? "Saved" : "Missing")

                Button(role: .destructive) {
                    appState.deleteAPIKey()
                } label: {
                    Label("Delete API Key", systemImage: "trash")
                }
                .disabled(!appState.hasAPIKey)
            }
        }
    }
}

private struct SettingsWritingPane: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        SettingsPane {
            Section("Transcription Hints") {
                TextField("Language code, optional (blank = auto)", text: $appState.transcriptionLanguageText)
                TextField("Transcription prompt, optional", text: $appState.transcriptionPromptText, axis: .vertical)
                    .lineLimit(2...4)
            }

            Section("Personal Dictionary") {
                LabeledContent("Cleanup context", value: appState.personalDictionarySummary)
                LabeledContent(
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
            Section("Dictation Archive") {
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
                    .foregroundStyle(.secondary)
                SettingsLongValue(label: "Archive folder", value: appState.archiveDirectoryPath)
            }
        }
    }
}

private struct SettingsDiagnosticsPane: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        SettingsPane {
            Section("Usage") {
                LabeledContent("Dictations", value: "\(appState.usageSnapshot.totalDictations)")
                LabeledContent("Recorded", value: appState.usageRecordedMinutesSummary)
                LabeledContent("Cleanup requests", value: "\(appState.usageSnapshot.cleanupRequests)")
                LabeledContent("Transcription failures", value: "\(appState.usageSnapshot.transcriptionFailures)")
                LabeledContent("Cleanup fallbacks", value: "\(appState.usageSnapshot.cleanupFallbacks)")
                Button {
                    appState.resetUsageCounters()
                } label: {
                    Label("Reset Usage Counters", systemImage: "arrow.counterclockwise")
                }
            }

            Section("Permissions") {
                LabeledContent("Microphone", value: appState.microphonePermissionStatus.displayName)
                LabeledContent("Accessibility", value: appState.accessibilityPermissionStatus.displayName)

                HStack {
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

            Section("Latest Draft") {
                LabeledContent("Raw transcript", value: appState.latestRawTranscriptSummary)
                LabeledContent("Final draft", value: appState.latestFinalDraftSummary)

                HStack {
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

            Section("Diagnostics") {
                LabeledContent("Version", value: BuildMetadata.appVersion)
                LabeledContent("Build commit", value: BuildMetadata.gitCommitShortHash)
                SettingsLongValue(label: "App bundle", value: appState.appBundlePath)
                LabeledContent("Bundle ID", value: appState.appBundleIdentifier)
                LabeledContent("Code signing", value: appState.codeSigningSummary)
                LabeledContent("Last failure", value: appState.lastFailureCategory)
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

private struct SettingsLongValue: View {
    let label: String
    let value: String
    var isPending = false

    var body: some View {
        LabeledContent(label) {
            Text(value)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(isPending ? .orange : .secondary)
                .multilineTextAlignment(.trailing)
                .lineLimit(3)
                .textSelection(.enabled)
                .frame(maxWidth: 420, alignment: .trailing)
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
        Form {
            Section("Vocabulary") {
                TextEditor(text: $vocabularyText)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 140)
            }

            Section("Corrections") {
                TextEditor(text: $correctionsText)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 140)
            }

            Section("Storage") {
                Text(store.fileURL.path)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
            }

            Section {
                HStack {
                    Button("Save") {
                        save()
                    }
                    Button("Reload") {
                        load()
                    }
                    Button("Teach Correction...") {
                        onTeachCorrection()
                    }
                    Button("Close") {
                        NSApp.keyWindow?.performClose(nil)
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                } else if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear {
            load()
        }
        .padding(24)
        .frame(width: 620)
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
        Form {
            Section("Correction") {
                TextField("Wrong / heard as", text: $wrongText)
                TextField("Preferred spelling", text: $preferredText)
                Text("Used as a cleanup hint, not transcript history.")
                    .foregroundStyle(.secondary)
            }

            Section("Recent Examples") {
                LabeledContent("Raw transcript", value: appState.latestRawTranscriptSummary)
                LabeledContent("Final draft", value: appState.latestFinalDraftSummary)

                HStack {
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

            Section {
                HStack {
                    Button("Save Correction") {
                        save()
                    }
                    .keyboardShortcut(.defaultAction)

                    Button("Clear") {
                        clear()
                    }

                    Button("Close") {
                        NSApp.keyWindow?.performClose(nil)
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                } else if !statusMessage.isEmpty {
                    Text(statusMessage)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(24)
        .frame(width: 460)
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
