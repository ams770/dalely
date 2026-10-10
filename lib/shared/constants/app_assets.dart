import 'package:flutter/widgets.dart';

/// Centralized asset provider holding paths and [AssetImage] references for app assets.
abstract final class AssetProvider {
  /// Path to the car illustration/icon.
  static const String car = 'assets/images/car.png';

  /// [AssetImage] provider for the car image.
  static const AssetImage carImage = AssetImage(car);

  /// Onboarding illustration 1 (Car & pin).
  static const String onboarding1 = 'assets/images/onboarding_1.png';
  static const AssetImage onboarding1Image = AssetImage(onboarding1);

  /// Onboarding illustration 2 (Map & pins).
  static const String onboarding2 = 'assets/images/onboarding_2.png';
  static const AssetImage onboarding2Image = AssetImage(onboarding2);

  /// Onboarding illustration 3 (Phone & privacy shield).
  static const String onboarding3 = 'assets/images/onboarding_3.png';
  static const AssetImage onboarding3Image = AssetImage(onboarding3);
}

/// Alias for [AssetProvider].
typedef AppAssets = AssetProvider;
