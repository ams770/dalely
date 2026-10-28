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

    var iconName: String { systemImage }
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

enum AppThemeMode: String, Codable, CaseIterable {
    case system
    case light
    case dark
}

