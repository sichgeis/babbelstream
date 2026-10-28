import Foundation
import BabbelStreamCore

// Explicit developer-only smoke command. All inputs and storage must be disposable
// synthetic fixtures; ordinary task check never downloads or invokes native models.
func runLocalModelSmoke() async throws {
    func argument(_ name: String) throws -> String {
        let args = CommandLine.arguments
        guard let index = args.firstIndex(of: name), args.indices.contains(index + 1) else { throw LocalModelError.invalidManifest }
        return args[index + 1]
    }
    let root = URL(fileURLWithPath: try argument("--model-root"), isDirectory: true)
    guard root.standardizedFileURL.path.hasPrefix("/private/tmp/") || root.standardizedFileURL.path.hasPrefix("/tmp/") else {
        throw LocalModelError.invalidManifest
    }
    let helper = URL(fileURLWithPath: try argument("--helper"))
    let runtime = BundledLocalSpeechRuntime(executable: helper, supportedModels: [.parakeetUltra])
    let store = LocalModelStore(root: root)
    let manifest = try LocalModelCatalog.manifest(.parakeetUltra)
    if !(await store.isInstalled(manifest)) {
        try await store.install(manifest, progress: { _ in }, prepare: { directory in
            try await runtime.prepare(model: .parakeetUltra, directory: directory)
        })
    }
    let directory = await store.directory(manifest)
    try await store.verify(manifest, at: directory)
    print("Pinned Parakeet assets verified and prepared with network-denied inference.")
    let audio = URL(fileURLWithPath: try argument("--synthetic-audio"))
    let language = (try? argument("--language")) ?? ""
    let result = try await runtime.transcribe(model: .parakeetUltra, directory: directory, audio: audio, language: language)
    if let expected = try? argument("--expect-word") {
        check(result.localizedCaseInsensitiveContains(expected), "Synthetic transcript must contain the expected fixture word.")
    }
    check(!result.isEmpty, "Synthetic spoken sample must produce a nonempty local transcript.")
    print("Synthetic audio transcribed locally; output discarded. No microphone, key, clipboard or production store used.")
}
