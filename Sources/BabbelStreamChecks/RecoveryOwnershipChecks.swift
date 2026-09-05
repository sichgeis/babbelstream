import Foundation
import BabbelStreamCore

final class RecoveryFaultFileManager: FileManager, @unchecked Sendable {
    var failCopy = false
    var failRemovalAt: URL?
    var failMetadataPermissions = false

    override func copyItem(at srcURL: URL, to dstURL: URL) throws {
        if failCopy { throw CocoaError(.fileWriteOutOfSpace) }
        try super.copyItem(at: srcURL, to: dstURL)
    }

    override func removeItem(at URL: URL) throws {
        if URL.standardizedFileURL.path == failRemovalAt?.standardizedFileURL.path { throw CocoaError(.fileWriteNoPermission) }
        try super.removeItem(at: URL)
    }

    override func setAttributes(_ attributes: [FileAttributeKey: Any], ofItemAtPath path: String) throws {
        if failMetadataPermissions && path.hasSuffix("metadata.json") {
            throw CocoaError(.fileWriteNoPermission)
        }
        try super.setAttributes(attributes, ofItemAtPath: path)
    }
}

func runRecoveryOwnershipChecks() throws {
    let fm = RecoveryFaultFileManager()
    let root = fm.temporaryDirectory.appendingPathComponent("BabbelStreamOwnershipChecks-\(UUID())")
    try fm.createDirectory(at: root, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
    defer { try? FileManager.default.removeItem(at: root) }
    let recovery = root.appendingPathComponent("Recovery")
    let source = root.appendingPathComponent("\(UUID()).m4a")
    let fixture = Data("synthetic-stopped-recording".utf8)
    try fixture.write(to: source)
    let audio = RecordedAudio(temporaryFileURL: source, duration: 5, byteCount: Int64(fixture.count), createdAt: Date(), deletedAt: nil)
    let ownership = try StoppedAudioOwnership.mark(audio, fileManager: fm)
    let marker = StoppedAudioOwnership.markerURL(for: source)
    let markerPermissions = try fm.attributesOfItem(atPath: marker.path)[.posixPermissions] as? NSNumber
    check(markerPermissions?.intValue == 0o600, "Stopped ownership metadata must be user-only.")
    let disposable = root.appendingPathComponent("\(UUID()).m4a")
    try Data("partial".utf8).write(to: disposable)
    let count = try AudioTempFileStore.deleteStaleTemporaryAudioFiles(in: root, fileManager: fm)
    check(count == 1 && fm.fileExists(atPath: source.path), "Stale cleanup must delete partial audio but retain marked stopped audio.")
    let store = FileDictationRecoveryStore(recoveryDirectoryURL: recovery, fileManager: fm, temporaryDirectories: [root])
    try Data("blocked storage root".utf8).write(to: recovery)
    let blockedSnapshot = try store.loadSnapshot()
    check(blockedSnapshot.recordings.count == 1 && blockedSnapshot.storageWarning != nil, "Unavailable recovery storage must not hide a pending source.")
    try fm.removeItem(at: recovery)
    fm.failCopy = true
    do {
        _ = try store.adopt(audio, target: nil, settings: AppSettings())
        check(false, "Injected copy failure must fail adoption.")
    } catch {}
    let restarted = FileDictationRecoveryStore(recoveryDirectoryURL: recovery, fileManager: fm, temporaryDirectories: [root])
    var snapshot = try restarted.loadSnapshot(markProcessingAsInterrupted: true)
    check(snapshot.recordings.count == 1 && snapshot.recordings.first?.id == ownership.id, "Restart must rediscover one stopped recording after copy failure.")
    check(snapshot.recordings.first?.state == .safeguardPending, "Unsafeguarded sources must require adoption before retry.")
    let exported = root.appendingPathComponent("export.m4a")
    fm.failCopy = false
    try restarted.exportAudio(for: snapshot.recordings[0], to: exported)
    check(tryData(exported) == fixture && fm.fileExists(atPath: source.path), "Pending audio can be exported without losing its source.")

    fm.failMetadataPermissions = true
    do {
        _ = try restarted.prepareForRetry(snapshot.recordings[0])
        check(false, "Metadata failure must stop adoption.")
    } catch {}
    check(fm.fileExists(atPath: source.path), "Metadata failure must retain original audio.")
    fm.failMetadataPermissions = false
    fm.failRemovalAt = source
    do {
        _ = try restarted.prepareForRetry(snapshot.recordings[0])
        check(false, "Source deletion failure must stop adoption before provider work.")
    } catch {}
    snapshot = try restarted.loadSnapshot(markProcessingAsInterrupted: true)
    check(snapshot.recordings.count == 1 && snapshot.recordings[0].id == ownership.id, "A completed destination and retained source must appear as one entry.")
    check(snapshot.recordings[0].state == .safeguardPending, "Duplicate source cleanup must finish before processing.")
    do {
        try restarted.delete(snapshot.recordings[0])
        check(false, "Failed deletion must not report success.")
    } catch {}
    let finalAudio = recovery.appendingPathComponent(ownership.id.uuidString).appendingPathComponent("recording.m4a")
    check(fm.fileExists(atPath: finalAudio.path), "Source-deletion failure must keep the completed copy.")
    fm.failRemovalAt = nil
    // Prove the existing completed copy is reused, rather than copied a second time.
    fm.failCopy = true
    let adopted = try restarted.prepareForRetry(snapshot.recordings[0])
    check(!fm.fileExists(atPath: source.path) && !fm.fileExists(atPath: marker.path), "Successful adoption must remove both source and marker.")
    check(tryData(finalAudio) == fixture, "Idempotent adoption must retain exact fixture bytes.")
    try restarted.delete(adopted)
    let deletedSnapshot = try restarted.loadSnapshot()
    check(deletedSnapshot.recordings.isEmpty, "Explicit deletion must remove all ownership for an item.")

    // A damaged marker is still recoverable from the UUID audio filename.
    try fixture.write(to: source)
    _ = try StoppedAudioOwnership.mark(audio, fileManager: fm)
    try Data("damaged".utf8).write(to: marker)
    snapshot = try restarted.loadSnapshot()
    check(snapshot.recordings.count == 1 && snapshot.recordings[0].id == ownership.id, "Damaged ownership metadata must not hide stopped audio.")
    try restarted.deleteAll()
    check(!fm.fileExists(atPath: source.path), "Delete All must include sources awaiting adoption.")
}

private func tryData(_ url: URL) -> Data? { try? Data(contentsOf: url) }
