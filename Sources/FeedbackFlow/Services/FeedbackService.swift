import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Network service for communicating with Supabase REST API.
final class FeedbackService: @unchecked Sendable {
    private let baseUrl: String
    private let anonKey: String
    private let session: URLSession

    init(baseUrl: String, anonKey: String) {
        self.baseUrl = baseUrl
        self.anonKey = anonKey
        self.session = URLSession.shared
    }

    // MARK: - Device ID

    private static let deviceIdKey = "feedbackflow_device_id"

    var deviceId: String {
        if let stored = UserDefaults.standard.string(forKey: Self.deviceIdKey) {
            return stored
        }
        #if canImport(UIKit)
        let id = UIDevice.current.identifierForVendor?.uuidString ?? UUID().uuidString
        #else
        let id = UUID().uuidString
        #endif
        UserDefaults.standard.set(id, forKey: Self.deviceIdKey)
        return id
    }

    // MARK: - JSON Coders

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)
            // Try ISO8601 with fractional seconds first
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: string) { return date }
            // Fallback without fractional seconds
            formatter.formatOptions = [.withInternetDateTime]
            if let date = formatter.date(from: string) { return date }
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date: \(string)")
        }
        return d
    }()

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        return e
    }()

    // MARK: - Fetch Approved Requests

    func fetchRequests() async throws -> [FeedbackRequest] {
        // Fetch non-pending requests, ordered by vote_count desc
        let urlString = "\(baseUrl)/rest/v1/feedback_requests?status=neq.pending&order=vote_count.desc,created_at.desc&select=*"
        guard let url = URL(string: urlString) else {
            throw FeedbackError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyHeaders(&request)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try Self.decoder.decode([FeedbackRequest].self, from: data)
    }

    // MARK: - Submit New Request

    func submitRequest(title: String, description: String?, email: String?) async throws {
        let urlString = "\(baseUrl)/rest/v1/feedback_requests"
        guard let url = URL(string: urlString) else {
            throw FeedbackError.invalidURL
        }

        let payload = CreateFeedbackPayload(
            title: title,
            description: description,
            email: email,
            deviceId: deviceId
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        applyHeaders(&request)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        request.httpBody = try Self.encoder.encode(payload)

        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }

    // MARK: - Toggle Vote (RPC)

    /// Returns `true` if the vote was added, `false` if removed.
    @discardableResult
    func toggleVote(requestId: UUID) async throws -> Bool {
        let urlString = "\(baseUrl)/rest/v1/rpc/toggle_vote"
        guard let url = URL(string: urlString) else {
            throw FeedbackError.invalidURL
        }

        let payload = ToggleVotePayload(pRequestId: requestId, pDeviceId: deviceId)

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        applyHeaders(&request)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try Self.encoder.encode(payload)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        let result = try Self.decoder.decode(ToggleVoteResponse.self, from: data)
        return result.voted
    }

    // MARK: - Fetch My Votes

    func fetchMyVotes() async throws -> Set<UUID> {
        let encoded = deviceId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? deviceId
        let urlString = "\(baseUrl)/rest/v1/feedback_votes?device_id=eq.\(encoded)&select=request_id"
        guard let url = URL(string: urlString) else {
            throw FeedbackError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyHeaders(&request)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        let votes = try Self.decoder.decode([FeedbackVote].self, from: data)
        return Set(votes.map(\.requestId))
    }

    // MARK: - Fetch Comments

    func fetchComments(requestId: UUID) async throws -> [FeedbackComment] {
        let urlString = "\(baseUrl)/rest/v1/feedback_comments?request_id=eq.\(requestId.uuidString)&order=created_at.asc&select=*"
        guard let url = URL(string: urlString) else {
            throw FeedbackError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        applyHeaders(&request)

        let (data, response) = try await session.data(for: request)
        try validateResponse(response)
        return try Self.decoder.decode([FeedbackComment].self, from: data)
    }

    // MARK: - Submit Comment

    func submitComment(requestId: UUID, body: String) async throws {
        let urlString = "\(baseUrl)/rest/v1/feedback_comments"
        guard let url = URL(string: urlString) else {
            throw FeedbackError.invalidURL
        }

        let payload = CreateCommentPayload(
            requestId: requestId,
            body: body,
            deviceId: deviceId
        )

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        applyHeaders(&request)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("return=minimal", forHTTPHeaderField: "Prefer")
        request.httpBody = try Self.encoder.encode(payload)

        let (_, response) = try await session.data(for: request)
        try validateResponse(response)
    }

    // MARK: - Helpers

    private func applyHeaders(_ request: inout URLRequest) {
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(anonKey)", forHTTPHeaderField: "Authorization")
    }

    private func validateResponse(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse else {
            throw FeedbackError.invalidResponse
        }
        guard (200...299).contains(http.statusCode) else {
            throw FeedbackError.httpError(http.statusCode)
        }
    }
}

// MARK: - Errors

enum FeedbackError: LocalizedError {
    case notConfigured
    case invalidURL
    case invalidResponse
    case httpError(Int)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "FeedbackFlow is not configured. Call FeedbackFlow.configure() first."
        case .invalidURL:
            return "Invalid URL."
        case .invalidResponse:
            return "Invalid server response."
        case .httpError(let code):
            return "Server error (\(code))."
        }
    }
}
