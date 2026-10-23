import Darwin
import Foundation

public enum SingleInstanceError: Error {
    case alreadyRunning
    case unavailable
}

/// A per-user advisory lock held until process exit. Never unlink the locked file:
/// a second inode would let a later process acquire a different lock at the same path.
public final class SingleInstanceLock {
    private let descriptor: Int32

    public init(directory: URL) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: [.posixPermissions: 0o700])
        let path = directory.appendingPathComponent("instance.lock").path
        descriptor = Darwin.open(path, O_CREAT | O_RDWR | O_NOFOLLOW | O_CLOEXEC, mode_t(0o600))
        guard descriptor >= 0 else { throw SingleInstanceError.unavailable }
        guard flock(descriptor, LOCK_EX | LOCK_NB) == 0 else {
            let busy = errno == EWOULDBLOCK
            Darwin.close(descriptor)
            throw busy ? SingleInstanceError.alreadyRunning : SingleInstanceError.unavailable
        }
    }

    deinit { Darwin.close(descriptor) }
}
