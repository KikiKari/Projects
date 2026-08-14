import Foundation

enum CompanionTab: String, CaseIterable, Identifiable {
    case live = "Live", chat = "Chat", song = "Song", player = "Player", more = "Mehr"
    var id: String { rawValue }
}

enum RecognitionSource: String, CaseIterable, Identifiable, Codable {
    case microphone = "Mikrofon"
    case webview = "WebView (experimentell)"
    var id: String { rawValue }
}

struct RecognitionResult: Equatable, Codable {
    let matched: Bool
    let title: String
    let artist: String
    let album: String?
    let artworkURL: URL?
    let songURL: URL?
    let matchOffset: Double?
    let source: RecognitionSource
    var safeSongURL: URL? { songURL?.scheme == "https" && songURL?.host?.isEmpty == false ? songURL : nil }
}

struct BridgeEnvelope: Decodable, Equatable {
    let version: Int
    let type: String
    let streamId: String
    let sequence: Int
    let timestamp: String
    let payload: [String: JSONValue]
}

struct MobileMediaLink: Equatable, Identifiable {
    let id = UUID()
    let url: URL
    let type: String
    let label: String
}

struct CaptionRecord: Equatable, Identifiable {
    let id = UUID()
    let timestamp: String
    let sentenceId: String
    let definite: Bool
    let language: String
    let text: String
    let raw: [String: Any]

    static func == (lhs: CaptionRecord, rhs: CaptionRecord) -> Bool {
        lhs.timestamp == rhs.timestamp && lhs.sentenceId == rhs.sentenceId && lhs.language == rhs.language && lhs.text == rhs.text
    }
}

struct RecommendationItem: Equatable, Identifiable {
    var id: String { handle.lowercased() }
    let handle: String
    let displayName: String
    let title: String
    let viewerCount: Int?
    let viewerLabel: String
    let url: URL
    let position: Int
}

struct ParticipantStats: Equatable {
    var messages = 0
    var words = 0
}

struct TopChatter: Identifiable, Equatable {
    var id: String { author.lowercased() }
    let author: String
    let messages: Int
    let words: Int
}

enum JSONValue: Decodable, Equatable {
    case string(String), number(Double), bool(Bool), object([String: JSONValue]), array([JSONValue]), null

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer()
        if value.decodeNil() { self = .null }
        else if let decoded = try? value.decode(Bool.self) { self = .bool(decoded) }
        else if let decoded = try? value.decode(Double.self) { self = .number(decoded) }
        else if let decoded = try? value.decode(String.self) { self = .string(decoded) }
        else if let decoded = try? value.decode([String: JSONValue].self) { self = .object(decoded) }
        else { self = .array(try value.decode([JSONValue].self)) }
    }

    var stringValue: String? { if case .string(let value) = self { return value }; return nil }
    var boolValue: Bool? { if case .bool(let value) = self { return value }; return nil }
    var numberValue: Double? { if case .number(let value) = self { return value }; return nil }
    var objectValue: [String: JSONValue]? { if case .object(let value) = self { return value }; return nil }
    var arrayValue: [JSONValue]? { if case .array(let value) = self { return value }; return nil }
    var foundationValue: Any {
        switch self {
        case .string(let value): return value
        case .number(let value): return value
        case .bool(let value): return value
        case .object(let value): return value.mapValues { $0.foundationValue }
        case .array(let value): return value.map { $0.foundationValue }
        case .null: return NSNull()
        }
    }
}

extension BridgeEnvelope {
    var rawObject: [String: Any] {
        ["version": version, "type": type, "streamId": streamId, "sequence": sequence, "timestamp": timestamp, "payload": payload.mapValues { $0.foundationValue }]
    }
}
