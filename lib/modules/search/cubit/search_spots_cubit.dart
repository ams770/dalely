import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/constants/spot_categories.dart';
import '../../../shared/cubits/spots/spots_cubit.dart';
import '../../../shared/models/spot.dart';
import 'search_spots_state.dart';

class SearchSpotsCubit extends Cubit<SearchSpotsState> {
  SearchSpotsCubit({
    required this.spotsCubit,
  }) : super(
          SearchSpotsState(
            matchingSpots: spotsCubit.state.allSpots,
            availableCategories:
                _computeAvailableCategories(spotsCubit.state.allSpots),
          ),
        ) {
    textController.addListener(_onControllerChanged);
    _spotsSubscription = spotsCubit.stream.listen((_) {
      if (!isClosed) {
        _applyFilter();
      }
    });
  }

  final SpotsCubit spotsCubit;
  final TextEditingController textController = TextEditingController();
  StreamSubscription<dynamic>? _spotsSubscription;

  static List<SpotCategory> _computeAvailableCategories(List<Spot> spots) {
    final presentCategories = spots.map((s) => s.category).toSet();
    return SpotCategory.values
        .where((cat) => presentCategories.contains(cat))
        .toList();
  }

  void _onControllerChanged() {
    final newQuery = textController.text;
    if (newQuery != state.query) {
      onQueryChanged(newQuery);
    }
  }

  void onQueryChanged(String query) {
    emit(state.copyWith(query: query));
    _applyFilter();
  }

  void clearQuery() {
    textController.clear();
    emit(state.copyWith(query: ''));
    _applyFilter();
  }

  void toggleCategory(SpotCategory category) {
    if (state.selectedCategory == category) {
      emit(state.copyWith(selectedCategory: () => null));
    } else {
      emit(state.copyWith(selectedCategory: () => category));
    }
    _applyFilter();
  }

  void _applyFilter() {
    final allSpots = spotsCubit.state.allSpots;
    final availableCategories = _computeAvailableCategories(allSpots);
    final normalizedQuery = _normalize(state.query.trim());
    var selectedCat = state.selectedCategory;

    if (selectedCat != null && !availableCategories.contains(selectedCat)) {
      selectedCat = null;
    }

    final filtered = allSpots.where((spot) {
      if (selectedCat != null && spot.category != selectedCat) {
        return false;
      }

      if (normalizedQuery.isEmpty) {
        return true;
      }

      final normalizedName = _normalize(spot.name);
      final normalizedCategoryName = _normalize(spot.category.name);

      return normalizedName.contains(normalizedQuery) ||
          normalizedCategoryName.contains(normalizedQuery);
    }).toList();

    emit(state.copyWith(
      matchingSpots: filtered,
      availableCategories: availableCategories,
      selectedCategory: () => selectedCat,
    ));
  }

  static String _normalize(String input) {
    if (input.isEmpty) return '';
    var text = input.toLowerCase();

    // Arabic normalization
    text = text
        .replaceAll(RegExp(r'[\u064B-\u0652]'), '') // remove tashkeel
        .replaceAll(RegExp(r'[أإآٱ]'), 'ا')
        .replaceAll('ة', 'ه')
        .replaceAll('ى', 'ي');

    return text;
  }

  @override
  Future<void> close() {
    _spotsSubscription?.cancel();
    textController.removeListener(_onControllerChanged);
    textController.dispose();
    return super.close();
  }
}
