import Foundation
import Security

public enum SecretStoreError: Error, Equatable, LocalizedError, Sendable {
    case keychainError(OSStatus)
    case invalidSecretData

    public var errorDescription: String? {
        switch self {
        case let .keychainError(status):
            "Keychain operation failed with status \(status)."
        case .invalidSecretData:
            "Stored API key could not be read."
        }
    }
}

public protocol SecretStore: AnyObject {
    func readAPIKey() throws -> String?
    func saveAPIKey(_ apiKey: String) throws
    func deleteAPIKey() throws
}

public protocol APIKeyPresenceStore: AnyObject {
    var hasSavedAPIKey: Bool { get set }
}

public final class UserDefaultsAPIKeyPresenceStore: APIKeyPresenceStore {
    private let userDefaults: UserDefaults
    private let key: String

    public init(
        userDefaults: UserDefaults = .standard,
        key: String = "provider.apiKey.saved"
    ) {
        self.userDefaults = userDefaults
        self.key = key
    }

    public var hasSavedAPIKey: Bool {
        get {
            userDefaults.bool(forKey: key)
        }
        set {
            userDefaults.set(newValue, forKey: key)
        }
    }
}

public final class KeychainSecretStore: SecretStore {
    private let service: String
    private let account: String

    public init(
        service: String = "com.sichgeis.babbelstream",
        account: String = "provider-api-key"
    ) {
        self.service = service
        self.account = account
    }

    public func readAPIKey() throws -> String? {
        var query = baseQuery()
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw SecretStoreError.keychainError(status)
        }
        guard
            let data = item as? Data,
            let value = String(data: data, encoding: .utf8)
        else {
            throw SecretStoreError.invalidSecretData
        }

        return value
    }

    public func saveAPIKey(_ apiKey: String) throws {
        let data = Data(apiKey.utf8)
        let attributes: [String: Any] = [
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        let updateStatus = SecItemUpdate(baseQuery() as CFDictionary, attributes as CFDictionary)

        if updateStatus == errSecSuccess {
            return
        }
        guard updateStatus == errSecItemNotFound else {
            throw SecretStoreError.keychainError(updateStatus)
        }

        try addAPIKey(data)
    }

    private func addAPIKey(_ data: Data) throws {
        var query = baseQuery()
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let addStatus = SecItemAdd(query as CFDictionary, nil)
        guard addStatus == errSecSuccess else {
            throw SecretStoreError.keychainError(addStatus)
        }
    }

    public func deleteAPIKey() throws {
        let status = SecItemDelete(baseQuery() as CFDictionary)

        if status == errSecSuccess || status == errSecItemNotFound {
            return
        }

        throw SecretStoreError.keychainError(status)
    }

    private func baseQuery() -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
