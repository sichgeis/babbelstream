import AppKit
import BabbelStreamCore
import SwiftUI

@MainActor
final class OnboardingWindowController: NSObject, NSWindowDelegate {
    let model: OnboardingModel
    let pasteTest: LocalPasteTestSession
    private let showProvider: () -> Void
    private let testInsertion: (any TextInsertionService)?
    private var controller: NSWindowController?

    init(appState: AppState, store: any OnboardingProgressStore = UserDefaultsOnboardingProgressStore(),
         testInsertion: (any TextInsertionService)? = nil, showProvider: @escaping () -> Void) {
        model = OnboardingModel(appState: appState, store: store)
        pasteTest = LocalPasteTestSession(appState: appState)
        self.showProvider = showProvider
        self.testInsertion = testInsertion
        super.init()
    }

    func show(repairOnly: Bool = false) {
        guard model.appState.canStart else { return }
        pasteTest.reset()
        model.repairOnly = repairOnly
        model.step = repairOnly ? .permissions : .welcome
        model.refreshPermissions()
        if controller == nil {
            let window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 640, height: 580),
                                  styleMask: [.titled, .closable, .miniaturizable, .resizable], backing: .buffered, defer: false)
            window.title = "Set Up BabbelStream"
            window.contentViewController = makeDialogHostingController(rootView: OnboardingView(
                model: model, pasteTest: pasteTest, testInsertion: testInsertion, showProvider: showProvider,
                close: { [weak self] in self?.controller?.close() }
            ).environmentObject(model.appState))
            window.setDialogInitialContentSize(NSSize(width: 640, height: 580), minimum: NSSize(width: 600, height: 500))
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.center()
            controller = NSWindowController(window: window)
        }
        controller?.showWindow(nil)
        controller?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowDidResignKey(_ notification: Notification) {
        pasteTest.cancel()
    }

    func windowWillClose(_ notification: Notification) {
        pasteTest.cancel()
        model.dismiss()
    }
}

private struct OnboardingView: View {
    @ObservedObject var model: OnboardingModel
    @ObservedObject var pasteTest: LocalPasteTestSession
    @EnvironmentObject private var appState: AppState
    @State private var field = NativePasteTestField()
    let testInsertion: (any TextInsertionService)?
    let showProvider: () -> Void
    let close: () -> Void

    var body: some View {
        AppDialogScaffold {
            Text(title).font(.title2.bold())
            if !model.repairOnly {
                Text("Step \(model.step.rawValue + 1) of 5").foregroundStyle(.secondary)
            }
            switch model.step {
            case .welcome: welcome
            case .permissions: permissions
            case .provider: provider
            case .pasteTest: localTest
            case .ready: ready
            }
        } status: {
            Text(pasteTest.isTesting ? "Testing only the local paste field…" : "Nothing is sent automatically.")
                .foregroundStyle(.secondary)
        } actions: {
            if pasteTest.isTesting {
                Button("Cancel Test") { pasteTest.cancel() }
            } else {
                if model.step == .welcome {
                    Button("Set Up Later", action: close)
                } else if !model.repairOnly {
                    Button("Back") { navigate(-1) }
                }
                if model.repairOnly || model.step == .ready {
                    Button("Done", action: close).keyboardShortcut(.defaultAction)
                } else {
                    Button(continueTitle) { navigate(1) }.keyboardShortcut(.defaultAction)
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            model.refreshPermissions()
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didResignActiveNotification)) { _ in
            pasteTest.cancel()
        }
        .onDisappear { pasteTest.cancel() }
    }

    private var title: String {
        switch model.step {
        case .welcome: "Set up BabbelStream"
        case .permissions: model.repairOnly ? "Restore recording and automatic paste" : "Allow recording and automatic paste"
        case .provider: "Connect your provider"
        case .pasteTest: "Try automatic paste"
        case .ready: "Your setup at a glance"
        }
    }
    private var continueTitle: String {
        if model.step == .permissions && appState.accessibilityPermissionStatus != .trusted { return "Continue With Manual Paste" }
        if model.step == .pasteTest && pasteTest.result != .passed { return "Skip Test" }
        return "Continue"
    }
    private func navigate(_ offset: Int) {
        pasteTest.cancel()
        model.refreshPermissions()
        model.step = OnboardingModel.Step(rawValue: model.step.rawValue + offset) ?? .ready
    }

    private var welcome: some View {
        AppFormSection("Dictation that leaves you in control") {
            Text("Record with a shortcut. Paste into your focused app. Nothing is sent automatically.")
            Text("Audio is processed by the provider you configure. Review its destination before your first dictation. API keys stay in your macOS Keychain.")
            Text("Setup checks permissions and offers a local paste test. You can postpone it or reopen it from the menu or General Settings.")
        }
    }

    private var permissions: some View {
        Group {
            AppFormSection("Microphone — \(appState.microphonePermissionStatus.displayName)") {
                Text("Record only when you start dictation.")
                if appState.microphonePermissionStatus != .authorized {
                    if appState.microphonePermissionStatus == .notDetermined {
                        Button("Allow Microphone") { Task { await appState.requestMicrophonePermission(); model.refreshPermissions() } }
                            .disabled(!appState.canStart)
                    }
                    Button("Open Microphone Settings…") { appState.openMicrophonePrivacySettings() }
                }
            }
            AppFormSection("Automatic paste — \(appState.accessibilityPermissionStatus.displayName)") {
                Text("Accessibility lets BabbelStream paste your finished draft into the focused app using Command–V. It never presses Enter or sends the draft.")
                if appState.accessibilityPermissionStatus != .trusted {
                    Button("Enable Automatic Paste…") { appState.requestAccessibilityPermission(); model.refreshPermissions() }
                    Button("Open Accessibility Settings…") { appState.openAccessibilityPrivacySettings() }
                    Text("Automatic paste is unavailable. Dictation can still copy the draft for manual paste.")
                    Text("If the system toggle is already enabled, remove and re-add /Applications/BabbelStream.app, then restart BabbelStream. A changed signing identity can leave an older grant behind.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            Button("Check Again") { model.refreshPermissions() }
            Text("These statuses come from the running app’s macOS permission checks. Return here after granting access.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var provider: some View {
        AppFormSection("Your saved connection") {
            Text(appState.needsConnectionSetup ? "Provider setup is incomplete." : "Saved configuration retained.")
            Text(appState.isPersonalOpenAIDirectModeApplied ? appState.personalOpenAIFallbackReadinessSummary : appState.connectionReadinessSummary)
            Text(appState.activeProviderDestinationSummary).textSelection(.enabled)
            Text("Use your own approved, revocable key. Ask IT for the company URL and key; BabbelStream does not include a shared key.")
            Button("Open Provider Settings…", action: showProvider)
            Text("Review and Apply changes there, then return here. Saving a key is not a connection test. The optional silent-audio test asks separately before sending and may incur a provider charge.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var localTest: some View {
        AppFormSection("A local check, without recording") {
            Text("This replaces your clipboard with “\(LocalPasteTestSession.sample)” and tries Command–V only in the field below. It uses no microphone or provider and does not send a message.")
            PasteTestEditor(field: field).frame(height: 84)
            Button("Test Automatic Paste") { pasteTest.start(field: field, insertion: testInsertion) }
                .disabled(pasteTest.isTesting || !appState.canStart || appState.accessibilityPermissionStatus != .trusted)
            Text(pasteTest.result.message)
                .foregroundStyle(pasteTest.result == .passed ? Color.primary : Color.secondary)
                .accessibilityIdentifier("localPasteTestResult")
            if appState.accessibilityPermissionStatus != .trusted {
                Button("Review Permissions") { model.step = .permissions }
            }
            Text("A pass confirms this test field received the sample. Still try your usual editor before relying on dictation.")
                .font(.caption).foregroundStyle(.secondary)
        }
    }

    private var ready: some View {
        Group {
            AppFormSection("Current readiness") {
                Text("Microphone: \(appState.microphonePermissionStatus.displayName)")
                Text("Automatic paste: \(appState.accessibilityPermissionStatus.displayName)")
                Text(appState.needsConnectionSetup ? "Provider: setup needed" : "Provider: saved configuration; review verification in Settings")
                Text(pasteTest.result == .passed ? "Local paste test passed in this session." : "Local paste test not verified in this session.")
                if appState.microphonePermissionStatus != .authorized || appState.needsConnectionSetup {
                    Text("Finish the missing setup before dictating.")
                } else if appState.accessibilityPermissionStatus != .trusted {
                    Text("Dictation can copy drafts; use Command–V to paste manually.")
                }
            }
            AppFormSection("Try your first draft") {
                Text("Focus an unsent TextEdit or Slack draft. Press Control–Option–Space: tap to start and tap again to stop, or hold for push-to-talk. Keep that app focused until processing finishes.")
                Text("Review the draft before sending. Starting dictation records audio and sends it to your configured provider. Setup does not start recording or send audio.")
            }
        }
    }
}
