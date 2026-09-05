import Foundation

/// Durable ownership of stopped audio still awaiting recovery-store adoption.
/// The source is derived from the marker's location, never from a stored path.
public struct StoppedAudioOwnership: Sendable {
    public let id: UUID
    public let audioURL: URL
    public let createdAt: Date
    public let duration: TimeInterval

    private struct Metadata: Codable {
        let id: UUID
        let createdAt: Date
        let duration: TimeInterval
    }

    public static func markerURL(for audioURL: URL) -> URL {
        audioURL.appendingPathExtension("stopped.json")
    }

    public static func mark(
        _ recording: RecordedAudio,
        fileManager: FileManager = .default
    ) throws -> StoppedAudioOwnership {
        let url = markerURL(for: recording.temporaryFileURL)
        if fileManager.fileExists(atPath: url.path) {
            try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: recording.temporaryFileURL.path)
            try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
            return try load(markerURL: url, fileManager: fileManager)
        }
        let metadata = Metadata(
            id: UUID(uuidString: recording.temporaryFileURL.deletingPathExtension().lastPathComponent) ?? UUID(),
            createdAt: recording.createdAt,
            duration: recording.duration
        )
        // Fail before relinquishing recorder ownership if privacy or marker setup fails.
        try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: recording.temporaryFileURL.path)
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        var audioURL = recording.temporaryFileURL
        try audioURL.setResourceValues(values)
        try JSONEncoder().encode(metadata).write(to: url, options: [.atomic])
        // The containing temp directory is user-only, including the atomic-write window.
        try fileManager.setAttributes([.posixPermissions: 0o600], ofItemAtPath: url.path)
        var marker = url
        try marker.setResourceValues(values)
        return StoppedAudioOwnership(id: metadata.id, audioURL: audioURL, createdAt: metadata.createdAt, duration: metadata.duration)
    }

    public static func load(markerURL: URL, fileManager: FileManager = .default) throws -> StoppedAudioOwnership {
        let audioURL = markerURL.deletingPathExtension().deletingPathExtension()
        let metadata: Metadata
        do {
            metadata = try JSONDecoder().decode(Metadata.self, from: Data(contentsOf: markerURL))
        } catch {
            // Production audio filenames are UUIDs, so damaged metadata retains identity.
            guard let id = UUID(uuidString: audioURL.deletingPathExtension().lastPathComponent) else { throw error }
            let attributes = try fileManager.attributesOfItem(atPath: audioURL.path)
            metadata = Metadata(id: id, createdAt: attributes[.creationDate] as? Date ?? Date(), duration: 0)
        }
        return StoppedAudioOwnership(id: metadata.id, audioURL: audioURL, createdAt: metadata.createdAt, duration: metadata.duration)
    }

    public static func discover(in directories: [URL], fileManager: FileManager = .default) throws -> [StoppedAudioOwnership] {
        var sources: [StoppedAudioOwnership] = []
        for directory in Set(directories) where fileManager.fileExists(atPath: directory.path) {
            for marker in try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
                where marker.lastPathComponent.hasSuffix(".m4a.stopped.json") {
                let audioURL = marker.deletingPathExtension().deletingPathExtension()
                guard fileManager.fileExists(atPath: audioURL.path) else {
                    // A crash after source removal may leave non-sensitive ownership metadata.
                    try? fileManager.removeItem(at: marker)
                    continue
                }
                sources.append(try load(markerURL: marker, fileManager: fileManager))
            }
        }
        return sources
    }

    public func recordedAudio(fileManager: FileManager = .default) throws -> RecordedAudio {
        let attributes = try fileManager.attributesOfItem(atPath: audioURL.path)
        return RecordedAudio(
            temporaryFileURL: audioURL, duration: duration,
            byteCount: (attributes[.size] as? NSNumber)?.int64Value ?? 0,
            createdAt: createdAt, deletedAt: nil
        )
    }
}
