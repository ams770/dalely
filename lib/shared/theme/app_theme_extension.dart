import 'package:flutter/material.dart';

import '../constants/spot_categories.dart';
import 'app_colors.dart';

/// Extended theme tokens for Dalely-specific styling.
///
/// Extended theme tokens for Dalely-specific styling.
///
/// Accessed via `context.tokens` or `Theme.of(context).extension<AppThemeExtension>()!`.
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.carCardBackground,
    required this.carCardForeground,
    required this.carCardArcColor,
    required this.carCardButtonDarkBg,
    required this.carCardButtonDarkFg,
    required this.carCardButtonLightBg,
    required this.carCardButtonLightFg,
    required this.carCardPillBg,
    required this.carCardPillFg,
    required this.carCardShadow,
    required this.carGradientStart,
    required this.carGradientEnd,
    required this.carOnGradient,
    required this.pillBackground,
    required this.pillForeground,
    required this.mapOverlaySurface,
    required this.mapOverlayBorder,
    required this.categoryColors,
  });

  final Color carCardBackground;
  final Color carCardForeground;
  final Color carCardArcColor;
  final Color carCardButtonDarkBg;
  final Color carCardButtonDarkFg;
  final Color carCardButtonLightBg;
  final Color carCardButtonLightFg;
  final Color carCardPillBg;
  final Color carCardPillFg;
  final Color carCardShadow;

  final Color carGradientStart;
  final Color carGradientEnd;
  final Color carOnGradient;
  final Color pillBackground;
  final Color pillForeground;
  final Color mapOverlaySurface;
  final Color mapOverlayBorder;
  final Map<SpotCategory, Color> categoryColors;

  Color categoryColor(SpotCategory category) =>
      categoryColors[category] ?? categoryColors[SpotCategory.other]!;

  static const AppThemeExtension light = AppThemeExtension(
    carCardBackground: Color(0xFFFF8A65),
    carCardForeground: Color(0xFF12263F),
    carCardArcColor: Color(0x33FFFFFF),
    carCardButtonDarkBg: Color(0xFF12263F),
    carCardButtonDarkFg: Colors.white,
    carCardButtonLightBg: Colors.white,
    carCardButtonLightFg: Color(0xFF12263F),
    carCardPillBg: Colors.white,
    carCardPillFg: Color(0xFF12263F),
    carCardShadow: Color(0x4DFF8A65),
    carGradientStart: Color(0xFFFF8A65),
    carGradientEnd: Color(0xFFFF7A59),
    carOnGradient: Color(0xFF12263F),
    pillBackground: Color(0xFFF3F9FF),
    pillForeground: Color(0xFF0B6FBF),
    mapOverlaySurface: Color(0xFFFFFFFF),
    mapOverlayBorder: Color(0xFFE2E8F0),
    categoryColors: {
      SpotCategory.car: AppColors.catCarLight,
      SpotCategory.market: AppColors.catMarketLight,
      SpotCategory.home: AppColors.catHomeLight,
      SpotCategory.pharmacy: AppColors.catPharmacyLight,
      SpotCategory.work: AppColors.catWorkLight,
      SpotCategory.restaurant: AppColors.catRestaurantLight,
      SpotCategory.hospital: AppColors.catHospitalLight,
      SpotCategory.school: AppColors.catSchoolLight,
      SpotCategory.gym: AppColors.catGymLight,
      SpotCategory.mosque: AppColors.catMosqueLight,
      SpotCategory.fuel: AppColors.catFuelLight,
      SpotCategory.park: AppColors.catParkLight,
      SpotCategory.club: AppColors.catClubLight,
      SpotCategory.beautyCenter: AppColors.catBeautyCenterLight,
      SpotCategory.other: AppColors.catOtherLight,
    },
  );

  static const AppThemeExtension dark = AppThemeExtension(
    carCardBackground: Color(0xFFD95338),
    carCardForeground: Color(0xFF12263F),
    carCardArcColor: Color(0x28FFFFFF),
    carCardButtonDarkBg: Color(0xFF12263F),
    carCardButtonDarkFg: Colors.white,
    carCardButtonLightBg: Colors.white,
    carCardButtonLightFg: Color(0xFF12263F),
    carCardPillBg: Colors.white,
    carCardPillFg: Color(0xFF12263F),
    carCardShadow: Color(0x40000000),
    carGradientStart: Color(0xFFFF8A65),
    carGradientEnd: Color(0xFFC83E20),
    carOnGradient: Color(0xFF12263F),
    pillBackground: Color(0xFF12263F),
    pillForeground: Color(0xFFCBD5E1),
    mapOverlaySurface: Color(0xFF12263F),
    mapOverlayBorder: Color(0xFF223D5F),
    categoryColors: {
      SpotCategory.car: AppColors.catCarDark,
      SpotCategory.market: AppColors.catMarketDark,
      SpotCategory.home: AppColors.catHomeDark,
      SpotCategory.pharmacy: AppColors.catPharmacyDark,
      SpotCategory.work: AppColors.catWorkDark,
      SpotCategory.restaurant: AppColors.catRestaurantDark,
      SpotCategory.hospital: AppColors.catHospitalDark,
      SpotCategory.school: AppColors.catSchoolDark,
      SpotCategory.gym: AppColors.catGymDark,
      SpotCategory.mosque: AppColors.catMosqueDark,
      SpotCategory.fuel: AppColors.catFuelDark,
      SpotCategory.park: AppColors.catParkDark,
      SpotCategory.club: AppColors.catClubDark,
      SpotCategory.beautyCenter: AppColors.catBeautyCenterDark,
      SpotCategory.other: AppColors.catOtherDark,
    },
  );

  @override
  AppThemeExtension copyWith({
    Color? carCardBackground,
    Color? carCardForeground,
    Color? carCardArcColor,
    Color? carCardButtonDarkBg,
    Color? carCardButtonDarkFg,
    Color? carCardButtonLightBg,
    Color? carCardButtonLightFg,
    Color? carCardPillBg,
    Color? carCardPillFg,
    Color? carCardShadow,
    Color? carGradientStart,
    Color? carGradientEnd,
    Color? carOnGradient,
    Color? pillBackground,
    Color? pillForeground,
    Color? mapOverlaySurface,
    Color? mapOverlayBorder,
    Map<SpotCategory, Color>? categoryColors,
  }) {
    return AppThemeExtension(
      carCardBackground: carCardBackground ?? this.carCardBackground,
      carCardForeground: carCardForeground ?? this.carCardForeground,
      carCardArcColor: carCardArcColor ?? this.carCardArcColor,
      carCardButtonDarkBg: carCardButtonDarkBg ?? this.carCardButtonDarkBg,
      carCardButtonDarkFg: carCardButtonDarkFg ?? this.carCardButtonDarkFg,
      carCardButtonLightBg: carCardButtonLightBg ?? this.carCardButtonLightBg,
      carCardButtonLightFg: carCardButtonLightFg ?? this.carCardButtonLightFg,
      carCardPillBg: carCardPillBg ?? this.carCardPillBg,
      carCardPillFg: carCardPillFg ?? this.carCardPillFg,
      carCardShadow: carCardShadow ?? this.carCardShadow,
      carGradientStart: carGradientStart ?? this.carGradientStart,
      carGradientEnd: carGradientEnd ?? this.carGradientEnd,
      carOnGradient: carOnGradient ?? this.carOnGradient,
      pillBackground: pillBackground ?? this.pillBackground,
      pillForeground: pillForeground ?? this.pillForeground,
      mapOverlaySurface: mapOverlaySurface ?? this.mapOverlaySurface,
      mapOverlayBorder: mapOverlayBorder ?? this.mapOverlayBorder,
      categoryColors: categoryColors ?? this.categoryColors,
    );
  }

  @override
  AppThemeExtension lerp(ThemeExtension<AppThemeExtension>? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      carCardBackground: Color.lerp(
        carCardBackground,
        other.carCardBackground,
        t,
      )!,
      carCardForeground: Color.lerp(
        carCardForeground,
        other.carCardForeground,
        t,
      )!,
      carCardArcColor: Color.lerp(carCardArcColor, other.carCardArcColor, t)!,
      carCardButtonDarkBg: Color.lerp(
        carCardButtonDarkBg,
        other.carCardButtonDarkBg,
        t,
      )!,
      carCardButtonDarkFg: Color.lerp(
        carCardButtonDarkFg,
        other.carCardButtonDarkFg,
        t,
      )!,
      carCardButtonLightBg: Color.lerp(
        carCardButtonLightBg,
        other.carCardButtonLightBg,
        t,
      )!,
      carCardButtonLightFg: Color.lerp(
        carCardButtonLightFg,
        other.carCardButtonLightFg,
        t,
      )!,
      carCardPillBg: Color.lerp(carCardPillBg, other.carCardPillBg, t)!,
      carCardPillFg: Color.lerp(carCardPillFg, other.carCardPillFg, t)!,
      carCardShadow: Color.lerp(carCardShadow, other.carCardShadow, t)!,
      carGradientStart: Color.lerp(
        carGradientStart,
        other.carGradientStart,
        t,
      )!,
      carGradientEnd: Color.lerp(carGradientEnd, other.carGradientEnd, t)!,
      carOnGradient: Color.lerp(carOnGradient, other.carOnGradient, t)!,
      pillBackground: Color.lerp(pillBackground, other.pillBackground, t)!,
      pillForeground: Color.lerp(pillForeground, other.pillForeground, t)!,
      mapOverlaySurface: Color.lerp(
        mapOverlaySurface,
        other.mapOverlaySurface,
        t,
      )!,
      mapOverlayBorder: Color.lerp(
        mapOverlayBorder,
        other.mapOverlayBorder,
        t,
      )!,
      categoryColors: categoryColors.map(
        (key, value) => MapEntry(
          key,
          Color.lerp(value, other.categoryColors[key] ?? value, t)!,
        ),
      ),
    );
  }
}
