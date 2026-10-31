import Foundation
import CoreLocation

struct ParsedGeoLocation: Equatable {
    var latitude: Double
    var longitude: Double
    var label: String?
    /// True when the coordinate came from geocoding a name/address instead of an exact coordinate.
    /// Use it to force the "confirm on map" screen before saving.
    var isApproximate: Bool = false
    /// Address text that came with the link, used as a fallback name when there is no place name.
    var address: String? = nil
}

/// Stops URLSession from following redirects so we can read every hop ourselves.
private final class NoRedirectDelegate: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}

enum GeoUriParser {

    // MARK: - Debug logging (stripped from release builds)

    @inline(__always)
    private static func dlog(_ message: @autoclosure () -> String) {
        #if DEBUG
        print("[GeoParse] \(message())")
        #endif
    }

    private static func describe(_ r: ParsedGeoLocation?) -> String {
        guard let r else { return "nil" }
        return "lat=\(r.latitude) lng=\(r.longitude) label=\(r.label ?? "-") approx=\(r.isApproximate)"
    }

    // MARK: - Regexes

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

    /// Used to scan an HTML body for an Apple Maps coordinate parameter.
    private static let bodyCoordRegex = try! NSRegularExpression(
        pattern: #"(?:coordinate|sll|ll)=(-?\d{1,2}(?:\.\d+)?)(?:,|%2C)(-?\d{1,3}(?:\.\d+)?)"#
    )

    private static let userAgent =
        "Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.0 Mobile/15E148 Safari/604.1"

    // MARK: - Public API

    /// Synchronous, offline parse. Returns nil for short links that need network resolution.
    static func parse(_ raw: String?) -> ParsedGeoLocation? {
        let result = parseInternal(raw)
        dlog("parse(\(String(raw?.prefix(120) ?? "nil"))) -> \(describe(result))")
        return result
    }

    /// Offline parse first, then resolves short links (Apple Maps maps.apple/p/..., Google short links).
    static func parseAsync(_ raw: String?) async -> ParsedGeoLocation? {
        dlog("parseAsync input: \(raw ?? "nil")")

        if let parsed = parse(raw) {
            dlog("resolved offline, no network needed")
            return parsed
        }

        guard let raw else { return nil }
        let decoded = safeDecode(raw)

        guard let match = first(embeddedURLRegex, in: decoded),
              let range = Range(match.range, in: decoded),
              let url = URL(string: String(decoded[range])),
              url.scheme?.hasPrefix("http") == true else {
            dlog("no http(s) link found inside the input, giving up")
            return nil
        }

        let linkText = String(decoded[range])
        let textLabel = extractTextLabel(decoded, embeddedURL: linkText)
        dlog("extracted link: \(linkText)")

        var result = await resolveShortLink(url)
        if result != nil, result?.label == nil { result?.label = textLabel }
        dlog("parseAsync final -> \(describe(result))")
        return result
    }

    static func extractLabel(_ raw: String?) -> String? {
        cleanPlaceName(raw)
    }

    // MARK: - Core offline parser

    private static func parseInternal(_ raw: String?) -> ParsedGeoLocation? {
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let decoded = safeDecode(trimmed)

        if let feen = parseFeen(decoded) { return feen }

        let isDirect = decoded.hasPrefix("http://") || decoded.hasPrefix("https://") || decoded.hasPrefix("geo:") || decoded.hasPrefix("feen:") || decoded.hasPrefix("dalely:")
        if !isDirect || decoded.contains("\n"),
           let match = first(embeddedURLRegex, in: decoded) ?? first(embeddedURLRegex, in: trimmed) {
            let embedded = String(decoded[Range(match.range, in: decoded)!])
            if embedded != decoded, let nested = parseInternal(embedded) {
                return ParsedGeoLocation(
                    latitude: nested.latitude,
                    longitude: nested.longitude,
                    label: extractTextLabel(decoded, embeddedURL: embedded) ?? nested.label
                )
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

        // Matches maps.apple.com/... and the short form maps.apple/p/...
        if decoded.contains("maps.apple") {
            if let apple = parseApple(trimmed, decoded: decoded, label: label) { return apple }
            dlog("Apple Maps link has no coordinate in the URL itself (short link?)")
            // Do not fall through to generic coordinate guessing for Apple links:
            // short links cannot contain coordinates and the loose regex could match junk.
            return nil
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

    // MARK: - Short link resolution

    private static func resolveShortLink(_ start: URL, maxHops: Int = 8) async -> ParsedGeoLocation? {
        let session = URLSession(configuration: .ephemeral,
                                 delegate: NoRedirectDelegate(),
                                 delegateQueue: nil)
        defer { session.finishTasksAndInvalidate() }

        var current = start
        var hintName: String?
        var hintAddress: String?

        for hop in 0..<maxHops {
            dlog("---- hop \(hop) ----")
            dlog("url: \(current.absoluteString)")

            // 1. Coordinate or hints already inside this hop's URL?
            if let comps = URLComponents(url: current, resolvingAgainstBaseURL: false) {
                let items = comps.queryItems ?? []
                dlog("query params: \(items.map { "\($0.name)=\($0.value ?? "")" }.joined(separator: " | "))")

                if let n = items.first(where: { $0.name == "name" })?.value, !n.isEmpty { hintName = n }
                if let a = items.first(where: { $0.name == "address" })?.value, !a.isEmpty { hintAddress = a }
            }

            if var apple = parseApple(current.absoluteString,
                                      decoded: safeDecode(current.absoluteString),
                                      label: nil) {
                dlog("coordinate found in hop \(hop) URL")
                if apple.label == nil { apple.label = cleanPlaceName(hintName) }
                if apple.address == nil { apple.address = hintAddress }
                return apple
            }

            // 2. Fetch this hop without following redirects.
            var req = URLRequest(url: current)
            req.httpMethod = "GET"           // not HEAD
            req.timeoutInterval = 8
            req.setValue(userAgent, forHTTPHeaderField: "User-Agent")

            let data: Data
            let response: URLResponse
            do {
                (data, response) = try await session.data(for: req)
            } catch {
                dlog("request failed: \(error.localizedDescription)")
                break
            }

            guard let http = response as? HTTPURLResponse else {
                dlog("not an HTTP response")
                break
            }

            dlog("status: \(http.statusCode)")
            for (key, value) in http.allHeaderFields {
                dlog("header: \(key) = \(value)")
            }

            // 3. Redirect: move to the next hop.
            if (300..<400).contains(http.statusCode),
               let loc = http.value(forHTTPHeaderField: "Location"),
               let next = URL(string: loc, relativeTo: current)?.absoluteURL {
                dlog("redirect -> \(next.absoluteString)")
                current = next
                continue
            }

            // 4. Not a redirect: look inside the body for a coordinate parameter.
            let bodyText = String(data: data.prefix(20_000), encoding: .utf8) ?? ""
            dlog("body length: \(data.count) bytes")
            dlog("body snippet: \(String(bodyText.prefix(300)).replacingOccurrences(of: "\n", with: " "))")

            if let m = first(bodyCoordRegex, in: bodyText),
               let latR = Range(m.range(at: 1), in: bodyText),
               let lngR = Range(m.range(at: 2), in: bodyText),
               let lat = Double(bodyText[latR]), let lng = Double(bodyText[lngR]),
               isValid(lat, lng) {
                dlog("coordinate found in response body")
                return ParsedGeoLocation(latitude: lat, longitude: lng,
                                         label: cleanPlaceName(hintName), address: hintAddress)
            }
            break
        }

        // 5. Fallback: geocode name/address collected along the way.
        dlog("no exact coordinate found. hints: name=\(hintName ?? "-") address=\(hintAddress ?? "-")")
        return await geocodeFallback(name: hintName, address: hintAddress)
    }

    private static func geocodeFallback(name: String?, address: String?) async -> ParsedGeoLocation? {
        let query = [address, name].compactMap { $0 }.first(where: { !$0.isEmpty })
        guard let query else {
            dlog("geocode fallback skipped: no name or address available")
            return nil
        }
        dlog("geocoding: \(query)")
        do {
            let placemarks = try await CLGeocoder().geocodeAddressString(query)
            guard let coord = placemarks.first?.location?.coordinate else {
                dlog("geocoder returned no results")
                return nil
            }
            return ParsedGeoLocation(latitude: coord.latitude,
                                     longitude: coord.longitude,
                                     label: cleanPlaceName(name),
                                     isApproximate: true,
                                     address: address)
        } catch {
            dlog("geocoder error: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Label cleanup

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

    // MARK: - Per-scheme parsers

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
        let items = uri.queryItems ?? []

        // "coordinate" is used by the long maps.apple.com/place?... links (iOS 26 and recent versions).
        let ll = items.first(where: { ["coordinate", "ll", "sll", "daddr"].contains($0.name) })?.value
        // Prefer the place name explicitly. In Apple links "address" comes before "name" in the URL,
        // so taking the first match would return the address instead of the name.
        func value(_ key: String) -> String? { items.first(where: { $0.name == key })?.value }
        let placeName = cleanPlaceName(value("name")) ?? cleanPlaceName(value("q"))
        let rawAddress = value("address")?.trimmingCharacters(in: .whitespacesAndNewlines)
        let addressText = (rawAddress?.isEmpty == false) ? rawAddress : nil

        if let ll, let coords = firstCoords(in: ll) {
            return ParsedGeoLocation(latitude: coords.0, longitude: coords.1,
                                     label: label ?? placeName, address: addressText)
        }
        if let q = items.first(where: { $0.name == "q" })?.value, let coords = firstCoords(in: q) {
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

    // MARK: - Helpers

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