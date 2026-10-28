import Foundation
import Darwin
import FluidAudio
#if BABBELSTREAM_MLX
import MLXAudioCore
import MLXAudioSTT
#endif

// One request per process. Redirect every library print/log away from the private
// result pipe. Errors cross the boundary as reviewed categories only.
struct Request: Decodable {
    let model: String
    let directory: String
    let audio: String?
    let language: String
}
struct Response: Encodable { let text: String?; let error: String? }

@main
struct LocalSpeechMain {
    static func main() async {
        let resultFD = dup(STDOUT_FILENO)
        let sink = open("/dev/null", O_WRONLY)
        dup2(sink, STDOUT_FILENO)
        dup2(sink, STDERR_FILENO)
        close(sink)
        let output = FileHandle(fileDescriptor: resultFD, closeOnDealloc: true)
        let response: Response
        do {
            let data = FileHandle.standardInput.readDataToEndOfFile()
            guard data.count <= 32_768 else { throw RuntimeFailure.invalidRequest }
            let request = try JSONDecoder().decode(Request.self, from: data)
            let directory = URL(fileURLWithPath: request.directory, isDirectory: true)
            let text: String
            switch request.model {
            case "parakeetUltra":
                // This exact-directory API never resolves a repository or downloads.
                ModelHub.offlineMode = true
                let models = try AsrModels.loadLocal(from: directory, version: .ultra)
                if let audio = request.audio {
                    let manager = AsrManager(config: .default)
                    try await manager.loadModels(models)
                    var decoder = try TdtDecoderState()
                    text = try await manager.transcribe(URL(fileURLWithPath: audio), decoderState: &decoder).text
                } else { text = "" }
            #if BABBELSTREAM_MLX
            case "qwen3ASR":
                let model = try await Qwen3ASRModel.fromModelDirectory(directory)
                if let audio = request.audio {
                    let (_, samples) = try loadAudioArray(from: URL(fileURLWithPath: audio), sampleRate: 16_000)
                    text = model.generate(audio: samples, maxTokens: 4096,
                        language: request.language.isEmpty ? nil : request.language,
                        chunkDuration: 30).text
                } else { text = "" }
            case "graniteSpeech":
                let model = try await GraniteSpeechModel.fromModelDirectory(directory)
                if let audio = request.audio {
                    let (_, samples) = try loadAudioArray(from: URL(fileURLWithPath: audio), sampleRate: 16_000)
                    // Bound encoder memory; retain the entire recording via chunks.
                    var parts: [String] = []
                    for offset in stride(from: 0, to: samples.dim(0), by: 30 * 16_000) {
                        let end = min(samples.dim(0), offset + 30 * 16_000)
                        parts.append(model.generate(audio: samples[offset..<end], maxTokens: 2048,
                            sourceLanguage: request.language.isEmpty ? nil : request.language,
                            punctuate: true).text)
                    }
                    text = parts.joined(separator: " ")
                } else { text = "" }
            #endif
            default: throw RuntimeFailure.unsupportedModel
            }
            response = Response(text: text, error: nil)
        } catch {
            response = Response(text: nil, error: "localInferenceFailed")
        }
        if let bytes = try? JSONEncoder().encode(response) { try? output.write(contentsOf: bytes) }
    }
    enum RuntimeFailure: Error { case invalidRequest, unsupportedModel }
}
