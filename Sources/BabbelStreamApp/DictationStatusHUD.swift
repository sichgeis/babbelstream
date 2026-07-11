import AppKit
import BabbelStreamCore
import SwiftUI

@MainActor
private final class DictationHUDMetrics: ObservableObject {
    @Published private(set) var samples = Array(repeating: Float.zero, count: 22)
    private var smoothedLevel: Float = 0

    func append(level: Float) {
        let clampedLevel = min(max(level, 0), 1)
        let smoothing: Float = clampedLevel > smoothedLevel ? 0.45 : 0.2
        smoothedLevel += (clampedLevel - smoothedLevel) * smoothing
        samples.removeFirst()
        samples.append(smoothedLevel)
    }

    func reset() {
        smoothedLevel = 0
        samples = Array(repeating: 0, count: samples.count)
    }
}

@MainActor
final class DictationStatusHUDController {
    private static let panelSize = NSSize(width: 220, height: 44)

    private let appState: AppState
    private let metrics: DictationHUDMetrics
    private let panel: NSPanel
    private var stateObserverID: UUID?
    private var dismissalTask: Task<Void, Never>?
    private var meteringTask: Task<Void, Never>?
    private var presentedActiveOperation = false

    init(appState: AppState) {
        let metrics = DictationHUDMetrics()
        self.appState = appState
        self.metrics = metrics
        self.panel = Self.makePanel(appState: appState, metrics: metrics)
        self.stateObserverID = appState.addStateChangeObserver { [weak self] in
            self?.refreshVisibility()
        }
        refreshVisibility()
    }

    deinit {
        MainActor.assumeIsolated {
            dismissalTask?.cancel()
            meteringTask?.cancel()
            if let stateObserverID {
                appState.removeStateChangeObserver(stateObserverID)
            }
        }
    }

    private func refreshVisibility() {
        dismissalTask?.cancel()
        dismissalTask = nil
        refreshMetering()

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
            visibilitySeconds = 1.5
        }
        dismissalTask = Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: UInt64(visibilitySeconds * 1_000_000_000))
            guard !Task.isCancelled else {
                return
            }
            self?.panel.orderOut(nil)
        }
    }

    private func refreshMetering() {
        guard appState.isRecording else {
            meteringTask?.cancel()
            meteringTask = nil
            metrics.reset()
            return
        }

        guard meteringTask == nil else {
            return
        }

        metrics.reset()
        meteringTask = Task { @MainActor [weak self] in
            while !Task.isCancelled {
                guard let self, self.appState.isRecording else {
                    break
                }
                self.metrics.append(level: self.appState.currentAudioLevel)
                try? await Task.sleep(nanoseconds: 33_000_000)
            }
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
                y: visibleFrame.minY + 40
            )
        )
    }

    private static func makePanel(
        appState: AppState,
        metrics: DictationHUDMetrics
    ) -> NSPanel {
        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: panelSize),
            styleMask: [.nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .transient, .ignoresCycle]
        panel.isFloatingPanel = true
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.hidesOnDeactivate = false
        panel.isMovable = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.contentViewController = NSHostingController(
            rootView: DictationStatusHUDView(metrics: metrics)
                .environmentObject(appState)
        )
        return panel
    }
}

private struct DictationStatusHUDView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var metrics: DictationHUDMetrics

    var body: some View {
        Group {
            if appState.isRecording {
                recordingContent
            } else {
                statusContent
            }
        }
        .padding(.horizontal, 8)
        .frame(width: 220, height: 44)
        .background(Color.black.opacity(0.88), in: Capsule())
        .overlay {
            Capsule()
                .strokeBorder(.white.opacity(0.13), lineWidth: 1)
        }
        .contentShape(Capsule())
        .accessibilityElement(children: .contain)
        .accessibilityLabel("BabbelStream \(compactStatus)")
    }

    private var recordingContent: some View {
        HStack(spacing: 7) {
            Button {
                Task { @MainActor in
                    await appState.stopActiveRecording()
                }
            } label: {
                Circle()
                    .fill(.red.opacity(0.95))
                    .frame(width: 28, height: 28)
                    .overlay {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(.white)
                            .frame(width: 9, height: 9)
                    }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Stop recording and process dictation")

            Text(recordingBadge)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
                .truncationMode(.tail)
                .padding(.horizontal, 7)
                .padding(.vertical, 4)
                .background(.white.opacity(0.14), in: Capsule())
                .frame(maxWidth: 72)

            LiveAudioWaveform(samples: metrics.samples)
                .frame(maxWidth: .infinity)
                .frame(height: 24)
                .accessibilityHidden(true)
        }
    }

    private var statusContent: some View {
        HStack(spacing: 9) {
            statusIndicator

            Text(compactStatus)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(1)

            Spacer(minLength: 0)

            if appState.canCancel {
                Button {
                    Task { @MainActor in
                        await appState.cancelRecording()
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white.opacity(0.55))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Cancel active dictation")
                .accessibilityHint("Stops active work. A stopped dictation remains available under Failed Recordings.")
            }
        }
    }

    @ViewBuilder
    private var statusIndicator: some View {
        if appState.isProcessing || appState.canCancel {
            Circle()
                .fill(.blue.opacity(0.92))
                .frame(width: 28, height: 28)
                .overlay {
                    Image(systemName: "waveform")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .accessibilityHidden(true)
        } else {
            Circle()
                .fill(completionColor.opacity(0.92))
                .frame(width: 28, height: 28)
                .overlay {
                    Image(systemName: completionIcon)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .accessibilityHidden(true)
        }
    }

    private var recordingBadge: String {
        if appState.status == "Recording test" {
            return "Test"
        }
        return appState.pasteTargetSummary ?? "Recording"
    }

    private var compactStatus: String {
        if appState.isRecording {
            return "Recording"
        }
        if appState.isProcessing || appState.canCancel {
            switch appState.status {
            case "Transcribing", "Max reached; transcribing":
                return "Transcribing"
            case "Retrying transcription":
                return "Retrying"
            case "Cleaning up":
                return "Cleaning up"
            case "Pasting draft":
                return "Pasting"
            case "Canceling dictation":
                return "Canceling"
            default:
                return "Processing"
            }
        }
        if appState.status == "Copied" {
            return "Copied"
        }
        if appState.status == "Recording saved"
            || appState.lastResult.localizedCaseInsensitiveContains("Failed Recordings")
            || appState.lastResult.localizedCaseInsensitiveContains("recording retained")
        {
            return "Recording saved"
        }
        if appState.errorMessage != nil || appState.status.localizedCaseInsensitiveContains("failed") {
            return "Error"
        }
        if appState.lastResult.localizedCaseInsensitiveContains("canceled") {
            return "Canceled"
        }
        if appState.lastResult.localizedCaseInsensitiveContains("draft inserted")
            || appState.lastResult.localizedCaseInsensitiveContains("paste shortcut")
        {
            return "Pasted"
        }
        return "Done"
    }

    private var completionIcon: String {
        switch compactStatus {
        case "Copied":
            return "doc.on.doc.fill"
        case "Error", "Recording saved":
            return "exclamationmark.triangle.fill"
        case "Canceled":
            return "xmark.circle.fill"
        default:
            return "checkmark.circle.fill"
        }
    }

    private var completionColor: Color {
        switch compactStatus {
        case "Copied":
            return .orange
        case "Error", "Recording saved":
            return .red
        case "Canceled":
            return .secondary
        default:
            return .green
        }
    }
}

private struct LiveAudioWaveform: View {
    let samples: [Float]

    var body: some View {
        Canvas { context, size in
            guard !samples.isEmpty else {
                return
            }

            let spacing: CGFloat = 2
            let barWidth = max(1.5, (size.width - spacing * CGFloat(samples.count - 1)) / CGFloat(samples.count))
            let totalWidth = barWidth * CGFloat(samples.count) + spacing * CGFloat(samples.count - 1)
            let startX = max(0, (size.width - totalWidth) / 2)

            for (index, sample) in samples.enumerated() {
                let centerDistance = abs(CGFloat(index) - CGFloat(samples.count - 1) / 2)
                let centerScale = 1 - 0.25 * centerDistance / max(CGFloat(samples.count) / 2, 1)
                let height = max(3, min(size.height, CGFloat(sample) * size.height * centerScale))
                let rect = CGRect(
                    x: startX + CGFloat(index) * (barWidth + spacing),
                    y: (size.height - height) / 2,
                    width: barWidth,
                    height: height
                )
                context.fill(
                    Path(roundedRect: rect, cornerRadius: barWidth / 2),
                    with: .color(.white.opacity(0.62))
                )
            }
        }
    }
}
