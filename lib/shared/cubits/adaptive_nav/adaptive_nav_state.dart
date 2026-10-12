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
    this.requestTimestamp = 0,
  });

  final DetailPaneType detailPane;
  final String? selectedSpotId;
  final int requestTimestamp;

  AdaptiveNavState copyWith({
    DetailPaneType? detailPane,
    ValueGetter<String?>? selectedSpotId,
    int? requestTimestamp,
  }) {
    return AdaptiveNavState(
      detailPane: detailPane ?? this.detailPane,
      selectedSpotId: selectedSpotId != null
          ? selectedSpotId()
          : this.selectedSpotId,
      requestTimestamp: requestTimestamp ?? this.requestTimestamp,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AdaptiveNavState &&
          other.detailPane == detailPane &&
          other.selectedSpotId == selectedSpotId &&
          other.requestTimestamp == requestTimestamp;

  @override
  int get hashCode => Object.hash(detailPane, selectedSpotId, requestTimestamp);
}
