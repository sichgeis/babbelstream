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
        var query = baseQuery()
        let attributes = [kSecValueData as String: data]
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)

        if status == errSecSuccess {
            return
        }
        if status != errSecItemNotFound {
            throw SecretStoreError.keychainError(status)
        }

        query[kSecValueData as String] = data
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
