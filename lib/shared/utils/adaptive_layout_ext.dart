import 'dart:ui' show DisplayFeatureType;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

extension AdaptiveLayoutContext on BuildContext {
  /// True if running on a tablet or unfolded foldable device (width >= 600 dp).
  bool get isWideScreen => MediaQuery.sizeOf(this).width >= 670;
  bool get isSmallScreen => MediaQuery.sizeOf(this).height <= 680;
  double get width => MediaQuery.sizeOf(this).width;
  double get height => MediaQuery.sizeOf(this).height;

  /// True if running on a foldable or flip device in unfolded posture.

  bool get isFoldableDevice {
    final size = MediaQuery.sizeOf(this);
    
    if (size.width < 600) return false;

    // 1. Hardware display features (hinge / fold) - Android foldables
    final features = MediaQuery.displayFeaturesOf(this);
    final hasFoldFeature = features.any(
      (f) =>
          f.type == DisplayFeatureType.fold ||
          f.type == DisplayFeatureType.hinge,
    );

    if (hasFoldFeature) return true;

    // 2. Medium window size class (600 <= width < 840 dp)
    if (size.width < 840) return true;

    // 3. Squarish inner screens (e.g. Pixel Fold)
    final aspectRatio = size.width / size.height;
    if (size.width <= 920 && aspectRatio >= 0.8 && aspectRatio <= 1.35) {
      return true;
    }

    // 4. iPhone Duo inner display (~626x890 pt, ratio ~1:1.42, either
    // orientation). Flutter exposes no fold features on iOS, so detect by
    // size. Every iPad has a longest side well above 920 pt, which keeps
    // this from matching tablets.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final shortest = size.shortestSide;
      final longest = size.longestSide;
      final ratio = longest / shortest;
      if (shortest >= 600 && longest <= 920 && ratio >= 1.35 && ratio <= 1.5) {
        return true;
      }
    }

    return false;
  }

  /// True if running on a tablet (width >= 840 dp without a foldable hinge).
  bool get isTabletDevice => isWideScreen && !isFoldableDevice;
}
