import Foundation

public enum DictationHUDProviderAccent: Equatable, Sendable {
    case standard
    case personalOpenAI
}

public enum DictationHUDPhase: Equatable, Sendable {
    case recording
    case transcribing
    case tryingMini
    case tryingPersonalOpenAI
    case retrying
    case cleaningUp
    case pasting
    case canceling
    case processing
    case copied
    case draftAvailable
    case recordingSaved
    case error
    case canceled
    case pasted
    case done

    public var displayName: String {
        switch self {
        case .recording:
            "Recording"
        case .transcribing:
            "Transcribing"
        case .tryingMini:
            "Trying Mini"
        case .tryingPersonalOpenAI:
            "Personal OpenAI"
        case .retrying:
            "Retrying"
        case .cleaningUp:
            "Cleaning up"
        case .pasting:
            "Pasting"
        case .canceling:
            "Canceling"
        case .processing:
            "Processing"
        case .draftAvailable:
            "Copy Last Draft"
        case .copied:
            "Copied"
        case .recordingSaved:
            "Recording saved"
        case .error:
            "Error"
        case .canceled:
            "Canceled"
        case .pasted:
            "Pasted"
        case .done:
            "Done"
        }
    }
}

public enum DictationStatus: String, Sendable {
    case ready = "Ready"
    case preparing = "Preparing recording"
    case microphoneUnavailable = "Microphone unavailable"
    case canceling = "Canceling dictation"
    case cancelFailed = "Cancel failed"
    case invalidSettings = "Settings invalid"
    case personal = "Trying personal OpenAI"
    case mini = "Trying Mini transcription"
    case transcribing = "Transcribing"
    case retrying = "Retrying transcription"
    case recording = "Recording dictation"
    case test = "Recording test"
    case recordingFailed = "Recording failed"
    case stopFailed = "Stop failed"
    case dictationFailed = "Dictation failed"
    case draftAvailable = "Copy Last Draft"
    case cleanupFailed = "Cleanup failed"
    case saved = "Recording saved"
    case transcribingAtLimit = "Max reached; transcribing"
    case localTranscription = "Transcribing on this Mac"
    case localCleanup = "Cleaning up on this Mac"
    case cleanup = "Cleaning up"
    case retryingRecording = "Retrying saved recording"
    case copied = "Copied"
    case pasting = "Pasting draft"
    case pasteFailed = "Paste failed"
    case pasted, canceled, canceledAfterStop, failedAndRetained

    public var displayName: String {
        switch self {
        case .pasted, .canceled, .canceledAfterStop: "Ready"
        case .failedAndRetained: "Dictation failed"
        default: rawValue
        }
    }

    public var hudPhase: DictationHUDPhase {
        switch self {
        case .recording, .test: .recording
        case .preparing: .processing
        case .transcribing, .transcribingAtLimit, .localTranscription: .transcribing
        case .personal: .tryingPersonalOpenAI
        case .mini: .tryingMini
        case .retrying, .retryingRecording: .retrying
        case .cleanup, .localCleanup: .cleaningUp
        case .canceling: .canceling
        case .pasting: .pasting
        case .pasted: .pasted
        case .copied: .copied
        case .draftAvailable: .draftAvailable
        case .saved, .cleanupFailed, .canceledAfterStop, .failedAndRetained: .recordingSaved
        case .canceled: .canceled
        case .microphoneUnavailable, .invalidSettings, .recordingFailed, .stopFailed,
             .dictationFailed, .cancelFailed, .pasteFailed: .error
        case .ready: .done
        }
    }
}

public enum DictationHUDPresentation {
    public static func providerAccent(personalOpenAIActive: Bool) -> DictationHUDProviderAccent {
        personalOpenAIActive ? .personalOpenAI : .standard
    }
}

/// Completion timing belongs to the active-to-idle transition, not every notification.
public struct DictationHUDVisibilityPolicy: Sendable {
    public enum Action: Equatable, Sendable {
        case hide
        case showActive
        case beginCompletion(seconds: Double)
        case keepCompletion
    }
    private enum State { case idle, active, completing(attention: Bool) }
    private var state: State = .idle
    public init() {}

    public mutating func update(isActive: Bool, needsAttention: Bool) -> Action {
        if isActive {
            state = .active
            return .showActive
        }
        switch state {
        case .idle: return .hide
        case .active:
            state = .completing(attention: needsAttention)
            return .beginCompletion(seconds: needsAttention ? 6 : 1.5)
        case .completing(let hadAttention):
            if needsAttention && !hadAttention {
                state = .completing(attention: true)
                return .beginCompletion(seconds: 6)
            }
            return .keepCompletion
        }
    }

    public mutating func completionExpired() { state = .idle }
}
