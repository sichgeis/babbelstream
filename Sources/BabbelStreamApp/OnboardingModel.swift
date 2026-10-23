import BabbelStreamCore
import Foundation
import Combine

struct OnboardingProgress: Codable, Equatable {
    var introductionDismissed = false
    var microphoneWasAllowed = false
    var pasteWasAllowed = false
}

@MainActor
protocol OnboardingProgressStore: AnyObject {
    func load() -> OnboardingProgress
    func save(_ progress: OnboardingProgress)
}

@MainActor
final class UserDefaultsOnboardingProgressStore: OnboardingProgressStore {
    private let defaults: UserDefaults
    private let key = "onboarding.progress.v1"
    init(defaults: UserDefaults = .standard) { self.defaults = defaults }
    func load() -> OnboardingProgress {
        guard let data = defaults.data(forKey: key),
              let progress = try? JSONDecoder().decode(OnboardingProgress.self, from: data)
        else { return OnboardingProgress() }
        return progress
    }
    func save(_ progress: OnboardingProgress) {
        if let data = try? JSONEncoder().encode(progress) { defaults.set(data, forKey: key) }
    }
}

enum OnboardingPresentation: Equatable {
    case introduction, permissionRepair, none
    static func resolve(progress: OnboardingProgress, microphoneAllowed: Bool, pasteAllowed: Bool) -> Self {
        if !progress.introductionDismissed { return .introduction }
        if (progress.microphoneWasAllowed && !microphoneAllowed) || (progress.pasteWasAllowed && !pasteAllowed) {
            return .permissionRepair
        }
        return .none
    }
}

@MainActor
final class OnboardingModel: ObservableObject {
    enum Step: Int, CaseIterable { case welcome, permissions, provider, pasteTest, ready }
    @Published var step: Step = .welcome
    @Published var repairOnly = false
    private(set) var progress: OnboardingProgress
    private let store: any OnboardingProgressStore
    let appState: AppState

    init(appState: AppState, store: any OnboardingProgressStore) {
        self.appState = appState
        self.store = store
        progress = store.load()
        refreshPermissions()
    }

    var launchPresentation: OnboardingPresentation {
        .resolve(progress: progress,
                 microphoneAllowed: appState.microphonePermissionStatus == .authorized,
                 pasteAllowed: appState.accessibilityPermissionStatus == .trusted)
    }

    func refreshPermissions() {
        appState.refreshPermissionStatuses()
        let previous = progress
        progress.microphoneWasAllowed = progress.microphoneWasAllowed || appState.microphonePermissionStatus == .authorized
        progress.pasteWasAllowed = progress.pasteWasAllowed || appState.accessibilityPermissionStatus == .trusted
        if progress != previous { store.save(progress) }
    }

    func dismiss() {
        progress.introductionDismissed = true
        store.save(progress)
    }
}
