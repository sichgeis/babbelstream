import BabbelStreamCore
import Foundation

func check(_ condition: @autoclosure () -> Bool, _ message: String) {
    guard condition() else {
        fatalError(message)
    }
}

let configuration = ProviderConfiguration()
let tempDirectory = AudioTempFileStore.temporaryDirectory()
let deterministicAudioURL = try AudioTempFileStore.makeTemporaryAudioURL(
    id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
)

check(ProjectDefaults.cleanupEnabledByDefault, "Cleanup should be enabled by default.")
check(!ProjectDefaults.autoSendEnabledByDefault, "MVP must not auto-send messages.")
check(!ProjectDefaults.transcriptHistoryEnabledByDefault, "MVP must not persist transcript history.")
check(!ProjectDefaults.debugPersistenceEnabledByDefault, "Debug persistence must be opt-in.")
check(ProjectDefaults.maxAudioDurationSeconds == 60, "MS1 max recording duration should remain 60 seconds.")
check(ProjectDefaults.audioFileExtension == "m4a", "MS1 should record m4a files.")
check(ProjectDefaults.defaultTranscriptionModel == "gpt-4o-transcribe", "Unexpected default STT model.")
check(ProjectDefaults.defaultCleanupModel == "gpt-4o-mini", "Unexpected default cleanup model.")
check(ProjectDefaults.defaultTranscriptionResponseFormat == "json", "Transcription should default to JSON responses.")
check(configuration.transcriptionEndpointPath == "/v1/audio/transcriptions", "Unexpected transcription endpoint default.")
check(configuration.cleanupEndpointPath == "/v1/chat/completions", "Unexpected cleanup endpoint default.")
check(configuration.transcriptionModel == ProjectDefaults.defaultTranscriptionModel, "Provider configuration should use the default STT model.")
check(configuration.cleanupModel == ProjectDefaults.defaultCleanupModel, "Provider configuration should use the default cleanup model.")
check(CleanupPrompt.slackReady.contains("German-English"), "Cleanup prompt must protect mixed-language dictation.")
check(CleanupPrompt.slackReady.contains("ticket IDs"), "Cleanup prompt must protect ticket IDs.")
check(
    ProviderEndpointBuilder.endpointURL(baseURL: configuration.baseURL, path: configuration.transcriptionEndpointPath)?
        .absoluteString == "https://litellm.example.local/v1/audio/transcriptions",
    "Provider endpoint builder should join base URL and paths predictably."
)
try AppSettingsValidator.validate(AppSettings())
check(
    AudioTempFileStore.isUnderSystemTemporaryDirectory(tempDirectory),
    "Audio temp directory should stay under the system temp directory."
)
check(
    AudioTempFileStore.isUnderSystemTemporaryDirectory(deterministicAudioURL),
    "Audio temp files should stay under the system temp directory."
)
check(
    deterministicAudioURL.pathExtension == ProjectDefaults.audioFileExtension,
    "Audio temp files should use the configured audio extension."
)

try Data("delete-check".utf8).write(to: deterministicAudioURL)
check(FileManager.default.fileExists(atPath: deterministicAudioURL.path), "Delete-check temp file should exist before deletion.")
let multipart = try MultipartFormDataBuilder.build(
    fields: [
        "model": configuration.transcriptionModel,
        "response_format": ProjectDefaults.defaultTranscriptionResponseFormat
    ],
    fileFieldName: "file",
    fileURL: deterministicAudioURL,
    boundary: "babbelstream-check-boundary"
)
check(multipart.contentType.contains("multipart/form-data"), "Multipart content type should be form-data.")
check(multipart.body.count > 0, "Multipart body should not be empty.")
_ = try AudioTempFileStore.deleteTemporaryAudio(at: deterministicAudioURL)
check(!FileManager.default.fileExists(atPath: deterministicAudioURL.path), "Delete-check temp file should be deleted.")
let retainedRecording = RecordedAudio(
    temporaryFileURL: deterministicAudioURL,
    duration: 1,
    byteCount: 12,
    createdAt: Date(),
    deletedAt: nil
)
check(!retainedRecording.wasDeleted, "Retained recordings should report that temp audio still needs cleanup.")

print("BabbelStream scaffold checks passed.")
