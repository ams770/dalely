import 'package:flutter_bloc/flutter_bloc.dart';

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
    emit(state.copyWith(detailPane: DetailPaneType.saveSpot));
  }

  void openSettings() {
    emit(state.copyWith(detailPane: DetailPaneType.settings));
  }

  void openSearch() {
    emit(state.copyWith(detailPane: DetailPaneType.search));
  }

  void closeDetail() {
    showMap();
  }
}
