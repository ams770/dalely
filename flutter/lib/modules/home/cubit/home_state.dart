class HomeState {
  const HomeState({
    this.visibleCount = 50,
  });

  final int visibleCount;

  HomeState copyWith({
    int? visibleCount,
  }) {
    return HomeState(
      visibleCount: visibleCount ?? this.visibleCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HomeState && other.visibleCount == visibleCount;

  @override
  int get hashCode => visibleCount.hashCode;
}
