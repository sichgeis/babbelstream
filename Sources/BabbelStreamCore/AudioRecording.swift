import AVFoundation
import Foundation

@MainActor
public protocol AudioRecorder: AnyObject {
    var isRecording: Bool { get }

    func microphonePermissionStatus() -> MicrophonePermissionStatus
    func requestMicrophonePermission() async -> MicrophonePermissionStatus
    func start(maxDuration: TimeInterval) async throws
    func stop(deleteTemporaryFile: Bool) async throws -> RecordedAudio
    func cancel() async throws
}

public enum MicrophonePermissionStatus: String, Equatable, Sendable {
    case notDetermined
    case authorized
    case denied
    case restricted
    case unknown

    public var canRecord: Bool {
        self == .authorized
    }

    public var displayName: String {
        switch self {
        case .notDetermined:
            "Not requested"
        case .authorized:
            "Allowed"
        case .denied:
            "Denied"
        case .restricted:
            "Restricted"
        case .unknown:
            "Unknown"
        }
    }
}

public struct RecordedAudio: Equatable, Sendable {
    public let temporaryFileURL: URL
    public let duration: TimeInterval
    public let byteCount: Int64
    public let createdAt: Date
    public let deletedAt: Date?

    public init(
        temporaryFileURL: URL,
        duration: TimeInterval,
        byteCount: Int64,
        createdAt: Date,
        deletedAt: Date?
    ) {
        self.temporaryFileURL = temporaryFileURL
        self.duration = duration
        self.byteCount = byteCount
        self.createdAt = createdAt
        self.deletedAt = deletedAt
    }

    public var wasDeleted: Bool {
        deletedAt != nil
    }
}

public enum AudioRecordingError: Error, Equatable, LocalizedError, Sendable {
    case microphonePermissionDenied(MicrophonePermissionStatus)
    case alreadyRecording
    case notRecording
    case couldNotCreateTempDirectory(String)
    case couldNotStartRecording
    case missingRecordingFile(URL)
    case couldNotReadRecordingMetadata(String)
    case couldNotDeleteTemporaryFile(URL, String)

    public var errorDescription: String? {
        switch self {
        case let .microphonePermissionDenied(status):
            "Microphone permission is \(status.displayName.lowercased())."
        case .alreadyRecording:
            "A recording is already in progress."
        case .notRecording:
            "No recording is in progress."
        case let .couldNotCreateTempDirectory(message):
            "Could not create the temporary recording directory: \(message)"
        case .couldNotStartRecording:
            "Could not start recording."
        case let .missingRecordingFile(url):
            "The temporary recording file was not found at \(url.path)."
        case let .couldNotReadRecordingMetadata(message):
            "Could not read recording metadata: \(message)"
        case let .couldNotDeleteTemporaryFile(url, message):
            "Could not delete temporary recording at \(url.path): \(message)"
        }
    }
}

public enum AudioTempFileStore {
    public static func temporaryDirectory(fileManager: FileManager = .default) -> URL {
        fileManager.temporaryDirectory
            .appendingPathComponent(ProjectDefaults.audioTempDirectoryName, isDirectory: true)
    }

    public static func makeTemporaryAudioURL(
        id: UUID = UUID(),
        fileManager: FileManager = .default
    ) throws -> URL {
        let directory = temporaryDirectory(fileManager: fileManager)

        do {
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        } catch {
            throw AudioRecordingError.couldNotCreateTempDirectory(error.localizedDescription)
        }

        return directory
            .appendingPathComponent(id.uuidString)
            .appendingPathExtension(ProjectDefaults.audioFileExtension)
    }

    public static func deleteTemporaryAudio(
        at url: URL,
        fileManager: FileManager = .default
    ) throws -> Date {
        guard fileManager.fileExists(atPath: url.path) else {
            return Date()
        }

        do {
            try fileManager.removeItem(at: url)
            return Date()
        } catch {
            throw AudioRecordingError.couldNotDeleteTemporaryFile(url, error.localizedDescription)
        }
    }

    public static func isUnderSystemTemporaryDirectory(
        _ url: URL,
        fileManager: FileManager = .default
    ) -> Bool {
        let tempPath = fileManager.temporaryDirectory.standardizedFileURL.path
        let candidatePath = url.standardizedFileURL.path

        return candidatePath == tempPath || candidatePath.hasPrefix(tempPath + "/")
    }
}

@MainActor
public final class AVFoundationAudioRecorder: NSObject, AudioRecorder {
    private struct ActiveRecording {
        let recorder: AVAudioRecorder
        let fileURL: URL
        let createdAt: Date
        let maxDuration: TimeInterval
    }

    private var activeRecording: ActiveRecording?

    public var isRecording: Bool {
        activeRecording?.recorder.isRecording == true
    }

    public override init() {
        super.init()
    }

    public func microphonePermissionStatus() -> MicrophonePermissionStatus {
        Self.microphonePermissionStatus()
    }

    public func requestMicrophonePermission() async -> MicrophonePermissionStatus {
        let currentStatus = microphonePermissionStatus()

        guard currentStatus == .notDetermined else {
            return currentStatus
        }

        let granted = await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }

        return granted ? .authorized : .denied
    }

    public func start(maxDuration: TimeInterval = ProjectDefaults.maxAudioDurationSeconds) async throws {
        guard activeRecording == nil else {
            throw AudioRecordingError.alreadyRecording
        }

        let permissionStatus = microphonePermissionStatus()
        guard permissionStatus.canRecord else {
            throw AudioRecordingError.microphonePermissionDenied(permissionStatus)
        }

        let fileURL = try AudioTempFileStore.makeTemporaryAudioURL()
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44_100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue
        ]

        let recorder = try AVAudioRecorder(url: fileURL, settings: settings)
        recorder.prepareToRecord()

        guard recorder.record(forDuration: maxDuration) else {
            _ = try? AudioTempFileStore.deleteTemporaryAudio(at: fileURL)
            throw AudioRecordingError.couldNotStartRecording
        }

        activeRecording = ActiveRecording(
            recorder: recorder,
            fileURL: fileURL,
            createdAt: Date(),
            maxDuration: maxDuration
        )
    }

    public func stop(deleteTemporaryFile: Bool = true) async throws -> RecordedAudio {
        guard let recording = activeRecording else {
            throw AudioRecordingError.notRecording
        }

        activeRecording = nil

        let duration = min(recording.recorder.currentTime, recording.maxDuration)

        if recording.recorder.isRecording {
            recording.recorder.stop()
        }

        let byteCount: Int64
        do {
            byteCount = try recordingFileSize(at: recording.fileURL)
        } catch {
            _ = try? AudioTempFileStore.deleteTemporaryAudio(at: recording.fileURL)
            throw error
        }

        let deletedAt = deleteTemporaryFile
            ? try AudioTempFileStore.deleteTemporaryAudio(at: recording.fileURL)
            : nil

        return RecordedAudio(
            temporaryFileURL: recording.fileURL,
            duration: duration,
            byteCount: byteCount,
            createdAt: recording.createdAt,
            deletedAt: deletedAt
        )
    }

    public func cancel() async throws {
        guard let recording = activeRecording else {
            return
        }

        activeRecording = nil

        if recording.recorder.isRecording {
            recording.recorder.stop()
        }

        _ = try AudioTempFileStore.deleteTemporaryAudio(at: recording.fileURL)
    }

    private static func microphonePermissionStatus() -> MicrophonePermissionStatus {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .notDetermined:
            .notDetermined
        case .authorized:
            .authorized
        case .denied:
            .denied
        case .restricted:
            .restricted
        @unknown default:
            .unknown
        }
    }

    private func recordingFileSize(at url: URL) throws -> Int64 {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw AudioRecordingError.missingRecordingFile(url)
        }

        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            let fileSize = attributes[.size] as? NSNumber

            return fileSize?.int64Value ?? 0
        } catch {
            throw AudioRecordingError.couldNotReadRecordingMetadata(error.localizedDescription)
        }
    }
}
