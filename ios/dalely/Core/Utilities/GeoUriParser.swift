import Foundation

struct ParsedGeoLocation: Equatable {
    var latitude: Double
    var longitude: Double
    var label: String?
}

enum GeoUriParser {
    private static let coordRegex = try! NSRegularExpression(
        pattern: #"([+-]?\d{1,2}(?:\.\d+)?)\s*,\s*([+-]?\d{1,3}(?:\.\d+)?)"#
    )
    private static let atCoordRegex = try! NSRegularExpression(
        pattern: #"@([+-]?\d{1,2}(?:\.\d+)?)\s*,\s*([+-]?\d{1,3}(?:\.\d+)?)"#
    )
    private static let googleDataRegex = try! NSRegularExpression(
        pattern: #"!3d([+-]?\d{1,2}(?:\.\d+)?)(?:!4d|.*?!4d)([+-]?\d{1,3}(?:\.\d+)?)"#
    )
    private static let parenRegex = try! NSRegularExpression(pattern: #"\(([^)]+)\)"#)
    private static let embeddedURLRegex = try! NSRegularExpression(
        pattern: #"(https?://[^\s]+|geo:[^\s]+|feen:[^\s]+|dalely:[^\s]+)"#
    )
    private static let placePathRegex = try! NSRegularExpression(pattern: #"/(?:place|search)/([^/@?]+)"#)

    static func parse(_ raw: String?) -> ParsedGeoLocation? {
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let decoded = safeDecode(trimmed)

        if let feen = parseFeen(decoded) { return feen }

        let isDirect = decoded.hasPrefix("http://") || decoded.hasPrefix("https://") || decoded.hasPrefix("geo:") || decoded.hasPrefix("feen:") || decoded.hasPrefix("dalely:")
        if !isDirect || decoded.contains("\n"),
           let match = first(embeddedURLRegex, in: decoded) ?? first(embeddedURLRegex, in: trimmed) {
            let embedded = String(decoded[Range(match.range, in: decoded)!])
            if embedded != decoded, let nested = parse(embedded) {
                return ParsedGeoLocation(latitude: nested.latitude, longitude: nested.longitude, label: extractTextLabel(decoded, embeddedURL: embedded) ?? nested.label)
            }
        }

        var label: String?
        if let match = first(parenRegex, in: decoded) ?? first(parenRegex, in: trimmed),
           let range = Range(match.range(at: 1), in: decoded) {
            label = cleanPlaceName(String(decoded[range]))
        }

        if decoded.hasPrefix("geo:") || trimmed.hasPrefix("geo:") {
            if let geo = parseGeo(decoded.hasPrefix("geo:") ? decoded : trimmed, label: label) {
                return geo
            }
        }

        if decoded.contains("maps.apple.com") {
            if let apple = parseApple(trimmed, decoded: decoded, label: label) { return apple }
        }

        if decoded.contains("maps.google.") || decoded.contains("google.com/maps") || decoded.contains("maps.app.goo.gl") || decoded.contains("goo.gl/maps") {
            if let google = parseGoogle(trimmed, decoded: decoded, label: label) { return google }
        }

        if let uri = URL(string: trimmed) ?? URL(string: decoded),
           let items = URLComponents(url: uri, resolvingAgainstBaseURL: false)?.queryItems {
            for item in items {
                if let value = item.value, let coords = firstCoords(in: value) {
                    return ParsedGeoLocation(latitude: coords.0, longitude: coords.1, label: label)
                }
            }
        }

        if let coords = firstCoords(in: decoded) ?? firstCoords(in: trimmed) {
            return ParsedGeoLocation(latitude: coords.0, longitude: coords.1, label: label)
        }
        return nil
    }

    static func parseAsync(_ raw: String?) async -> ParsedGeoLocation? {
        if let parsed = parse(raw) { return parsed }
        guard let raw, let url = URL(string: raw), url.scheme?.hasPrefix("http") == true else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.setValue("Mozilla/5.0", forHTTPHeaderField: "User-Agent")
        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            if let http = response as? HTTPURLResponse, let location = http.url?.absoluteString {
                return parse(location)
            }
        } catch {
            return nil
        }
        return nil
    }

    static func extractLabel(_ raw: String?) -> String? {
        cleanPlaceName(raw)
    }

    static func cleanPlaceName(_ raw: String?) -> String? {
        guard var text = raw.map(safeDecode)?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else { return nil }
        text = text.replacingOccurrences(of: "\u{00A0}", with: " ")
        if let regex = try? NSRegularExpression(pattern: "[\\u200B-\\u200F\\u202A-\\u202E\\u2066-\\u2069\\uFEFF]") {
            text = regex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: "")
        }
        text = text.replacingOccurrences(of: "+", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        if let match = first(embeddedURLRegex, in: text), let range = Range(match.range, in: text) {
            text = text.replacingCharacters(in: range, with: "").trimmingCharacters(in: .whitespacesAndNewlines)
        }
        if let match = first(coordRegex, in: text), let range = Range(match.range, in: text) {
            text.removeSubrange(range)
            text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        let dropped = ["dropped pin", "pinned location", "موقع تم وضع علامة عليه", "علامة موضع"]
        if dropped.contains(where: { text.lowercased().contains($0) }) { return nil }
        text = text.trimmingCharacters(in: CharacterSet(charactersIn: "\"'`[](){}"))
        return text.isEmpty ? nil : text
    }

    private static func parseFeen(_ decoded: String) -> ParsedGeoLocation? {
        guard decoded.hasPrefix("feen:") || decoded.hasPrefix("dalely:") else { return nil }
        guard let uri = URLComponents(string: decoded) else { return nil }
        let lat = uri.queryItems?.first(where: { $0.name == "lat" })?.value.flatMap(Double.init)
        let lng = uri.queryItems?.first(where: { $0.name == "lng" })?.value.flatMap(Double.init)
        guard let lat, let lng, isValid(lat, lng) else { return nil }
        let name = uri.queryItems?.first(where: { ["name", "label", "title"].contains($0.name) })?.value
        return ParsedGeoLocation(latitude: lat, longitude: lng, label: cleanPlaceName(name))
    }

    private static func parseGeo(_ active: String, label: String?) -> ParsedGeoLocation? {
        let ssp = String(active.dropFirst(4))
        let parts = ssp.split(separator: "?", maxSplits: 1).map(String.init)
        let pathPart = parts.first ?? ""
        let queryString = parts.count > 1 ? parts[1] : ""
        if let q = queryValue(queryString, key: "q"), let coords = firstCoords(in: q) {
            return ParsedGeoLocation(latitude: coords.0, longitude: coords.1, label: label)
        }
        if let coords = firstCoords(in: pathPart), coords.0 != 0 || coords.1 != 0 || queryString.isEmpty {
            return ParsedGeoLocation(latitude: coords.0, longitude: coords.1, label: label)
        }
        return nil
    }

    private static func parseApple(_ trimmed: String, decoded: String, label: String?) -> ParsedGeoLocation? {
        guard let uri = URLComponents(string: trimmed) ?? URLComponents(string: decoded) else { return nil }
        let ll = uri.queryItems?.first(where: { ["ll", "sll", "daddr"].contains($0.name) })?.value
        if let ll, let coords = firstCoords(in: ll) {
            let qLabel = cleanPlaceName(uri.queryItems?.first(where: { ["q", "address"].contains($0.name) })?.value)
            return ParsedGeoLocation(latitude: coords.0, longitude: coords.1, label: label ?? qLabel)
        }
        if let q = uri.queryItems?.first(where: { $0.name == "q" })?.value, let coords = firstCoords(in: q) {
            return ParsedGeoLocation(latitude: coords.0, longitude: coords.1, label: label)
        }
        return nil
    }

    private static func parseGoogle(_ trimmed: String, decoded: String, label: String?) -> ParsedGeoLocation? {
        var extracted = label
        if extracted == nil, let match = first(placePathRegex, in: decoded), let range = Range(match.range(at: 1), in: decoded) {
            extracted = cleanPlaceName(String(decoded[range]))
        }
        if let match = first(atCoordRegex, in: decoded) ?? first(atCoordRegex, in: trimmed),
           let latR = Range(match.range(at: 1), in: decoded), let lngR = Range(match.range(at: 2), in: decoded),
           let lat = Double(decoded[latR]), let lng = Double(decoded[lngR]), isValid(lat, lng) {
            return ParsedGeoLocation(latitude: lat, longitude: lng, label: extracted)
        }
        if let match = first(googleDataRegex, in: decoded),
           let latR = Range(match.range(at: 1), in: decoded), let lngR = Range(match.range(at: 2), in: decoded),
           let lat = Double(decoded[latR]), let lng = Double(decoded[lngR]), isValid(lat, lng) {
            return ParsedGeoLocation(latitude: lat, longitude: lng, label: extracted)
        }
        if let uri = URLComponents(string: trimmed) ?? URLComponents(string: decoded) {
            let qVal = uri.queryItems?.first(where: { ["q", "query", "ll", "daddr", "destination"].contains($0.name) })?.value
            if let qVal, let coords = firstCoords(in: qVal) {
                return ParsedGeoLocation(latitude: coords.0, longitude: coords.1, label: extracted)
            }
        }
        return nil
    }

    private static func extractTextLabel(_ decoded: String, embeddedURL: String) -> String? {
        cleanPlaceName(decoded.replacingOccurrences(of: embeddedURL, with: ""))
    }

    private static func firstCoords(in text: String) -> (Double, Double)? {
        guard let match = first(coordRegex, in: text),
              let latR = Range(match.range(at: 1), in: text),
              let lngR = Range(match.range(at: 2), in: text),
              let lat = Double(text[latR]), let lng = Double(text[lngR]), isValid(lat, lng) else { return nil }
        return (lat, lng)
    }

    private static func isValid(_ lat: Double, _ lng: Double) -> Bool {
        lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180
    }

    private static func queryValue(_ query: String, key: String) -> String? {
        URLComponents(string: "x://x?\(query)")?.queryItems?.first(where: { $0.name == key })?.value
    }

    private static func first(_ regex: NSRegularExpression, in text: String) -> NSTextCheckingResult? {
        regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text))
    }

    static func safeDecode(_ input: String) -> String {
        input.removingPercentEncoding ?? input
    }
}
