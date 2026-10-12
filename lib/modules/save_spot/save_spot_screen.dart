import 'package:flutter/material.dart';

import '../spots_map/cubit/spots_map_state.dart';
import '../spots_map/spots_map_screen.dart';

/// Legacy / convenience wrapper for opening the unified map in add spot mode.
class SaveSpotScreen extends StatelessWidget {
  const SaveSpotScreen({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return SpotsMapScreen(
      initialMode: SpotsMapMode.addSpot,
      onClose: onClose,
      
    );
  }
}
