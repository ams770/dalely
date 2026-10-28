import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/cubits/spots/spots_cubit.dart';
import '../../../shared/cubits/spots/spots_state.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required this.spotsCubit,
  }) : super(const HomeState()) {
    scrollController.addListener(_onScroll);
    _lastSortOrder = spotsCubit.state.sortOrder;
    _spotsSubscription = spotsCubit.stream.listen((spotsState) {
      if (!isClosed) {
        if (spotsState.sortOrder != _lastSortOrder) {
          _lastSortOrder = spotsState.sortOrder;
          emit(state.copyWith(visibleCount: pageSize));
        } else if (state.visibleCount > spotsState.spots.length &&
            state.visibleCount > pageSize) {
          emit(state.copyWith(
            visibleCount: spotsState.spots.length > pageSize
                ? spotsState.spots.length
                : pageSize,
          ));
        }
      }
    });
  }

  static const int pageSize = 50;

  final SpotsCubit spotsCubit;
  final ScrollController scrollController = ScrollController();
  StreamSubscription<dynamic>? _spotsSubscription;
  SpotSortOrder? _lastSortOrder;
  bool _isLoadingMore = false;

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
    final total = spotsCubit.state.spots.length;
    if (state.visibleCount >= total) return;
    emit(state.copyWith(visibleCount: state.visibleCount + pageSize));
  }

  @override
  Future<void> close() {
    _spotsSubscription?.cancel();
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    return super.close();
  }
}
