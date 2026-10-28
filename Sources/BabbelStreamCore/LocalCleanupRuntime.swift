import Foundation

public enum LocalCleanupCatalog {
    public static let manifest = LocalModelManifest(id: .qwenCleanup,
        repository: "unsloth/Qwen3.5-4B-GGUF", revision: "e87f176479d0855a907a41277aca2f8ee7a09523",
        files: [LocalModelFile(path: "Qwen3.5-4B-Q4_K_M.gguf", bytes: 2_740_937_888,
            sha256: "00fe7986ff5f6b463e62455821146049db6f9313603938a70800d1fb69ef11a4")])
}

public protocol LocalCleanupRuntime: LocalModelRuntime {
    func cleanup(directory: URL, transcript: String, dictionary: PersonalDictionary) async throws -> String
}

public enum LocalCleanupError: Error, LocalizedError, Sendable {
    case failed
    public var errorDescription: String? {
        "Local cleanup could not finish within its size or time limits. Using the raw transcript; the recording remains available for retry."
    }
}

public enum LocalCleanupPrompt {
    public static func make(transcript: String, dictionary: PersonalDictionary) -> String {
        // The pinned Qwen3.5 non-thinking ChatML template. Dictated special-token
        // spellings are escaped before tokenization to preserve role boundaries.
        func content(_ text: String) -> String {
            text.replacingOccurrences(of: "<|", with: "< |")
                .replacingOccurrences(of: "<think>", with: "< think>")
                .replacingOccurrences(of: "</think>", with: "</ think>")
        }
        let base = CleanupPrompt.slackReady + "\nMixed-language rule: preserve the exact language of each word. Keep English words inside German sentences, including technical verbs and nouns; do not replace them with German synonyms. Preserve numbers, negation and identifiers exactly. Only remove speech fillers and accidental repetition, fix punctuation and casing. Explicit personal dictionary corrections and preferred spellings below take priority over preserving the input spelling: apply matching wrong-to-preferred corrections. When uncertain, copy the original wording."
        let instructions = DictionaryPromptBuilder.cleanupSystemPrompt(basePrompt: base, dictionary: dictionary)
        return "<|im_start|>system\n\(content(instructions))<|im_end|>\n<|im_start|>user\n\(content(CleanupPrompt.userMessage(for: transcript)))<|im_end|>\n<|im_start|>assistant\n<think>\n\n</think>\n\n"
    }
    public static func validatedResult(_ data: Data) throws -> String {
        guard let result = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              !result.isEmpty, !result.contains("<|"), !result.contains("<think>"),
              !result.contains("</think>") else { throw LocalCleanupError.failed }
        return result
    }
}

public struct BundledLocalCleanupRuntime: LocalCleanupRuntime {
    private let executable: URL?
    public var supportedModels: Set<LocalModelID> { executable == nil ? [] : [.qwenCleanup] }
    public init(bundle: Bundle = .main) {
        let helper = bundle.bundleURL.appendingPathComponent("Contents/Helpers/BabbelStreamLocalCleanup")
        #if arch(arm64)
        if #available(macOS 14, *), FileManager.default.isExecutableFile(atPath: helper.path) {
            executable = helper; return
        }
        #endif
        executable = nil
    }
    public init(executable: URL) { self.executable = executable }
    public func prepare(model: LocalModelID, directory: URL) async throws {
        guard model == .qwenCleanup else { throw LocalModelError.runtimeUnavailable }
        _ = try await run(directory: directory, prompt: "")
    }
    public func cleanup(directory: URL, transcript: String, dictionary: PersonalDictionary) async throws -> String {
        let prompt = LocalCleanupPrompt.make(transcript: transcript, dictionary: dictionary)
        guard prompt.utf8.count <= 131_072 else { throw LocalCleanupError.failed }
        let result = try LocalCleanupPrompt.validatedResult(await run(directory: directory, prompt: prompt))
        return LocalCleanupDictionary.apply(to: result, dictionary: dictionary)
    }
    private func run(directory: URL, prompt: String) async throws -> Data {
        guard let executable else { throw LocalModelError.runtimeUnavailable }
        let model = directory.appendingPathComponent(LocalCleanupCatalog.manifest.files[0].path)
        let invocation = LocalSpeechInvocation(executable: executable, request: Data(prompt.utf8),
                                               arguments: [model.path], timeout: 180)
        do {
            return try await withTaskCancellationHandler {
                try Task.checkCancellation()
                let data = try await invocation.run()
                try Task.checkCancellation()
                return data
            } onCancel: { invocation.cancel() }
        } catch {
            if Task.isCancelled { throw CancellationError() }
            throw LocalCleanupError.failed
        }
    }
}
