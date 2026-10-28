import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../constants/app_assets.dart';
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

  double get pinSize {
    return switch (this) {
      MarkerZoomTier.high => 88.0,
      MarkerZoomTier.medium => 58.0,
      MarkerZoomTier.low => 38.0,
    };
  }

  Offset get anchor {
    return switch (this) {
      MarkerZoomTier.high => const Offset(0.5, 1.0),
      MarkerZoomTier.medium => const Offset(0.5, 1.0),
      MarkerZoomTier.low => const Offset(0.5, 0.5),
    };
  }
}

/// Pre-renders and caches custom map marker icons as PNG byte arrays.
class MarkerIconCache {
  MarkerIconCache._internal();
  static final MarkerIconCache _instance = MarkerIconCache._internal();
  factory MarkerIconCache() => _instance;

  final Map<String, Uint8List> _cache = {};
  ui.Image? _cachedCarImage;

  Future<ui.Image> _getCarImage() async {
    if (_cachedCarImage != null) return _cachedCarImage!;
    final byteData = await rootBundle.load(AssetProvider.car);
    final codec = await ui.instantiateImageCodec(byteData.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    _cachedCarImage = frame.image;
    return _cachedCarImage!;
  }

  /// Ground anchor for the car pin marker matching standard pin geometry.
  Offset carMarkerAnchor(MarkerZoomTier tier) => tier.anchor;

  /// Retrieves or creates a custom car pin marker with assets/images/car.png inside.
  Future<Uint8List> getCarMarker({
    Color color = const Color(0xFFFF8A65),
    bool isSelected = false,
    MarkerZoomTier tier = MarkerZoomTier.high,
  }) async {
    final key = 'car_pin_${color.toARGB32()}_${isSelected}_${tier.name}';
    final existing = _cache[key];
    if (existing != null) return existing;

    try {
      final bytes = await _renderCarPin(
        color: color,
        isSelected: isSelected,
        tier: tier,
      );
      _cache[key] = bytes;
      return bytes;
    } catch (_) {
      final bytes = await _renderCategoryPin(
        icon: SpotCategory.car.icon,
        color: color,
        isSelected: isSelected,
        tier: tier,
      );
      _cache[key] = bytes;
      return bytes;
    }
  }

  /// Retrieves or creates a category marker pin adapted for the given zoom tier.
  Future<Uint8List> getCategoryMarker({
    required SpotCategory category,
    required Color color,
    bool isSelected = false,
    MarkerZoomTier tier = MarkerZoomTier.high,
  }) async {
    if (category == SpotCategory.car) {
      return getCarMarker(color: color, isSelected: isSelected, tier: tier);
    }

    final key =
        '${category.name}_${color.toARGB32()}_${isSelected}_${tier.name}';
    final existing = _cache[key];
    if (existing != null) return existing;

    final bytes = await _renderCategoryPin(
      icon: category.icon,
      color: color,
      isSelected: isSelected,
      tier: tier,
    );
    _cache[key] = bytes;
    return bytes;
  }

  /// Retrieves or creates a custom user location marker (blue dot + direction cone).
  Future<Uint8List> getUserLocationMarker({
    required double heading,
  }) async {
    // Quantize heading to 5 degree buckets to avoid cache explosion
    final bucket = ((heading / 5).round() * 5) % 360;
    final key = 'user_location_$bucket';
    final existing = _cache[key];
    if (existing != null) return existing;

    const size = 110.0;
    final bytes = await _renderUserLocation(
      size: size,
      heading: bucket.toDouble(),
    );
    _cache[key] = bytes;
    return bytes;
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
    const width = 88.0;
    const height = 76.0;
    const scale = 3.0;
    final physicalWidth = (width * scale).toInt();
    final physicalHeight = (height * scale).toInt();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(scale, scale);

    final radius = isSelected ? 27.0 : 23.0;
    final center = Offset(width / 2, height - radius - 11.0);

    // Glowing halo when selected
    if (isSelected) {
      final glowPaint = Paint()
        ..color = color.withAlpha(80)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 7);
      canvas.drawCircle(center, radius + 6, glowPaint);
    }

    // Drop shadow
    final shadowPaint = Paint()
      ..color = const Color(0x38000000)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6);
    canvas.drawCircle(center.translate(0, 5), radius, shadowPaint);

    // Outer ring / border
    final ringPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius + 3.0, ringPaint);

    // Colored body
    final bodyPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bodyPaint);

    // Pin bottom pointer triangle (tip terminates precisely at height)
    final pointerPath = Path()
      ..moveTo(width / 2 - 7.5, center.dy + radius - 3)
      ..lineTo(width / 2 + 7.5, center.dy + radius - 3)
      ..lineTo(width / 2, height)
      ..close();
    canvas.drawPath(pointerPath, ringPaint);

    final innerPointerPath = Path()
      ..moveTo(width / 2 - 5.5, center.dy + radius - 3)
      ..lineTo(width / 2 + 5.5, center.dy + radius - 3)
      ..lineTo(width / 2, height - 3.0)
      ..close();
    canvas.drawPath(innerPointerPath, bodyPaint);

    // Icon in center
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: isSelected ? 28.0 : 23.0,
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
    final image = await picture.toImage(physicalWidth, physicalHeight);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _renderMediumZoomPin({
    required IconData icon,
    required Color color,
    required bool isSelected,
  }) async {
    const width = 58.0;
    const height = 50.0;
    const scale = 3.0;
    final physicalWidth = (width * scale).toInt();
    final physicalHeight = (height * scale).toInt();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(scale, scale);

    final radius = isSelected ? 19.0 : 16.0;
    final center = Offset(width / 2, height - radius - 7.5);

    // Glowing halo when selected
    if (isSelected) {
      final glowPaint = Paint()
        ..color = color.withAlpha(80)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5);
      canvas.drawCircle(center, radius + 4, glowPaint);
    }

    // Drop shadow
    final shadowPaint = Paint()
      ..color = const Color(0x30000000)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);
    canvas.drawCircle(center.translate(0, 3), radius, shadowPaint);

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

    // Pin bottom pointer triangle (tip terminates precisely at height)
    final pointerPath = Path()
      ..moveTo(width / 2 - 5, center.dy + radius - 2.5)
      ..lineTo(width / 2 + 5, center.dy + radius - 2.5)
      ..lineTo(width / 2, height)
      ..close();
    canvas.drawPath(pointerPath, ringPaint);

    final innerPointerPath = Path()
      ..moveTo(width / 2 - 3.5, center.dy + radius - 2.5)
      ..lineTo(width / 2 + 3.5, center.dy + radius - 2.5)
      ..lineTo(width / 2, height - 2.5)
      ..close();
    canvas.drawPath(innerPointerPath, bodyPaint);

    // Icon in center
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: isSelected ? 19.0 : 16.0,
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
    final image = await picture.toImage(physicalWidth, physicalHeight);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _renderLowZoomPin({
    required IconData icon,
    required Color color,
    required bool isSelected,
  }) async {
    const size = 38.0;
    const scale = 3.0;
    final physicalSize = (size * scale).toInt();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(scale, scale);

    const center = Offset(size / 2, size / 2);
    final radius = isSelected ? 13.0 : 11.0;

    // Drop shadow
    final shadowPaint = Paint()
      ..color = const Color(0x28000000)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3);
    canvas.drawCircle(center.translate(0, 2), radius, shadowPaint);

    // Outer ring
    final ringPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius + 2.0, ringPaint);

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
        fontSize: isSelected ? 12.5 : 10.5,
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
    final image = await picture.toImage(physicalSize, physicalSize);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _renderUserLocation({
    required double size,
    required double heading,
  }) async {
    const scale = 3.0;
    final physicalSize = (size * scale).toInt();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(scale, scale);

    final center = Offset(size / 2, size / 2);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate((heading * math.pi) / 180.0);
    canvas.translate(-center.dx, -center.dy);

    // Direction cone
    final coneGradient = ui.Gradient.radial(
      center,
      48.0,
      [const Color(0x553C79F3), const Color(0x003C79F3)],
      [0.2, 1.0],
    );
    final conePaint = Paint()
      ..shader = coneGradient
      ..style = PaintingStyle.fill;

    final conePath = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: 48.0),
        -math.pi / 2 - (math.pi / 5),
        (2 * math.pi / 5),
        false,
      )
      ..close();
    canvas.drawPath(conePath, conePaint);

    canvas.restore();

    // Pulse outer halo
    final haloPaint = Paint()
      ..color = const Color(0x333C79F3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 18.5, haloPaint);

    // White border ring
    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 10.5, borderPaint);

    // Blue center dot
    final dotPaint = Paint()
      ..color = const Color(0xFF3C79F3)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 7.5, dotPaint);

    final picture = recorder.endRecording();
    final image = await picture.toImage(physicalSize, physicalSize);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _renderCarPin({
    required Color color,
    required bool isSelected,
    required MarkerZoomTier tier,
  }) async {
    final image = await _getCarImage();
    return switch (tier) {
      MarkerZoomTier.high => _renderHighZoomCarPin(
        image: image,
        color: color,
        isSelected: isSelected,
      ),
      MarkerZoomTier.medium => _renderMediumZoomCarPin(
        image: image,
        color: color,
        isSelected: isSelected,
      ),
      MarkerZoomTier.low => _renderLowZoomCarPin(
        image: image,
        color: color,
        isSelected: isSelected,
      ),
    };
  }

  Future<Uint8List> _renderHighZoomCarPin({
    required ui.Image image,
    required Color color,
    required bool isSelected,
  }) async {
    const width = 88.0;
    const height = 76.0;
    const scale = 3.0;
    final physicalWidth = (width * scale).toInt();
    final physicalHeight = (height * scale).toInt();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(scale, scale);

    final radius = isSelected ? 27.0 : 23.0;
    final center = Offset(width / 2, height - radius - 11.0);

    // Glowing halo when selected
    if (isSelected) {
      final glowPaint = Paint()
        ..color = color.withAlpha(80)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 7);
      canvas.drawCircle(center, radius + 6, glowPaint);
    }

    // Drop shadow
    final shadowPaint = Paint()
      ..color = const Color(0x38000000)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 6);
    canvas.drawCircle(center.translate(0, 5), radius, shadowPaint);

    // Outer ring / border
    final ringPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius + 3.0, ringPaint);

    // Colored body
    final bodyPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bodyPaint);

    // Pin bottom pointer triangle (tip terminates precisely at height)
    final pointerPath = Path()
      ..moveTo(width / 2 - 7.5, center.dy + radius - 3)
      ..lineTo(width / 2 + 7.5, center.dy + radius - 3)
      ..lineTo(width / 2, height)
      ..close();
    canvas.drawPath(pointerPath, ringPaint);

    final innerPointerPath = Path()
      ..moveTo(width / 2 - 5.5, center.dy + radius - 3)
      ..lineTo(width / 2 + 5.5, center.dy + radius - 3)
      ..lineTo(width / 2, height - 3.0)
      ..close();
    canvas.drawPath(innerPointerPath, bodyPaint);

    // White badge disk inside pin
    final badgePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final badgeRadius = radius - 3.5;
    canvas.drawCircle(center, badgeRadius, badgePaint);

    // Car image inside badge
    final carWidth = isSelected ? 34.0 : 28.0;
    final carHeight = carWidth / 1.5;
    final dstRect = Rect.fromCenter(
      center: center,
      width: carWidth,
      height: carHeight,
    );
    final srcRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final carPaint = Paint()..filterQuality = ui.FilterQuality.high;
    canvas.drawImageRect(image, srcRect, dstRect, carPaint);

    final picture = recorder.endRecording();
    final renderedImage = await picture.toImage(physicalWidth, physicalHeight);
    final byteData = await renderedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _renderMediumZoomCarPin({
    required ui.Image image,
    required Color color,
    required bool isSelected,
  }) async {
    const width = 58.0;
    const height = 50.0;
    const scale = 3.0;
    final physicalWidth = (width * scale).toInt();
    final physicalHeight = (height * scale).toInt();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(scale, scale);

    final radius = isSelected ? 19.0 : 16.0;
    final center = Offset(width / 2, height - radius - 7.5);

    // Glowing halo when selected
    if (isSelected) {
      final glowPaint = Paint()
        ..color = color.withAlpha(80)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 5);
      canvas.drawCircle(center, radius + 4, glowPaint);
    }

    // Drop shadow
    final shadowPaint = Paint()
      ..color = const Color(0x30000000)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 4);
    canvas.drawCircle(center.translate(0, 3), radius, shadowPaint);

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

    // Pin bottom pointer triangle (tip terminates precisely at height)
    final pointerPath = Path()
      ..moveTo(width / 2 - 5, center.dy + radius - 2.5)
      ..lineTo(width / 2 + 5, center.dy + radius - 2.5)
      ..lineTo(width / 2, height)
      ..close();
    canvas.drawPath(pointerPath, ringPaint);

    final innerPointerPath = Path()
      ..moveTo(width / 2 - 3.5, center.dy + radius - 2.5)
      ..lineTo(width / 2 + 3.5, center.dy + radius - 2.5)
      ..lineTo(width / 2, height - 2.5)
      ..close();
    canvas.drawPath(innerPointerPath, bodyPaint);

    // White badge disk inside pin
    final badgePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final badgeRadius = radius - 2.5;
    canvas.drawCircle(center, badgeRadius, badgePaint);

    // Car image inside badge
    final carWidth = isSelected ? 23.0 : 18.0;
    final carHeight = carWidth / 1.5;
    final dstRect = Rect.fromCenter(
      center: center,
      width: carWidth,
      height: carHeight,
    );
    final srcRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final carPaint = Paint()..filterQuality = ui.FilterQuality.high;
    canvas.drawImageRect(image, srcRect, dstRect, carPaint);

    final picture = recorder.endRecording();
    final renderedImage = await picture.toImage(physicalWidth, physicalHeight);
    final byteData = await renderedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData!.buffer.asUint8List();
  }

  Future<Uint8List> _renderLowZoomCarPin({
    required ui.Image image,
    required Color color,
    required bool isSelected,
  }) async {
    const size = 38.0;
    const scale = 3.0;
    final physicalSize = (size * scale).toInt();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.scale(scale, scale);

    const center = Offset(size / 2, size / 2);
    final radius = isSelected ? 13.0 : 11.0;

    // Glowing halo when selected
    if (isSelected) {
      final glowPaint = Paint()
        ..color = color.withAlpha(80)
        ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3.5);
      canvas.drawCircle(center, radius + 3, glowPaint);
    }

    // Drop shadow
    final shadowPaint = Paint()
      ..color = const Color(0x28000000)
      ..maskFilter = const ui.MaskFilter.blur(ui.BlurStyle.normal, 3);
    canvas.drawCircle(center.translate(0, 2), radius, shadowPaint);

    // Outer ring
    final ringPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius + 2.0, ringPaint);

    // Colored body
    final bodyPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bodyPaint);

    // White badge disk inside pin
    final badgePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final badgeRadius = radius - 2.0;
    canvas.drawCircle(center, badgeRadius, badgePaint);

    // Car image inside badge
    final carWidth = isSelected ? 15.5 : 12.5;
    final carHeight = carWidth / 1.5;
    final dstRect = Rect.fromCenter(
      center: center,
      width: carWidth,
      height: carHeight,
    );
    final srcRect = Rect.fromLTWH(
      0,
      0,
      image.width.toDouble(),
      image.height.toDouble(),
    );
    final carPaint = Paint()..filterQuality = ui.FilterQuality.high;
    canvas.drawImageRect(image, srcRect, dstRect, carPaint);

    final picture = recorder.endRecording();
    final renderedImage = await picture.toImage(physicalSize, physicalSize);
    final byteData = await renderedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData!.buffer.asUint8List();
  }
}
