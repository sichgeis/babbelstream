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

public enum DictationHUDPresentation {
    public static func providerAccent(personalOpenAIActive: Bool) -> DictationHUDProviderAccent {
        personalOpenAIActive ? .personalOpenAI : .standard
    }

    public static func phase(
        isRecording: Bool,
        isProcessing: Bool,
        canCancel: Bool,
        status: String,
        lastResult: String,
        hasError: Bool
    ) -> DictationHUDPhase {
        if isRecording {
            return .recording
        }

        if isProcessing || canCancel {
            switch status {
            case "Transcribing", "Max reached; transcribing":
                return .transcribing
            case "Trying Mini transcription":
                return .tryingMini
            case "Trying personal OpenAI":
                return .tryingPersonalOpenAI
            case "Retrying transcription":
                return .retrying
            case "Cleaning up":
                return .cleaningUp
            case "Pasting draft":
                return .pasting
            case "Canceling dictation":
                return .canceling
            default:
                return .processing
            }
        }

        if status == "Copy Last Draft" { return .draftAvailable }

        if status == "Copied" {
            return .copied
        }

        if status == "Recording saved"
            || lastResult.localizedCaseInsensitiveContains("Failed Recordings")
            || lastResult.localizedCaseInsensitiveContains("recording retained")
        {
            return .recordingSaved
        }

        if hasError || status.localizedCaseInsensitiveContains("failed") {
            return .error
        }

        if lastResult.localizedCaseInsensitiveContains("canceled") {
            return .canceled
        }

        if lastResult.localizedCaseInsensitiveContains("draft inserted")
            || lastResult.localizedCaseInsensitiveContains("paste shortcut")
        {
            return .pasted
        }

        return .done
    }
}
