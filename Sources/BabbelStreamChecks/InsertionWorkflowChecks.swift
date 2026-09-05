import Foundation
import BabbelStreamCore

@MainActor
final class FakeInsertionEnvironment: TextInsertionEnvironment {
    var clipboardChangeCount = 0
    var clipboard = "original fixture"
    var clipboardWrites = 0
    var posts = 0
    var directWrites = 0
    var directSucceeds = false
    var trusted = true
    var target: TextInsertionTarget? = TextInsertionTarget(processIdentifier: 123, localizedName: "Fixture", bundleIdentifier: "com.openai.codex")
    var beforePaste: (() async throws -> Void)?

    func accessibilityPermissionStatus() -> AccessibilityPermissionStatus { trusted ? .trusted : .notTrusted }
    func requestAccessibilityPermission() {}
    func captureTarget() -> TextInsertionTarget? { target }
    func insertDirectlyIntoFocusedElement(_ text: String, target: TextInsertionTarget?) -> Bool {
        directWrites += 1
        return directSucceeds
    }
    func writeToClipboard(_ text: String) throws -> Int {
        clipboard = text
        clipboardWrites += 1
        clipboardChangeCount += 1
        return clipboardChangeCount
    }
    func waitForPastePreparation() async throws { try await beforePaste?() }
    func postPasteShortcut() async -> Bool { posts += 1; return true }
}

@MainActor
func runInsertionWorkflowChecks() async throws {
    let normal = FakeInsertionEnvironment()
    let normalResult = try await ClipboardTextInsertionService(environment: normal).insertText("fixture", target: normal.target)
    check(normalResult == .pasteShortcutPosted && normal.posts == 1 && normal.directWrites == 0, "Unchanged clipboard must post exactly one paste for web editors.")

    let signal = FakeInsertionEnvironment()
    signal.target = TextInsertionTarget(processIdentifier: 124, localizedName: "Signal fixture", bundleIdentifier: "org.whispersystems.signal-desktop")
    signal.directSucceeds = true
    let signalResult = try await ClipboardTextInsertionService(environment: signal).insertText("signal draft fixture", target: signal.target)
    check(signalResult == .pasteShortcutPosted && signal.directWrites == 0, "Signal must bypass even a reportedly successful AX insertion.")
    check(signal.clipboardWrites == 1 && signal.posts == 1 && signal.clipboard == "signal draft fixture", "Signal must use the normal clipboard path exactly once.")

    let changed = FakeInsertionEnvironment()
    changed.beforePaste = { [weak changed] in
        changed?.clipboard = "newer clipboard fixture"
        changed?.clipboardChangeCount += 1
    }
    let changedResult = try await ClipboardTextInsertionService(environment: changed).insertText("fixture", target: changed.target)
    check(changedResult == .clipboardChanged && changed.posts == 0, "Clipboard replacement must block automatic paste.")
    check(changed.clipboard == "newer clipboard fixture" && changed.clipboardWrites == 1, "Contention must preserve newer clipboard contents without a second write.")

    let switched = FakeInsertionEnvironment()
    switched.beforePaste = { [weak switched] in switched?.target = nil }
    let switchedResult = try await ClipboardTextInsertionService(environment: switched).insertText("fixture", target: switched.target)
    check(switchedResult == .copiedBecauseTargetChanged && switched.posts == 0, "Switching applications during preparation must block paste.")

    let canceled = FakeInsertionEnvironment()
    canceled.beforePaste = { throw CancellationError() }
    do {
        _ = try await ClipboardTextInsertionService(environment: canceled).insertText("fixture", target: canceled.target)
        check(false, "Cancellation during preparation must propagate.")
    } catch is CancellationError {}
    check(canceled.posts == 0, "Canceled preparation must post no events.")

    let native = FakeInsertionEnvironment()
    native.target = TextInsertionTarget(processIdentifier: 123, localizedName: "Native fixture")
    native.directSucceeds = true
    let nativeResult = try await ClipboardTextInsertionService(environment: native).insertText("fixture", target: native.target)
    check(nativeResult == .insertedDirectly && native.clipboardWrites == 0 && native.posts == 0, "Native direct insertion must avoid clipboard and synthetic events.")
    check(DictationHUDPresentation.phase(isRecording: false, isProcessing: false, canCancel: false, status: "Copy Last Draft", lastResult: "", hasError: false) == .draftAvailable, "Clipboard contention must show a truthful Copy Last Draft HUD.")
}
