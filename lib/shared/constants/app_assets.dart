import 'package:flutter/widgets.dart';

/// Centralized asset provider holding paths and [AssetImage] references for app assets.
abstract final class AssetProvider {
  /// Path to the car illustration/icon.
  static const String car = 'assets/images/car.png';

  /// [AssetImage] provider for the car image.
  static const AssetImage carImage = AssetImage(car);
}

/// Alias for [AssetProvider].
typedef AppAssets = AssetProvider;
