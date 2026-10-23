import AppKit
import BabbelStreamCore
import SwiftUI

@MainActor
protocol LocalPasteTestField: AnyObject {
    func prepareForSample() -> TextInsertionTarget?
    var isFocused: Bool { get }
    var receivedSample: Bool { get }
}

@MainActor
final class LocalPasteTestSession: ObservableObject {
    static let sample = "BabbelStream paste test."
    enum Result: Equatable {
        case idle, testing, passed, cancelled, failed(String)
        var message: String {
            switch self {
            case .idle: "Optional: check automatic paste without recording or contacting a provider."
            case .testing: "Waiting for the sample in the test field…"
            case .passed: "Sample received. Automatic paste worked in this test field."
            case .cancelled: "Test canceled. Run it again when you are ready."
            case .failed(let message): message
            }
        }
    }
    @Published private(set) var result: Result = .idle
    @Published private(set) var isTesting = false
    private var task: Task<Void, Never>?
    private let appState: AppState

    init(appState: AppState) { self.appState = appState }

    func start(field: any LocalPasteTestField, insertion: (any TextInsertionService)? = nil) {
        guard !isTesting else { return }
        guard appState.beginLocalPasteTest() else {
            result = .failed("Finish the current recording, processing or connection test first.")
            return
        }
        appState.refreshPermissionStatuses()
        guard appState.accessibilityPermissionStatus == .trusted else {
            appState.endLocalPasteTest()
            result = .failed("Allow Accessibility for the running app, then check again.")
            return
        }
        guard let target = field.prepareForSample(), field.isFocused else {
            appState.endLocalPasteTest()
            result = .failed("Keep the setup window active and try again.")
            return
        }
        let service = insertion ?? ClipboardTextInsertionService(additionalTargetCheck: { field.isFocused })
        isTesting = true
        result = .testing
        task = Task { @MainActor in
            defer {
                isTesting = false
                task = nil
                appState.endLocalPasteTest()
            }
            do {
                let delivery = try await service.insertText(Self.sample, target: target)
                try Task.checkCancellation()
                guard delivery == .pasteShortcutPosted else {
                    switch delivery {
                    case .clipboardChanged:
                        result = .failed("Clipboard changed during the test. Its newer content was preserved; try again.")
                    case .copiedForManualPaste:
                        result = .failed("Accessibility is not allowed. The sample was copied but not pasted.")
                    case .copiedBecauseTargetChanged:
                        result = .failed("Focus changed. No automatic paste was attempted; try again here.")
                    default:
                        result = .failed("The paste shortcut could not be posted. Check Accessibility and try again.")
                    }
                    return
                }
                let deadline = ContinuousClock.now.advanced(by: .seconds(1))
                while ContinuousClock.now < deadline {
                    try Task.checkCancellation()
                    guard field.isFocused else {
                        result = .failed("Focus changed before the sample could be verified. Try again here.")
                        return
                    }
                    if field.receivedSample { result = .passed; return }
                    try await Task.sleep(for: .milliseconds(20))
                }
                result = .failed("The shortcut was posted, but no sample arrived. Check Accessibility and try again.")
            } catch is CancellationError {
                result = .cancelled
            } catch {
                result = .failed("The local paste test could not complete. Check permissions and try again.")
            }
        }
    }

    func reset() {
        guard !isTesting else { return }
        result = .idle
    }
    func cancel() { task?.cancel() }
    func waitForCompletion() async { await task?.value }
}

/// Only this app-owned field is inspected. External editor text is never queried.
@MainActor
final class NativePasteTestField: LocalPasteTestField {
    weak var editor: NSTextView?
    var isFocused: Bool {
        guard let editor, let window = editor.window else { return false }
        return NSApp.isActive && window.isKeyWindow && window.firstResponder === editor
    }
    var receivedSample: Bool { editor?.string == LocalPasteTestSession.sample }
    func prepareForSample() -> TextInsertionTarget? {
        guard let editor, let window = editor.window, NSApp.isActive, window.isKeyWindow else { return nil }
        editor.string = ""
        guard window.makeFirstResponder(editor), isFocused else { return nil }
        return TextInsertionTarget(processIdentifier: ProcessInfo.processInfo.processIdentifier,
                                   localizedName: "BabbelStream setup", bundleIdentifier: Bundle.main.bundleIdentifier)
    }
}

struct PasteTestEditor: NSViewRepresentable {
    let field: NativePasteTestField
    func makeNSView(context: Context) -> NSScrollView {
        let scroll = NSScrollView()
        let editor = NSTextView(frame: NSRect(x: 0, y: 0, width: 500, height: 84))
        editor.minSize = NSSize(width: 0, height: 84)
        editor.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        editor.isHorizontallyResizable = false
        editor.isRichText = false
        editor.font = .systemFont(ofSize: NSFont.systemFontSize)
        editor.textContainerInset = NSSize(width: 8, height: 8)
        editor.isVerticallyResizable = true
        editor.autoresizingMask = [.width]
        editor.textContainer?.widthTracksTextView = true
        editor.setAccessibilityLabel("Local paste test field")
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        scroll.documentView = editor
        field.editor = editor
        return scroll
    }
    func updateNSView(_ nsView: NSScrollView, context: Context) {}
}
