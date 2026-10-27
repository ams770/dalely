import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/spot.dart';
import 'adaptive_nav_state.dart';

class AdaptiveNavCubit extends Cubit<AdaptiveNavState> {
  AdaptiveNavCubit() : super(const AdaptiveNavState());

  void showMap({String? spotId, bool onlyShowSpot = false}) {
    emit(state.copyWith(
      detailPane: DetailPaneType.map,
      selectedSpotId: () => spotId,
      onlyShowSpot: onlyShowSpot,
      requestTimestamp: DateTime.now().microsecondsSinceEpoch,
    ));
  }

  void openSaveSpot() {
    emit(state.copyWith(
      detailPane: DetailPaneType.saveSpot,
      editingSpot: () => null,
    ));
  }

  void openEditSpot(Spot spot) {
    emit(state.copyWith(
      detailPane: DetailPaneType.saveSpot,
      editingSpot: () => spot,
      requestTimestamp: DateTime.now().microsecondsSinceEpoch,
    ));
  }

  void openSettings() {
    emit(state.copyWith(detailPane: DetailPaneType.settings));
  }

  void openSearch({String? query}) {
    emit(state.copyWith(
      detailPane: DetailPaneType.search,
      searchQuery: () => query,
    ));
  }

  void openParkingHistory() {
    emit(state.copyWith(detailPane: DetailPaneType.parkingHistory));
  }

  void closeDetail() {
    emit(state.copyWith(searchQuery: () => null));
    showMap();
  }
}
