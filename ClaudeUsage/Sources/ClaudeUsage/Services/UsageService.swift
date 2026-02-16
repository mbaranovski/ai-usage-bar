// Sources/ClaudeUsage/Services/UsageService.swift

import Foundation

enum UsageServiceError: Error, LocalizedError {
    case noToken
    case networkError(Error)
    case invalidResponse
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .noToken:
            return "No authentication token available"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let code):
            return "HTTP error: \(code)"
        }
    }
}

class UsageService {
    static let shared = UsageService()

    private let apiURL = URL(string: "https://api.anthropic.com/api/oauth/usage")!
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }

    func fetchUsage() async throws -> UsageResponse {
        // Get token from keychain
        let token = try KeychainService.shared.getAccessToken()

        var request = URLRequest(url: apiURL)
        request.httpMethod = "GET"
        request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("claude-code/2.0.32", forHTTPHeaderField: "User-Agent")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw UsageServiceError.invalidResponse
            }

            guard httpResponse.statusCode == 200 else {
                throw UsageServiceError.httpError(httpResponse.statusCode)
            }

            let usageResponse = try JSONDecoder().decode(UsageResponse.self, from: data)
            return usageResponse
        } catch let error as UsageServiceError {
            throw error
        } catch {
            throw UsageServiceError.networkError(error)
        }
    }
}
