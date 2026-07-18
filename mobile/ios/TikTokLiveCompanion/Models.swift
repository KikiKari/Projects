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
}
