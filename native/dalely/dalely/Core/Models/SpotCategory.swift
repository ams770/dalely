import SwiftUI

enum SpotCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case other
    case restaurant
    case fuel
    case gym
    case mosque
    case market
    case pharmacy
    case home
    case work
    case hospital
    case school
    case park
    case club
    case beautyCenter
    case car

    var id: String { rawValue }

    var isCar: Bool { self == .car }

    static let selectable: [SpotCategory] = allCases.filter { !$0.isCar }

    static func fromName(_ name: String?) -> SpotCategory {
        guard let name else { return .other }
        return SpotCategory(rawValue: name) ?? .other
    }

    var systemImage: String {
        switch self {
        case .other: "mappin.circle.fill"
        case .restaurant: "fork.knife"
        case .fuel: "fuelpump.fill"
        case .gym: "figure.strengthtraining.traditional"
        case .mosque: "moon.stars.fill"
        case .market: "cart.fill"
        case .pharmacy: "cross.case.fill"
        case .home: "house.fill"
        case .work: "briefcase.fill"
        case .hospital: "cross.fill"
        case .school: "graduationcap.fill"
        case .park: "leaf.fill"
        case .club: "soccerball"
        case .beautyCenter: "sparkles"
        case .car: "car.fill"
        }
    }

    func label(_ l10n: L10n) -> String {
        switch self {
        case .car: l10n.t("categoryCar")
        case .market: l10n.t("categoryMarket")
        case .home: l10n.t("categoryHome")
        case .pharmacy: l10n.t("categoryPharmacy")
        case .work: l10n.t("categoryWork")
        case .restaurant: l10n.t("categoryRestaurant")
        case .hospital: l10n.t("categoryHospital")
        case .school: l10n.t("categorySchool")
        case .gym: l10n.t("categoryGym")
        case .mosque: l10n.t("categoryMosque")
        case .fuel: l10n.t("categoryFuel")
        case .park: l10n.t("categoryPark")
        case .club: l10n.t("categoryClub")
        case .beautyCenter: l10n.t("categoryBeautyCenter")
        case .other: l10n.t("categoryOther")
        }
    }
}

enum SpotStatus: String, Codable, Hashable {
    case parking
    case found
    case none

    static func fromName(_ name: String?) -> SpotStatus {
        guard let name, !name.isEmpty else { return .none }
        return SpotStatus(rawValue: name) ?? .none
    }
}

enum SpotSortOrder: String, Codable, CaseIterable {
    case dateDesc
    case nearest
    case category
    case name
}

enum AppThemeMode: String, Codable, CaseIterable {
    case system
    case light
    case dark

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum LocationAccess: Equatable {
    case unknown
    case granted
    case denied
    case deniedForever
    case serviceDisabled
}
