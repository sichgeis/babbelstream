import Foundation

public enum DictationRecoveryState: String, Codable, CaseIterable, Sendable {
    case processing
    case safeguardPending
    case transcriptionFailed
    case cleanupFailed
    case processingCanceled
    case interrupted
    case copyFailed

    public var displayName: String {
        switch self {
        case .processing: "Processing"
        case .safeguardPending: "Waiting for safe storage"
        case .transcriptionFailed: "Transcription failed"
        case .cleanupFailed: "Cleanup failed"
        case .processingCanceled: "Processing canceled"
        case .interrupted: "Processing interrupted"
        case .copyFailed: "Draft copy failed"
        }
    }
}

public struct DictationRecoveryRecording: Codable, Equatable, Identifiable, Sendable {
    public static let currentSchemaVersion = 1

    public var schemaVersion: Int
    public var id: UUID
    public var recordedAt: Date
    public var updatedAt: Date
    public var durationSeconds: TimeInterval
    public var byteCount: Int64
    public var targetApplicationName: String?
    public var targetBundleIdentifier: String?
    public var providerHost: String
    public var primaryModel: String
    public var cleanupModel: String?
    public var cleanupEnabled: Bool
    public var state: DictationRecoveryState
    public var failureCategory: String?
    public var retryCount: Int

    public init(
        schemaVersion: Int = currentSchemaVersion,
        id: UUID = UUID(),
        recordedAt: Date,
        updatedAt: Date = Date(),
        durationSeconds: TimeInterval,
        byteCount: Int64,
        targetApplicationName: String?,
        targetBundleIdentifier: String?,
        providerHost: String,
        primaryModel: String,
        cleanupModel: String?,
        cleanupEnabled: Bool,
        state: DictationRecoveryState = .processing,
        failureCategory: String? = nil,
        retryCount: Int = 0
    ) {
        self.schemaVersion = schemaVersion
        self.id = id
        self.recordedAt = recordedAt
        self.updatedAt = updatedAt
        self.durationSeconds = max(0, durationSeconds)
        self.byteCount = max(0, byteCount)
        self.targetApplicationName = targetApplicationName
        self.targetBundleIdentifier = targetBundleIdentifier
        self.providerHost = providerHost
        self.primaryModel = primaryModel
        self.cleanupModel = cleanupModel
        self.cleanupEnabled = cleanupEnabled
        self.state = state
        self.failureCategory = failureCategory
        self.retryCount = max(0, retryCount)
    }
}

public struct DictationRecoverySnapshot: Equatable, Sendable {
    public let recordings: [DictationRecoveryRecording]
    public let totalByteCount: Int64
    public let recoveredMetadataCount: Int
    public let storageWarning: String?

    public init(recordings: [DictationRecoveryRecording], recoveredMetadataCount: Int = 0, storageWarning: String? = nil) {
        self.storageWarning = storageWarning
        self.recordings = recordings.sorted { $0.recordedAt > $1.recordedAt }
        self.totalByteCount = recordings.reduce(0) { $0 + $1.byteCount }
        self.recoveredMetadataCount = max(0, recoveredMetadataCount)
    }
}

public enum DictationRecoveryError: Error, LocalizedError, Sendable {
    case recordingMissing
    case recordingAlreadyExists
    case itemNotFound
    case invalidExportDestination
    case fileOperationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .recordingMissing:
            "The recording file is no longer available."
        case .recordingAlreadyExists:
            "A recovery item already exists for this recording."
        case .itemNotFound:
            "The failed recording could not be found."
        case .invalidExportDestination:
            "Choose a different destination for the exported recording."
        case let .fileOperationFailed(message):
            "The failed recording could not be stored safely: \(message)"
        }
    }
}

public protocol DictationRecoveryStore: AnyObject {
    var recoveryDirectoryURL: URL { get }

    func adopt(
        _ recording: RecordedAudio,
        target: TextInsertionTarget?,
        settings: AppSettings
    ) throws -> DictationRecoveryRecording
    func prepareForRetry(_ recording: DictationRecoveryRecording) throws -> DictationRecoveryRecording
    func loadSnapshot(markProcessingAsInterrupted: Bool) throws -> DictationRecoverySnapshot
    func update(
        _ recording: DictationRecoveryRecording,
        state: DictationRecoveryState,
        failureCategory: String?,
        incrementRetryCount: Bool
    ) throws -> DictationRecoveryRecording
    func audioURL(for recording: DictationRecoveryRecording) throws -> URL
    func exportAudio(for recording: DictationRecoveryRecording, to destinationURL: URL) throws
    func delete(_ recording: DictationRecoveryRecording) throws
    func deleteAll() throws
}

public final class FileDictationRecoveryStore: DictationRecoveryStore {
    public let recoveryDirectoryURL: URL

    private let fileManager: FileManager
    private let temporaryDirectories: [URL]
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    private let audioFileName = "recording.m4a"
    private let metadataFileName = "metadata.json"

    public init(
        recoveryDirectoryURL: URL = DictationRecoveryPaths.defaultRecoveryDirectoryURL(),
        fileManager: FileManager = .default,
        temporaryDirectories: [URL] = AudioTempFileStore.recoverySearchDirectories()
    ) {
        self.temporaryDirectories = temporaryDirectories
        self.recoveryDirectoryURL = recoveryDirectoryURL
        self.fileManager = fileManager

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]
        self.encoder = encoder

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.decoder = decoder
    }

    public func adopt(
        _ recording: RecordedAudio,
        target: TextInsertionTarget?,
        settings: AppSettings
    ) throws -> DictationRecoveryRecording {
        guard fileManager.fileExists(atPath: recording.temporaryFileURL.path) else {
            throw DictationRecoveryError.recordingMissing
        }

        let source = try StoppedAudioOwnership.mark(recording, fileManager: fileManager)
        let configuration = settings.providerConfiguration
        let item = DictationRecoveryRecording(
            id: source.id,
            recordedAt: recording.createdAt,
            durationSeconds: recording.duration,
            byteCount: recording.byteCount,
            targetApplicationName: target?.localizedName,
            targetBundleIdentifier: target?.bundleIdentifier,
            providerHost: configuration.baseURL.host ?? "unknown",
            primaryModel: configuration.transcriptionModel,
            cleanupModel: settings.cleanupEnabled ? configuration.cleanupModel : nil,
            cleanupEnabled: settings.cleanupEnabled
        )
        return try finishAdoption(source, item: item)
    }

    public func prepareForRetry(_ recording: DictationRecoveryRecording) throws -> DictationRecoveryRecording {
        guard let source = try stoppedSources().first(where: { $0.id == recording.id }) else {
            _ = try audioURL(for: recording)
            return recording
        }
        return try finishAdoption(source, item: recording)
    }

    private func finishAdoption(
        _ source: StoppedAudioOwnership,
        item: DictationRecoveryRecording
    ) throws -> DictationRecoveryRecording {
        let directory = itemDirectoryURL(for: item.id)
        do {
            try prepareRecoveryRoot()
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
            try fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: directory.path)
            try excludeFromBackup(directory)
            let stagedAudioURL = directory.appendingPathComponent("recording.pending")
            let finalAudioURL = directory.appendingPathComponent(audioFileName)
            // A completed copy is authoritative. Reuse it after a failed source deletion.
            if !fileManager.fileExists(atPath: finalAudioURL.path) {
                if fileManager.fileExists(atPath: stagedAudioURL.path) {
                    try fileManager.removeItem(at: stagedAudioURL)
                }
                try fileManager.copyItem(at: source.audioURL, to: stagedAudioURL)
                try setUserOnlyPermissions(on: stagedAudioURL)
                try writeMetadata(item, in: directory)
                try fileManager.moveItem(at: stagedAudioURL, to: finalAudioURL)
            }
            // Do not start provider work until duplicate source ownership is settled.
            try fileManager.removeItem(at: source.audioURL)
            try fileManager.removeItem(at: StoppedAudioOwnership.markerURL(for: source.audioURL))
            return item
        } catch {
            // Keep the durable marker/source and any completed destination for retry.
            throw DictationRecoveryError.fileOperationFailed(error.localizedDescription)
        }
    }

    private func stoppedSources() throws -> [StoppedAudioOwnership] {
        try StoppedAudioOwnership.discover(in: temporaryDirectories, fileManager: fileManager)
    }

    public func loadSnapshot(markProcessingAsInterrupted: Bool = false) throws -> DictationRecoverySnapshot {
        let sources = try stoppedSources()
        var recordings: [DictationRecoveryRecording] = []
        var recoveredMetadataCount = 0
        var directories: [URL] = []
        var storageWarning: String?
        if fileManager.fileExists(atPath: recoveryDirectoryURL.path) {
            do {
                directories = try fileManager.contentsOfDirectory(
                    at: recoveryDirectoryURL,
                    includingPropertiesForKeys: [.isDirectoryKey, .contentModificationDateKey]
                )
            } catch {
                // Pending sources must remain actionable even if the destination is unavailable.
                storageWarning = "Recovery storage could not be read. Showing stopped sources still awaiting safe storage."
            }
        }

        for directory in directories {
            guard (try? directory.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true,
                  let id = UUID(uuidString: directory.lastPathComponent),
                  fileManager.fileExists(atPath: directory.appendingPathComponent(audioFileName).path)
            else {
                continue
            }

            var item: DictationRecoveryRecording
            do {
                item = try decoder.decode(
                    DictationRecoveryRecording.self,
                    from: Data(contentsOf: directory.appendingPathComponent(metadataFileName))
                )
            } catch {
                item = try recoveredItem(id: id, directory: directory)
                try? writeMetadata(item, in: directory)
                recoveredMetadataCount += 1
            }

            if markProcessingAsInterrupted, item.state == .processing {
                item.state = .interrupted
                item.failureCategory = "interrupted"
                try? writeMetadata(item, in: directory)
            }
            recordings.append(item)
        }

        for source in sources {
            if let index = recordings.firstIndex(where: { $0.id == source.id }) {
                recordings[index].state = .safeguardPending
            } else {
                let audio = try source.recordedAudio(fileManager: fileManager)
                recordings.append(DictationRecoveryRecording(
                    id: source.id, recordedAt: source.createdAt, durationSeconds: source.duration,
                    byteCount: audio.byteCount, targetApplicationName: nil, targetBundleIdentifier: nil,
                    providerHost: "unknown", primaryModel: "unknown", cleanupModel: nil,
                    cleanupEnabled: false, state: .safeguardPending
                ))
            }
        }

        return DictationRecoverySnapshot(
            recordings: recordings,
            recoveredMetadataCount: recoveredMetadataCount,
            storageWarning: storageWarning
        )
    }

    public func update(
        _ recording: DictationRecoveryRecording,
        state: DictationRecoveryState,
        failureCategory: String?,
        incrementRetryCount: Bool = false
    ) throws -> DictationRecoveryRecording {
        let directory = itemDirectoryURL(for: recording.id)
        guard fileManager.fileExists(atPath: directory.appendingPathComponent(audioFileName).path) else {
            throw DictationRecoveryError.itemNotFound
        }

        var updated = recording
        updated.updatedAt = Date()
        updated.state = state
        updated.failureCategory = failureCategory
        if incrementRetryCount {
            updated.retryCount += 1
        }
        try writeMetadata(updated, in: directory)
        return updated
    }

    public func audioURL(for recording: DictationRecoveryRecording) throws -> URL {
        let url = itemDirectoryURL(for: recording.id).appendingPathComponent(audioFileName)
        if fileManager.fileExists(atPath: url.path) { return url }
        if let source = try stoppedSources().first(where: { $0.id == recording.id }) {
            return source.audioURL
        }
        throw DictationRecoveryError.itemNotFound
    }

    public func exportAudio(for recording: DictationRecoveryRecording, to destinationURL: URL) throws {
        let sourceURL = try audioURL(for: recording)
        guard sourceURL.standardizedFileURL != destinationURL.standardizedFileURL else {
            throw DictationRecoveryError.invalidExportDestination
        }
        do {
            if fileManager.fileExists(atPath: destinationURL.path) {
                try fileManager.removeItem(at: destinationURL)
            }
            try fileManager.copyItem(at: sourceURL, to: destinationURL)
        } catch {
            throw DictationRecoveryError.fileOperationFailed(error.localizedDescription)
        }
    }

    public func delete(_ recording: DictationRecoveryRecording) throws {
        do {
            // Remove owned source first: a failure must leave the completed copy visible.
            for source in try stoppedSources() where source.id == recording.id {
                try fileManager.removeItem(at: source.audioURL)
                try fileManager.removeItem(at: StoppedAudioOwnership.markerURL(for: source.audioURL))
            }
            let directory = itemDirectoryURL(for: recording.id)
            if fileManager.fileExists(atPath: directory.path) {
                try fileManager.removeItem(at: directory)
            }
        } catch {
            throw DictationRecoveryError.fileOperationFailed(error.localizedDescription)
        }
    }

    public func deleteAll() throws {
        for recording in try loadSnapshot().recordings {
            try delete(recording)
        }
        if fileManager.fileExists(atPath: recoveryDirectoryURL.path) {
            try fileManager.removeItem(at: recoveryDirectoryURL)
        }
    }

    private func prepareRecoveryRoot() throws {
        try fileManager.createDirectory(
            at: recoveryDirectoryURL,
            withIntermediateDirectories: true,
            attributes: [.posixPermissions: 0o700]
        )
        try fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: recoveryDirectoryURL.path)
        try excludeFromBackup(recoveryDirectoryURL)
    }

    private func writeMetadata(_ item: DictationRecoveryRecording, in directory: URL) throws {
        let metadataURL = directory.appendingPathComponent(metadataFileName)
        try encoder.encode(item).write(to: metadataURL, options: .atomic)
        try setUserOnlyPermissions(on: metadataURL)
    }

    private func setUserOnlyPermissions(on url: URL) throws {
        try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
    }

    private func excludeFromBackup(_ url: URL) throws {
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var mutableURL = url
        try mutableURL.setResourceValues(values)
    }

    private func recoveredItem(id: UUID, directory: URL) throws -> DictationRecoveryRecording {
        let audioURL = directory.appendingPathComponent(audioFileName)
        let attributes = try fileManager.attributesOfItem(atPath: audioURL.path)
        let byteCount = (attributes[.size] as? NSNumber)?.int64Value ?? 0
        let date = attributes[.modificationDate] as? Date ?? Date()
        return DictationRecoveryRecording(
            id: id,
            recordedAt: date,
            durationSeconds: 0,
            byteCount: byteCount,
            targetApplicationName: nil,
            targetBundleIdentifier: nil,
            providerHost: "unknown",
            primaryModel: "unknown",
            cleanupModel: nil,
            cleanupEnabled: false,
            state: .interrupted,
            failureCategory: "metadata recovered"
        )
    }

    private func itemDirectoryURL(for id: UUID) -> URL {
        recoveryDirectoryURL.appendingPathComponent(id.uuidString, isDirectory: true)
    }
}

public enum DictationRecoveryPaths {
    public static func defaultRecoveryDirectoryURL(fileManager: FileManager = .default) -> URL {
        let applicationSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? fileManager.homeDirectoryForCurrentUser.appendingPathComponent("Library/Application Support")
        return applicationSupport
            .appendingPathComponent(ProjectDefaults.appName, isDirectory: true)
            .appendingPathComponent("Recovery", isDirectory: true)
    }
}
