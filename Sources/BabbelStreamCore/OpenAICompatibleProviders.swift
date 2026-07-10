import Foundation

public enum ProviderError: Error, Equatable, LocalizedError, Sendable {
    case missingAPIKey
    case invalidEndpointURL
    case emptyAudioFile
    case connectionTimedOut(seconds: Int)
    case requestFailed(statusCode: Int, message: String?)
    case malformedResponse
    case emptyTranscript
    case emptyCleanupOutput

    public var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            "Missing provider API key. Add it in Settings."
        case .invalidEndpointURL:
            "Provider endpoint URL is invalid."
        case .emptyAudioFile:
            "Recording file is empty."
        case let .connectionTimedOut(seconds):
            "Provider connection did not start sending within \(seconds) seconds."
        case let .requestFailed(statusCode, message):
            if let message {
                "Provider request failed with HTTP \(statusCode): \(message)"
            } else {
                "Provider request failed with HTTP \(statusCode)."
            }
        case .malformedResponse:
            "Provider response could not be parsed."
        case .emptyTranscript:
            "Transcription provider returned no text."
        case .emptyCleanupOutput:
            "Cleanup provider returned no text."
        }
    }
}

public struct TranscriptionRequest: Sendable {
    public let audioURL: URL
    public let settings: AppSettings
    public let apiKey: String
    public let onEvent: @Sendable (ProviderRequestEvent) async -> Void

    public init(
        audioURL: URL,
        settings: AppSettings,
        apiKey: String,
        onEvent: @escaping @Sendable (ProviderRequestEvent) async -> Void = { _ in }
    ) {
        self.audioURL = audioURL
        self.settings = settings
        self.apiKey = apiKey
        self.onEvent = onEvent
    }
}

public struct CleanupRequest: Sendable {
    public let transcript: String
    public let settings: AppSettings
    public let apiKey: String
    public let personalDictionary: PersonalDictionary

    public init(
        transcript: String,
        settings: AppSettings,
        apiKey: String,
        personalDictionary: PersonalDictionary = PersonalDictionary()
    ) {
        self.transcript = transcript
        self.settings = settings
        self.apiKey = apiKey
        self.personalDictionary = personalDictionary
    }
}

public protocol TranscriptionProvider: Sendable {
    func transcribe(_ request: TranscriptionRequest) async throws -> String
}

public protocol CleanupProvider: Sendable {
    func cleanup(_ request: CleanupRequest) async throws -> String
}

public enum ProviderRetryReason: Equatable, Sendable {
    case connectionTimeout
    case requestTimeout
    case networkUnavailable
    case httpStatus(Int)

    public var displayName: String {
        switch self {
        case .connectionTimeout:
            "connection timeout"
        case .requestTimeout:
            "request timeout"
        case .networkUnavailable:
            "network unavailable"
        case let .httpStatus(statusCode):
            "HTTP \(statusCode)"
        }
    }
}

public enum ProviderRequestEvent: Equatable, Sendable {
    case attemptStarted(attempt: Int, totalAttempts: Int)
    case retryScheduled(nextAttempt: Int, totalAttempts: Int, reason: ProviderRetryReason)
}

public enum ProviderRetryPolicy {
    public static let maximumRetryCount = 3

    public static func isCancellation(_ error: Error) -> Bool {
        if error is CancellationError {
            return true
        }

        return (error as? URLError)?.code == .cancelled
    }

    public static func shouldRetry(_ error: Error) -> Bool {
        if let providerError = error as? ProviderError {
            switch providerError {
            case .connectionTimedOut:
                return true
            case let .requestFailed(statusCode, _):
                return statusCode == 408
                    || statusCode == 425
                    || statusCode == 429
                    || (500...599).contains(statusCode)
            default:
                return false
            }
        }

        guard let urlError = error as? URLError else {
            return false
        }

        return [
            .timedOut,
            .cannotFindHost,
            .cannotConnectToHost,
            .networkConnectionLost,
            .dnsLookupFailed,
            .notConnectedToInternet,
            .resourceUnavailable
        ].contains(urlError.code)
    }

    public static func retryReason(for error: Error) -> ProviderRetryReason? {
        if let providerError = error as? ProviderError {
            switch providerError {
            case .connectionTimedOut:
                return .connectionTimeout
            case let .requestFailed(statusCode, _):
                return .httpStatus(statusCode)
            default:
                return nil
            }
        }

        guard let urlError = error as? URLError else {
            return nil
        }

        if urlError.code == .timedOut {
            return .requestTimeout
        }
        if shouldRetry(urlError) {
            return .networkUnavailable
        }
        return nil
    }
}

public final class OpenAICompatibleTranscriptionProvider: TranscriptionProvider {
    private let urlSession: URLSession
    private let connectionTimeoutSeconds: TimeInterval

    public init(
        urlSession: URLSession = .shared,
        connectionTimeoutSeconds: TimeInterval = ProjectDefaults.providerConnectionTimeoutSeconds
    ) {
        self.urlSession = urlSession
        self.connectionTimeoutSeconds = connectionTimeoutSeconds
    }

    public func transcribe(_ request: TranscriptionRequest) async throws -> String {
        let apiKey = request.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !apiKey.isEmpty else {
            throw ProviderError.missingAPIKey
        }

        let configuration = request.settings.providerConfiguration
        guard
            let endpoint = ProviderEndpointBuilder.endpointURL(
                baseURL: configuration.baseURL,
                path: configuration.transcriptionEndpointPath
            )
        else {
            throw ProviderError.invalidEndpointURL
        }

        let attributes = try FileManager.default.attributesOfItem(atPath: request.audioURL.path)
        let fileSize = (attributes[.size] as? NSNumber)?.intValue ?? 0
        guard fileSize > 0 else {
            throw ProviderError.emptyAudioFile
        }

        let fields = [
            "model": configuration.transcriptionModel,
            "response_format": request.settings.transcriptionResponseFormat,
            "language": TranscriptionLanguageNormalizer.apiValue(from: request.settings.transcriptionLanguage) ?? "",
            "prompt": request.settings.transcriptionPrompt
        ]
        let multipart = try MultipartFormDataBuilder.build(
            fields: fields,
            fileFieldName: "file",
            fileURL: request.audioURL
        )
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = configuration.timeoutSeconds
        urlRequest.httpBody = multipart.body
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue(multipart.contentType, forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json, text/plain;q=0.9, */*;q=0.1", forHTTPHeaderField: "Accept")

        return try await ProviderRequestExecutor.perform(
            retryCount: configuration.retryCount,
            onEvent: request.onEvent
        ) { [urlSession] in
            let (data, response) = try await ProviderURLSessionOperation.data(
                for: urlRequest,
                using: urlSession,
                connectionTimeoutSeconds: min(connectionTimeoutSeconds, configuration.timeoutSeconds)
            )
            try ProviderResponseValidator.validate(response, data: data)

            let text = try TranscriptionResponseParser.parse(data: data)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty else {
                throw ProviderError.emptyTranscript
            }

            return text
        }
    }
}

private enum ProviderRequestExecutor {
    static func perform<Value>(
        retryCount: Int,
        onEvent: @Sendable (ProviderRequestEvent) async -> Void,
        operation: () async throws -> Value
    ) async throws -> Value {
        let maximumRetries = min(max(0, retryCount), ProviderRetryPolicy.maximumRetryCount)
        var retriesPerformed = 0
        let totalAttempts = maximumRetries + 1

        while true {
            await onEvent(.attemptStarted(attempt: retriesPerformed + 1, totalAttempts: totalAttempts))
            do {
                try Task.checkCancellation()
                return try await operation()
            } catch {
                if ProviderRetryPolicy.isCancellation(error) {
                    throw CancellationError()
                }
                guard retriesPerformed < maximumRetries,
                      ProviderRetryPolicy.shouldRetry(error),
                      let retryReason = ProviderRetryPolicy.retryReason(for: error)
                else {
                    throw error
                }

                let delayNanoseconds = UInt64(350_000_000 * (1 << retriesPerformed))
                retriesPerformed += 1
                await onEvent(
                    .retryScheduled(
                        nextAttempt: retriesPerformed + 1,
                        totalAttempts: totalAttempts,
                        reason: retryReason
                    )
                )
                try await Task.sleep(nanoseconds: delayNanoseconds)
            }
        }
    }
}

public final class OpenAICompatibleCleanupProvider: CleanupProvider {
    private let urlSession: URLSession
    private let connectionTimeoutSeconds: TimeInterval

    public init(
        urlSession: URLSession = .shared,
        connectionTimeoutSeconds: TimeInterval = ProjectDefaults.providerConnectionTimeoutSeconds
    ) {
        self.urlSession = urlSession
        self.connectionTimeoutSeconds = connectionTimeoutSeconds
    }

    public func cleanup(_ request: CleanupRequest) async throws -> String {
        let apiKey = request.apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !apiKey.isEmpty else {
            throw ProviderError.missingAPIKey
        }

        let configuration = request.settings.providerConfiguration
        guard
            let endpoint = ProviderEndpointBuilder.endpointURL(
                baseURL: configuration.baseURL,
                path: configuration.cleanupEndpointPath
            )
        else {
            throw ProviderError.invalidEndpointURL
        }

        let payload: [String: Any] = [
            "model": configuration.cleanupModel,
            "temperature": 0,
            "messages": [
                [
                    "role": "system",
                    "content": DictionaryPromptBuilder.cleanupSystemPrompt(dictionary: request.personalDictionary)
                ],
                ["role": "user", "content": CleanupPrompt.userMessage(for: request.transcript)]
            ]
        ]

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = configuration.timeoutSeconds
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: payload)
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await ProviderURLSessionOperation.data(
            for: urlRequest,
            using: urlSession,
            connectionTimeoutSeconds: min(connectionTimeoutSeconds, configuration.timeoutSeconds)
        )
        try ProviderResponseValidator.validate(response, data: data)

        let text = try CleanupResponseParser.parse(data: data)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            throw ProviderError.emptyCleanupOutput
        }

        return text
    }
}

private final class ProviderURLSessionOperation: @unchecked Sendable {
    private let lock = NSLock()
    private var continuation: CheckedContinuation<(Data, URLResponse), Error>?
    private var dataTask: URLSessionDataTask?
    private var watchdogTask: Task<Void, Never>?
    private var isFinished = false
    private var isCancelled = false

    static func data(
        for request: URLRequest,
        using urlSession: URLSession,
        connectionTimeoutSeconds: TimeInterval
    ) async throws -> (Data, URLResponse) {
        let operation = ProviderURLSessionOperation()
        return try await operation.run(
            request: request,
            urlSession: urlSession,
            connectionTimeoutSeconds: connectionTimeoutSeconds
        )
    }

    private func run(
        request: URLRequest,
        urlSession: URLSession,
        connectionTimeoutSeconds: TimeInterval
    ) async throws -> (Data, URLResponse) {
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                lock.lock()
                guard !isCancelled else {
                    lock.unlock()
                    continuation.resume(throwing: CancellationError())
                    return
                }

                self.continuation = continuation
                let task = urlSession.dataTask(with: request) { [weak self] data, response, error in
                    self?.complete(data: data, response: response, error: error)
                }
                dataTask = task
                lock.unlock()

                task.resume()
                startConnectionWatchdog(seconds: connectionTimeoutSeconds)
            }
        } onCancel: {
            cancel()
        }
    }

    private func startConnectionWatchdog(seconds: TimeInterval) {
        guard seconds > 0 else {
            connectionTimeoutFired(seconds: seconds)
            return
        }

        let nanoseconds = UInt64(seconds * 1_000_000_000)
        let task = Task { [weak self] in
            try? await Task.sleep(nanoseconds: nanoseconds)
            guard !Task.isCancelled else {
                return
            }
            self?.connectionTimeoutFired(seconds: seconds)
        }

        lock.lock()
        if isFinished {
            lock.unlock()
            task.cancel()
            return
        }
        watchdogTask = task
        lock.unlock()
    }

    private func connectionTimeoutFired(seconds: TimeInterval) {
        lock.lock()
        guard !isFinished, let dataTask, dataTask.countOfBytesSent == 0 else {
            lock.unlock()
            return
        }

        isFinished = true
        let continuation = self.continuation
        self.continuation = nil
        watchdogTask = nil
        lock.unlock()

        dataTask.cancel()
        continuation?.resume(
            throwing: ProviderError.connectionTimedOut(seconds: max(1, Int(seconds.rounded(.up))))
        )
    }

    private func complete(data: Data?, response: URLResponse?, error: Error?) {
        lock.lock()
        guard !isFinished else {
            lock.unlock()
            return
        }

        isFinished = true
        let continuation = self.continuation
        self.continuation = nil
        let watchdogTask = self.watchdogTask
        self.watchdogTask = nil
        lock.unlock()

        watchdogTask?.cancel()
        if let error {
            continuation?.resume(throwing: error)
        } else if let data, let response {
            continuation?.resume(returning: (data, response))
        } else {
            continuation?.resume(throwing: URLError(.badServerResponse))
        }
    }

    private func cancel() {
        lock.lock()
        isCancelled = true
        guard !isFinished else {
            lock.unlock()
            return
        }

        isFinished = true
        let continuation = self.continuation
        self.continuation = nil
        let dataTask = self.dataTask
        let watchdogTask = self.watchdogTask
        self.watchdogTask = nil
        lock.unlock()

        watchdogTask?.cancel()
        dataTask?.cancel()
        continuation?.resume(throwing: CancellationError())
    }
}

public enum ProviderEndpointBuilder {
    public static func endpointURL(baseURL: URL, path: String) -> URL? {
        var base = baseURL.absoluteString.trimmingCharacters(in: .whitespacesAndNewlines)
        let endpointPath = path.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !base.isEmpty, !endpointPath.isEmpty else {
            return nil
        }

        while base.hasSuffix("/") {
            base.removeLast()
        }

        let normalizedPath = endpointPath.hasPrefix("/") ? endpointPath : "/\(endpointPath)"
        return URL(string: base + normalizedPath)
    }
}

public enum MultipartFormDataBuilder {
    public struct MultipartBody: Sendable {
        public let body: Data
        public let contentType: String
    }

    public static func build(
        fields: [String: String],
        fileFieldName: String,
        fileURL: URL,
        boundary: String = "----babbelstream-\(UUID().uuidString)"
    ) throws -> MultipartBody {
        var body = Data()

        for (name, value) in fields where !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            body.appendString("--\(boundary)\r\n")
            body.appendString("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n")
            body.appendString(value)
            body.appendString("\r\n")
        }

        body.appendString("--\(boundary)\r\n")
        body.appendString(
            "Content-Disposition: form-data; name=\"\(fileFieldName)\"; filename=\"\(fileURL.lastPathComponent)\"\r\n"
        )
        body.appendString("Content-Type: \(mimeType(for: fileURL))\r\n\r\n")
        body.append(try Data(contentsOf: fileURL))
        body.appendString("\r\n")
        body.appendString("--\(boundary)--\r\n")

        return MultipartBody(
            body: body,
            contentType: "multipart/form-data; boundary=\(boundary)"
        )
    }

    private static func mimeType(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "m4a":
            "audio/mp4"
        case "mp3":
            "audio/mpeg"
        case "wav":
            "audio/wav"
        case "webm":
            "audio/webm"
        case "flac":
            "audio/flac"
        default:
            "application/octet-stream"
        }
    }
}

public enum ProviderResponseValidator {
    public static func validate(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ProviderError.malformedResponse
        }
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw ProviderError.requestFailed(
                statusCode: httpResponse.statusCode,
                message: ProviderErrorMessageExtractor.message(from: data)
            )
        }
    }
}

public enum ProviderErrorMessageExtractor {
    public static func message(from data: Data) -> String? {
        guard !data.isEmpty else {
            return nil
        }

        if let object = try? JSONSerialization.jsonObject(with: data) {
            return sanitized(extractMessage(from: object))
        }

        return sanitized(String(data: data, encoding: .utf8))
    }

    private static func extractMessage(from object: Any) -> String? {
        if let dictionary = object as? [String: Any] {
            for key in ["error", "message", "detail", "error_description", "msg", "type", "code", "param"] {
                guard let value = dictionary[key] else {
                    continue
                }

                if let message = value as? String {
                    return message
                }

                if let message = extractMessage(from: value) {
                    return message
                }
            }
        }

        if let array = object as? [Any] {
            let messages = array.compactMap(extractMessage)
            return messages.isEmpty ? nil : messages.joined(separator: "; ")
        }

        return object as? String
    }

    private static func sanitized(_ message: String?) -> String? {
        guard let message else {
            return nil
        }

        let collapsed = message
            .replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !collapsed.isEmpty else {
            return nil
        }

        let limit = 300
        if collapsed.count > limit {
            return "\(collapsed.prefix(limit))..."
        }

        return collapsed
    }
}

public enum TranscriptionResponseParser {
    public static func parse(data: Data) throws -> String {
        if let object = try? JSONSerialization.jsonObject(with: data) {
            guard let dictionary = object as? [String: Any],
                  let text = dictionary["text"] as? String
            else {
                throw ProviderError.malformedResponse
            }

            return text
        }

        if let plainText = String(data: data, encoding: .utf8) {
            return plainText
        }

        throw ProviderError.malformedResponse
    }
}

public enum CleanupResponseParser {
    public static func parse(data: Data) throws -> String {
        guard
            let object = try JSONSerialization.jsonObject(with: data) as? [String: Any],
            let choices = object["choices"] as? [[String: Any]],
            let firstChoice = choices.first,
            let message = firstChoice["message"] as? [String: Any],
            let content = message["content"] as? String
        else {
            throw ProviderError.malformedResponse
        }

        return content
    }
}

private extension Data {
    mutating func appendString(_ string: String) {
        append(Data(string.utf8))
    }
}
