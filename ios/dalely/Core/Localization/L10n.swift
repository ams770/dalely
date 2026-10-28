import Foundation

struct L10n: Equatable {
    var locale: Locale

    var isArabic: Bool {
        locale.language.languageCode?.identifier == "ar"
    }

    var layoutDirection: LayoutDirectionHint {
        isArabic ? .rightToLeft : .leftToRight
    }

    func t(_ key: String) -> String {
        let table = isArabic ? L10nCatalog.arabic : L10nCatalog.english
        return table[key] ?? L10nCatalog.english[key] ?? key
    }

    func format(_ key: String, _ replacements: [String: String]) -> String {
        var value = t(key)
        for (token, replacement) in replacements {
            value = value.replacingOccurrences(of: "{\(token)}", with: replacement)
        }
        return value
    }

    func savedSpotsCount(_ count: Int) -> String {
        if isArabic {
            switch arabicPlural(count) {
            case .zero: return "لا توجد أماكن محفوظة"
            case .one: return "مكان واحد محفوظ"
            case .two: return "مكانان محفوظان"
            case .few: return "\(count) أماكن محفوظة"
            case .many: return "\(count) مكانًا محفوظًا"
            case .other: return "\(count) مكان محفوظ"
            }
        }
        if count == 0 { return "No saved spots" }
        if count == 1 { return "1 saved spot" }
        return "\(count) saved spots"
    }

    func timeMinutesAgo(_ count: Int) -> String { relativeCount(englishOne: "1 min ago", englishOther: "\(count) min ago", arabic: arabicMinutesAgo(count)) }
    func timeHoursAgo(_ count: Int) -> String { relativeCount(englishOne: "1 h ago", englishOther: "\(count) h ago", arabic: arabicHoursAgo(count)) }
    func timeDaysAgo(_ count: Int) -> String { relativeCount(englishOne: "1 day ago", englishOther: "\(count) days ago", arabic: arabicDaysAgo(count)) }
    func timeWeeksAgo(_ count: Int) -> String { relativeCount(englishOne: "1 week ago", englishOther: "\(count) weeks ago", arabic: arabicWeeksAgo(count)) }
    func timeMonthsAgo(_ count: Int) -> String { relativeCount(englishOne: "1 month ago", englishOther: "\(count) months ago", arabic: arabicMonthsAgo(count)) }
    func timeYearsAgo(_ count: Int) -> String { relativeCount(englishOne: "1 year ago", englishOther: "\(count) years ago", arabic: arabicYearsAgo(count)) }

    func durationMinutes(_ count: Int) -> String {
        if !isArabic {
            return count == 1 ? "1 minute" : "\(count) minutes"
        }
        switch arabicPlural(count) {
        case .one: return "دقيقة"
        case .two: return "دقيقتين"
        case .few: return "\(count) دقائق"
        default: return "\(count) دقيقة"
        }
    }

    func durationHours(_ count: Int) -> String {
        if !isArabic {
            return count == 1 ? "1 hour" : "\(count) hours"
        }
        switch arabicPlural(count) {
        case .one: return "ساعة"
        case .two: return "ساعتين"
        case .few: return "\(count) ساعات"
        default: return "\(count) ساعة"
        }
    }

    func durationDays(_ count: Int) -> String {
        if !isArabic {
            return count == 1 ? "1 day" : "\(count) days"
        }
        switch arabicPlural(count) {
        case .one: return "يوم"
        case .two: return "يومين"
        case .few: return "\(count) أيام"
        default: return "\(count) يوم"
        }
    }

    func carTrackingAboutMinutes(_ count: Int) -> String {
        CarTrackingCalculator.formatWalkTime(minutes: count, isArabic: isArabic)
    }

    private func relativeCount(englishOne: String, englishOther: String, arabic: String) -> String {
        if isArabic { return arabic }
        return englishOne.contains("1") && englishOther != englishOne ? (englishOther.hasPrefix("1 ") ? englishOne : englishOther) : (englishOther)
    }

    private func arabicMinutesAgo(_ count: Int) -> String {
        switch arabicPlural(count) {
        case .one: return "منذ دقيقة"
        case .two: return "منذ دقيقتين"
        case .few: return "منذ \(count) دقائق"
        default: return "منذ \(count) دقيقة"
        }
    }

    private func arabicHoursAgo(_ count: Int) -> String {
        switch arabicPlural(count) {
        case .one: return "منذ ساعة"
        case .two: return "منذ ساعتين"
        case .few: return "منذ \(count) ساعات"
        default: return "منذ \(count) ساعة"
        }
    }

    private func arabicDaysAgo(_ count: Int) -> String {
        switch arabicPlural(count) {
        case .one: return "منذ يوم"
        case .two: return "منذ يومين"
        case .few: return "منذ \(count) أيام"
        default: return "منذ \(count) يوم"
        }
    }

    private func arabicWeeksAgo(_ count: Int) -> String {
        switch arabicPlural(count) {
        case .one: return "منذ أسبوع"
        case .two: return "منذ أسبوعين"
        case .few: return "منذ \(count) أسابيع"
        default: return "منذ \(count) أسبوع"
        }
    }

    private func arabicMonthsAgo(_ count: Int) -> String {
        switch arabicPlural(count) {
        case .one: return "منذ شهر"
        case .two: return "منذ شهرين"
        case .few: return "منذ \(count) أشهر"
        default: return "منذ \(count) شهر"
        }
    }

    private func arabicYearsAgo(_ count: Int) -> String {
        switch arabicPlural(count) {
        case .one: return "منذ سنة"
        case .two: return "منذ سنتين"
        case .few: return "منذ \(count) سنوات"
        default: return "منذ \(count) سنة"
        }
    }

    private enum ArabicPlural { case zero, one, two, few, many, other }

    private func arabicPlural(_ n: Int) -> ArabicPlural {
        if n == 0 { return .zero }
        if n == 1 { return .one }
        if n == 2 { return .two }
        let mod100 = n % 100
        if (3...10).contains(mod100) { return .few }
        if (11...99).contains(mod100) { return .many }
        return .other
    }
}

enum LayoutDirectionHint {
    case leftToRight
    case rightToLeft
}
