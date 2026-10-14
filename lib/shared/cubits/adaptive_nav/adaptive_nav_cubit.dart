import 'package:flutter_bloc/flutter_bloc.dart';

import '../../models/spot.dart';
import 'adaptive_nav_state.dart';

class AdaptiveNavCubit extends Cubit<AdaptiveNavState> {
  AdaptiveNavCubit() : super(const AdaptiveNavState());

  void showMap({String? spotId}) {
    emit(state.copyWith(
      detailPane: DetailPaneType.map,
      selectedSpotId: () => spotId,
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

  void openSearch() {
    emit(state.copyWith(detailPane: DetailPaneType.search));
  }

  void openParkingHistory() {
    emit(state.copyWith(detailPane: DetailPaneType.parkingHistory));
  }

  void closeDetail() {
    showMap();
  }
}
