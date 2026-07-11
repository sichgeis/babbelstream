import AppKit
import BabbelStreamCore
import SwiftUI

enum AppWindowLaunchMode: String, CaseIterable {
    case settings = "--settings"
    case personalDictionary = "--personal-dictionary"
    case teachCorrection = "--teach-correction"
    case dictationArchive = "--dictation-archive"
    case failedRecordings = "--failed-recordings"

    static var requested: AppWindowLaunchMode? {
        allCases.first { CommandLine.arguments.contains($0.rawValue) }
    }

    static var usesMinimumWindowSize: Bool {
        CommandLine.arguments.contains("--minimum-window-size")
    }
}

extension NSWindow {
    func setDialogInitialContentSize(_ defaultContentSize: NSSize) {
        if AppWindowLaunchMode.usesMinimumWindowSize {
            setFrame(NSRect(origin: .zero, size: minSize), display: false)
        } else {
            setContentSize(defaultContentSize)
        }
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
            contentRect: NSRect(x: 0, y: 0, width: 760, height: 640),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "\(ProjectDefaults.appName) Settings"
        window.minSize = NSSize(width: 700, height: 560)
        if AppWindowLaunchMode.requested == .settings {
            window.sharingType = .readOnly
        }
        window.contentViewController = NSHostingController(
            rootView: SettingsView()
                .environmentObject(appState)
        )
        window.isReleasedWhenClosed = false
        window.center()

        return NSWindowController(window: window)
    }
}
@MainActor
final class PersonalDictionaryWindowController {
    private let store: PersonalDictionaryStore
    private let onTeachCorrection: () -> Void
    private var windowController: NSWindowController?

    init(store: PersonalDictionaryStore, onTeachCorrection: @escaping () -> Void) {
        self.store = store
        self.onTeachCorrection = onTeachCorrection
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
            contentRect: NSRect(x: 0, y: 0, width: 720, height: 640),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "\(ProjectDefaults.appName) Personal Dictionary"
        window.minSize = NSSize(width: 620, height: 520)
        if AppWindowLaunchMode.requested == .personalDictionary {
            window.sharingType = .readOnly
        }
        window.contentViewController = NSHostingController(
            rootView: PersonalDictionaryView(
                store: store,
                onTeachCorrection: onTeachCorrection
            )
        )
        window.setDialogInitialContentSize(NSSize(width: 720, height: 640))
        window.isReleasedWhenClosed = false
        window.center()

        return NSWindowController(window: window)
    }
}

@MainActor
final class TeachCorrectionWindowController {
    private let store: PersonalDictionaryStore
    private let appState: AppState
    private var windowController: NSWindowController?

    init(store: PersonalDictionaryStore, appState: AppState) {
        self.store = store
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
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 500),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "\(ProjectDefaults.appName) Teach Correction"
        window.minSize = NSSize(width: 500, height: 420)
        if AppWindowLaunchMode.requested == .teachCorrection {
            window.sharingType = .readOnly
        }
        window.contentViewController = NSHostingController(
            rootView: TeachCorrectionView(store: store)
                .environmentObject(appState)
        )
        window.setDialogInitialContentSize(NSSize(width: 560, height: 500))
        window.isReleasedWhenClosed = false
        window.center()

        return NSWindowController(window: window)
    }
}
