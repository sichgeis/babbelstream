import Foundation
import BabbelStreamCore
@testable import BabbelStreamApplication

@MainActor
func runCoordinatorWorkflowChecks() async throws {
    // Actual AppState, isolated OS adapters and stores: no credentials or work content.
    do {
        let f = try CoordinatorFixture(cleanupEnabled: false)
        defer { try? f.dispose() }
        f.app.setDictationArchiveEnabled(true)
        await f.app.startDictation()
        await f.app.stopActiveRecording()
        let browser = f.app.archiveBrowser
        check(browser.snapshot.entries.count == 1, "The archive browser must refresh after an opted-in dictation.")
        browser.monthText = "invalid"
        browser.loadMonth()
        check(browser.errorMessage != nil && browser.snapshot.entries.count == 1, "Invalid input preserves the displayed month.")
        browser.monthText = browser.snapshot.month.directoryName
        browser.copyMarkdownExport()
        check(f.insertion.copied.count == 1 && browser.errorMessage == nil, "Archive export copies through the injected clipboard.")
        browser.clear()
        browser.loadMonth()
        check(browser.snapshot.entries.isEmpty, "Clearing the fixture archive must clear both the browser and store.")
    }

    do {
        let f = try CoordinatorFixture(cleanupEnabled: false)
        defer { try? f.dispose() }
        let currentTarget = f.insertion.target
        f.insertion.target = nil
        await f.app.startDictation()
        f.insertion.target = currentTarget
        await f.app.stopActiveRecording()
        check(f.insertion.deliveryTargets.count == 1 && f.insertion.deliveryTargets[0] == nil,
              "Delivery must preserve an unavailable start target despite a later activation.")
        await f.app.retryPasteLatestDraft()
        check(f.insertion.deliveryTargets.count == 2 && f.insertion.deliveryTargets[1] == currentTarget,
              "Explicit Paste Last Draft must capture a fresh target.")
    }

    do {
        let f = try CoordinatorFixture(cleanupEnabled: false)
        defer { try? f.dispose() }
        f.app.setPersonalOpenAIFallbackEnabledDraft(true)
        f.app.saveSettings()
        f.transcription.action = { _ in throw ProviderError.requestFailed(statusCode: 429, message: nil) }
        f.mini.action = { _ in throw URLError(.timedOut) }
        await f.app.startDictation()
        await f.app.stopActiveRecording()
        check(f.mini.requests.count == 1 && f.personalSecret.reads == 0,
              "A rate limit followed by a Mini timeout must retain audio without switching accounts.")
        check(f.app.recoverySnapshot.recordings.first?.state == .transcriptionFailed,
              "Mixed failures must remain recoverable.")
    }

    do {
        let f = try CoordinatorFixture()
        defer { try? f.dispose() }
        let item = try await f.createFailedRecording()
        let (started, signal) = AsyncStream<Void>.makeStream()
        f.transcription.action = { _ in
            signal.yield(())
            signal.finish()
            try await Task.sleep(for: .seconds(30))
            return "late fixture"
        }
        let retry = Task { await f.app.retryRecoveryRecording(item) }
        for await _ in started { break }
        check(f.hotkey.cancelEnabled, "Escape must be registered while retry is processing.")
        f.hotkey.onCancel?()
        await retry.value
        check(!f.hotkey.cancelEnabled && f.app.recoverySnapshot.recordings.first?.state == .processingCanceled,
              "Escape must cancel retry, retain the audio and release the hotkey.")
        check(f.insertion.copied.isEmpty, "Canceled retry must not deliver late text.")
    }

    do {
        let f = try CoordinatorFixture()
        defer { try? f.dispose() }
        check(f.secret.reads == 0 && f.personalSecret.reads == 0, "Coordinator startup must not read credentials.")
        await f.app.startDictation()
        f.app.settingsDraft.baseURLText = "https://later.example.invalid"
        f.app.apiKeyInput = "replacement-fixture-key"
        f.app.saveSettings()
        check(f.app.settingsErrorMessage == nil, "Fixture settings edit must actually apply.")
        await f.app.stopActiveRecording()
        check(f.transcription.requests.count == 1 && f.mini.requests.isEmpty, "Normal workflow must make one primary request.")
        check(f.transcription.requests.first?.settings.providerConfiguration.baseURL.host == "primary.example.invalid", "Recording must retain its original provider snapshot after Apply.")
        check(f.transcription.requests.first?.apiKey == "synthetic-key-not-a-credential", "An active operation must retain the previously approved origin's key during replacement.")
        check(f.cleanup.requests.first?.settings.providerConfiguration.baseURL.host == "primary.example.invalid", "Cleanup must use the same operation settings snapshot.")
        check(f.insertion.inserted == ["clean fixture "], "Normal workflow must deliver a separated unsent draft once.")
        let snapshot = try f.recovery.loadSnapshot()
        check(snapshot.recordings.isEmpty, "Successful workflow must delete safeguarded audio.")
        check(f.app.canStart, "Normal completion must release busy state.")
    }

    do {
        let f = try CoordinatorFixture()
        defer { try? f.dispose() }
        let item = try await f.createFailedRecording()
        check(item.state == .cleanupFailed && f.insertion.inserted == ["raw fixture "], "Cleanup fallback must deliver raw text and retain audio.")
        let initialInsertCount = f.insertion.inserted.count
        f.app.settingsDraft.baseURLText = "https://retry.example.invalid"
        f.app.apiKeyInput = "replacement-fixture-key"
        f.app.saveSettings()
        f.transcription.action = { [weak app = f.app] _ in
            app?.settingsDraft.baseURLText = "https://next.example.invalid"
            app?.apiKeyInput = "next-fixture-key"
            app?.saveSettings()
            return "raw fixture"
        }
        await f.app.retryRecoveryRecording(item)
        check(f.transcription.requests.last?.settings.providerConfiguration.baseURL.host == "retry.example.invalid", "Recovery must snapshot current applied settings.")
        check(f.cleanup.requests.last?.settings.providerConfiguration.baseURL.host == "retry.example.invalid", "An Apply during retry must not redirect cleanup mid-operation.")
        check(f.insertion.inserted.count == initialInsertCount && f.insertion.copied == ["clean fixture "], "Recovery must copy output without auto-pasting.")
        check(f.app.lastResult == "Recovered draft copied; saved recording deleted.", "Successful recovery deletion must report the real outcome.")
        let snapshot = try f.recovery.loadSnapshot()
        check(snapshot.recordings.isEmpty, "Successful recovery must delete audio.")
    }

    do {
        let f = try CoordinatorFixture()
        defer { try? f.dispose() }
        let item = try await f.createFailedRecording()
        f.fm.failRemovalAt = f.recovery.recoveryDirectoryURL.appendingPathComponent(item.id.uuidString)
        await f.app.retryRecoveryRecording(item)
        check(f.insertion.copied == ["clean fixture "], "Deletion failure must not prevent the recovered copy.")
        check(f.app.warningMessage?.contains("could not be deleted") == true, "Recovery must preserve the deletion-failure warning.")
        check(f.app.lastResult.contains("recording retained") && !f.app.lastResult.contains("saved recording deleted"), "Recovery must never claim deletion when it failed.")
        check(f.app.recoverySnapshot.recordings.count == 1, "Failed deletion must keep the recovery entry visible.")
        f.fm.failRemovalAt = nil
        f.app.deleteRecoveryRecording(item)
        check(f.app.recoverySnapshot.recordings.isEmpty, "Explicit deletion must remove a retained successful recording.")
    }

    do {
        let f = try CoordinatorFixture()
        defer { try? f.dispose() }
        let earlier = try await f.createFailedRecording()
        await f.app.startDictation()
        f.recorder.audio = nil
        await f.app.stopActiveRecording()
        check(f.app.operationStatus.hudPhase == .error && f.app.recoverySnapshot.recordings.map(\.id) == [earlier.id],
              "A previous failed recording must not make the HUD claim the current recording was saved.")
    }

    do {
        let f = try CoordinatorFixture()
        defer { try? f.dispose() }
        f.fm.failCopy = true
        await f.app.startDictation()
        await f.app.stopActiveRecording()
        check(f.transcription.requests.isEmpty && f.mini.requests.isEmpty, "Failed adoption must make no provider request.")
        check(f.app.recoverySnapshot.recordings.count == 1, "Failed adoption must surface stopped audio immediately.")
        let pending = f.app.recoverySnapshot.recordings[0]
        await f.app.retryRecoveryRecording(pending)
        check(f.transcription.requests.isEmpty, "Retry must finish adoption before contacting a provider.")
        f.fm.failCopy = false
        await f.app.retryRecoveryRecording(pending)
        check(f.transcription.requests.count == 1 && f.insertion.inserted.isEmpty && f.insertion.copied.count == 1, "Repaired adoption must recover through copy only.")
    }

    do {
        let f = try CoordinatorFixture()
        defer { try? f.dispose() }
        f.recorder.failStopOwnership = true
        await f.app.startDictation()
        await f.app.stopActiveRecording()
        check(f.app.canStop && f.app.canCancel && !f.app.canStart, "Stop-marker failure must retain Stop/Cancel and prevent another recording.")
        check(f.transcription.requests.isEmpty, "Stop-marker failure must not call a provider.")
        await f.app.cancelRecording()
        check(f.app.canStart && !f.recorder.isRecording, "Explicit Cancel must release recorder ownership after a stop-marker failure.")
        check(!FileManager.default.fileExists(atPath: f.recorder.audio!.temporaryFileURL.path), "Canceled partial audio must be deleted.")
    }

    do {
        let f = try CoordinatorFixture()
        defer { try? f.dispose() }
        let (started, signal) = AsyncStream<Void>.makeStream()
        f.transcription.action = { _ in
            signal.yield(())
            signal.finish()
            try await Task.sleep(nanoseconds: 30_000_000_000)
            return "late fixture"
        }
        await f.app.startDictation()
        let stopping = Task { @MainActor in await f.app.stopActiveRecording() }
        for await _ in started { break }
        await f.app.cancelRecording()
        await stopping.value
        let snapshot = try f.recovery.loadSnapshot()
        check(snapshot.recordings.count == 1 && snapshot.recordings[0].state == .processingCanceled, "Processing cancellation must retain stopped audio.")
        check(f.insertion.inserted.isEmpty && f.insertion.copied.isEmpty, "Canceled processing must not deliver a draft.")
        check(f.app.canStart && !f.hotkey.cancelEnabled, "Cancellation must restore readiness and release Escape.")
    }

    do {
        let f = try CoordinatorFixture()
        defer { try? f.dispose() }
        let item = try await f.createFailedRecording()
        f.insertion.failCopy = true
        await f.app.retryRecoveryRecording(item)
        check(f.app.recoverySnapshot.recordings.first?.state == .copyFailed, "Recovery clipboard failure must retain audio and its reason.")
    }

    do {
        let f = try CoordinatorFixture(cleanupEnabled: false)
        defer { try? f.dispose() }
        f.insertion.result = .clipboardChanged
        await f.app.startDictation()
        await f.app.stopActiveRecording()
        check(f.app.status == "Copy Last Draft", "Coordinator must present the clipboard-contention recovery action.")
        check(f.insertion.copied.isEmpty, "Clipboard contention must not trigger an automatic second copy.")
        f.app.copyLatestDraft()
        check(f.insertion.copied == ["raw fixture"], "The prepared draft must remain available through explicit Copy Last Draft.")
    }

    do {
        let f = try CoordinatorFixture()
        defer { try? f.dispose() }
        f.cleanup.fail = true
        f.insertion.result = .clipboardChanged
        await f.app.startDictation()
        await f.app.stopActiveRecording()
        check(f.app.status == "Copy Last Draft" && !f.app.lastResult.contains("delivered"), "Cleanup fallback plus clipboard contention must not claim delivery.")
        check(f.app.recoverySnapshot.recordings.count == 1, "Cleanup fallback must still retain audio after clipboard contention.")
    }
}
