// Sources/AIUsageBar/Services/KeychainService.swift

import Foundation
import Security

enum KeychainError: Error, LocalizedError {
    case itemNotFound
    case invalidData
    case unexpectedStatus(OSStatus)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .itemNotFound:
            return "Claude Code credentials not found in Keychain. Please login via Claude Code CLI first."
        case .invalidData:
            return "Invalid credential data in Keychain"
        case .unexpectedStatus(let status):
            return "Keychain error: \(status)"
        case .decodingError(let error):
            return "Failed to decode credentials: \(error.localizedDescription)"
        }
    }
}

class KeychainService {
    static let shared = KeychainService()

    private let service = "Claude Code-credentials"

    private init() {}

    func getCredentials() throws -> Credentials {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unexpectedStatus(status)
        }

        guard let data = result as? Data else {
            throw KeychainError.invalidData
        }

        do {
            let credentials = try JSONDecoder().decode(Credentials.self, from: data)
            return credentials
        } catch {
            throw KeychainError.decodingError(error)
        }
    }

    func getAccessToken() throws -> String {
        let credentials = try getCredentials()
        return credentials.claudeAiOauth.accessToken
    }
}
