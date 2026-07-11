import Foundation

public enum TranscriptionModelRole: String, Equatable, Sendable {
    case primary
    case fallback
}

public struct HedgedTranscriptionResult: Equatable, Sendable {
    public let transcript: String
    public let winningRole: TranscriptionModelRole
    public let hedgeStarted: Bool

    public init(transcript: String, winningRole: TranscriptionModelRole, hedgeStarted: Bool) {
        self.transcript = transcript
        self.winningRole = winningRole
        self.hedgeStarted = hedgeStarted
    }
}

public enum HedgedTranscriptionError: Error, LocalizedError, Equatable, Sendable {
    case deadlineExceeded(seconds: Int)
    case attemptsFailed

    public var errorDescription: String? {
        switch self {
        case let .deadlineExceeded(seconds):
            "Transcription did not finish within the \(seconds)-second recovery deadline."
        case .attemptsFailed:
            "Both transcription models failed."
        }
    }
}

public enum HedgedTranscriptionRunner {
    private enum Event: @unchecked Sendable {
        case succeeded(TranscriptionModelRole, String)
        case failed(TranscriptionModelRole, Error)
        case hedgeDelayElapsed
        case deadlineElapsed
    }

    public static func run(
        hedgeDelaySeconds: TimeInterval = ProjectDefaults.transcriptionHedgeDelaySeconds,
        deadlineSeconds: TimeInterval = ProjectDefaults.transcriptionOverallTimeoutSeconds,
        shouldHedgeAfterError: @escaping @Sendable (Error) -> Bool,
        onHedgeStarted: @escaping @Sendable () async -> Void = {},
        primary: @escaping @Sendable () async throws -> String,
        fallback: @escaping @Sendable () async throws -> String
    ) async throws -> HedgedTranscriptionResult {
        try await withThrowingTaskGroup(of: Event.self) { group in
            group.addTask {
                do {
                    return .succeeded(.primary, try await primary())
                } catch {
                    return .failed(.primary, error)
                }
            }
            group.addTask {
                try await Task.sleep(nanoseconds: nanoseconds(for: hedgeDelaySeconds))
                return .hedgeDelayElapsed
            }
            group.addTask {
                try await Task.sleep(nanoseconds: nanoseconds(for: deadlineSeconds))
                return .deadlineElapsed
            }

            var hedgeStarted = false
            var primaryFinished = false
            var fallbackFinished = false
            var lastError: Error?

            func startFallback() async {
                guard !hedgeStarted else { return }
                hedgeStarted = true
                await onHedgeStarted()
                group.addTask {
                    do {
                        return .succeeded(.fallback, try await fallback())
                    } catch {
                        return .failed(.fallback, error)
                    }
                }
            }

            while let event = try await group.next() {
                try Task.checkCancellation()
                switch event {
                case let .succeeded(role, transcript):
                    group.cancelAll()
                    return HedgedTranscriptionResult(
                        transcript: transcript,
                        winningRole: role,
                        hedgeStarted: hedgeStarted
                    )
                case let .failed(.primary, error):
                    primaryFinished = true
                    lastError = error
                    if shouldHedgeAfterError(error) {
                        await startFallback()
                    } else {
                        group.cancelAll()
                        throw error
                    }
                case let .failed(.fallback, error):
                    fallbackFinished = true
                    lastError = error
                case .hedgeDelayElapsed:
                    if !primaryFinished {
                        await startFallback()
                    }
                case .deadlineElapsed:
                    group.cancelAll()
                    throw HedgedTranscriptionError.deadlineExceeded(
                        seconds: max(1, Int(deadlineSeconds.rounded(.up)))
                    )
                }

                if primaryFinished, hedgeStarted, fallbackFinished {
                    group.cancelAll()
                    throw lastError ?? HedgedTranscriptionError.attemptsFailed
                }
            }

            throw lastError ?? CancellationError()
        }
    }

    private static func nanoseconds(for seconds: TimeInterval) -> UInt64 {
        UInt64(max(0, seconds) * 1_000_000_000)
    }
}
