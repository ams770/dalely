class ParkingHistoryState {
  const ParkingHistoryState({this.visibleCount = 50});

  final int visibleCount;

  ParkingHistoryState copyWith({int? visibleCount}) {
    return ParkingHistoryState(visibleCount: visibleCount ?? this.visibleCount);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParkingHistoryState && other.visibleCount == visibleCount;

  @override
  int get hashCode => visibleCount.hashCode;
}
