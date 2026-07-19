import Foundation

/// Normalisiert eine Streamnamen-Eingabe (mit oder ohne führendes "@") zu einer TikTok-LIVE-URL.
enum StreamNameNormalizer {
    private static let pattern = "^[a-z0-9._]{2,24}$"

    /// Liefert den bereinigten Nutzernamen ohne "@" oder nil bei ungültiger Eingabe.
    static func normalize(_ input: String) -> String? {
        var name = input.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if name.hasPrefix("@") { name.removeFirst() }
        guard name.range(of: pattern, options: .regularExpression) != nil else { return nil }
        return name
    }

    /// Liefert die vollständige LIVE-URL oder nil bei ungültiger Eingabe.
    static func liveURL(_ input: String) -> URL? {
        guard let name = normalize(input) else { return nil }
        return URL(string: "https://www.tiktok.com/@\(name)/live")
    }
}
