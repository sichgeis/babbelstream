import BabbelStreamCore
import SwiftUI

@main
struct BabbelStreamApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra(ProjectDefaults.appName, systemImage: appState.menuBarSystemImage) {
            StatusMenuView()
                .environmentObject(appState)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}

@MainActor
final class AppState: ObservableObject {
    @Published var cleanupEnabled = ProjectDefaults.cleanupEnabledByDefault
    @Published var providerConfiguration = ProviderConfiguration()
    @Published var status = "Ready"

    var menuBarSystemImage: String {
        status == "Recording" ? "mic.fill" : "mic"
    }
}

struct StatusMenuView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(appState.status)
                .font(.headline)

            Toggle("Cleanup", isOn: $appState.cleanupEnabled)

            Divider()

            Button("Settings...") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }

            Button("Quit") {
                NSApp.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding()
        .frame(minWidth: 220, alignment: .leading)
    }
}

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Form {
            Section("Provider") {
                Text(appState.providerConfiguration.baseURL.absoluteString)
                Text(appState.providerConfiguration.transcriptionEndpointPath)
                Text(appState.providerConfiguration.cleanupEndpointPath)
            }

            Section("Defaults") {
                Toggle("Cleanup", isOn: $appState.cleanupEnabled)
                LabeledContent("Max duration", value: "\(Int(ProjectDefaults.maxAudioDurationSeconds))s")
                LabeledContent("Auto-send", value: ProjectDefaults.autoSendEnabledByDefault ? "On" : "Off")
                LabeledContent("History", value: ProjectDefaults.transcriptHistoryEnabledByDefault ? "On" : "Off")
            }
        }
        .padding(24)
        .frame(width: 420)
    }
}
