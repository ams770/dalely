import 'package:flutter/foundation.dart';

import '../../models/spot.dart';

enum DetailPaneType {
  map,
  saveSpot,
  settings,
  search,
  parkingHistory;

  bool get isMap => this == DetailPaneType.map;
}

class AdaptiveNavState {
  const AdaptiveNavState({
    this.detailPane = DetailPaneType.map,
    this.selectedSpotId,
    this.editingSpot,
    this.requestTimestamp = 0,
    this.onlyShowSpot = false,
  });

  final DetailPaneType detailPane;
  final String? selectedSpotId;
  final Spot? editingSpot;
  final int requestTimestamp;
  final bool onlyShowSpot;

  AdaptiveNavState copyWith({
    DetailPaneType? detailPane,
    ValueGetter<String?>? selectedSpotId,
    ValueGetter<Spot?>? editingSpot,
    int? requestTimestamp,
    bool? onlyShowSpot,
  }) {
    return AdaptiveNavState(
      detailPane: detailPane ?? this.detailPane,
      selectedSpotId: selectedSpotId != null
          ? selectedSpotId()
          : this.selectedSpotId,
      editingSpot: editingSpot != null ? editingSpot() : this.editingSpot,
      requestTimestamp: requestTimestamp ?? this.requestTimestamp,
      onlyShowSpot: onlyShowSpot ?? this.onlyShowSpot,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdaptiveNavState &&
          other.detailPane == detailPane &&
          other.selectedSpotId == selectedSpotId &&
          other.editingSpot == editingSpot &&
          other.requestTimestamp == requestTimestamp &&
          other.onlyShowSpot == onlyShowSpot;

  @override
  int get hashCode => Object.hash(
        detailPane,
        selectedSpotId,
        editingSpot,
        requestTimestamp,
        onlyShowSpot,
      );
}
