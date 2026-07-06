import Foundation

public struct UsageSnapshot: Codable, Equatable, Sendable {
    public var totalDictations: Int
    public var totalRecordedSeconds: TimeInterval
    public var cleanupRequests: Int
    public var transcriptionFailures: Int
    public var cleanupFallbacks: Int

    public init(
        totalDictations: Int = 0,
        totalRecordedSeconds: TimeInterval = 0,
        cleanupRequests: Int = 0,
        transcriptionFailures: Int = 0,
        cleanupFallbacks: Int = 0
    ) {
        self.totalDictations = totalDictations
        self.totalRecordedSeconds = totalRecordedSeconds
        self.cleanupRequests = cleanupRequests
        self.transcriptionFailures = transcriptionFailures
        self.cleanupFallbacks = cleanupFallbacks
    }

    public var totalRecordedMinutes: Double {
        totalRecordedSeconds / 60
    }

    public mutating func recordDictation(duration: TimeInterval) {
        totalDictations += 1
        totalRecordedSeconds += max(0, duration)
    }

    public mutating func recordCleanupRequest() {
        cleanupRequests += 1
    }

    public mutating func recordTranscriptionFailure() {
        transcriptionFailures += 1
    }

    public mutating func recordCleanupFallback() {
        cleanupFallbacks += 1
    }
}

public protocol UsageTracker: AnyObject {
    func load() -> UsageSnapshot
    func save(_ snapshot: UsageSnapshot)
    func reset()
}

public final class UserDefaultsUsageTracker: UsageTracker {
    private let userDefaults: UserDefaults
    private let key: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(
        userDefaults: UserDefaults = .standard,
        key: String = "usage.snapshot"
    ) {
        self.userDefaults = userDefaults
        self.key = key
    }

    public func load() -> UsageSnapshot {
        guard let data = userDefaults.data(forKey: key),
              let snapshot = try? decoder.decode(UsageSnapshot.self, from: data)
        else {
            return UsageSnapshot()
        }

        return snapshot
    }

    public func save(_ snapshot: UsageSnapshot) {
        guard let data = try? encoder.encode(snapshot) else {
            return
        }

        userDefaults.set(data, forKey: key)
    }

    public func reset() {
        userDefaults.removeObject(forKey: key)
    }
}

public enum PrivacyDiagnosticsBuilder {
    public static func redactSecrets(in text: String) -> String {
        var redacted = text
        let replacements = [
            (#"sk-[A-Za-z0-9_\-]{8,}"#, "[redacted-api-key]"),
            (#"Bearer\s+[A-Za-z0-9_\-\.]+"#, "Bearer [redacted]"),
            (#"(?i)(api[_ -]?key\s*[:=]\s*)\S+"#, "$1[redacted]")
        ]

        for (pattern, replacement) in replacements {
            redacted = redacted.replacingOccurrences(
                of: pattern,
                with: replacement,
                options: .regularExpression
            )
        }

        return redacted
    }
}
