class OnboardingState {
  const OnboardingState({
    this.currentPage = 0,
    this.isCompleting = false,
  });

  final int currentPage;
  final bool isCompleting;

  bool get isLastPage => currentPage == 2;

  OnboardingState copyWith({
    int? currentPage,
    bool? isCompleting,
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      isCompleting: isCompleting ?? this.isCompleting,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OnboardingState &&
          other.currentPage == currentPage &&
          other.isCompleting == isCompleting;

  @override
  int get hashCode => Object.hash(currentPage, isCompleting);
}
