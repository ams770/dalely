import '../../models/spot.dart';

enum SpotsStatus { initial, loading, success, failure }

enum SpotSortOrder {
  dateDesc,
  nearest,
  category,
  name,
}

class SpotsState {
  const SpotsState({
    this.status = SpotsStatus.initial,
    this.car,
    this.spots = const [],
    this.parkingHistory = const [],
    this.sortOrder = SpotSortOrder.dateDesc,
    this.favoriteSpotId,
    this.errorMessage,
  });

  final SpotsStatus status;
  final Spot? car;
  final List<Spot> spots;
  final List<Spot> parkingHistory;
  final SpotSortOrder sortOrder;
  final String? favoriteSpotId;
  final String? errorMessage;

  bool get hasCar => car != null;
  int get totalSavedCount => (car != null ? 1 : 0) + spots.length;

  Spot? get favoriteSpot {
    if (favoriteSpotId == null) return null;
    if (car?.id == favoriteSpotId) return car;
    for (final spot in spots) {
      if (spot.id == favoriteSpotId) return spot;
    }
    return null;
  }

  List<Spot> get allSpots => [
        ...?car != null ? [car!] : null,
        ...spots,
      ];

  SpotsState copyWith({
    SpotsStatus? status,
    Spot? car,
    bool clearCar = false,
    List<Spot>? spots,
    List<Spot>? parkingHistory,
    SpotSortOrder? sortOrder,
    String? favoriteSpotId,
    bool clearFavorite = false,
    String? errorMessage,
  }) {
    return SpotsState(
      status: status ?? this.status,
      car: clearCar ? null : (car ?? this.car),
      spots: spots ?? this.spots,
      parkingHistory: parkingHistory ?? this.parkingHistory,
      sortOrder: sortOrder ?? this.sortOrder,
      favoriteSpotId:
          clearFavorite ? null : (favoriteSpotId ?? this.favoriteSpotId),
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SpotsState &&
          other.status == status &&
          other.car == car &&
          other.sortOrder == sortOrder &&
          other.favoriteSpotId == favoriteSpotId &&
          other.errorMessage == errorMessage &&
          _listEquals(other.spots, spots) &&
          _listEquals(other.parkingHistory, parkingHistory);

  @override
  int get hashCode => Object.hash(
        status,
        car,
        sortOrder,
        favoriteSpotId,
        errorMessage,
        Object.hashAll(spots),
        Object.hashAll(parkingHistory),
      );

  static bool _listEquals(List<Spot> a, List<Spot> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
