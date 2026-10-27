import 'package:flutter/material.dart';

import '../utils/adaptive_layout_ext.dart';

/// Listens for window/display expansion to the two-pane layout.
/// When the screen expands (e.g. device unfolded or rotated to wide landscape),
/// invokes [onExpandToTwoPane] so standalone routes can seamlessly collapse back into
/// the underlying two-pane Home layout.
class AdaptiveExpandListener extends StatelessWidget {
  const AdaptiveExpandListener({
    super.key,
    required this.child,
    required this.onExpandToTwoPane,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback onExpandToTwoPane;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (enabled && context.isTwoPaneLayout) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final modal = ModalRoute.of(context);
        if (modal != null && modal.isCurrent && modal.canPop) {
          onExpandToTwoPane();
        }
      });
    }
    return child;
  }
}
