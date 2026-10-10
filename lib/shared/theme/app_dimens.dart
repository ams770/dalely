import 'package:flutter/material.dart';

/// Spacing, radii, and sizing constants.
abstract final class AppDimens {
  // Spacing
  static const double space4 = 4.0;
  static const double space6 = 6.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;

  // Radii
  static const double radiusSmall = 10.0;
  static const double radiusMedium = 16.0;
  static const double radiusLarge = 24.0;
  static const double radiusFull = 999.0;

  static const BorderRadius borderRadiusSmall = BorderRadius.all(
    Radius.circular(radiusSmall),
  );
  static const BorderRadius borderRadiusMedium = BorderRadius.all(
    Radius.circular(radiusMedium),
  );
  static const BorderRadius borderRadiusLarge = BorderRadius.all(
    Radius.circular(radiusLarge),
  );
  static const BorderRadius borderRadiusFull = BorderRadius.all(
    Radius.circular(radiusFull),
  );

  // Minimum Touch Targets & Sizes
  static const double minTouchTarget = 48.0;
  static const double primaryButtonHeight = 56.0;
  static const double iconButtonSize = 44.0;
  static const double categoryBadgeSize = 44.0;
  static const double mapPreviewHeight = 140.0;

  // Image & Component Sizes
  static const double carImageHeight = 140.0;
  static const double carImageSize = 112.0;

  // Icon Sizes
  static const double iconSmall = 18.0;
  static const double iconMedium = 22.0;
  static const double iconLarge = 28.0;

  // Animations
  static const Duration animDurationShort = Duration(milliseconds: 250);
  static const Duration animDurationMedium = Duration(milliseconds: 400);
}
