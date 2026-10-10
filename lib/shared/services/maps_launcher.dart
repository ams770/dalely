import 'dart:io';
import 'package:url_launcher/url_launcher.dart';

class MapsLauncher {
  const MapsLauncher();

  /// Opens turn-by-turn directions to the given coordinate in Google Maps or default maps app.
  Future<bool> openDirections({
    required double latitude,
    required double longitude,
    String? label,
  }) async {
    if (Platform.isIOS) {
      final googleMapsUri = Uri.parse(
        'comgooglemaps://?daddr=$latitude,$longitude&directionsmode=driving',
      );
      if (await canLaunchUrl(googleMapsUri)) {
        return launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
      }

      final appleMapsUri = Uri.parse(
        'https://maps.apple.com/?daddr=$latitude,$longitude&dirflg=d',
      );
      if (await canLaunchUrl(appleMapsUri)) {
        return launchUrl(appleMapsUri, mode: LaunchMode.externalApplication);
      }
    } else if (Platform.isAndroid) {
      final googleMapsUri = Uri.parse(
        'google.navigation:q=$latitude,$longitude',
      );
      if (await canLaunchUrl(googleMapsUri)) {
        return launchUrl(googleMapsUri, mode: LaunchMode.externalApplication);
      }

      final geoUri = Uri.parse(
        'geo:$latitude,$longitude?q=$latitude,$longitude${label != null ? '($label)' : ''}',
      );
      if (await canLaunchUrl(geoUri)) {
        return launchUrl(geoUri, mode: LaunchMode.externalApplication);
      }
    }

    // Universal fallback: Google Maps web directions URL
    final webUri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude',
    );
    return launchUrl(webUri, mode: LaunchMode.externalApplication);
  }

  /// Opens an external web URL or mailto.
  Future<bool> openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
