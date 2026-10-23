import Foundation
import BabbelStreamCore
@testable import BabbelStreamApplication

@MainActor
private final class FixturePasteTestField: LocalPasteTestField {
    var isFocused = true
    var receivedSample = false
    var preparations = 0
    var target: TextInsertionTarget? = TextInsertionTarget(processIdentifier: 123, localizedName: "Fixture")
    func prepareForSample() -> TextInsertionTarget? {
        preparations += 1
        receivedSample = false
        return target
    }
}

@MainActor
func runOnboardingChecks() async throws {
    let fresh = OnboardingProgress()
    check(OnboardingPresentation.resolve(progress: fresh, microphoneAllowed: false, pasteAllowed: false) == .introduction, "First use must offer setup without requesting permissions itself.")
    let deferred = OnboardingProgress(introductionDismissed: true)
    check(OnboardingPresentation.resolve(progress: deferred, microphoneAllowed: false, pasteAllowed: false) == .none, "Postponed setup must not replay the tour or block manual paste.")
    let allowed = OnboardingProgress(introductionDismissed: true, microphoneWasAllowed: true, pasteWasAllowed: true)
    check(OnboardingPresentation.resolve(progress: allowed, microphoneAllowed: true, pasteAllowed: true) == .none, "An update with preserved grants must not replay setup.")
    for (mic, paste) in [(false, true), (true, false), (false, false)] {
        check(OnboardingPresentation.resolve(progress: allowed, microphoneAllowed: mic, pasteAllowed: paste) == .permissionRepair, "Lost grants must offer focused repair rather than trust stored completion.")
    }
    do {
        let f = try CoordinatorFixture(permissionsReady: false)
        defer { try? f.dispose() }
        let model = OnboardingModel(appState: f.app, store: f.onboarding)
        check(model.launchPresentation == .introduction && !model.progress.pasteWasAllowed, "Denied live permissions must not become allowed from setup history.")
        model.dismiss()
        f.recorder.permission = .authorized
        f.insertion.permission = .trusted
        model.refreshPermissions()
        check(f.app.accessibilityPermissionStatus == .trusted && f.onboarding.value.pasteWasAllowed && f.onboarding.value.microphoneWasAllowed, "Returning to setup must query OS adapters and record observed grants.")
        f.insertion.permission = .notTrusted
        model.refreshPermissions()
        check(model.launchPresentation == .permissionRepair && f.app.accessibilityPermissionStatus == .notTrusted, "Observed revocation must override stored successful setup.")
        check(f.secret.reads == 0 && f.transcription.requests.isEmpty && !f.recorder.isRecording, "Permission setup must not read secrets, record or contact providers.")
    }
    do {
        let suite = "BabbelStreamOnboardingChecks-\(UUID())"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = UserDefaultsOnboardingProgressStore(defaults: defaults)
        check(store.load() == fresh, "An isolated new preference domain must start fresh.")
        store.save(allowed)
        check(UserDefaultsOnboardingProgressStore(defaults: defaults).load() == allowed, "Dismissal and observed grants must survive relaunch without storing test text.")
    }
    do {
        let f = try CoordinatorFixture(permissionsReady: false)
        defer { try? f.dispose() }
        let field = FixturePasteTestField()
        let environment = FakeInsertionEnvironment()
        let session = LocalPasteTestSession(appState: f.app)
        session.start(field: field, insertion: ClipboardTextInsertionService(environment: environment))
        await session.waitForCompletion()
        check(field.preparations == 0 && environment.clipboardWrites == 0 && environment.posts == 0 && !f.app.isLocalPasteTesting, "Denied paste test must not focus a field or modify clipboard/events.")
        check(session.result != .passed, "Denied test cannot pass.")
    }
    for scenario in ["received", "no-receipt", "focus-lost", "clipboard", "revoked", "cancel", "focus-return", "post-failure", "write-failure"] {
        let f = try CoordinatorFixture()
        defer { try? f.dispose() }
        let field = FixturePasteTestField()
        let environment = FakeInsertionEnvironment()
        defer { environment.beforePaste = nil; environment.onPost = nil }
        let service = ClipboardTextInsertionService(environment: environment, additionalTargetCheck: { field.isFocused })
        let session = LocalPasteTestSession(appState: f.app)
        environment.postSucceeds = scenario != "post-failure"
        environment.failWrite = scenario == "write-failure"
        environment.beforePaste = {
            switch scenario {
            case "focus-lost": field.isFocused = false
            case "clipboard": environment.clipboard = "newer fixture"; environment.clipboardChangeCount += 1
            case "revoked":
                environment.trusted = false
                f.insertion.permission = .notTrusted
            case "focus-return":
                field.isFocused = false
                session.cancel() // Window/app focus-loss notification.
                field.isFocused = true
                try Task.checkCancellation()
            case "cancel": session.cancel(); try Task.checkCancellation()
            default: break
            }
        }
        environment.onPost = { if scenario == "received" { field.receivedSample = true } }
        session.start(field: field, insertion: service)
        session.start(field: field, insertion: service)
        check(f.app.isLocalPasteTesting && !f.app.canStart, "An active local test must exclusively reserve the coordinator and reject duplicate starts.")
        await f.app.startDictation()
        await f.app.testSavedConnection()
        check(!f.recorder.isRecording && f.transcription.requests.isEmpty, "Hotkey/provider tests must not start while local paste owns the coordinator.")
        await session.waitForCompletion()
        check(!f.app.isLocalPasteTesting && f.app.canStart, "All local test exits must release the coordinator.")
        check((session.result == .passed) == (scenario == "received"), "Only actual receipt of the known sample may pass: \(scenario).")
        check(environment.posts <= 1 && environment.clipboardWrites <= 1 && field.preparations == 1, "No duplicate paste or second clipboard write is allowed.")
        if ["focus-lost", "clipboard", "revoked", "cancel", "focus-return", "write-failure"].contains(scenario) {
            check(environment.posts == 0, "Focus/contention/permission/cancel/write failure must block event posting: \(scenario).")
        }
        if scenario == "revoked" {
            check(f.app.accessibilityPermissionStatus == .notTrusted, "Test completion must refresh live permission state after revocation.")
        }
        if scenario == "clipboard" { check(environment.clipboard == "newer fixture", "Contention must preserve the newer clipboard.") }
        check(f.secret.reads == 0 && f.personalSecret.reads == 0 && f.transcription.requests.isEmpty && f.mini.requests.isEmpty && f.cleanup.requests.isEmpty && f.app.latestFinalDraftSummary == "None", "Local test must never read keys, contact providers or replace Last Draft.")
    }
    do {
        let f = try CoordinatorFixture()
        defer { try? f.dispose() }
        await f.app.startDictation()
        let session = LocalPasteTestSession(appState: f.app)
        let field = FixturePasteTestField()
        session.start(field: field, insertion: f.insertion)
        check(!session.isTesting && field.preparations == 0 && f.insertion.inserted.isEmpty, "Local test must not interrupt an existing recording.")
        await f.app.cancelRecording()
    }
    // A manual Last Draft delivery is also an active operation, even without a provider task.
    do {
        let f = try CoordinatorFixture()
        defer { try? f.dispose() }
        await f.app.startDictation()
        await f.app.stopActiveRecording()
        let session = LocalPasteTestSession(appState: f.app)
        let field = FixturePasteTestField()
        defer { f.insertion.action = nil }
        f.insertion.action = { _ in
            session.start(field: field, insertion: f.insertion)
            check(!session.isTesting && field.preparations == 0, "Local test must not overlap an existing Last Draft delivery.")
            return .pasteShortcutPosted
        }
        await f.app.retryPasteLatestDraft()
        check(f.app.canStart, "Last Draft delivery must release its activity guard.")
    }
    // Cancellation after posting cannot turn a delayed sample into success.
    do {
        let f = try CoordinatorFixture()
        defer { try? f.dispose() }
        let field = FixturePasteTestField()
        let environment = FakeInsertionEnvironment()
        let session = LocalPasteTestSession(appState: f.app)
        environment.onPost = { session.cancel(); field.receivedSample = true }
        session.start(field: field, insertion: ClipboardTextInsertionService(environment: environment))
        await session.waitForCompletion()
        check(session.result == .cancelled && !f.app.isLocalPasteTesting, "A closed/canceled test must reject delayed success and release ownership.")
    }
}
