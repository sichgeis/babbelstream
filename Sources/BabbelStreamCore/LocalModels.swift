import Foundation
import CryptoKit

public enum TranscriptionBackend: String, CaseIterable, Sendable { case remote, local }

public enum LocalModelID: String, CaseIterable, Codable, Sendable {
    case parakeetUltra, qwen3ASR, graniteSpeech, unavailable
    public static let allCases: [LocalModelID] = [.parakeetUltra, .qwen3ASR, .graniteSpeech]
    public var displayName: String {
        switch self {
        case .parakeetUltra: "Parakeet Ultra — Fast"
        case .qwen3ASR: "Qwen3-ASR 1.7B — Multilingual"
        case .graniteSpeech: "Granite Speech 5.0 — Experimental"
        case .unavailable: "Saved model unavailable"
        }
    }
    public var license: String { self == .parakeetUltra ? "CC-BY-4.0" : "Apache-2.0" }
}

public struct LocalModelFile: Codable, Equatable, Sendable {
    public let path: String
    public let bytes: Int64
    public let sha256: String
    public init(path: String, bytes: Int64, sha256: String) {
        self.path = path; self.bytes = bytes; self.sha256 = sha256
    }
}

public struct LocalModelManifest: Codable, Equatable, Sendable {
    public let id: LocalModelID
    public let repository: String
    public let revision: String
    public let files: [LocalModelFile]
    public var bytes: Int64 { files.reduce(0) { $0 + $1.bytes } }
    public init(id: LocalModelID, repository: String, revision: String, files: [LocalModelFile]) {
        self.id = id; self.repository = repository; self.revision = revision; self.files = files
    }
    public func validate() throws {
        guard revision.range(of: "^[a-f0-9]{40}$", options: .regularExpression) != nil,
              repository.range(of: "^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$", options: .regularExpression) != nil,
              !files.isEmpty, Set(files.map(\.path)).count == files.count else { throw LocalModelError.invalidManifest }
        for file in files {
            let components = file.path.split(separator: "/", omittingEmptySubsequences: false)
            guard !components.contains(where: { $0.isEmpty || $0 == "." || $0 == ".." }),
                  !file.path.contains("\\"), !file.path.contains(":"),
                  file.bytes >= 0,
                  file.sha256.range(of: "^[a-f0-9]{64}$", options: .regularExpression) != nil
            else { throw LocalModelError.invalidManifest }
        }
    }
    public func downloadURL(for file: LocalModelFile) -> URL {
        URL(string: "https://huggingface.co")!.appendingPathComponent(repository)
            .appendingPathComponent("resolve").appendingPathComponent(revision).appendingPathComponent(file.path)
    }
}

public enum LocalModelCatalog {
    public static let manifests: [LocalModelManifest] = {
        guard let decoded = try? JSONDecoder().decode([LocalModelManifest].self, from: Data(localModelCatalogJSON.utf8)),
              decoded.count == LocalModelID.allCases.count,
              Set(decoded.map(\.id)) == Set(LocalModelID.allCases),
              decoded.allSatisfy({ (try? $0.validate()) != nil }) else { return [] }
        return decoded
    }()
    public static func manifest(_ id: LocalModelID) throws -> LocalModelManifest {
        guard let manifest = manifests.first(where: { $0.id == id }) else { throw LocalModelError.invalidManifest }
        return manifest
    }
}

public enum LocalModelError: Error, LocalizedError, Sendable {
    case invalidManifest, insufficientStorage, integrityFailed, notInstalled, busy, downloadFailed, runtimeUnavailable, inferenceFailed, stagingCleanupFailed
    public var errorDescription: String? {
        switch self {
        case .stagingCleanupFailed: "Model setup stopped, but temporary model files could not be removed. Retry model setup to clean them up."
        case .invalidManifest: "The model catalog is invalid. Update BabbelStream before downloading."
        case .insufficientStorage: "There is not enough free space to stage and prepare this model."
        case .integrityFailed: "Model verification failed. Remove the model and download it again."
        case .notInstalled: "Download and prepare the selected local model first."
        case .busy: "Wait for the current model operation to finish."
        case .downloadFailed: "The model download failed. Check your connection and retry."
        case .runtimeUnavailable: "This build cannot run that local model. Local speech requires Apple Silicon, macOS 14 or later and the matching bundled runtime."
        case .inferenceFailed: "The local model could not process the audio. The stopped recording remains available for retry."
        }
    }
}

public protocol LocalModelDownloading: Sendable {
    func download(_ url: URL, to destination: URL, expectedBytes: Int64,
                  progress: @escaping @Sendable (Int64) -> Void) async throws
}

public enum LocalModelDownloadPolicy {
    public static func permits(_ url: URL) -> Bool {
        url.scheme?.lowercased() == "https" && url.host?.isEmpty == false
            && url.user == nil && url.password == nil
    }
}

/// No credentials, cookies, cache or retry. Cross-host HTTPS redirects are necessary
/// for Hugging Face's file CDN; reject all transport downgrade and URL credentials.
public final class HTTPSLocalModelDownloader: LocalModelDownloading, Sendable {
    public init() {}
    public func download(_ url: URL, to destination: URL, expectedBytes: Int64,
                         progress: @escaping @Sendable (Int64) -> Void) async throws {
        guard LocalModelDownloadPolicy.permits(url) else { throw LocalModelError.downloadFailed }
        let delegate = ModelDownloadDelegate(destination: destination, expectedBytes: expectedBytes, progress: progress)
        let config = URLSessionConfiguration.ephemeral
        config.httpCookieStorage = nil; config.urlCredentialStorage = nil; config.urlCache = nil
        config.timeoutIntervalForRequest = 120; config.timeoutIntervalForResource = 7200
        let session = URLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        defer { session.invalidateAndCancel() }
        try await withTaskCancellationHandler {
            try await delegate.start(session: session, url: url)
        } onCancel: { session.invalidateAndCancel() }
        try Task.checkCancellation()
    }
}

private final class ModelDownloadDelegate: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {
    private let destination: URL
    private let expectedBytes: Int64
    private let progress: @Sendable (Int64) -> Void
    private var continuation: CheckedContinuation<Void, Error>?
    private var failure: Error?
    init(destination: URL, expectedBytes: Int64, progress: @escaping @Sendable (Int64) -> Void) {
        self.destination = destination; self.expectedBytes = expectedBytes; self.progress = progress
    }
    func start(session: URLSession, url: URL) async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            session.downloadTask(with: url).resume()
        }
    }
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        guard let url = request.url, LocalModelDownloadPolicy.permits(url) else {
            failure = LocalModelError.downloadFailed; completionHandler(nil); return
        }
        completionHandler(request)
    }
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64,
                    totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesWritten > expectedBytes {
            failure = LocalModelError.integrityFailed; downloadTask.cancel()
        } else { progress(totalBytesWritten) }
    }
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        guard let response = downloadTask.response as? HTTPURLResponse, response.statusCode == 200 else {
            failure = LocalModelError.downloadFailed; return
        }
        do { try FileManager.default.moveItem(at: location, to: destination) }
        catch { failure = LocalModelError.downloadFailed }
    }
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        let result = failure ?? error
        if let result { continuation?.resume(throwing: result) }
        else { continuation?.resume() }
        continuation = nil
    }
}

public actor LocalModelStore {
    public let root: URL
    private let downloader: any LocalModelDownloading
    private var busy = false
    public init(root: URL, downloader: any LocalModelDownloading = HTTPSLocalModelDownloader()) {
        self.root = root; self.downloader = downloader
    }
    public static var defaultRoot: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("BabbelStream/Models", isDirectory: true)
    }
    public func directory(_ manifest: LocalModelManifest) -> URL {
        root.appendingPathComponent(manifest.id.rawValue + "-" + manifest.revision, isDirectory: true)
    }
    private func ensureDirectory(_ url: URL) throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true,
                                               attributes: [.posixPermissions: 0o700])
        guard try url.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink != true else {
            throw LocalModelError.integrityFailed
        }
    }
    public func hasFiles(_ manifest: LocalModelManifest) -> Bool {
        FileManager.default.fileExists(atPath: directory(manifest).path)
    }
    public func isInstalled(_ manifest: LocalModelManifest) -> Bool {
        let dir = directory(manifest)
        guard (try? Data(contentsOf: dir.appendingPathComponent(".ready"))) == Data(manifest.revision.utf8) else { return false }
        return manifest.files.allSatisfy { file in
            guard let values = try? dir.appendingPathComponent(file.path).resourceValues(
                forKeys: [.isRegularFileKey, .isSymbolicLinkKey, .fileSizeKey]) else { return false }
            return values.isRegularFile == true && values.isSymbolicLink != true && Int64(values.fileSize ?? -1) == file.bytes
        }
    }
    public func verify(_ manifest: LocalModelManifest, at directory: URL) throws {
        try manifest.validate()
        for file in manifest.files {
            try Task.checkCancellation()
            var ancestor = directory
            for component in file.path.split(separator: "/") {
                ancestor.appendPathComponent(String(component))
                guard try ancestor.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink != true else {
                    throw LocalModelError.integrityFailed
                }
            }
            let url = directory.appendingPathComponent(file.path)
            let values = try url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
            guard values.isRegularFile == true, Int64(values.fileSize ?? -1) == file.bytes else {
                throw LocalModelError.integrityFailed
            }
            let handle = try FileHandle(forReadingFrom: url)
            defer { try? handle.close() }
            var hash = SHA256()
            while let data = try handle.read(upToCount: 1_048_576), !data.isEmpty {
                try Task.checkCancellation(); hash.update(data: data)
            }
            guard hash.finalize().map({ String(format: "%02x", $0) }).joined() == file.sha256 else {
                throw LocalModelError.integrityFailed
            }
        }
    }
    public func install(_ manifest: LocalModelManifest,
                        progress: @escaping @Sendable (Double) -> Void,
                        prepare: @escaping @Sendable (URL) async throws -> Void) async throws {
        guard !busy else { throw LocalModelError.busy }
        busy = true; defer { busy = false }
        try manifest.validate()
        try ensureDirectory(root)
        guard !FileManager.default.fileExists(atPath: directory(manifest).path) else { throw LocalModelError.busy }
        // Recover only our UUID-named incomplete staging directories, on the next
        // explicit setup action. Never enumerate or delete other app/user data.
        for url in try FileManager.default.contentsOfDirectory(at: root, includingPropertiesForKeys: nil) {
            let name = url.lastPathComponent
            if name.hasPrefix(".staging-"), UUID(uuidString: String(name.dropFirst(9))) != nil {
                do { try FileManager.default.removeItem(at: url) }
                catch { throw LocalModelError.stagingCleanupFailed }
            }
        }
        let values = try root.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
        if let available = values.volumeAvailableCapacityForImportantUsage,
           available < manifest.bytes * 2 + 536_870_912 { throw LocalModelError.insufficientStorage }
        let stage = root.appendingPathComponent(".staging-" + UUID().uuidString, isDirectory: true)
        try ensureDirectory(stage)
        do {
            var completed: Int64 = 0
            for file in manifest.files {
                try Task.checkCancellation()
                let target = stage.appendingPathComponent(file.path)
                try ensureDirectory(target.deletingLastPathComponent())
                let previous = completed, total = max(1, manifest.bytes)
                try await downloader.download(manifest.downloadURL(for: file), to: target, expectedBytes: file.bytes) { bytes in
                    progress(Double(previous + bytes) / Double(total))
                }
                try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: target.path)
                completed += file.bytes
            }
            try verify(manifest, at: stage)
            try Task.checkCancellation()
            // Prepare before activation. SDK-generated tokenizer/cache files stay here.
            try await prepare(stage)
            try Task.checkCancellation()
            try Data(manifest.revision.utf8).write(to: stage.appendingPathComponent(".ready"), options: .atomic)
            let final = directory(manifest)
            // An installed version is never overwritten. Explicit removal precedes repair.
            guard !FileManager.default.fileExists(atPath: final.path) else { throw LocalModelError.busy }
            try FileManager.default.moveItem(at: stage, to: final)
        } catch {
            let operationError = error
            if FileManager.default.fileExists(atPath: stage.path) {
                do { try FileManager.default.removeItem(at: stage) }
                catch { throw LocalModelError.stagingCleanupFailed }
            }
            throw operationError
        }
    }
    public func remove(_ manifest: LocalModelManifest) throws {
        guard !busy else { throw LocalModelError.busy }
        let target = directory(manifest)
        guard FileManager.default.fileExists(atPath: target.path) else { return }
        guard try root.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink != true,
              try target.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink != true else {
            throw LocalModelError.integrityFailed
        }
        try FileManager.default.removeItem(at: target)
    }
}
