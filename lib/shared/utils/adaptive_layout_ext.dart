import 'dart:ui' show DisplayFeatureType;
import 'package:flutter/widgets.dart';

extension AdaptiveLayoutContext on BuildContext {
  /// True if running on a tablet or unfolded foldable device (width >= 600 dp).
  bool get isWideScreen => MediaQuery.sizeOf(this).width >= 600;

  /// True if running on a foldable or flip device in unfolded posture.
  bool get isFoldableDevice {
    final size = MediaQuery.sizeOf(this);
    if (size.width < 600) return false;

    // 1. Hardware display features (hinge / fold)
    final features = MediaQuery.displayFeaturesOf(this);
    final hasFoldFeature = features.any(
      (f) =>
          f.type == DisplayFeatureType.fold ||
          f.type == DisplayFeatureType.hinge,
    );
    if (hasFoldFeature) return true;

    // 2. Medium window size class (600 <= width < 840 dp) is typical of
    // unfolded foldables (e.g. Galaxy Z Fold inner screen width ~ 673-768 dp).
    if (size.width < 840) return true;

    // 3. Foldables with wider inner screens (e.g. Pixel Fold 840x700 dp)
    // have a squarish aspect ratio (close to 1:1, ratio between 0.8 and 1.35).
    final aspectRatio = size.width / size.height;
    if (size.width <= 920 && aspectRatio >= 0.8 && aspectRatio <= 1.35) {
      return true;
    }

    return false;
  }

  /// True if running on a tablet (width >= 840 dp without a foldable hinge).
  bool get isTabletDevice => isWideScreen && !isFoldableDevice;
}
