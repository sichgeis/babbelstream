import Foundation
import BabbelStreamCore

@MainActor
final class FakeInsertionEnvironment: TextInsertionEnvironment {
    var clipboardChangeCount = 0
    var clipboard = "original fixture"
    var clipboardWrites = 0
    var posts = 0
    var postSucceeds = true
    var failWrite = false
    var trusted = true
    var target: TextInsertionTarget? = TextInsertionTarget(processIdentifier: 123, localizedName: "Fixture", bundleIdentifier: "com.openai.codex")
    var beforePaste: (() async throws -> Void)?

    func accessibilityPermissionStatus() -> AccessibilityPermissionStatus { trusted ? .trusted : .notTrusted }
    func requestAccessibilityPermission() {}
    func captureTarget() -> TextInsertionTarget? { target }
    func writeToClipboard(_ text: String) throws -> Int {
        if failWrite { throw TextInsertionError.pasteboardUnavailable }
        clipboard = text
        clipboardWrites += 1
        clipboardChangeCount += 1
        return clipboardChangeCount
    }
    func waitForPastePreparation() async throws { try await beforePaste?() }
    func postPasteShortcut() async -> Bool { posts += 1; return postSucceeds }
}

@MainActor
func runInsertionWorkflowChecks() async throws {
    // Every application takes the same delivery path, including former AX targets.
    for bundle in ["com.tinyspeck.slackmacgap", "com.apple.TextEdit", "com.microsoft.VSCode",
                   "com.anthropic.claudefordesktop", "com.openai.codex", "com.openai.chat",
                   "org.whispersystems.signal-desktop", "com.google.Chrome", "company.thebrowser.Browser",
                   "com.apple.mail", "com.microsoft.Outlook", "example.unknown", "", nil] as [String?] {
        let environment = FakeInsertionEnvironment()
        environment.target = TextInsertionTarget(processIdentifier: 123, localizedName: "Fixture", bundleIdentifier: bundle)
        let result = try await ClipboardTextInsertionService(environment: environment).insertText("draft fixture", target: environment.target)
        check(result == .pasteShortcutPosted && environment.posts == 1, "Every target must post exactly one paste.")
        check(environment.clipboardWrites == 1 && environment.clipboard == "draft fixture", "Every target must copy the draft exactly once.")
    }

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

    let denied = FakeInsertionEnvironment()
    denied.trusted = false
    let deniedResult = try await ClipboardTextInsertionService(environment: denied).insertText("fixture", target: denied.target)
    check(deniedResult == .copiedForManualPaste && denied.posts == 0 && denied.clipboardWrites == 1, "Denied Accessibility must copy without posting.")

    let missing = FakeInsertionEnvironment()
    let missingResult = try await ClipboardTextInsertionService(environment: missing).insertText("fixture", target: nil)
    check(missingResult == .copiedBecauseTargetChanged && missing.posts == 0 && missing.clipboardWrites == 1, "Missing capture must copy without posting.")

    let wrongApp = FakeInsertionEnvironment()
    let oldTarget = wrongApp.target
    wrongApp.target = TextInsertionTarget(processIdentifier: 456, localizedName: "Other fixture")
    let wrongAppResult = try await ClipboardTextInsertionService(environment: wrongApp).insertText("fixture", target: oldTarget)
    check(wrongAppResult == .copiedBecauseTargetChanged && wrongApp.posts == 0, "A changed process must block paste before preparation.")

    let bothChanged = FakeInsertionEnvironment()
    bothChanged.beforePaste = { [weak bothChanged] in
        bothChanged?.target = nil
        bothChanged?.clipboard = "newer fixture"
        bothChanged?.clipboardChangeCount += 1
    }
    let bothResult = try await ClipboardTextInsertionService(environment: bothChanged).insertText("fixture", target: bothChanged.target)
    check(bothResult == .clipboardChanged && bothChanged.posts == 0 && bothChanged.clipboardWrites == 1, "Clipboard contention takes priority over target change.")
    check(bothChanged.clipboard == "newer fixture", "Concurrent target/clipboard changes preserve the newer copy.")

    let failedPost = FakeInsertionEnvironment()
    failedPost.postSucceeds = false
    let failedPostResult = try await ClipboardTextInsertionService(environment: failedPost).insertText("fixture", target: failedPost.target)
    check(failedPostResult == .copiedAfterPasteShortcutFailure && failedPost.posts == 1 && failedPost.clipboard == "fixture", "Failed event creation retains the draft without retrying.")

    let failedWrite = FakeInsertionEnvironment()
    failedWrite.failWrite = true
    do {
        _ = try await ClipboardTextInsertionService(environment: failedWrite).insertText("fixture", target: failedWrite.target)
        check(false, "Clipboard failure must propagate.")
    } catch TextInsertionError.pasteboardUnavailable {}
    check(failedWrite.posts == 0 && failedWrite.clipboard == "original fixture", "A failed clipboard write must never post paste.")

    check(DictationHUDPresentation.phase(isRecording: false, isProcessing: false, canCancel: false, status: "Copy Last Draft", lastResult: "", hasError: false) == .draftAvailable, "Clipboard contention must show a truthful Copy Last Draft HUD.")
}
