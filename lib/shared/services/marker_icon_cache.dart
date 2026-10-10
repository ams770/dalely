import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../constants/spot_categories.dart';

enum MarkerZoomTier {
  high,
  medium,
  low;

  static MarkerZoomTier fromZoom(double zoom) {
    if (zoom >= 13.5) return MarkerZoomTier.high;
    if (zoom >= 10.5) return MarkerZoomTier.medium;
    return MarkerZoomTier.low;
  }

  Offset get anchor {
    return switch (this) {
      MarkerZoomTier.high => const Offset(0.5, 0.83),
      MarkerZoomTier.medium => const Offset(0.5, 0.81),
      MarkerZoomTier.low => const Offset(0.5, 0.5),
    };
  }
}

/// Pre-renders and caches custom Google Map markers.
class MarkerIconCache {
  MarkerIconCache();

  final Map<String, BitmapDescriptor> _cache = {};

  /// Retrieves or creates a category marker pin adapted for the given zoom tier.
  Future<BitmapDescriptor> getCategoryMarker({
    required SpotCategory category,
    required Color color,
    bool isSelected = false,
    MarkerZoomTier tier = MarkerZoomTier.high,
  }) async {
    final key = '${category.name}_${color.toARGB32()}_${isSelected}_${tier.name}';
    final existing = _cache[key];
    if (existing != null) return existing;

    final bytes = await _renderCategoryPin(
      icon: category.icon,
      color: color,
      isSelected: isSelected,
      tier: tier,
    );

    final descriptor = BitmapDescriptor.bytes(bytes);
    _cache[key] = descriptor;
    return descriptor;
  }

  /// Retrieves or creates a custom user location marker (blue dot + direction cone).
  Future<BitmapDescriptor> getUserLocationMarker({
    required double heading,
  }) async {
    // Quantize heading to 5 degree buckets to avoid cache explosion
    final bucket = ((heading / 5).round() * 5) % 360;
    final key = 'user_location_$bucket';
    final existing = _cache[key];
    if (existing != null) return existing;

    final bytes = await _renderUserLocation(heading: bucket.toDouble());
    final descriptor = BitmapDescriptor.bytes(bytes);
    _cache[key] = descriptor;
    return descriptor;
  }

  Future<Uint8List> _renderCategoryPin({
    required IconData icon,
    required Color color,
    required bool isSelected,
    required MarkerZoomTier tier,
  }) async {
    return switch (tier) {
      MarkerZoomTier.high => _renderHighZoomPin(
          icon: icon,
          color: color,
          isSelected: isSelected,
        ),
      MarkerZoomTier.medium => _renderMediumZoomPin(
          icon: icon,
          color: color,
          isSelected: isSelected,
        ),
      MarkerZoomTier.low => _renderLowZoomPin(
          icon: icon,
          color: color,
          isSelected: isSelected,
        ),
    };
  }

  Future<Uint8List> _renderHighZoomPin({
    required IconData icon,
    required Color color,
    required bool isSelected,
  }) async {
    const size = 72.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final center = const Offset(size / 2, size / 2 - 6);
    final radius = isSelected ? 23.0 : 19.0;

    // Drop shadow
    final shadowPaint = Paint()
      ..color = const Color(0x38000000)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5);
    canvas.drawCircle(center.translate(0, 4), radius, shadowPaint);

    // Outer ring / border
    final ringPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius + 2.5, ringPaint);

    // Colored body
    final bodyPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bodyPaint);

    // Pin bottom pointer triangle
    final pointerPath = Path()
      ..moveTo(size / 2 - 6, center.dy + radius - 2.5)
      ..lineTo(size / 2 + 6, center.dy + radius - 2.5)
      ..lineTo(size / 2, center.dy + radius + 9)
      ..close();
    canvas.drawPath(pointerPath, ringPaint);

    final innerPointerPath = Path()
      ..moveTo(size / 2 - 4.5, center.dy + radius - 2.5)
      ..lineTo(size / 2 + 4.5, center.dy + radius - 2.5)
      ..lineTo(size / 2, center.dy + radius + 6.5)
      ..close();
    canvas.drawPath(innerPointerPath, bodyPaint);

    // Icon in center
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: isSelected ? 23.0 : 19.0,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _renderMediumZoomPin({
    required IconData icon,
    required Color color,
    required bool isSelected,
  }) async {
    const size = 48.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    final center = const Offset(size / 2, size / 2 - 4);
    final radius = isSelected ? 16.0 : 13.0;

    // Drop shadow
    final shadowPaint = Paint()
      ..color = const Color(0x30000000)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3.5);
    canvas.drawCircle(center.translate(0, 2.5), radius, shadowPaint);

    // Outer ring / border
    final ringPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius + 2.0, ringPaint);

    // Colored body
    final bodyPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bodyPaint);

    // Pin bottom pointer triangle
    final pointerPath = Path()
      ..moveTo(size / 2 - 4, center.dy + radius - 2)
      ..lineTo(size / 2 + 4, center.dy + radius - 2)
      ..lineTo(size / 2, center.dy + radius + 6)
      ..close();
    canvas.drawPath(pointerPath, ringPaint);

    final innerPointerPath = Path()
      ..moveTo(size / 2 - 3, center.dy + radius - 2)
      ..lineTo(size / 2 + 3, center.dy + radius - 2)
      ..lineTo(size / 2, center.dy + radius + 4.5)
      ..close();
    canvas.drawPath(innerPointerPath, bodyPaint);

    // Icon in center
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: isSelected ? 16.0 : 13.0,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _renderLowZoomPin({
    required IconData icon,
    required Color color,
    required bool isSelected,
  }) async {
    const size = 32.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    const center = Offset(size / 2, size / 2);
    final radius = isSelected ? 11.0 : 9.0;

    // Drop shadow
    final shadowPaint = Paint()
      ..color = const Color(0x28000000)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 2.5);
    canvas.drawCircle(center.translate(0, 1.5), radius, shadowPaint);

    // Outer ring
    final ringPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius + 1.5, ringPaint);

    // Colored body
    final bodyPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bodyPaint);

    // Center icon
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: isSelected ? 10.5 : 8.5,
        fontFamily: icon.fontFamily,
        package: icon.fontPackage,
        color: Colors.white,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _renderUserLocation({required double heading}) async {
    const size = 96.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    const center = Offset(size / 2, size / 2);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate((heading * math.pi) / 180.0);
    canvas.translate(-center.dx, -center.dy);

    // Direction cone
    final coneGradient = ui.Gradient.radial(
      center,
      42.0,
      [
        const Color(0x553B82F6),
        const Color(0x003B82F6),
      ],
      [0.2, 1.0],
    );
    final conePaint = Paint()
      ..shader = coneGradient
      ..style = PaintingStyle.fill;

    final conePath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: 42.0),
        -math.pi / 2 - (math.pi / 5),
        (2 * math.pi / 5),
        false,
      )
      ..close();
    canvas.drawPath(conePath, conePaint);

    canvas.restore();

    // Pulse outer halo
    final haloPaint = Paint()
      ..color = const Color(0x333B82F6)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 16.0, haloPaint);

    // White border ring
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 9.0, borderPaint);

    // Blue center dot
    final dotPaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 6.5, dotPaint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
