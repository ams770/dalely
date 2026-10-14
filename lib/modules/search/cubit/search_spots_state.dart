import 'package:flutter/foundation.dart';

import '../../../shared/constants/spot_categories.dart';
import '../../../shared/models/spot.dart';

class SearchSpotsState {
  const SearchSpotsState({
    this.query = '',
    this.matchingSpots = const [],
    this.selectedCategory,
    this.availableCategories = const [],
    this.visibleCount = 50,
  });

  final String query;
  final List<Spot> matchingSpots;
  final SpotCategory? selectedCategory;
  final List<SpotCategory> availableCategories;
  final int visibleCount;

  SearchSpotsState copyWith({
    String? query,
    List<Spot>? matchingSpots,
    ValueGetter<SpotCategory?>? selectedCategory,
    List<SpotCategory>? availableCategories,
    int? visibleCount,
  }) {
    return SearchSpotsState(
      query: query ?? this.query,
      matchingSpots: matchingSpots ?? this.matchingSpots,
      selectedCategory: selectedCategory != null
          ? selectedCategory()
          : this.selectedCategory,
      availableCategories: availableCategories ?? this.availableCategories,
      visibleCount: visibleCount ?? this.visibleCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchSpotsState &&
          other.query == query &&
          other.selectedCategory == selectedCategory &&
          other.visibleCount == visibleCount &&
          listEquals(other.matchingSpots, matchingSpots) &&
          listEquals(other.availableCategories, availableCategories);

  @override
  int get hashCode => Object.hash(
        query,
        selectedCategory,
        visibleCount,
        Object.hashAll(matchingSpots),
        Object.hashAll(availableCategories),
      );
}
