import BabbelStreamCore

enum LoginItemCheckError: Error {
    case denied
}

final class FakeSystemLoginItemService: SystemLoginItemService {
    var status: SystemLoginItemStatus
    var registrationError: Error?
    private(set) var registerCallCount = 0
    private(set) var unregisterCallCount = 0
    private(set) var openSettingsCallCount = 0

    init(status: SystemLoginItemStatus) {
        self.status = status
    }

    func register() throws {
        registerCallCount += 1
        if let registrationError {
            throw registrationError
        }
        status = .enabled
    }

    func unregister() throws {
        unregisterCallCount += 1
        status = .notRegistered
    }

    func openSystemSettings() {
        openSettingsCallCount += 1
    }
}
