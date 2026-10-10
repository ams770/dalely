import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../shared/constants/spot_categories.dart';
import '../../../shared/models/place_result.dart';

enum SaveSpotStatus { idle, saving, success, failure }

class SaveSpotState {
  const SaveSpotState({
    this.status = SaveSpotStatus.idle,
    this.target = const LatLng(30.0444, 31.2357),
    this.name = '',
    this.category = SpotCategory.other,
    this.isCameraMoving = false,
    this.isSearching = false,
    this.searchQuery = '',
    this.searchResults = const [],
    this.showResults = false,
    this.errorMessage,
  });

  final SaveSpotStatus status;
  final LatLng target;
  final String name;
  final SpotCategory category;
  final bool isCameraMoving;
  final bool isSearching;
  final String searchQuery;
  final List<PlaceResult> searchResults;
  final bool showResults;
  final String? errorMessage;

  bool get canSave => name.trim().isNotEmpty && status != SaveSpotStatus.saving;

  SaveSpotState copyWith({
    SaveSpotStatus? status,
    LatLng? target,
    String? name,
    SpotCategory? category,
    bool? isCameraMoving,
    bool? isSearching,
    String? searchQuery,
    List<PlaceResult>? searchResults,
    bool? showResults,
    String? errorMessage,
  }) {
    return SaveSpotState(
      status: status ?? this.status,
      target: target ?? this.target,
      name: name ?? this.name,
      category: category ?? this.category,
      isCameraMoving: isCameraMoving ?? this.isCameraMoving,
      isSearching: isSearching ?? this.isSearching,
      searchQuery: searchQuery ?? this.searchQuery,
      searchResults: searchResults ?? this.searchResults,
      showResults: showResults ?? this.showResults,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SaveSpotState &&
          other.status == status &&
          other.target == target &&
          other.name == name &&
          other.category == category &&
          other.isCameraMoving == isCameraMoving &&
          other.isSearching == isSearching &&
          other.searchQuery == searchQuery &&
          other.showResults == showResults &&
          other.errorMessage == errorMessage &&
          _listEquals(other.searchResults, searchResults);

  @override
  int get hashCode => Object.hash(
        status,
        target,
        name,
        category,
        isCameraMoving,
        isSearching,
        searchQuery,
        showResults,
        errorMessage,
        Object.hashAll(searchResults),
      );

  static bool _listEquals(List<PlaceResult> a, List<PlaceResult> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
