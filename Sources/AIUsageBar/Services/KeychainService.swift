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

protocol CredentialProvider: Sendable {
    func getCredentials() throws -> Credentials
    func getAccessToken() throws -> String
    func clearCache()
}

final class KeychainService: CredentialProvider, @unchecked Sendable {
    static let shared = KeychainService()

    private let service = "Claude Code-credentials"
    private var cachedCredentials: Credentials?

    private init() {}

    func getCredentials() throws -> Credentials {
        // Return cached credentials if available
        if let cached = cachedCredentials {
            #if DEBUG
            print("[KeychainService] Using cached credentials")
            #endif
            return cached
        }

        #if DEBUG
        print("[KeychainService] Querying keychain for service: '\(service)'")
        #endif

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
                #if DEBUG
                print("[KeychainService] ERROR: Credentials not found in keychain")
                #endif
                throw KeychainError.itemNotFound
            }
            #if DEBUG
            print("[KeychainService] ERROR: Keychain status \(status)")
            #endif
            throw KeychainError.unexpectedStatus(status)
        }

        guard let data = result as? Data else {
            #if DEBUG
            print("[KeychainService] ERROR: Result is not Data")
            #endif
            throw KeychainError.invalidData
        }

        #if DEBUG
        if let rawString = String(data: data, encoding: .utf8) {
            print("[KeychainService] Raw keychain data (\(data.count) bytes):\n\(rawString)")
        }
        #endif

        do {
            let credentials = try JSONDecoder().decode(Credentials.self, from: data)
            #if DEBUG
            print("[KeychainService] Successfully decoded credentials")
            print("[KeychainService] Token prefix: \(String(credentials.claudeAiOauth.accessToken.prefix(10)))...")
            print("[KeychainService] Subscription type: \(credentials.claudeAiOauth.subscriptionType ?? "nil")")
            #endif
            cachedCredentials = credentials  // Cache for future use
            return credentials
        } catch {
            #if DEBUG
            print("[KeychainService] DECODING ERROR: \(error)")
            #endif
            throw KeychainError.decodingError(error)
        }
    }

    func getAccessToken() throws -> String {
        let credentials = try getCredentials()
        return credentials.claudeAiOauth.accessToken
    }

    func clearCache() {
        cachedCredentials = nil
    }
}
