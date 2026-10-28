import Foundation
import SwiftUI
import BabbelStreamCore

@MainActor
final class LocalModelController: ObservableObject {
    @Published private(set) var present: Set<LocalModelID> = []
    @Published private(set) var installed: Set<LocalModelID> = []
    @Published private(set) var isBusy = false
    @Published private(set) var progress: Double = 0
    @Published private(set) var message = "Download a model to dictate on this Mac without an API key."
    let runtime: any LocalModelRuntime
    let store: LocalModelStore
    var onChange: (() -> Void)?
    private var task: Task<Void, Never>?
    private let manifests: [LocalModelManifest]
    init(runtime: any LocalModelRuntime = BundledLocalSpeechRuntime(),
         store: LocalModelStore = LocalModelStore(root: LocalModelStore.defaultRoot),
         manifests: [LocalModelManifest] = LocalModelCatalog.manifests) {
        self.runtime = runtime; self.store = store; self.manifests = manifests
        if manifests.contains(where: { $0.id == .qwenCleanup }) { message = "Download the cleanup model to format transcripts on this Mac." }
    }
    private func manifest(_ id: LocalModelID) throws -> LocalModelManifest {
        guard let manifest = manifests.first(where: { $0.id == id }) else { throw LocalModelError.invalidManifest }
        return manifest
    }
    var canCancelDownload: Bool { task != nil }
    func refresh() async {
        var ready: Set<LocalModelID> = []
        var downloaded: Set<LocalModelID> = []
        for model in manifests {
            if await store.isInstalled(model) { ready.insert(model.id) }
            if await store.hasFiles(model) { downloaded.insert(model.id) }
        }
        installed = ready; present = downloaded; onChange?()
    }
    func download(_ id: LocalModelID) {
        guard !isBusy, runtime.supportedModels.contains(id) else { return }
        isBusy = true; progress = 0; message = "Downloading \(id.displayName)…"; onChange?()
        task = Task { [self] in
            defer { isBusy = false; task = nil; onChange?() }
            do {
                let manifest = try manifest(id)
                try await store.install(manifest, progress: { [weak self] fraction in
                    Task { @MainActor in self?.progress = fraction }
                }, prepare: { [weak self, runtime] directory in
                    await MainActor.run { self?.message = "Verifying and preparing \(id.displayName)…" }
                    try await runtime.prepare(model: id, directory: directory)
                })
                message = "\(id.displayName) is ready. Apply Settings to select it."
            } catch is CancellationError { message = "Download canceled. Staged files removed." }
            catch {
                message = (error as? LocalModelError)?.localizedDescription ?? "Model setup failed. Check storage and connection, then retry."
            }
            await refresh()
        }
    }
    func cancel() { task?.cancel() }
    func remove(_ id: LocalModelID) {
        guard !isBusy else { return }
        isBusy = true; onChange?()
        task = Task { [self] in
            defer { isBusy = false; task = nil; onChange?() }
            do {
                try await store.remove(manifest(id))
                message = "Model removed. Recordings and other app data were preserved."
            } catch { message = "Could not remove the model. No other app data was changed." }
            await refresh()
        }
    }
    func transcribe(model: LocalModelID, audio: URL, language: String) async throws -> String {
        guard !isBusy else { throw LocalModelError.busy }
        guard runtime.supportedModels.contains(model) else { throw LocalModelError.runtimeUnavailable }
        isBusy = true; onChange?()
        defer { isBusy = false; onChange?() }
        let manifest = try manifest(model)
        guard await store.isInstalled(manifest) else { throw LocalModelError.notInstalled }
        let directory = await store.directory(manifest)
        try await store.verify(manifest, at: directory)
        try Task.checkCancellation()
        guard let speech = runtime as? any LocalSpeechRuntime else { throw LocalModelError.runtimeUnavailable }
        return try await speech.transcribe(model: model, directory: directory, audio: audio, language: language)
    }
    func cleanup(transcript: String, dictionary: PersonalDictionary) async throws -> String {
        guard !isBusy, let cleaner = runtime as? any LocalCleanupRuntime else { throw LocalModelError.busy }
        isBusy = true; onChange?()
        defer { isBusy = false; onChange?() }
        let manifest = try manifest(.qwenCleanup)
        guard await store.isInstalled(manifest) else { throw LocalModelError.notInstalled }
        let directory = await store.directory(manifest)
        try await store.verify(manifest, at: directory)
        try Task.checkCancellation()
        return try await cleaner.cleanup(directory: directory, transcript: transcript, dictionary: dictionary)
    }

}
