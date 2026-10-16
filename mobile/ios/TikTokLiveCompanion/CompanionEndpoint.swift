import Foundation

enum CompanionEndpoint {
    struct Failure: LocalizedError {
        let message: String
        var errorDescription: String? { message }
    }
    static let local = "http://127.0.0.1:43117"

    static func normalize(_ value: String) throws -> String {
        let text = value.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let address = text.contains("://") ? text : "https://" + text
        guard let url = URLComponents(string: address), let host = url.host, !host.isEmpty,
              url.user == nil, url.password == nil, url.query == nil, url.fragment == nil, url.path.isEmpty,
              url.port == nil || (1...65535).contains(url.port!) else {
            throw Failure(message: "Alternative Companion-Adresse ist ungültig; Host und optional Port angeben.")
        }
        let loopback = ["localhost", "127.0.0.1", "::1", "[::1]"].contains(host.lowercased())
        guard url.scheme == "https" || (url.scheme == "http" && loopback) else {
            throw Failure(message: "Lokaler Dienst nicht erreichbar. Die alternative Adresse benötigt HTTPS mit gültigem Zertifikat.")
        }
        return address
    }

    static func select(_ configured: String, probe: (String) async throws -> Void) async throws -> String {
        for candidate in [local, "http://localhost:43117"] {
            do { try Task.checkCancellation(); try await probe(candidate); return candidate }
            catch is CancellationError { throw CancellationError() }
            catch { if Task.isCancelled { throw CancellationError() } }
        }
        guard !configured.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw Failure(message: "Kein lokaler Companion-Dienst auf diesem Gerät erreichbar. Alternative Dienstadresse und Kopplungscode eintragen; Systemstimmen bleiben verfügbar.")
        }
        let alternative = try normalize(configured)
        do { try Task.checkCancellation(); try await probe(alternative) }
        catch is CancellationError { throw CancellationError() }
        catch {
            if Task.isCancelled { throw CancellationError() }
            throw Failure(message: "Lokaler und alternativer Companion-Dienst nicht erreichbar: \(error.localizedDescription)")
        }
        return alternative
    }
}
