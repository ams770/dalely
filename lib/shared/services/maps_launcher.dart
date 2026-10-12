import 'dart:io';
import 'package:in_app_review/in_app_review.dart';
import 'package:url_launcher/url_launcher.dart';

import '../constants/app_links.dart';

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
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }

  /// Opens the store listing or in-app review to rate the app.
  Future<void> openStoreReview() async {
    final inAppReview = InAppReview.instance;
    try {
      if (Platform.isAndroid) {
        await inAppReview.openStoreListing();
        return;
      } else if (Platform.isIOS) {
        if (await inAppReview.isAvailable()) {
          await inAppReview.requestReview();
          return;
        }
      } else {
        await inAppReview.openStoreListing();
        return;
      }
    } catch (_) {
      // Fall through to launcher fallback
    }

    final launchedMarket = await openUrl(AppLinks.playStoreMarket);
    if (!launchedMarket) {
      await openUrl(AppLinks.playStore);
    }
  }
}
