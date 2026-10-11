import 'package:flutter/material.dart';

import '../constants/spot_categories.dart';
import '../theme/app_dimens.dart';
import '../utils/context_ext.dart';

/// The central fixed pin shown over the map while picking location.
/// Lifts subtly when the camera is moving.
class CenterPin extends StatelessWidget {
  const CenterPin({
    super.key,
    required this.category,
    this.isCameraMoving = false,
  });

  final SpotCategory category;
  final bool isCameraMoving;

  @override
  Widget build(BuildContext context) {
    final color = context.tokens.categoryColor(category);

    return IgnorePointer(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Hint Bubble
          AnimatedOpacity(
            duration: const Duration(milliseconds: 200),
            opacity: isCameraMoving ? 0.0 : 1.0,
            child: Container(
              margin: const EdgeInsets.only(bottom: AppDimens.space8),
              padding: const EdgeInsetsDirectional.symmetric(
                horizontal: AppDimens.space12,
                vertical: AppDimens.space6,
              ),
              decoration: BoxDecoration(
                color: context.colorScheme.surface,
                borderRadius: AppDimens.borderRadiusFull,
                border: Border.all(
                  color: context.colorScheme.outline.withAlpha(120),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                context.l10n.movePinHint,
                style: context.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // Animated Pin
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            transform: Matrix4.translationValues(0, isCameraMoving ? -14 : 0, 0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: color.withAlpha(90),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    category.icon,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                // Pointer tip
                CustomPaint(
                  size: const Size(14, 10),
                  painter: _PinTipPainter(color: color),
                ),
              ],
            ),
          ),

          // Shadow on ground
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: isCameraMoving ? 16 : 24,
            height: isCameraMoving ? 6 : 8,
            decoration: BoxDecoration(
              color: Colors.black.withAlpha(isCameraMoving ? 30 : 60),
              borderRadius: AppDimens.borderRadiusFull,
            ),
          ),
        ],
      ),
    );
  }
}

class _PinTipPainter extends CustomPainter {
  const _PinTipPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _PinTipPainter oldDelegate) =>
      oldDelegate.color != color;
}
