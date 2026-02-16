import Foundation

/// A feature request / feedback item.
public struct FeedbackRequest: Identifiable, Codable, Sendable {
    public let id: UUID
    public let title: String
    public let description: String?
    public let email: String?
    public let status: Status
    public let voteCount: Int
    public let deviceId: String?
    public let createdAt: Date

    public enum Status: String, Codable, Sendable, CaseIterable {
        case pending
        case inReview = "in_review"
        case planned
        case inProgress = "in_progress"
        case completed
    }

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case description
        case email
        case status
        case voteCount = "vote_count"
        case deviceId = "device_id"
        case createdAt = "created_at"
    }
}

/// Payload for creating a new feedback request.
struct CreateFeedbackPayload: Encodable {
    let title: String
    let description: String?
    let email: String?
    let deviceId: String

    enum CodingKeys: String, CodingKey {
        case title
        case description
        case email
        case deviceId = "device_id"
    }
}

/// Payload for the toggle_vote RPC call.
struct ToggleVotePayload: Encodable {
    let pRequestId: UUID
    let pDeviceId: String

    enum CodingKeys: String, CodingKey {
        case pRequestId = "p_request_id"
        case pDeviceId = "p_device_id"
    }
}

/// Response from toggle_vote RPC.
struct ToggleVoteResponse: Decodable {
    let voted: Bool
}

/// A vote record (for fetching user's votes).
struct FeedbackVote: Decodable {
    let requestId: UUID

    enum CodingKeys: String, CodingKey {
        case requestId = "request_id"
    }
}

/// A comment on a feedback request.
public struct FeedbackComment: Identifiable, Codable, Sendable {
    public let id: UUID
    public let requestId: UUID
    public let body: String
    public let deviceId: String
    public let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case requestId = "request_id"
        case body
        case deviceId = "device_id"
        case createdAt = "created_at"
    }
}

/// Payload for creating a comment.
struct CreateCommentPayload: Encodable {
    let requestId: UUID
    let body: String
    let deviceId: String

    enum CodingKeys: String, CodingKey {
        case requestId = "request_id"
        case body
        case deviceId = "device_id"
    }
}
