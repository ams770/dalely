import 'package:flutter/material.dart';

/// Raw palette tokens for light and dark themes.
///
/// Dalely design language:
/// - Primary light blue (#3C79F3) for main brand actions & buttons
/// - Darker blue (#0B6FBF) for small links and icons
/// - Pale blue (#F3F9FF) for soft surfaces, chips, and tracks
/// - Deep navy (#12263F) for text and dark elements
/// - Coral (#FF8A65) exclusively for the car
/// - Clean layered neutral surfaces
abstract final class AppColors {
  // Light Palette
  static const Color lightPrimary = Color(0xFF3C79F3); // Primary light blue
  static const Color lightPrimaryDarker = Color(
    0xFF0B6FBF,
  ); // Darker blue (links & icons)
  static const Color lightPrimaryContainer = Color(
    0xFFF3F9FF,
  ); // Pale blue background
  static const Color lightOnPrimary = Colors.white;

  static const Color lightCar = Color(0xFFFF8A65); // Coral
  static const Color lightCarContainer = Color(0xFFFFF0EC);
  static const Color lightOnCar = Colors.white;

  static const Color lightBackground = Color(
    0xFFEBEFF4,
  ); // Pale blue backgrounds
  static const Color lightSurface = Colors.white;
  static const Color lightSurfaceSecondary = Color(0xFFF3F9FF);
  static const Color lightBottomSheet = Colors.white;
  static const Color lightBorder = Color(0xFFE2E8F0);

  static const Color lightTextPrimary = Color(0xFF12263F); // Deep Navy
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTextTertiary = Color(0xFF94A3B8);

  // Dark Palette
  static const Color darkPrimary = Color(0xFF3C79F3); // Light blue
  static const Color darkPrimaryContainer = Color(0xFF12263F); // Deep Navy
  static const Color darkOnPrimary = Colors.white;

  static const Color darkCar = Color(0xFFFF8A65); // Coral
  static const Color darkCarContainer = Color(0xFF3B1E16);
  static const Color darkOnCar = Colors.white;

  static const Color darkBackground = Color(0xFF0B131F); // Slate navy
  static const Color darkSurface = Color(0xFF12263F); // Deep Navy
  static const Color darkSurfaceSecondary = Color(0xFF1E293B);
  static const Color darkBottomSheet = Color(0xFF0B131F);
  static const Color darkBorder = Color(0xFF223D5F);
  static const Color darkMapBackground = Color(0xFF1D2C42);

  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextTertiary = Color(0xFF64748B);

  // Category Colors (Light / Dark pairs)
  static const Color catCarLight = Color(0xFFFF8A65); // Coral
  static const Color catCarDark = Color(0xFFFF8A65);

  static const Color catMarketLight = Color(0xFF3C79F3); // Light blue
  static const Color catMarketDark = Color(0xFF38BDF8);

  static const Color catHomeLight = Color(0xFF10B981); // Emerald
  static const Color catHomeDark = Color(0xFF34D399);

  static const Color greenLight = Color.fromARGB(255, 129, 238, 216);
  static const Color greenDark = Color.fromARGB(255, 16, 106, 88);

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

  static const Color catParkLight = Color(0xFF16A34A); // Emerald/Green
  static const Color catParkDark = Color(0xFF4ADE80);

  static const Color catClubLight = Color(0xFF6366F1); // Indigo
  static const Color catClubDark = Color(0xFF818CF8);

  static const Color catBeautyCenterLight = Color(0xFFE11D48); // Rose
  static const Color catBeautyCenterDark = Color(0xFFFB7185);

  static const Color catOtherLight = Color(0xFF3C79F3); // Light blue
  static const Color catOtherDark = Color(0xFF38BDF8);

  // Friendly Alert / SnackBar
  static const Color alertDark = Color(0xFF24262A); // Dark charcoal pill
  static const Color alertLight = Colors.white; // Light white pill
  static const Color alertSuccessBadge = Color(0xFF0E9E75); // Emerald green badge
  static const Color alertSuccessIcon = Color(0xFF0B241A); // Dark checkmark icon
  static const Color alertActionDark = Color(0xFF4C82F7); // Action blue in dark mode
}

