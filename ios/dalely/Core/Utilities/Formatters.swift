import CoreLocation
import Foundation

enum DistanceFormatter {
    static func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> CLLocationDistance {
        CLLocation(latitude: from.latitude, longitude: from.longitude)
            .distance(from: CLLocation(latitude: to.latitude, longitude: to.longitude))
    }

    static func format(_ meters: Double, l10n: L10n) -> String {
        if meters < 1000 {
            return l10n.format("distanceMeters", ["value": "\(Int(meters.rounded()))"])
        }
        let km = meters / 1000
        let value = km < 10 ? String(format: "%.1f", km) : "\(Int(km.rounded()))"
        return l10n.format("distanceKilometers", ["value": value])
    }
}

enum TimeAgoFormatter {
    static func format(_ date: Date, l10n: L10n, now: Date = Date()) -> String {
        let difference = now.timeIntervalSince(date)
        if difference < 60 { return l10n.t("timeJustNow") }
        let minutes = Int(difference / 60)
        if minutes < 60 { return l10n.timeMinutesAgo(minutes) }
        let hours = Int(difference / 3600)
        if hours < 24 { return l10n.timeHoursAgo(hours) }
        let days = Int(difference / 86400)
        if days == 1 { return l10n.t("timeYesterday") }
        if days < 7 { return l10n.timeDaysAgo(days) }
        let weeks = days / 7
        if weeks < 4 { return l10n.timeWeeksAgo(weeks) }
        let months = days / 30
        if months < 12 { return l10n.timeMonthsAgo(months) }
        return l10n.timeYearsAgo(days / 365)
    }
}

enum DurationFormatter {
    static func formatTimer(_ duration: TimeInterval) -> String {
        let clamped = max(0, duration)
        let total = Int(clamped)
        let seconds = total % 60
        let minutes = (total / 60) % 60
        let hours = (total / 3600) % 24
        let days = total / 86400
        let body = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        return days > 0 ? "\(days) d \(body)" : body
    }

    static func formatHuman(_ duration: TimeInterval, l10n: L10n) -> String {
        let clamped = max(0, duration)
        let totalMinutes = Int(clamped / 60)
        if totalMinutes < 1 { return l10n.t("durationLessThanMinute") }
        if totalMinutes < 60 { return l10n.durationMinutes(totalMinutes) }
        let days = Int(clamped / 86400)
        let hours = Int(clamped / 3600) % 24
        let minutes = totalMinutes % 60
        if days == 0 {
            let hStr = l10n.durationHours(hours)
            if minutes == 0 { return hStr }
            return l10n.format("durationHoursAndMinutes", ["hours": hStr, "minutes": l10n.durationMinutes(minutes)])
        }
        let dStr = l10n.durationDays(days)
        if hours == 0 { return dStr }
        return l10n.format("durationDaysAndHours", ["days": dStr, "hours": l10n.durationHours(hours)])
    }
}

enum SpotLinkBuilder {
    static func mapURL(latitude: Double, longitude: Double) -> String {
        "https://maps.google.com/?q=\(latitude),\(longitude)"
    }

    static func buildSingle(_ spot: Spot, l10n: L10n) -> String {
        let displayName = spot.isCar ? (spot.name.trimmingCharacters(in: .whitespaces).isEmpty ? l10n.t("myCar") : spot.name) : spot.name
        return "\(displayName) - \(mapURL(latitude: spot.latitude, longitude: spot.longitude))"
    }

    static func buildAll(_ spots: [Spot], l10n: L10n) -> String {
        let ordered = spots.sorted { a, b in
            if a.isCar { return true }
            if b.isCar { return false }
            return a.savedAt > b.savedAt
        }
        return ordered.map { buildSingle($0, l10n: l10n) }.joined(separator: "\n\n")
    }
}

enum SpotsCsvBuilder {
    static func build(_ spots: [Spot], l10n: L10n) -> String {
        guard !spots.isEmpty else { return "" }
        let ordered = spots.sorted { a, b in
            if a.isCar { return true }
            if b.isCar { return false }
            return a.savedAt > b.savedAt
        }
        var buffer = "Name,Latitude,Longitude,Google Maps URL\r\n"
        for spot in ordered {
            let displayName = spot.isCar ? (spot.name.trimmingCharacters(in: .whitespaces).isEmpty ? l10n.t("myCar") : spot.name) : spot.name
            let row = [escape(displayName), "\(spot.latitude)", "\(spot.longitude)", escape(SpotLinkBuilder.mapURL(latitude: spot.latitude, longitude: spot.longitude))]
            buffer += row.joined(separator: ",") + "\r\n"
        }
        return buffer
    }

    static func escape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") || value.contains("\r") {
            return "\"\(value.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return value
    }
}

enum SearchNormalizer {
    static func normalize(_ input: String) -> String {
        var text = input.lowercased()
        if let regex = try? NSRegularExpression(pattern: "[\\u064B-\\u0652]") {
            text = regex.stringByReplacingMatches(in: text, range: NSRange(text.startIndex..., in: text), withTemplate: "")
        }
        for ch in ["أ", "إ", "آ", "ٱ"] {
            text = text.replacingOccurrences(of: ch, with: "ا")
        }
        text = text.replacingOccurrences(of: "ة", with: "ه")
        text = text.replacingOccurrences(of: "ى", with: "ي")
        return text
    }
}

enum CarTrackingCalculator {
    static let walkingSpeedMetersPerSecond = 1.4
    static let arrivalDistanceMeters = 15.0
    static let arrivalMaxAccuracyMeters = 25.0
    static let departureDistanceMeters = 30.0
    static let maxTrackingDistanceMeters = 50_000.0

    static func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        DistanceFormatter.calculateDistance(from: from, to: to)
    }

    static func formatDistance(_ meters: Double, isArabic: Bool) -> String {
        let clamped = max(0, meters)
        if clamped < 100 {
            let rounded = Int((clamped / 5).rounded()) * 5
            return "\(rounded) \(isArabic ? "م" : "m")"
        }
        if clamped < 1000 {
            var rounded = Int((clamped / 10).rounded()) * 10
            if rounded >= 1000 {
                return String(format: "%.1f %@", Double(rounded) / 1000, isArabic ? "كم" : "km")
            }
            return "\(rounded) \(isArabic ? "م" : "m")"
        }
        return String(format: "%.1f %@", clamped / 1000, isArabic ? "كم" : "km")
    }

    static func calculateWalkMinutes(_ meters: Double) -> Int {
        if meters <= 0 { return 0 }
        let seconds = meters / walkingSpeedMetersPerSecond
        if seconds < 59 { return 0 }
        return Int(ceil((seconds - 1e-6) / 60))
    }

    static func formatWalkTime(minutes: Int, isArabic: Bool) -> String {
        if minutes <= 0 {
            return isArabic ? "أقل من دقيقة" : "Less than a minute"
        }
        if isArabic {
            if minutes == 1 { return "حوالي دقيقة سيرًا" }
            if minutes == 2 { return "حوالي دقيقتين سيرًا" }
            if (3...10).contains(minutes) { return "حوالي \(minutes) دقائق سيرًا" }
            return "حوالي \(minutes) دقيقة سيرًا"
        }
        return minutes == 1 ? "About 1 min walk" : "About \(minutes) min walk"
    }

    static func calculateProgress(currentDistance: Double, startDistance: Double) -> Double {
        guard startDistance > 0 else { return 1 }
        return min(1, max(0, 1 - currentDistance / startDistance))
    }

    static func shouldResetStartDistance(currentDistance: Double, startDistance: Double) -> Bool {
        currentDistance > (1.5 * startDistance)
    }

    static func checkArrival(distance: Double, horizontalAccuracy: Double, currentlyArrived: Bool) -> Bool {
        if currentlyArrived {
            return distance <= departureDistanceMeters
        }
        return distance <= arrivalDistanceMeters && horizontalAccuracy <= arrivalMaxAccuracyMeters
    }

    static func isTooFar(_ distanceMeters: Double) -> Bool {
        distanceMeters > maxTrackingDistanceMeters
    }
}
