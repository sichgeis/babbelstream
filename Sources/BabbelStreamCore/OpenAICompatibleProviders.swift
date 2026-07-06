import Foundation

public enum ProviderError: Error, Equatable, LocalizedError, Sendable {
    case missingAPIKey
    case invalidEndpointURL
    case emptyAudioFile
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

    public init(audioURL: URL, settings: AppSettings, apiKey: String) {
        self.audioURL = audioURL
        self.settings = settings
        self.apiKey = apiKey
    }
}

public struct CleanupRequest: Sendable {
    public let transcript: String
    public let settings: AppSettings
    public let apiKey: String

    public init(transcript: String, settings: AppSettings, apiKey: String) {
        self.transcript = transcript
        self.settings = settings
        self.apiKey = apiKey
    }
}

public protocol TranscriptionProvider: Sendable {
    func transcribe(_ request: TranscriptionRequest) async throws -> String
}

public protocol CleanupProvider: Sendable {
    func cleanup(_ request: CleanupRequest) async throws -> String
}

public final class OpenAICompatibleTranscriptionProvider: TranscriptionProvider {
    private let urlSession: URLSession

    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
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

        let (data, response) = try await urlSession.data(for: urlRequest)
        try ProviderResponseValidator.validate(response, data: data)

        let text = try TranscriptionResponseParser.parse(data: data)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            throw ProviderError.emptyTranscript
        }

        return text
    }
}

public final class OpenAICompatibleCleanupProvider: CleanupProvider {
    private let urlSession: URLSession

    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
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
                ["role": "system", "content": CleanupPrompt.slackReady],
                ["role": "user", "content": request.transcript]
            ]
        ]

        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.timeoutInterval = configuration.timeoutSeconds
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: payload)
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await urlSession.data(for: urlRequest)
        try ProviderResponseValidator.validate(response, data: data)

        let text = try CleanupResponseParser.parse(data: data)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            throw ProviderError.emptyCleanupOutput
        }

        return text
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
        if
            let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
            let text = object["text"] as? String
        {
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
