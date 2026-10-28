import 'package:flutter/material.dart';

import '../utils/context_ext.dart';

/// The single lookup for spot categories.
///
/// Icon lives here, color comes from the theme extension
/// (`context.tokens.categoryColor`), label comes from l10n
/// (`SpotCategoryLabel.label`). Stored in Hive by [name], never by index.
enum SpotCategory {
  other(Icons.place_rounded),
  restaurant(Icons.restaurant_rounded),
  fuel(Icons.local_gas_station_rounded),
  gym(Icons.fitness_center_rounded),
  mosque(Icons.mosque_rounded),
  market(Icons.shopping_cart_rounded),
  pharmacy(Icons.local_pharmacy_rounded),
  home(Icons.home_rounded),
  work(Icons.work_rounded),
  hospital(Icons.local_hospital_rounded),
  school(Icons.school_rounded),
  park(Icons.park_rounded),
  club(Icons.sports_soccer_rounded),
  beautyCenter(Icons.spa_rounded),
  car(Icons.directions_car_rounded);

  const SpotCategory(this.icon);

  final IconData icon;

  bool get isCar => this == SpotCategory.car;

  /// Categories available for user-created spots (excluding the special reserved car).
  static const List<SpotCategory> selectable = [
    SpotCategory.other,
    SpotCategory.restaurant,
    SpotCategory.fuel,
    SpotCategory.gym,
    SpotCategory.mosque,
    SpotCategory.market,
    SpotCategory.pharmacy,
    SpotCategory.home,
    SpotCategory.work,
    SpotCategory.hospital,
    SpotCategory.school,
    SpotCategory.park,
    SpotCategory.club,
    SpotCategory.beautyCenter,
  ];

  /// Resolves a stored name, falling back to [other] for unknown values.
  static SpotCategory fromName(String? name) {
    for (final category in values) {
      if (category.name == name) return category;
    }
    return SpotCategory.other;
  }
}

extension SpotCategoryLabel on SpotCategory {
  String label(BuildContext context) {
    final l10n = context.l10n;
    switch (this) {
      case SpotCategory.car:
        return l10n.categoryCar;
      case SpotCategory.market:
        return l10n.categoryMarket;
      case SpotCategory.home:
        return l10n.categoryHome;
      case SpotCategory.pharmacy:
        return l10n.categoryPharmacy;
      case SpotCategory.work:
        return l10n.categoryWork;
      case SpotCategory.restaurant:
        return l10n.categoryRestaurant;
      case SpotCategory.hospital:
        return l10n.categoryHospital;
      case SpotCategory.school:
        return l10n.categorySchool;
      case SpotCategory.gym:
        return l10n.categoryGym;
      case SpotCategory.mosque:
        return l10n.categoryMosque;
      case SpotCategory.fuel:
        return l10n.categoryFuel;
      case SpotCategory.park:
        return l10n.categoryPark;
      case SpotCategory.club:
        return l10n.categoryClub;
      case SpotCategory.beautyCenter:
        return l10n.categoryBeautyCenter;
      case SpotCategory.other:
        return l10n.categoryOther;
    }
  }
}
