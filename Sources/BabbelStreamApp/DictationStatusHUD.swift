import AppKit
import BabbelStreamCore
import SwiftUI

@MainActor
final class DictationStatusHUDController {
    private let appState: AppState
    private let panel: NSPanel
    private var stateObserverID: UUID?
    private var dismissalTask: Task<Void, Never>?
    private var presentedActiveOperation = false

    init(appState: AppState) {
        self.appState = appState
        self.panel = Self.makePanel(appState: appState)
        self.stateObserverID = appState.addStateChangeObserver { [weak self] in
            self?.refreshVisibility()
        }
        refreshVisibility()
    }

    deinit {
        MainActor.assumeIsolated {
            dismissalTask?.cancel()
            if let stateObserverID {
                appState.removeStateChangeObserver(stateObserverID)
            }
        }
    }

    private func refreshVisibility() {
        dismissalTask?.cancel()
        dismissalTask = nil

        if appState.isRecording || appState.isProcessing || appState.canCancel {
            presentedActiveOperation = true
            show()
            return
        }

        guard presentedActiveOperation else {
            panel.orderOut(nil)
            return
        }
        presentedActiveOperation = false

        show()
        let visibilitySeconds: TimeInterval
        if appState.status == "Copied" || appState.errorMessage != nil || appState.warningMessage != nil {
            visibilitySeconds = 6
        } else {
            visibilitySeconds = 2.5
        }
        dismissalTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(visibilitySeconds * 1_000_000_000))
            guard !Task.isCancelled else {
                return
            }
            self?.panel.orderOut(nil)
        }
    }

    private func show() {
        positionPanel()
        panel.orderFrontRegardless()
    }

    private func positionPanel() {
        guard let screen = NSScreen.main ?? NSScreen.screens.first else {
            return
        }

        let visibleFrame = screen.visibleFrame
        let frame = panel.frame
        panel.setFrameOrigin(
            NSPoint(
                x: visibleFrame.midX - (frame.width / 2),
                y: visibleFrame.maxY - frame.height - 24
            )
        )
    }

    private static func makePanel(appState: AppState) -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: 460, height: 104),
            styleMask: [.nonactivatingPanel, .hudWindow, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient]
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.isMovable = false
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.contentViewController = NSHostingController(
            rootView: DictationStatusHUDView()
                .environmentObject(appState)
        )
        return panel
    }
}

private struct DictationStatusHUDView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: appState.menuBarSystemImage)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(iconColor)
                .frame(width: 30)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 4) {
                Text(appState.status)
                    .font(.headline)
                Text(appState.hudDetail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if appState.canCancel {
                Button("Cancel") {
                    Task { @MainActor in
                        await appState.cancelRecording()
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .accessibilityHint("Stops the active recording or provider request and deletes temporary audio.")
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .frame(width: 460, height: 104)
        .background(.ultraThickMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(.white.opacity(0.12))
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("BabbelStream \(appState.status)")
    }

    private var iconColor: Color {
        if appState.isRecording {
            return .red
        }
        if appState.status == "Copied" || appState.errorMessage != nil {
            return .orange
        }
        return .accentColor
    }
}
