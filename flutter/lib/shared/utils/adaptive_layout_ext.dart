import 'dart:ui' show DisplayFeatureType;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

extension AdaptiveLayoutContext on BuildContext {
  /// True if running on a tablet or unfolded foldable device (width >= 650 dp).
  bool get isWideScreen => MediaQuery.sizeOf(this).width >= 650;
  bool get isSmallScreen => MediaQuery.sizeOf(this).height <= 680;
  double get width => MediaQuery.sizeOf(this).width;
  double get height => MediaQuery.sizeOf(this).height;

  /// True if the screen is in portrait orientation.
  bool get isPortrait => MediaQuery.orientationOf(this) == Orientation.portrait;

  /// True if the screen is in landscape orientation.
  bool get isLandscape =>
      MediaQuery.orientationOf(this) == Orientation.landscape;

  /// True if the split two-pane layout should be displayed (wide screen in landscape).
  /// In portrait, the page is not split but shown as a normal page.
  bool get isSplitLayout => isWideScreen;

  /// True if running on a foldable device with a vertical fold/hinge separating left and right displays.
  bool get hasVerticalHinge {
    final features = MediaQuery.displayFeaturesOf(this);
    final size = MediaQuery.sizeOf(this);
    return features.any(
      (f) =>
          (f.type == DisplayFeatureType.hinge ||
              f.type == DisplayFeatureType.fold) &&
          f.bounds.top <= 0 &&
          f.bounds.bottom >= size.height &&
          f.bounds.width > 1,
    );
  }

  /// True if the device is expanded to the wide two-pane split layout
  /// (either a wide landscape display or a foldable device with a vertical hinge,
  /// with sufficient vertical height).
  bool get isTwoPaneLayout =>
      (isSplitLayout || hasVerticalHinge) && height > 500;

  /// True if running on a dual-screen device in folded mode with a right-hand rail,
  /// or compact width with hardware status rail.
  bool get isDuoFolded {
    final padding = MediaQuery.paddingOf(this);
    if (padding.right >= 35 || padding.left >= 35) return true;
    final size = MediaQuery.sizeOf(this);
    return size.width >= 430 && size.width < 650 && size.height <= 720;
  }

  /// True if running on the left display of a dual-screen device (e.g. iPhone Duo left screen),
  /// where the hinge is on the right and the outer/thumb edge is on the physical left.
  bool get isDuoLeftScreen {
    if (!isDuoFolded) return false;

    // 1. Android / foldable display features: check if hinge is on the right of this window
    final features = MediaQuery.displayFeaturesOf(this);
    for (final f in features) {
      if ((f.type == DisplayFeatureType.hinge ||
              f.type == DisplayFeatureType.fold) &&
          f.bounds.left > 10) {
        return true;
      }
    }

    // 2. Hardware safe area insets:
    // On iPhone Duo in portrait, the hardware status rail (camera cutout, wifi, clock)
    // resides exclusively on the right edge of the right screen (padding.right >= 35).
    // If the device is flipped, it resides on the left (padding.left >= 35).
    // When the app is on the left display, padding.right is < 35 (the right edge touches the hinge),
    // and the outer ergonomic action rail resides on the physical left.
    final padding = MediaQuery.paddingOf(this);
    if (padding.left >= 35) return true;
    if (padding.right >= 35) return false;

    // Default for compact dual-screen without right rail: it's on the left screen
    return true;
  }

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
