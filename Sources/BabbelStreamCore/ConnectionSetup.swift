import Foundation

public enum ConnectionVerificationState: String, Sendable {
    case incomplete = "Setup incomplete"
    case unverified = "Key saved, unverified"
    case testing = "Testing saved transcription connection"
    case verified = "Transcription connection verified"
    case unavailable = "Temporarily unavailable"
}

public enum ConnectionPreset: String, Sendable {
    case custom
    case officialOpenAI

    /// Presets contain no credentials. Model selection remains explicit and unchanged.
    public var baseURL: String {
        switch self {
        case .custom: "https://provider.example.invalid"
        case .officialOpenAI: "https://api.openai.com"
        }
    }
}

public enum SyntheticConnectionAudio {
    /// 250 ms of silent mono 16-bit PCM at 16 kHz; no microphone or user content.
    public static func wavData() -> Data {
        let sampleRate: UInt32 = 16_000
        let byteCount: UInt32 = 8_000
        var data = Data("RIFF".utf8)
        func append<T: FixedWidthInteger>(_ value: T) {
            var littleEndian = value.littleEndian
            withUnsafeBytes(of: &littleEndian) { data.append(contentsOf: $0) }
        }
        append(UInt32(36) + byteCount)
        data.append(Data("WAVEfmt ".utf8))
        append(UInt32(16)); append(UInt16(1)); append(UInt16(1))
        append(sampleRate); append(sampleRate * 2); append(UInt16(2)); append(UInt16(16))
        data.append(Data("data".utf8)); append(byteCount)
        data.append(Data(repeating: 0, count: Int(byteCount)))
        return data
    }
}
