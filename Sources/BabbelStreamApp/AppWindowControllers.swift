import AppKit
import BabbelStreamCore
import SwiftUI

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
        if CommandLine.arguments.contains("--settings") {
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
            contentRect: NSRect(x: 0, y: 0, width: 620, height: 560),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "\(ProjectDefaults.appName) Personal Dictionary"
        window.contentViewController = NSHostingController(
            rootView: PersonalDictionaryView(
                store: store,
                onTeachCorrection: onTeachCorrection
            )
        )
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
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 360),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "\(ProjectDefaults.appName) Teach Correction"
        window.contentViewController = NSHostingController(
            rootView: TeachCorrectionView(store: store)
                .environmentObject(appState)
        )
        window.isReleasedWhenClosed = false
        window.center()

        return NSWindowController(window: window)
    }
}
