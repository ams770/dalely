import 'package:flutter/foundation.dart';

enum DetailPaneType {
  map,
  saveSpot,
  settings,
  search;

  bool get isMap => this == DetailPaneType.map;
}

class AdaptiveNavState {
  const AdaptiveNavState({
    this.detailPane = DetailPaneType.map,
    this.selectedSpotId,
  });

  final DetailPaneType detailPane;
  final String? selectedSpotId;

  AdaptiveNavState copyWith({
    DetailPaneType? detailPane,
    ValueGetter<String?>? selectedSpotId,
  }) {
    return AdaptiveNavState(
      detailPane: detailPane ?? this.detailPane,
      selectedSpotId: selectedSpotId != null
          ? selectedSpotId()
          : this.selectedSpotId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdaptiveNavState &&
          other.detailPane == detailPane &&
          other.selectedSpotId == selectedSpotId;

  @override
  int get hashCode => Object.hash(detailPane, selectedSpotId);
}
