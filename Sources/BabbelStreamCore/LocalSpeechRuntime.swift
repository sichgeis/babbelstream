import Foundation
import Darwin

public protocol LocalSpeechRuntime: Sendable {
    var supportedModels: Set<LocalModelID> { get }
    func prepare(model: LocalModelID, directory: URL) async throws
    func transcribe(model: LocalModelID, directory: URL, audio: URL, language: String) async throws -> String
}

public struct BundledLocalSpeechRuntime: LocalSpeechRuntime {
    private let executable: URL?
    public let supportedModels: Set<LocalModelID>
    public init(bundle: Bundle = .main) {
        #if arch(arm64)
        if #available(macOS 14, *) {
            let helper = bundle.bundleURL.appendingPathComponent("Contents/Helpers/BabbelStreamLocalSpeech")
            let capabilities = bundle.bundleURL.appendingPathComponent("Contents/Resources/LocalSpeechCapabilities.json")
            if FileManager.default.isExecutableFile(atPath: helper.path),
               let data = try? Data(contentsOf: capabilities),
               let ids = try? JSONDecoder().decode([LocalModelID].self, from: data) {
                executable = helper; supportedModels = Set(ids); return
            }
        }
        #endif
        executable = nil; supportedModels = []
    }
    public init(executable: URL, supportedModels: Set<LocalModelID>) {
        self.executable = executable; self.supportedModels = supportedModels
    }
    public func prepare(model: LocalModelID, directory: URL) async throws {
        _ = try await run(model: model, directory: directory, audio: nil, language: "")
    }
    public func transcribe(model: LocalModelID, directory: URL, audio: URL, language: String) async throws -> String {
        let text = try await run(model: model, directory: directory, audio: audio, language: language)
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { throw ProviderError.emptyTranscript }
        return text
    }
    private func run(model: LocalModelID, directory: URL, audio: URL?, language: String) async throws -> String {
        guard supportedModels.contains(model), let executable else { throw LocalModelError.runtimeUnavailable }
        let request = LocalSpeechProcessRequest(model: model.rawValue, directory: directory.path,
                                                audio: audio?.path, language: language)
        let invocation = LocalSpeechInvocation(executable: executable, request: try JSONEncoder().encode(request))
        return try await withTaskCancellationHandler {
            try Task.checkCancellation()
            let bytes = try await invocation.run()
            try Task.checkCancellation()
            guard let response = try? JSONDecoder().decode(LocalSpeechProcessResponse.self, from: bytes),
                  response.error == nil, let text = response.text else { throw LocalModelError.inferenceFailed }
            return text
        } onCancel: { invocation.cancel() }
    }
}

private struct LocalSpeechProcessRequest: Encodable {
    let model: String; let directory: String; let audio: String?; let language: String
}
private struct LocalSpeechProcessResponse: Decodable { let text: String?; let error: String? }

/// Blocking pipe IO lives on a utility queue, never on the main actor. Process
/// lifetime bounds memory, cancellation and all library console output. The OS
/// sandbox denies network even if a future SDK loader regresses.
private final class LocalSpeechInvocation: @unchecked Sendable {
    private let lock = NSLock()
    private var canceled = false
    private let process = Process()
    private let request: Data
    init(executable: URL, request: Data) {
        self.request = request
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sandbox-exec")
        process.arguments = ["-p", "(version 1)(allow default)(deny network*)", executable.path]
        process.environment = ["PATH": "/usr/bin:/bin", "OS_ACTIVITY_MODE": "disable"]
        process.standardError = FileHandle.nullDevice
    }
    func cancel() {
        lock.lock(); defer { lock.unlock() }
        canceled = true
        if process.isRunning {
            // SIGKILL avoids unbounded native/GPU work after cancellation. No
            // result is used; the parent retains stopped audio for recovery.
            kill(process.processIdentifier, SIGKILL)
        }
    }
    func run() async throws -> Data {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .utility).async { [self] in
                do {
                    let input = Pipe(), output = Pipe()
                    process.standardInput = input; process.standardOutput = output
                    lock.lock()
                    if canceled { lock.unlock(); throw CancellationError() }
                    do { try process.run() } catch {
                        lock.unlock(); throw LocalModelError.runtimeUnavailable
                    }
                    lock.unlock()
                    DispatchQueue.global(qos: .utility).asyncAfter(deadline: .now() + 600) { [weak self] in self?.cancel() }
                    try input.fileHandleForWriting.write(contentsOf: request)
                    try input.fileHandleForWriting.close()
                    var result = Data()
                    while let chunk = try output.fileHandleForReading.read(upToCount: 65_536), !chunk.isEmpty {
                        result.append(chunk)
                        guard result.count <= 1_048_576 else { cancel(); throw LocalModelError.inferenceFailed }
                    }
                    process.waitUntilExit()
                    lock.lock(); let wasCanceled = canceled; lock.unlock()
                    if wasCanceled { throw CancellationError() }
                    guard process.terminationStatus == 0 else { throw LocalModelError.inferenceFailed }
                    continuation.resume(returning: result)
                } catch {
                    cancel()
                    continuation.resume(throwing: error is CancellationError ? CancellationError() : LocalModelError.inferenceFailed)
                }
            }
        }
    }
}
