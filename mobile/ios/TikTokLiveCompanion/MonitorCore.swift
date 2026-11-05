import Foundation

struct MonitorConfiguration: Codable, Equatable {
    static let slotCount = 9
    var handles = Array(repeating: "", count: slotCount)
    var selectedSlots = [0, 1, 2, 3]
    var gridNine = false
    var autoSort = false
    var reverse = false
    var showLinks = false
    var skipOnline = false
    var enabled = true
    var intervalMinutes = 5
    var maxLinks = 5

    var isValid: Bool {
        handles.count == Self.slotCount && Set(handles.filter { !$0.isEmpty }).count == handles.filter { !$0.isEmpty }.count &&
        handles.allSatisfy { $0.isEmpty || $0.range(of: "^[a-z0-9._]{1,24}$", options: .regularExpression) != nil } &&
        selectedSlots.count == 4 && Set(selectedSlots).count == 4 && selectedSlots.allSatisfy { (0..<Self.slotCount).contains($0) } &&
        (1...60).contains(intervalMinutes) && (5...30).contains(maxLinks)
    }
    static func normalize(_ value: String) -> String {
        var result = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if result.hasPrefix("@") { result.removeFirst() }
        return result
    }
}

enum MonitorStatus: String, Codable { case unknown, checking, online, offline, error }
func nextMonitorSource(index: Int, count: Int, manual: Bool) -> Int? {
    precondition(count >= 0)
    guard count > 0 else { return nil }
    precondition((0..<count).contains(index))
    if index + 1 < count { return index + 1 }
    return manual ? 0 : nil
}
struct MonitorEntry: Equatable {
    var handle: String
    var status: MonitorStatus = .unknown
    var sources: [URL] = []
    var checkedAt: Date? = nil
}

func monitorGridSlots(_ config: MonitorConfiguration, _ rows: [MonitorEntry]) -> [Int] {
    precondition(rows.count == MonitorConfiguration.slotCount)
    let all = Array(0..<MonitorConfiguration.slotCount)
    let assigned = config.gridNine ? all : config.selectedSlots
    let candidates = config.autoSort && !config.gridNine ? assigned + all.filter { !assigned.contains($0) } : assigned
    let ordered = config.reverse ? Array(candidates.reversed()) : candidates
    let sorted = config.autoSort ? ordered.enumerated().sorted { a, b in
        let left = rows[a.element], right = rows[b.element]
        let lp = left.status == .online || (left.status == .checking && !left.sources.isEmpty)
        let rp = right.status == .online || (right.status == .checking && !right.sources.isEmpty)
        return lp == rp ? a.offset < b.offset : lp && !rp
    }.map(\.element) : ordered
    return Array(sorted.prefix(config.gridNine ? 9 : 4))
}

enum MonitorStoreError: Error { case invalidConfiguration }
struct MonitorStore {
    let defaults: UserDefaults
    private let key = "status-monitor.config"
    func load() -> MonitorConfiguration {
        guard let data = defaults.data(forKey: key), let config = try? JSONDecoder().decode(MonitorConfiguration.self, from: data), config.isValid else { return MonitorConfiguration() }
        return config
    }
    func save(_ config: MonitorConfiguration) throws {
        guard config.isValid else { throw MonitorStoreError.invalidConfiguration }
        let previous = load()
        for index in 0..<MonitorConfiguration.slotCount where previous.handles[index] != config.handles[index] {
            defaults.set(revision(index) + 1, forKey: "status-monitor.revision.\(index)")
            defaults.removeObject(forKey: "status-monitor.row.\(index)")
        }
        defaults.set(try JSONEncoder().encode(config), forKey: key)
    }
    func revision(_ index: Int) -> Int { defaults.integer(forKey: "status-monitor.revision.\(index)") }
    func loadRows(_ config: MonitorConfiguration) -> [MonitorEntry] {
        config.handles.enumerated().map { index, handle in
            let saved = defaults.dictionary(forKey: "status-monitor.row.\(index)")
            guard !handle.isEmpty, saved?["handle"] as? String == handle,
                  let value = saved?["status"] as? String, let status = MonitorStatus(rawValue: value),
                  let timestamp = saved?["checkedAt"] as? Double else { return MonitorEntry(handle: handle) }
            return MonitorEntry(handle: handle, status: status == .checking ? .unknown : status, checkedAt: Date(timeIntervalSince1970: timestamp))
        }
    }
    func saveStatus(_ entry: MonitorEntry, slot: Int, expectedRevision: Int) {
        guard (0..<MonitorConfiguration.slotCount).contains(slot), !entry.handle.isEmpty,
              revision(slot) == expectedRevision, load().handles[slot] == entry.handle, let checkedAt = entry.checkedAt else { return }
        let key = "status-monitor.row.\(slot)"
        if let existing = defaults.dictionary(forKey: key), existing["handle"] as? String == entry.handle,
           let old = existing["checkedAt"] as? Double, old > checkedAt.timeIntervalSince1970 { return }
        defaults.set(["handle": entry.handle, "status": entry.status.rawValue, "checkedAt": checkedAt.timeIntervalSince1970], forKey: key)
    }
}

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

struct MonitorProbe {
    private static let domains = ["tiktokcdn.com", "tiktokcdn-eu.com", "tiktokcdn-us.com", "tiktokcdn-in.com", "ttlivecdn.com"]
    static func usable(_ url: URL, now: Date = Date()) -> Bool {
        guard let parts = URLComponents(url: url, resolvingAgainstBaseURL: false), parts.scheme?.lowercased() == "https", parts.user == nil, parts.password == nil,
              let host = parts.host?.lowercased(), domains.contains(where: { host == $0 || host.hasSuffix("." + $0) }),
              parts.path.lowercased().contains(".m3u8") || parts.path.lowercased().contains(".flv") else { return false }
        let query = parts.queryItems ?? []
        if query.contains(where: { $0.name.lowercased() == "only_audio" && $0.value == "1" }) { return false }
        let mediaPath = parts.path + "?" + (parts.percentEncodedQuery ?? "")
        if mediaPath.range(of: "(?:^|[_-])audio(?:[_-]|\\.|$)", options: [.regularExpression, .caseInsensitive]) != nil { return false }
        if let expiry = query.first(where: { $0.name == "expire" })?.value.flatMap(Double.init), expiry <= now.timeIntervalSince1970 { return false }
        return true
    }
    static func parse(handle: String, html: String, maxLinks: Int, now: Date = Date()) -> MonitorEntry {
        let failure = MonitorEntry(handle: handle, status: .error, checkedAt: now)
        guard (5...30).contains(maxLinks),
              let regex = try? NSRegularExpression(pattern: "<script\\b[^>]*\\bid=[\\\"']SIGI_STATE[\\\"'][^>]*>([\\s\\S]*?)</script>", options: .caseInsensitive),
              let match = regex.firstMatch(in: html, range: NSRange(html.startIndex..., in: html)),
              let range = Range(match.range(at: 1), in: html), let data = String(html[range]).data(using: .utf8),
              let root = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any],
              let roomRoot = root["LiveRoom"] as? [String: Any], let info = roomRoot["liveRoomUserInfo"] as? [String: Any],
              let user = info["user"] as? [String: Any], let name = user["uniqueId"] as? String,
              MonitorConfiguration.normalize(name) == handle, let room = info["liveRoom"] as? [String: Any], let status = room["status"] as? Int else { return failure }
        if status == 4 { return MonitorEntry(handle: handle, status: .offline, checkedAt: now) }
        guard status == 2 else { return failure }
        var found = [URL](); var visited = 0
        func visit(_ item: Any, depth: Int) {
            guard depth <= 20, visited < 50000, found.count < maxLinks else { return }
            visited += 1
            if let dict = item as? [String: Any] { for value in dict.values { visit(value, depth: depth + 1) } }
            else if let array = item as? [Any] { for value in array { visit(value, depth: depth + 1) } }
            else if let string = item as? String {
                if let url = URL(string: string), usable(url, now: now), !found.contains(url) { found.append(url) }
                else if string.utf8.count <= 512 * 1024 {
                    if let data = string.data(using: .utf8), let embedded = try? JSONSerialization.jsonObject(with: data) {
                        visit(embedded, depth: depth + 1)
                    } else if let pattern = try? NSRegularExpression(pattern: "https://[^\\s\\\"'<>\\\\]+", options: .caseInsensitive) {
                        let full = NSRange(string.startIndex..., in: string)
                        for match in pattern.matches(in: string, range: full) where found.count < maxLinks {
                            guard let range = Range(match.range, in: string) else { continue }
                            let candidate = String(string[range]).trimmingCharacters(in: CharacterSet(charactersIn: "),;]}"))
                            if let url = URL(string: candidate), usable(url, now: now), !found.contains(url) { found.append(url) }
                        }
                    }
                }
            }
        }
        visit(room, depth: 0)
        return MonitorEntry(handle: handle, status: .online, sources: found, checkedAt: now)
    }
}

extension MonitorProbe {
    private static let anonymousSession: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.httpShouldSetCookies = false
        configuration.httpCookieStorage = nil
        configuration.urlCache = nil
        return URLSession(configuration: configuration)
    }()
    func check(handle: String, maxLinks: Int, session: URLSession? = nil) async -> MonitorEntry {
        let failure = MonitorEntry(handle: handle, status: .error, checkedAt: Date())
        guard MonitorConfiguration.normalize(handle) == handle,
              handle.range(of: "^[a-z0-9._]{1,24}$", options: .regularExpression) != nil,
              let url = URL(string: "https://www.tiktok.com/@\(handle)/live") else { return failure }
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 15)
        request.setValue("Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36", forHTTPHeaderField: "User-Agent")
        do {
            let (data, response) = try await (session ?? Self.anonymousSession).data(for: request)
            guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
                  data.count <= 2 * 1024 * 1024, let html = String(data: data, encoding: .utf8) else { return failure }
            return Self.parse(handle: handle, html: html, maxLinks: maxLinks)
        } catch { return failure }
    }
}
