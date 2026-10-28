import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/cubits/spots/spots_cubit.dart';
import 'parking_history_state.dart';

class ParkingHistoryCubit extends Cubit<ParkingHistoryState> {
  ParkingHistoryCubit({
    required this.spotsCubit,
  }) : super(const ParkingHistoryState()) {
    scrollController.addListener(_onScroll);
    _spotsSubscription = spotsCubit.stream.listen((spotsState) {
      if (!isClosed) {
        if (state.visibleCount > spotsState.parkingHistory.length &&
            state.visibleCount > pageSize) {
          emit(state.copyWith(
            visibleCount: spotsState.parkingHistory.length > pageSize
                ? spotsState.parkingHistory.length
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
    final total = spotsCubit.state.parkingHistory.length;
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
