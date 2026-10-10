import 'package:flutter/material.dart';

/// Raw palette tokens for light and dark themes.
///
/// Feen design language:
/// - Soft indigo as primary brand / main actions
/// - Vibrant coral exclusively for the car
/// - Fresh green for home, vibrant tones for categories
/// - Clean layered neutral surfaces
abstract final class AppColors {
  // Light Palette
  static const Color lightPrimary = Color(0xFF4F46E5); // Indigo 600
  static const Color lightPrimaryContainer = Color(0xFFEEF2FF); // Indigo 50
  static const Color lightOnPrimary = Colors.white;

  static const Color lightCar = Color(0xFFFF6B4A); // Coral / Tangerine
  static const Color lightCarContainer = Color(0xFFFFECE5);
  static const Color lightOnCar = Colors.white;

  static const Color lightBackground = Color.fromARGB(255, 238, 240, 244);
  static const Color lightSurface = Colors.white;
  static const Color lightSurfaceSecondary = Color(0xFFF1F5F9);
  static const Color lightBottomSheet = Colors.white;
  static const Color lightBorder = Color(0xFFE2E8F0);

  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTextTertiary = Color(0xFF94A3B8);

  // Dark Palette
  static const Color darkPrimary = Color(0xFF6366F1); // Indigo 500
  static const Color darkPrimaryContainer = Color(0xFF1E1B4B); // Indigo 950
  static const Color darkOnPrimary = Colors.white;

  static const Color darkCar = Color(0xFFFF7A59);
  static const Color darkCarContainer = Color(0xFF3B1E16);
  static const Color darkOnCar = Colors.white;

  static const Color darkBackground = Color(0xFF0B0F19);
  static const Color darkSurface = Color(0xFF151C2C);
  static const Color darkSurfaceSecondary = Color(0xFF1E293B);
  static const Color darkBottomSheet = Color(0xFF0B0F19);
  static const Color darkBorder = Color(0xFF2E3B52);

  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextTertiary = Color(0xFF64748B);

  // Category Colors (Light / Dark pairs)
  static const Color catCarLight = Color(0xFFFF6B4A);
  static const Color catCarDark = Color(0xFFFF7A59);

  static const Color catMarketLight = Color(0xFF3B82F6); // Blue
  static const Color catMarketDark = Color(0xFF60A5FA);

  static const Color catHomeLight = Color(0xFF10B981); // Emerald
  static const Color catHomeDark = Color(0xFF34D399);

  static const Color catPharmacyLight = Color(0xFFEC4899); // Pink
  static const Color catPharmacyDark = Color(0xFFF472B6);

  static const Color catWorkLight = Color(0xFF8B5CF6); // Violet
  static const Color catWorkDark = Color(0xFFA78BFA);

  static const Color catRestaurantLight = Color(0xFFF59E0B); // Amber
  static const Color catRestaurantDark = Color(0xFFFBBF24);

  static const Color catHospitalLight = Color(0xFFEF4444); // Red
  static const Color catHospitalDark = Color(0xFFF87171);

  static const Color catSchoolLight = Color(0xFF06B6D4); // Cyan
  static const Color catSchoolDark = Color(0xFF22D3EE);

  static const Color catGymLight = Color(0xFF14B8A6); // Teal
  static const Color catGymDark = Color(0xFF2DD4BF);

  static const Color catMosqueLight = Color(0xFF059669); // Dark Green
  static const Color catMosqueDark = Color(0xFF10B981);

  static const Color catFuelLight = Color(0xFFD97706); // Orange-Amber
  static const Color catFuelDark = Color(0xFFF59E0B);

  static const Color catOtherLight = Color(0xFF6366F1); // Indigo
  static const Color catOtherDark = Color(0xFF818CF8);
}
