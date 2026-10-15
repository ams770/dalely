import 'dart:core';
import 'dart:io';

/// Holds the parsed latitude, longitude, and optional label extracted
/// from a location URI, map URL, or coordinates text.
class ParsedGeoLocation {
  const ParsedGeoLocation({
    required this.latitude,
    required this.longitude,
    this.label,
  });

  final double latitude;
  final double longitude;
  final String? label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParsedGeoLocation &&
          other.latitude == latitude &&
          other.longitude == longitude &&
          other.label == label;

  @override
  int get hashCode => Object.hash(latitude, longitude, label);

  @override
  String toString() =>
      'ParsedGeoLocation(lat: $latitude, lng: $longitude, label: $label)';
}

/// Robust parser for standard geographic URIs and map URLs:
/// - `geo:lat,lng`
/// - `geo:0,0?q=lat,lng`
/// - `geo:0,0?q=lat,lng(label)`
/// - `geo:lat,lng?q=...`
/// - `https://maps.google.com/?q=lat,lng`
/// - `https://www.google.com/maps?q=lat,lng`
/// - `https://www.google.com/maps/search/?api=1&query=lat,lng`
/// - `https://www.google.com/maps/@lat,lng,17z`
/// - `https://www.google.com/maps/place/PlaceName/@lat,lng,17z`
/// - `https://maps.apple.com/?ll=lat,lng`
/// - `https://maps.apple.com/?sll=lat,lng`
/// - `https://maps.apple.com/?q=lat,lng`
/// - `https://maps.apple.com/?q=label&ll=lat,lng`
/// - `https://maps.app.goo.gl/...` (via parseAsync)
/// - `https://goo.gl/maps/...` (via parseAsync)
/// - `feen://save?lat=...&lng=...&name=...`
abstract final class GeoUriParser {
  static final RegExp _coordRegex =
      RegExp(r'([+-]?\d{1,2}(?:\.\d+)?)\s*,\s*([+-]?\d{1,3}(?:\.\d+)?)');
  static final RegExp _atCoordRegex =
      RegExp(r'@([+-]?\d{1,2}(?:\.\d+)?)\s*,\s*([+-]?\d{1,3}(?:\.\d+)?)');
  static final RegExp _googleDataCoordRegex =
      RegExp(r'!3d([+-]?\d{1,2}(?:\.\d+)?)(?:!4d|.*?!4d)([+-]?\d{1,3}(?:\.\d+)?)');
  static final RegExp _labelInParenthesesRegex = RegExp(r'\(([^)]+)\)');
  static final RegExp _embeddedUrlRegex =
      RegExp(r'(https?://[^\s]+|geo:[^\s]+|feen:[^\s]+|dalely:[^\s]+)');
  static final RegExp _googlePlacePathRegex = RegExp(r'/(?:place|search)/([^/@?]+)');

  /// Safely percent-decodes a string without throwing [FormatException]
  /// if invalid or incomplete percent-sequences are encountered.
  static String safeDecode(String input) {
    try {
      return Uri.decodeFull(input);
    } catch (_) {
      try {
        return Uri.decodeComponent(input);
      } catch (_) {
        return input;
      }
    }
  }

  /// Cleans and extracts just the name of the place from any raw label,
  /// shared text, or Google Maps URL path.
  ///
  /// Works across all languages (Arabic, English, French, Japanese, Russian, etc.):
  /// - Strips full street addresses and postal codes after commas (`,`, `،`, `、`, `;`, `·`, `•`, `|`, ` - `).
  /// - Strips star ratings and review counts (`4.5 ★★★★☆ (1,234)` or `4.5★`).
  /// - Removes invisible directional formatting characters (`\u200E`, `\u200F`, etc.).
  /// - Removes generic dropped-pin / share placeholder text across languages.
  /// - Strips quotes, brackets, and extraneous symbols.
  static String? cleanPlaceName(String? raw) {
    if (raw == null) return null;
    var text = safeDecode(raw).trim();
    if (text.isEmpty) return null;

    // Strip invisible directional marks and zero-width spaces common in RTL/Arabic copy-paste
    text = text.replaceAll(RegExp(r'[\u200B-\u200F\u202A-\u202E\u2066-\u2069\uFEFF]'), '').trim();
    text = text.replaceAll('\u00A0', ' ');

    // 1. Replace '+' with spaces (common in URL query/paths)
    text = text.replaceAll('+', ' ').trim();

    // 2. Remove any embedded URLs
    text = text.replaceAll(_embeddedUrlRegex, '').trim();

    // 3. Remove standalone coordinates e.g. "24.7136, 46.6753"
    text = text.replaceAll(_coordRegex, '').trim();

    // 4. Strip star ratings e.g. "4.6 ★★★★☆ (1,234)" or "4.5★" or leading "4.5★ "
    text = text.replaceAll(RegExp(r'\b\d+(\.\d+)?\s*[★*]+.*$'), '').trim();
    text = text.replaceAll(RegExp(r'^[★*]+\s*\d*(\.\d+)?\s*'), '').trim();
    text = text.replaceAll(RegExp(r'^\d+(\.\d+)?\s*[★*]+\s*'), '').trim();

    // 5. Handle generic "Dropped pin" / "موقع تم وضع علامة عليه" phrases across languages
    final nearPatterns = [
      RegExp(r'^(?:موقع تم وضع علامة عليه|علامة موضع|موقع محدد)\s+بالقرب من\s+(.+)$', caseSensitive: false),
      RegExp(r'^(?:dropped pin|pinned location)\s+near\s+(.+)$', caseSensitive: false),
      RegExp(r'^(?:repère placé)\s+à proximité de\s+(.+)$', caseSensitive: false),
      RegExp(r'^(?:marcador colocado)\s+cerca de\s+(.+)$', caseSensitive: false),
      RegExp(r'^(?:gesetzte markierung)\s+in der nähe von\s+(.+)$', caseSensitive: false),
    ];

    for (final pattern in nearPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final extracted = match.group(1)?.trim();
        if (extracted != null && extracted.isNotEmpty) {
          text = extracted;
          break;
        }
      }
    }

    final lower = text.toLowerCase();
    final genericPhrases = [
      'موقع تم وضع علامة عليه',
      'علامة موضع',
      'موقع محدد',
      'موقع على الخريطة',
      'مشاركة موقع عبر خرائط google',
      'مشاركة موقع',
      'مشاركة الموقع',
      'dropped pin',
      'pinned location',
      'shared location',
      'repère placé',
      'marcador colocado',
      'gesetzte markierung',
    ];

    for (final phrase in genericPhrases) {
      if (lower == phrase || lower.startsWith('$phrase:') || lower.startsWith('$phrase -')) {
        return null;
      }
    }

    // 6. Split by delimiters to extract JUST the place name, not full address/city/postal code!
    // Supports English ',', Arabic '،' (\u060C), CJK '、' (\u3001), fullwidth comma '，' (\uFF0C), ';', middle dot '·', bullet '•', '|', and spaced dashes ' - '
    final delimiterRegex = RegExp(r'[,،、，;·•|]|\s+[-—]\s+');
    if (delimiterRegex.hasMatch(text)) {
      final parts = text.split(delimiterRegex);
      for (final part in parts) {
        final candidate = part.trim();
        if (candidate.isNotEmpty && !RegExp(r'^\d+$').hasMatch(candidate)) {
          text = candidate;
          break;
        }
      }
    }

    // 7. Strip surrounding quotes and brackets
    text = text.replaceAll(RegExp(r'^["' "'" r'«“‘\[\(]+|["' "'" r'»”’\]\)]+$'), '').trim();

    // 8. If text is empty or just punctuation/numbers, return null
    if (text.isEmpty || RegExp(r'^[\d\s\-_.,،;:]+$').hasMatch(text)) {
      return null;
    }

    return text;
  }

  /// Parses a given URI string, map link, or shared text into a [ParsedGeoLocation],
  /// or returns null if valid geographic coordinates could not be resolved synchronously.
  static ParsedGeoLocation? parse(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final decoded = safeDecode(trimmed);

    // 1. Check for custom app URI scheme (feen://save, dalely://save, etc.)
    final feenUri = Uri.tryParse(trimmed) ?? Uri.tryParse(decoded);
    if (feenUri != null &&
        (feenUri.scheme == 'feen' || feenUri.scheme == 'dalely')) {
      final dataParam = feenUri.queryParameters['data'];
      if (dataParam != null && dataParam.trim().isNotEmpty) {
        final parsedData = parse(dataParam);
        if (parsedData != null) return parsedData;
      }

      final latStr =
          feenUri.queryParameters['lat'] ?? feenUri.queryParameters['latitude'];
      final lngStr =
          feenUri.queryParameters['lng'] ?? feenUri.queryParameters['longitude'];
      if (latStr != null && lngStr != null) {
        final lat = double.tryParse(latStr);
        final lng = double.tryParse(lngStr);
        if (_isValidCoordinate(lat, lng)) {
          final name = cleanPlaceName(
            feenUri.queryParameters['name'] ??
                feenUri.queryParameters['label'] ??
                feenUri.queryParameters['title'],
          );
          return ParsedGeoLocation(
            latitude: lat!,
            longitude: lng!,
            label: name,
          );
        }
      }
    }

    // 2. Check if the text contains multiple lines or is preceded by a label with an embedded URL
    final isDirectScheme = decoded.startsWith('http://') ||
        decoded.startsWith('https://') ||
        decoded.startsWith('geo:') ||
        decoded.startsWith('feen:') ||
        decoded.startsWith('dalely:');

    if (!isDirectScheme || decoded.contains('\n')) {
      final urlMatch = _embeddedUrlRegex.firstMatch(decoded) ??
          _embeddedUrlRegex.firstMatch(trimmed);
      if (urlMatch != null) {
        final embeddedUrl = urlMatch.group(0)!;
        if (embeddedUrl != decoded && embeddedUrl != trimmed) {
          final urlResult = parse(embeddedUrl);
          final textLabel = _extractTextLabel(decoded, embeddedUrl);
          if (urlResult != null) {
            return ParsedGeoLocation(
              latitude: urlResult.latitude,
              longitude: urlResult.longitude,
              label: textLabel ?? urlResult.label,
            );
          }
        }
      }
    }

    // 3. Extract any label in parentheses e.g. geo:0,0?q=lat,lng(Label)
    String? label;
    final labelMatch = _labelInParenthesesRegex.firstMatch(decoded) ??
        _labelInParenthesesRegex.firstMatch(trimmed);
    if (labelMatch != null) {
      label = cleanPlaceName(labelMatch.group(1));
    }

    // 4. Handle geo: scheme
    if (decoded.startsWith('geo:') || trimmed.startsWith('geo:')) {
      final activeGeo = decoded.startsWith('geo:') ? decoded : trimmed;
      final ssp = activeGeo.substring(4);
      final queryIndex = ssp.indexOf('?');
      String pathPart = queryIndex == -1 ? ssp : ssp.substring(0, queryIndex);
      final queryString =
          queryIndex == -1 ? '' : ssp.substring(queryIndex + 1);

      // Check query parameter q=
      if (queryString.isNotEmpty) {
        final qParam = _extractQueryParam(queryString, 'q');
        if (qParam != null) {
          final coordMatch = _coordRegex.firstMatch(qParam);
          if (coordMatch != null) {
            final lat = double.tryParse(coordMatch.group(1)!);
            final lng = double.tryParse(coordMatch.group(2)!);
            if (_isValidCoordinate(lat, lng)) {
              return ParsedGeoLocation(
                latitude: lat!,
                longitude: lng!,
                label: label,
              );
            }
          }
        }
      }

      // Check the path coordinates (geo:lat,lng)
      final pathMatch = _coordRegex.firstMatch(pathPart);
      if (pathMatch != null) {
        final lat = double.tryParse(pathMatch.group(1)!);
        final lng = double.tryParse(pathMatch.group(2)!);
        if (_isValidCoordinate(lat, lng)) {
          if (lat != 0.0 || lng != 0.0 || queryString.isEmpty) {
            return ParsedGeoLocation(
              latitude: lat!,
              longitude: lng!,
              label: label,
            );
          }
        }
      }
    }

    // 5. Handle Apple Maps (maps.apple.com)
    if (decoded.contains('maps.apple.com') || trimmed.contains('maps.apple.com')) {
      final uri = Uri.tryParse(trimmed) ?? Uri.tryParse(decoded);
      if (uri != null) {
        final ll = uri.queryParameters['ll'] ??
            uri.queryParameters['sll'] ??
            uri.queryParameters['daddr'];
        if (ll != null) {
          final coordMatch = _coordRegex.firstMatch(ll);
          if (coordMatch != null) {
            final lat = double.tryParse(coordMatch.group(1)!);
            final lng = double.tryParse(coordMatch.group(2)!);
            if (_isValidCoordinate(lat, lng)) {
              final qLabel = cleanPlaceName(
                uri.queryParameters['q'] ?? uri.queryParameters['address'],
              );
              return ParsedGeoLocation(
                latitude: lat!,
                longitude: lng!,
                label: label ?? qLabel,
              );
            }
          }
        }

        final q = uri.queryParameters['q'];
        if (q != null) {
          final coordMatch = _coordRegex.firstMatch(q);
          if (coordMatch != null) {
            final lat = double.tryParse(coordMatch.group(1)!);
            final lng = double.tryParse(coordMatch.group(2)!);
            if (_isValidCoordinate(lat, lng)) {
              return ParsedGeoLocation(
                latitude: lat!,
                longitude: lng!,
                label: label,
              );
            }
          }
        }
      }
    }

    // 6. Handle Google Maps (maps.google.*, google.com/maps, maps.app.goo.gl, etc.)
    if (decoded.contains('maps.google.') ||
        decoded.contains('google.com/maps') ||
        decoded.contains('maps.app.goo.gl') ||
        decoded.contains('goo.gl/maps') ||
        trimmed.contains('maps.google.') ||
        trimmed.contains('google.com/maps') ||
        trimmed.contains('maps.app.goo.gl') ||
        trimmed.contains('goo.gl/maps')) {

      // Extract place name from URL path /place/Name or /search/Name
      String? extractedPlaceLabel = label;
      if (extractedPlaceLabel == null) {
        final placeMatch = _googlePlacePathRegex.firstMatch(decoded) ??
            _googlePlacePathRegex.firstMatch(trimmed);
        if (placeMatch != null) {
          extractedPlaceLabel = cleanPlaceName(placeMatch.group(1));
        }
      }

      if (extractedPlaceLabel == null) {
        final uri = Uri.tryParse(trimmed) ?? Uri.tryParse(decoded);
        if (uri != null) {
          final qVal = uri.queryParameters['q'] ?? uri.queryParameters['query'];
          if (qVal != null && !_coordRegex.hasMatch(qVal)) {
            extractedPlaceLabel = cleanPlaceName(qVal);
          }
        }
      }

      // 6a. Check @lat,lng in path e.g. /@24.7115,46.6744,17z
      final atMatch = _atCoordRegex.firstMatch(decoded) ??
          _atCoordRegex.firstMatch(trimmed);
      if (atMatch != null) {
        final lat = double.tryParse(atMatch.group(1)!);
        final lng = double.tryParse(atMatch.group(2)!);
        if (_isValidCoordinate(lat, lng)) {
          return ParsedGeoLocation(
            latitude: lat!,
            longitude: lng!,
            label: extractedPlaceLabel,
          );
        }
      }

      // 6b. Check !3d and !4d protobuf coordinates
      final dataMatch = _googleDataCoordRegex.firstMatch(decoded) ??
          _googleDataCoordRegex.firstMatch(trimmed);
      if (dataMatch != null) {
        final lat = double.tryParse(dataMatch.group(1)!);
        final lng = double.tryParse(dataMatch.group(2)!);
        if (_isValidCoordinate(lat, lng)) {
          return ParsedGeoLocation(
            latitude: lat!,
            longitude: lng!,
            label: extractedPlaceLabel,
          );
        }
      }

      // 6c. Check query params q=lat,lng or ll=lat,lng or query=lat,lng
      final uri = Uri.tryParse(trimmed) ?? Uri.tryParse(decoded);
      if (uri != null) {
        final qVal = uri.queryParameters['q'] ??
            uri.queryParameters['query'] ??
            uri.queryParameters['ll'] ??
            uri.queryParameters['daddr'] ??
            uri.queryParameters['destination'];
        if (qVal != null) {
          final coordMatch = _coordRegex.firstMatch(qVal);
          if (coordMatch != null) {
            final lat = double.tryParse(coordMatch.group(1)!);
            final lng = double.tryParse(coordMatch.group(2)!);
            if (_isValidCoordinate(lat, lng)) {
              return ParsedGeoLocation(
                latitude: lat!,
                longitude: lng!,
                label: extractedPlaceLabel,
              );
            }
          }
        }
      }
    }

    // 7. Generic query parameters or URL path search
    final uri = Uri.tryParse(trimmed) ?? Uri.tryParse(decoded);
    if (uri != null) {
      for (final value in uri.queryParameters.values) {
        final match = _coordRegex.firstMatch(value);
        if (match != null) {
          final lat = double.tryParse(match.group(1)!);
          final lng = double.tryParse(match.group(2)!);
          if (_isValidCoordinate(lat, lng)) {
            return ParsedGeoLocation(
              latitude: lat!,
              longitude: lng!,
              label: label,
            );
          }
        }
      }
    }

    // 8. General coordinates regex fallback anywhere in the text
    final genericMatch = _coordRegex.firstMatch(decoded) ??
        _coordRegex.firstMatch(trimmed);
    if (genericMatch != null) {
      final lat = double.tryParse(genericMatch.group(1)!);
      final lng = double.tryParse(genericMatch.group(2)!);
      if (_isValidCoordinate(lat, lng)) {
        final textLabel = label ?? _extractTextLabel(decoded, null);
        return ParsedGeoLocation(
          latitude: lat!,
          longitude: lng!,
          label: textLabel,
        );
      }
    }

    return null;
  }

  /// Extracts any textual label or place name from the raw shared payload,
  /// even when coordinates cannot be resolved.
  static String? extractLabel(String? raw) {
    if (raw == null) return null;
    var trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final feenUri = Uri.tryParse(trimmed) ?? Uri.tryParse(safeDecode(trimmed));
    if (feenUri != null &&
        (feenUri.scheme == 'feen' || feenUri.scheme == 'dalely')) {
      final dataParam = feenUri.queryParameters['data'];
      if (dataParam != null && dataParam.trim().isNotEmpty) {
        trimmed = dataParam.trim();
      }
    }

    final decoded = safeDecode(trimmed);

    // 1. If an embedded URL is present, look at the surrounding text
    final urlMatch = _embeddedUrlRegex.firstMatch(decoded) ??
        _embeddedUrlRegex.firstMatch(trimmed);
    final url = urlMatch?.group(0);
    final textLabel = _extractTextLabel(decoded, url);
    if (textLabel != null && textLabel.isNotEmpty) {
      return textLabel;
    }

    // 2. Check place path in Google Maps URL
    final placeMatch = _googlePlacePathRegex.firstMatch(decoded) ??
        _googlePlacePathRegex.firstMatch(trimmed);
    if (placeMatch != null) {
      final cleaned = cleanPlaceName(placeMatch.group(1));
      if (cleaned != null && cleaned.isNotEmpty) {
        return cleaned;
      }
    }

    // 3. Check query params q or address or query
    final uri = Uri.tryParse(trimmed) ?? Uri.tryParse(decoded);
    if (uri != null) {
      final q = uri.queryParameters['q'] ??
          uri.queryParameters['query'] ??
          uri.queryParameters['address'];
      if (q != null && !_coordRegex.hasMatch(q)) {
        final cleaned = cleanPlaceName(q);
        if (cleaned != null && cleaned.isNotEmpty) {
          return cleaned;
        }
      }
    }

    return null;
  }

  /// Asynchronously parses a payload, following HTTP redirects if a map short link
  /// (e.g. `maps.app.goo.gl`, `goo.gl/maps`, or generic short links) is detected.
  ///
  /// If redirect resolution fails or times out, returns the synchronous parse result or null.
  static Future<ParsedGeoLocation?> parseAsync(
    String? raw, {
    HttpClient? client,
    Duration timeout = const Duration(seconds: 4),
  }) async {
    if (raw == null) return null;
    var trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    // Check if raw is wrapped in feen:// or dalely:// scheme
    final feenUri = Uri.tryParse(trimmed) ?? Uri.tryParse(safeDecode(trimmed));
    if (feenUri != null &&
        (feenUri.scheme == 'feen' || feenUri.scheme == 'dalely')) {
      final dataParam = feenUri.queryParameters['data'];
      if (dataParam != null && dataParam.trim().isNotEmpty) {
        trimmed = dataParam.trim();
      }
    }

    // 1. Try immediate synchronous parse first
    final immediate = parse(trimmed);
    if (immediate != null) return immediate;

    // 2. Extract embedded URL if present
    final urlMatch = _embeddedUrlRegex.firstMatch(trimmed) ??
        _embeddedUrlRegex.firstMatch(safeDecode(trimmed));
    if (urlMatch == null) return null;

    final targetUrl = urlMatch.group(0)!;
    if (!targetUrl.startsWith('http://') && !targetUrl.startsWith('https://')) {
      return null;
    }

    final fallbackLabel = _extractTextLabel(trimmed, targetUrl);

    // 3. Follow HTTP redirects
    final resolvedUrl = await _resolveRedirectUrl(
      targetUrl,
      client: client,
      timeout: timeout,
    );

    if (resolvedUrl != null && resolvedUrl != targetUrl) {
      final resolvedParsed = parse(resolvedUrl);
      if (resolvedParsed != null) {
        return ParsedGeoLocation(
          latitude: resolvedParsed.latitude,
          longitude: resolvedParsed.longitude,
          label: fallbackLabel ?? resolvedParsed.label,
        );
      }
    }

    return null;
  }

  static Future<String?> _resolveRedirectUrl(
    String initialUrl, {
    HttpClient? client,
    Duration timeout = const Duration(seconds: 4),
  }) async {
    final shouldCloseClient = client == null;
    final httpClient = client ?? HttpClient();
    httpClient.connectionTimeout = timeout;

    try {
      final parsedUri = Uri.tryParse(initialUrl);
      if (parsedUri == null) return null;
      var currentUri = parsedUri;

      for (var hop = 0; hop < 5; hop++) {
        // If current URI already parses into coordinates, stop early
        if (parse(currentUri.toString()) != null) {
          return currentUri.toString();
        }

        final request = await httpClient.getUrl(currentUri).timeout(timeout);
        request.followRedirects = false;
        request.headers.set(
            HttpHeaders.userAgentHeader,
            'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15');

        final response = await request.close().timeout(timeout);
        await response.drain<void>().timeout(
          const Duration(seconds: 1),
          onTimeout: () {},
        );

        if (response.isRedirect) {
          final location = response.headers.value(HttpHeaders.locationHeader);
          if (location != null && location.trim().isNotEmpty) {
            final nextUri = currentUri.resolve(location.trim());
            currentUri = nextUri;
            if (parse(nextUri.toString()) != null) {
              return nextUri.toString();
            }
            continue;
          }
        }
        return currentUri.toString();
      }
      return currentUri.toString();
    } catch (_) {
      return null;
    } finally {
      if (shouldCloseClient) {
        httpClient.close(force: true);
      }
    }
  }

  static String? _extractTextLabel(String text, String? excludeUrl) {
    var cleaned = text;
    if (excludeUrl != null && excludeUrl.isNotEmpty) {
      cleaned = cleaned.replaceFirst(excludeUrl, '');
    }
    final lines = cleaned.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;
      // Skip if line is just coordinates e.g. "30.0444, 31.2357"
      final match = _coordRegex.firstMatch(trimmed);
      if (match != null && match.group(0)?.trim() == trimmed) {
        continue;
      }
      // Skip if line is just a URL or URI scheme
      if (trimmed.startsWith('http://') ||
          trimmed.startsWith('https://') ||
          trimmed.startsWith('geo:') ||
          trimmed.startsWith('feen:') ||
          trimmed.startsWith('dalely:')) {
        continue;
      }
      final cleanedPlace = cleanPlaceName(trimmed);
      if (cleanedPlace != null && cleanedPlace.isNotEmpty) {
        return cleanedPlace;
      }
    }
    return null;
  }

  static bool _isValidCoordinate(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    return lat >= -90.0 && lat <= 90.0 && lng >= -180.0 && lng <= 180.0;
  }

  static String? _extractQueryParam(String query, String key) {
    final pairs = query.split('&');
    for (final pair in pairs) {
      final kv = pair.split('=');
      if (kv.isNotEmpty && kv[0] == key) {
        return kv.length > 1 ? kv.sublist(1).join('=') : '';
      }
    }
    return null;
  }
}
