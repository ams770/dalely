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
            visibleCount: pageSize,
          ),
        ) {
    textController.addListener(_onControllerChanged);
    scrollController.addListener(_onScroll);
    _spotsSubscription = spotsCubit.stream.listen((_) {
      if (!isClosed) {
        _applyFilter();
      }
    });
  }

  static const int pageSize = 50;

  final SpotsCubit spotsCubit;
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  StreamSubscription<dynamic>? _spotsSubscription;
  bool _isLoadingMore = false;

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

  void _onScroll() {
    if (!scrollController.hasClients || _isLoadingMore) return;
    final position = scrollController.position;
    if (!position.hasContentDimensions) return;
    if (position.maxScrollExtent > 0 &&
        position.pixels >= position.maxScrollExtent - 200) {
      _isLoadingMore = true;
      loadMore();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!isClosed) {
          _isLoadingMore = false;
        }
      });
    }
  }

  void loadMore() {
    final total = state.matchingSpots.length;
    if (state.visibleCount >= total) return;
    emit(state.copyWith(visibleCount: state.visibleCount + pageSize));
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
      visibleCount: pageSize,
    ));

    if (scrollController.hasClients) {
      scrollController.jumpTo(0);
    }
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
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    return super.close();
  }
}
