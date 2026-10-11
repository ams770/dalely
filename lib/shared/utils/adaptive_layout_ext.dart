import 'package:flutter/widgets.dart';

extension AdaptiveLayoutContext on BuildContext {
  /// True if running on a tablet or unfolded foldable device (width >= 600 dp).
  bool get isWideScreen => MediaQuery.sizeOf(this).width >= 600;
}
