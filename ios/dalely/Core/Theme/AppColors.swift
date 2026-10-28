import SwiftUI

enum AppColors {
    static let lightPrimary = Color(hex: 0x3C79F3)
    static let lightPrimaryDarker = Color(hex: 0x0B6FBF)
    static let lightPrimaryContainer = Color(hex: 0xF3F9FF)
    static let lightCar = Color(hex: 0xFF8A65)
    static let lightCarContainer = Color(hex: 0xFFF0EC)
    static let lightBackground = Color(hex: 0xf2f2f2)
    static let lightSurface = Color.white
    static let lightSurfaceSecondary = Color(hex: 0xF3F9FF)
    static let lightBorder = Color(hex: 0xE2E8F0)
    static let lightTextPrimary = Color(hex: 0x12263F)
    static let lightTextSecondary = Color(hex: 0x64748B)
    static let lightTextTertiary = Color(hex: 0x94A3B8)

    static let darkPrimary = Color(hex: 0x3C79F3)
    static let darkPrimaryContainer = Color(hex: 0x12263F)
    static let darkCar = Color(hex: 0xFF8A65)
    static let darkCarContainer = Color(hex: 0x3B1E16)
    static let darkBackground = Color(hex: 0x0B131F)
    static let darkSurface = Color(hex: 0x12263F)
    static let darkSurfaceSecondary = Color(hex: 0x1E293B)
    static let darkBorder = Color(hex: 0x223D5F)
    static let darkMapBackground = Color(hex: 0x1D2C42)
    static let darkTextPrimary = Color(hex: 0xF8FAFC)
    static let darkTextSecondary = Color(hex: 0x94A3B8)
    static let darkTextTertiary = Color(hex: 0x64748B)

    static let arrivedGreen = Color(hex: 0x0E9F75)
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: alpha
        )
    }
}

struct AppPalette {
    let primary: Color
    let primaryDarker: Color
    let primaryContainer: Color
    let car: Color
    let carContainer: Color
    let background: Color
    let surface: Color
    let surfaceSecondary: Color
    let border: Color
    let textPrimary: Color
    let textSecondary: Color
    let textTertiary: Color
    let carCardBackground: Color
    let carCardForeground: Color
    let carCardArc: Color
    let carButtonDarkBg: Color
    let carButtonDarkFg: Color
    let carButtonLightBg: Color
    let carButtonLightFg: Color
    let pillBackground: Color
    let pillForeground: Color
    let mapOverlaySurface: Color
    let mapOverlayBorder: Color
    let categoryColors: [SpotCategory: Color]

    static let light = AppPalette(
        primary: AppColors.lightPrimary,
        primaryDarker: AppColors.lightPrimaryDarker,
        primaryContainer: AppColors.lightPrimaryContainer,
        car: AppColors.lightCar,
        carContainer: AppColors.lightCarContainer,
        background: AppColors.lightBackground,
        surface: AppColors.lightSurface,
        surfaceSecondary: AppColors.lightSurfaceSecondary,
        border: AppColors.lightBorder,
        textPrimary: AppColors.lightTextPrimary,
        textSecondary: AppColors.lightTextSecondary,
        textTertiary: AppColors.lightTextTertiary,
        carCardBackground: Color(hex: 0xFF8A65),
        carCardForeground: Color(hex: 0x12263F),
        carCardArc: Color.white.opacity(0.2),
        carButtonDarkBg: Color(hex: 0x12263F),
        carButtonDarkFg: .white,
        carButtonLightBg: .white,
        carButtonLightFg: Color(hex: 0x12263F),
        pillBackground: Color(hex: 0xF3F9FF),
        pillForeground: Color(hex: 0x0B6FBF),
        mapOverlaySurface: .white,
        mapOverlayBorder: Color(hex: 0xE2E8F0),
        categoryColors: [
            .car: Color(hex: 0xFF8A65),
            .market: Color(hex: 0x3C79F3),
            .home: Color(hex: 0x10B981),
            .pharmacy: Color(hex: 0xEC4899),
            .work: Color(hex: 0x8B5CF6),
            .restaurant: Color(hex: 0xF59E0B),
            .hospital: Color(hex: 0xEF4444),
            .school: Color(hex: 0x06B6D4),
            .gym: Color(hex: 0x14B8A6),
            .mosque: Color(hex: 0x059669),
            .fuel: Color(hex: 0xD97706),
            .park: Color(hex: 0x16A34A),
            .club: Color(hex: 0x6366F1),
            .beautyCenter: Color(hex: 0xE11D48),
            .other: Color(hex: 0x3C79F3),
        ]
    )

    static let dark = AppPalette(
        primary: AppColors.darkPrimary,
        primaryDarker: AppColors.lightPrimaryDarker,
        primaryContainer: AppColors.darkPrimaryContainer,
        car: AppColors.darkCar,
        carContainer: AppColors.darkCarContainer,
        background: AppColors.darkBackground,
        surface: AppColors.darkSurface,
        surfaceSecondary: AppColors.darkSurfaceSecondary,
        border: AppColors.darkBorder,
        textPrimary: AppColors.darkTextPrimary,
        textSecondary: AppColors.darkTextSecondary,
        textTertiary: AppColors.darkTextTertiary,
        carCardBackground: Color(hex: 0xD95338),
        carCardForeground: Color(hex: 0x12263F),
        carCardArc: Color.white.opacity(0.16),
        carButtonDarkBg: Color(hex: 0x12263F),
        carButtonDarkFg: .white,
        carButtonLightBg: .white,
        carButtonLightFg: Color(hex: 0x12263F),
        pillBackground: Color(hex: 0x12263F),
        pillForeground: Color(hex: 0xCBD5E1),
        mapOverlaySurface: Color(hex: 0x12263F),
        mapOverlayBorder: Color(hex: 0x223D5F),
        categoryColors: [
            .car: Color(hex: 0xFF8A65),
            .market: Color(hex: 0x38BDF8),
            .home: Color(hex: 0x34D399),
            .pharmacy: Color(hex: 0xF472B6),
            .work: Color(hex: 0xA78BFA),
            .restaurant: Color(hex: 0xFBBF24),
            .hospital: Color(hex: 0xF87171),
            .school: Color(hex: 0x22D3EE),
            .gym: Color(hex: 0x2DD4BF),
            .mosque: Color(hex: 0x10B981),
            .fuel: Color(hex: 0xF59E0B),
            .park: Color(hex: 0x4ADE80),
            .club: Color(hex: 0x818CF8),
            .beautyCenter: Color(hex: 0xFB7185),
            .other: Color(hex: 0x38BDF8),
        ]
    )

    func categoryColor(_ category: SpotCategory) -> Color {
        categoryColors[category] ?? categoryColors[.other]!
    }
}

enum AppDimens {
    static let space4: CGFloat = 4
    static let space6: CGFloat = 6
    static let space8: CGFloat = 8
    static let space12: CGFloat = 12
    static let space16: CGFloat = 16
    static let space20: CGFloat = 20
    static let space24: CGFloat = 24
    static let space32: CGFloat = 32
    static let space40: CGFloat = 40
    static let radiusSmall: CGFloat = 10
    static let radiusMedium: CGFloat = 16
    static let radiusLarge: CGFloat = 24
    static let minTouch: CGFloat = 48
    static let primaryButtonHeight: CGFloat = 56
    static let categoryBadge: CGFloat = 44
    static let mapPreviewHeight: CGFloat = 140
    static let animShort: Double = 0.25
    static let animMedium: Double = 0.4
}
