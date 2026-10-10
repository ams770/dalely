import 'package:flutter/material.dart';

/// The single lookup for spot categories.
///
/// Icon lives here, color comes from the theme extension
/// (`context.tokens.categoryColor`), label comes from l10n
/// (`SpotCategoryLabel.label`). Stored in Hive by [name], never by index.
enum SpotCategory {
  car(Icons.directions_car_rounded),
  market(Icons.shopping_cart_rounded),
  home(Icons.home_rounded),
  pharmacy(Icons.local_pharmacy_rounded),
  work(Icons.work_rounded),
  restaurant(Icons.restaurant_rounded),
  hospital(Icons.local_hospital_rounded),
  school(Icons.school_rounded),
  gym(Icons.fitness_center_rounded),
  mosque(Icons.mosque_rounded),
  fuel(Icons.local_gas_station_rounded),
  other(Icons.place_rounded);

  const SpotCategory(this.icon);

  final IconData icon;

  bool get isCar => this == SpotCategory.car;

  /// Resolves a stored name, falling back to [other] for unknown values.
  static SpotCategory fromName(String? name) {
    for (final category in values) {
      if (category.name == name) return category;
    }
    return SpotCategory.other;
  }
}
