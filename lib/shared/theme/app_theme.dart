import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_dimens.dart';
import 'app_theme_extension.dart';

/// Configures light and dark [ThemeData] with comprehensive component themes.
abstract final class AppTheme {
  static const String fontFamily = 'ReadexPro';

  static ThemeData light() {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.lightPrimary,
      onPrimary: AppColors.lightOnPrimary,
      primaryContainer: AppColors.lightPrimaryContainer,
      onPrimaryContainer: AppColors.lightPrimaryDarker,
      secondary: AppColors.lightCar,
      onSecondary: AppColors.lightOnCar,
      secondaryContainer: AppColors.lightCarContainer,
      onSecondaryContainer: AppColors.lightCar,
      surface: AppColors.lightSurface,
      onSurface: AppColors.lightTextPrimary,
      surfaceContainerHighest: AppColors.lightSurfaceSecondary,
      onSurfaceVariant: AppColors.lightTextSecondary,
      outline: AppColors.lightBorder,
      outlineVariant: AppColors.lightBorder,
      error: AppColors.catHospitalLight,
      onError: Colors.white,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldBg: AppColors.lightBackground,
      extension: AppThemeExtension.light,
    );
  }

  static ThemeData dark() {
    final colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.darkPrimary,
      onPrimary: AppColors.darkOnPrimary,
      primaryContainer: AppColors.darkPrimaryContainer,
      onPrimaryContainer: AppColors.darkPrimary,
      secondary: AppColors.darkCar,
      onSecondary: AppColors.darkOnCar,
      secondaryContainer: AppColors.darkCarContainer,
      onSecondaryContainer: AppColors.darkCar,
      surface: AppColors.darkSurface,
      onSurface: AppColors.darkTextPrimary,
      surfaceContainerHighest: AppColors.darkSurfaceSecondary,
      onSurfaceVariant: AppColors.darkTextSecondary,
      outline: AppColors.darkBorder,
      outlineVariant: AppColors.darkBorder,
      error: AppColors.catHospitalDark,
      onError: Colors.white,
    );

    return _buildTheme(
      colorScheme: colorScheme,
      scaffoldBg: AppColors.darkBackground,
      extension: AppThemeExtension.dark,
    );
  }

  static ThemeData _buildTheme({
    required ColorScheme colorScheme,
    required Color scaffoldBg,
    required AppThemeExtension extension,
  }) {
    final isDark = colorScheme.brightness == Brightness.dark;

    final baseTextTheme =
        Typography.material2021(
          platform: TargetPlatform.iOS,
          colorScheme: colorScheme,
        ).black.apply(
          fontFamily: fontFamily,
          bodyColor: colorScheme.onSurface,
          displayColor: colorScheme.onSurface,
        );

    final textTheme = baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w400,
      ),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w400,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBg,
      textTheme: textTheme,
      extensions: [extension],

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(
          color: colorScheme.onSurface,
          size: AppDimens.iconMedium,
        ),
      ),

      // Card
      cardTheme: CardThemeData(
        color: colorScheme.surface,
        elevation: isDark ? 0 : 1,
        shadowColor: Colors.black.withAlpha(isDark ? 0 : 10),
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: AppDimens.borderRadiusLarge,
          side: BorderSide(
            color: colorScheme.outline.withAlpha(isDark ? 80 : 100),
            width: 1,
          ),
        ),
      ),

      // FilledButton (Primary thumb-zone actions)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          minimumSize: const Size(
            double.infinity,
            AppDimens.primaryButtonHeight,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppDimens.borderRadiusLarge,
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          elevation: 0,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppDimens.space24,
          ),
        ),
      ),

      // OutlinedButton
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          minimumSize: const Size(0, 42),
          side: BorderSide(color: colorScheme.outline, width: 1),
          shape: const RoundedRectangleBorder(
            borderRadius: AppDimens.borderRadiusMedium,
          ),
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppDimens.space16,
            vertical: AppDimens.space8,
          ),
        ),
      ),

      // TextButton
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark
              ? colorScheme.primary
              : AppColors.lightPrimaryDarker,
          textStyle: textTheme.labelLarge,
          padding: const EdgeInsetsDirectional.symmetric(
            horizontal: AppDimens.space12,
            vertical: AppDimens.space8,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppDimens.borderRadiusSmall,
          ),
        ),
      ),

      // IconButton
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          backgroundColor: colorScheme.surface,
          foregroundColor: colorScheme.onSurface,
          minimumSize: const Size(
            AppDimens.iconButtonSize,
            AppDimens.iconButtonSize,
          ),
          shape: const RoundedRectangleBorder(
            borderRadius: AppDimens.borderRadiusMedium,
          ),
          elevation: 0,
        ),
      ),

      // FloatingActionButton
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: AppDimens.borderRadiusMedium,
        ),
      ),

      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.surface,
        selectedColor: colorScheme.primaryContainer,
        disabledColor: colorScheme.surfaceContainerHighest,
        labelStyle: textTheme.labelLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        secondaryLabelStyle: textTheme.labelLarge?.copyWith(
          color: colorScheme.primary,
        ),
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppDimens.space12,
          vertical: AppDimens.space8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppDimens.borderRadiusFull,
          side: BorderSide(color: colorScheme.outline, width: 1),
        ),
        showCheckmark: false,
      ),

      // SegmentedButton
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.primary;
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return colorScheme.onPrimary;
            }
            return colorScheme.onSurfaceVariant;
          }),
          side: WidgetStatePropertyAll(
            BorderSide(color: colorScheme.outline, width: 1),
          ),
          shape: const WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: AppDimens.borderRadiusLarge),
          ),
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
          padding: const WidgetStatePropertyAll(
            EdgeInsetsDirectional.symmetric(
              horizontal: AppDimens.space16,
              vertical: AppDimens.space12,
            ),
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surface,
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppDimens.space20,
          vertical: AppDimens.space16,
        ),
        border: OutlineInputBorder(
          borderRadius: AppDimens.borderRadiusMedium,
          borderSide: BorderSide(color: colorScheme.outline, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppDimens.borderRadiusMedium,
          borderSide: BorderSide(color: colorScheme.outline, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppDimens.borderRadiusMedium,
          borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppDimens.borderRadiusMedium,
          borderSide: BorderSide(color: colorScheme.error, width: 1),
        ),
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      // ListTile
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppDimens.space16,
          vertical: AppDimens.space4,
        ),
        titleTextStyle: textTheme.titleMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
        subtitleTextStyle: textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
        iconColor: colorScheme.onSurfaceVariant,
        shape: const RoundedRectangleBorder(
          borderRadius: AppDimens.borderRadiusMedium,
        ),
      ),

      // BottomSheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark
            ? AppColors.darkBottomSheet
            : AppColors.lightBottomSheet,
        modalBackgroundColor: isDark
            ? AppColors.darkBottomSheet
            : AppColors.lightBottomSheet,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: colorScheme.outline.withAlpha(isDark ? 140 : 160),
        dragHandleSize: const Size(36, 4),
        elevation: 8,
        shadowColor: Colors.black.withAlpha(isDark ? 80 : 30),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadiusDirectional.vertical(
            top: Radius.circular(AppDimens.radiusLarge),
          ),
        ),
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: AppDimens.borderRadiusLarge,
        ),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: colorScheme.onSurface,
        ),
        contentTextStyle: textTheme.bodyLarge?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      // ProgressIndicator
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colorScheme.primary,
        linearTrackColor: colorScheme.primaryContainer,
        circularTrackColor: colorScheme.primaryContainer,
      ),

      // SnackBar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark
            ? const Color(0xFF1E293B)
            : const Color(0xFF12263F),
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: Colors.white),
        actionTextColor: isDark
            ? AppColors.darkPrimary
            : AppColors.lightPrimary,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: AppDimens.borderRadiusMedium,
        ),
      ),

      // Divider
      dividerTheme: DividerThemeData(
        color: colorScheme.outline.withAlpha(isDark ? 60 : 120),
        thickness: 1,
        space: 1,
      ),
    );
  }
}
