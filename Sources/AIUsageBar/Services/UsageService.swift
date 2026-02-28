// Sources/AIUsageBar/Services/UsageService.swift

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

protocol UsageFetching: Sendable {
    func fetchUsage(token: String) async throws -> UsageResponse
}

final class UsageService: UsageFetching, @unchecked Sendable {
    static let shared = UsageService()

    private let apiURL: URL
    private let session: URLSession

    private init() {
        // Safe URL initialization - this is a compile-time constant URL that will always succeed
        guard let url = URL(string: "https://api.anthropic.com/api/oauth/usage") else {
            fatalError("Invalid API URL configuration")
        }
        self.apiURL = url

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)
    }


    func fetchUsage(token: String) async throws -> UsageResponse {
        var request = URLRequest(url: apiURL)
        request.httpMethod = "GET"
        request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("claude-code/2.0.32", forHTTPHeaderField: "User-Agent")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")

        #if DEBUG
        print("[UsageService] Fetching usage from: \(apiURL)")
        print("[UsageService] Token prefix: \(String(token.prefix(10)))...")
        #endif

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                print("[UsageService] ERROR: Response is not HTTPURLResponse")
                throw UsageServiceError.invalidResponse
            }

            #if DEBUG
            print("[UsageService] HTTP Status: \(httpResponse.statusCode)")
            print("[UsageService] Response headers: \(httpResponse.allHeaderFields)")
            if let bodyString = String(data: data, encoding: .utf8) {
                print("[UsageService] Response body (\(data.count) bytes):\n\(bodyString)")
            } else {
                print("[UsageService] Response body: \(data.count) bytes (not UTF-8)")
            }
            #endif

            guard httpResponse.statusCode == 200 else {
                throw UsageServiceError.httpError(httpResponse.statusCode)
            }

            do {
                let usageResponse = try JSONDecoder().decode(UsageResponse.self, from: data)
                #if DEBUG
                print("[UsageService] Successfully decoded UsageResponse")
                #endif
                return usageResponse
            } catch let decodingError {
                #if DEBUG
                print("[UsageService] DECODING ERROR: \(decodingError)")
                if let decodingError = decodingError as? DecodingError {
                    switch decodingError {
                    case .keyNotFound(let key, let context):
                        print("[UsageService]   Missing key: '\(key.stringValue)' at path: \(context.codingPath.map(\.stringValue).joined(separator: "."))")
                    case .typeMismatch(let type, let context):
                        print("[UsageService]   Type mismatch: expected \(type) at path: \(context.codingPath.map(\.stringValue).joined(separator: "."))")
                        print("[UsageService]   Debug description: \(context.debugDescription)")
                    case .valueNotFound(let type, let context):
                        print("[UsageService]   Value not found: expected \(type) at path: \(context.codingPath.map(\.stringValue).joined(separator: "."))")
                    case .dataCorrupted(let context):
                        print("[UsageService]   Data corrupted at path: \(context.codingPath.map(\.stringValue).joined(separator: "."))")
                        print("[UsageService]   Debug description: \(context.debugDescription)")
                    @unknown default:
                        print("[UsageService]   Unknown decoding error")
                    }
                }
                #endif
                throw UsageServiceError.networkError(decodingError)
            }
        } catch let error as UsageServiceError {
            throw error
        } catch {
            #if DEBUG
            print("[UsageService] NETWORK ERROR: \(error)")
            #endif
            throw UsageServiceError.networkError(error)
        }
    }
}
