import 'package:flutter/foundation.dart';

import '../../../shared/constants/spot_categories.dart';
import '../../../shared/models/spot.dart';

class SearchSpotsState {
  const SearchSpotsState({
    this.query = '',
    this.matchingSpots = const [],
    this.selectedCategory,
  });

  final String query;
  final List<Spot> matchingSpots;
  final SpotCategory? selectedCategory;

  SearchSpotsState copyWith({
    String? query,
    List<Spot>? matchingSpots,
    ValueGetter<SpotCategory?>? selectedCategory,
  }) {
    return SearchSpotsState(
      query: query ?? this.query,
      matchingSpots: matchingSpots ?? this.matchingSpots,
      selectedCategory: selectedCategory != null
          ? selectedCategory()
          : this.selectedCategory,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchSpotsState &&
          other.query == query &&
          other.selectedCategory == selectedCategory &&
          listEquals(other.matchingSpots, matchingSpots);

  @override
  int get hashCode => Object.hash(
        query,
        selectedCategory,
        Object.hashAll(matchingSpots),
      );
}
