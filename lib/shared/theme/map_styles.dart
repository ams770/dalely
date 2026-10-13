import 'dalely_map_style_data.dart';

/// Vector style definitions for MapLibre GL matching Dalely's aesthetic
/// (Simple, normal map colors with a subtle blue theme tint, no orange).
abstract final class MapStyles {
  /// Simple normal map style with subtle cool blue tint (green parks, clean blue water, white/cream roads).
  static const String light = DalelyMapStyleData.light;

  /// Simple normal dark map style with subtle midnight navy tint (deep blue water, clean slate roads).
  static const String dark = DalelyMapStyleData.dark;

  /// Standard CARTO Voyager vector tile style URL.
  static const String voyager =
      'https://basemaps.cartocdn.com/gl/voyager-gl-style/style.json';

  /// Standard CARTO Dark Matter vector tile style URL.
  static const String darkMatter =
      'https://basemaps.cartocdn.com/gl/dark-matter-gl-style/style.json';

  /// Standard CARTO Positron vector tile style URL.
  static const String positron =
      'https://basemaps.cartocdn.com/gl/positron-gl-style/style.json';
}
