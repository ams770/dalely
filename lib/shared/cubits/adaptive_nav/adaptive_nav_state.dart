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
  });

  final DetailPaneType detailPane;
  final String? selectedSpotId;
  final Spot? editingSpot;
  final int requestTimestamp;

  AdaptiveNavState copyWith({
    DetailPaneType? detailPane,
    ValueGetter<String?>? selectedSpotId,
    ValueGetter<Spot?>? editingSpot,
    int? requestTimestamp,
  }) {
    return AdaptiveNavState(
      detailPane: detailPane ?? this.detailPane,
      selectedSpotId: selectedSpotId != null
          ? selectedSpotId()
          : this.selectedSpotId,
      editingSpot: editingSpot != null ? editingSpot() : this.editingSpot,
      requestTimestamp: requestTimestamp ?? this.requestTimestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdaptiveNavState &&
          other.detailPane == detailPane &&
          other.selectedSpotId == selectedSpotId &&
          other.editingSpot == editingSpot &&
          other.requestTimestamp == requestTimestamp;

  @override
  int get hashCode =>
      Object.hash(detailPane, selectedSpotId, editingSpot, requestTimestamp);
}
