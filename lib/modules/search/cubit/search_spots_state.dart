import 'package:flutter/foundation.dart';

import '../../../shared/constants/spot_categories.dart';
import '../../../shared/models/spot.dart';

class SearchSpotsState {
  const SearchSpotsState({
    this.query = '',
    this.matchingSpots = const [],
    this.selectedCategory,
    this.availableCategories = const [],
  });

  final String query;
  final List<Spot> matchingSpots;
  final SpotCategory? selectedCategory;
  final List<SpotCategory> availableCategories;

  SearchSpotsState copyWith({
    String? query,
    List<Spot>? matchingSpots,
    ValueGetter<SpotCategory?>? selectedCategory,
    List<SpotCategory>? availableCategories,
  }) {
    return SearchSpotsState(
      query: query ?? this.query,
      matchingSpots: matchingSpots ?? this.matchingSpots,
      selectedCategory: selectedCategory != null
          ? selectedCategory()
          : this.selectedCategory,
      availableCategories: availableCategories ?? this.availableCategories,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchSpotsState &&
          other.query == query &&
          other.selectedCategory == selectedCategory &&
          listEquals(other.matchingSpots, matchingSpots) &&
          listEquals(other.availableCategories, availableCategories);

  @override
  int get hashCode => Object.hash(
        query,
        selectedCategory,
        Object.hashAll(matchingSpots),
        Object.hashAll(availableCategories),
      );
}
