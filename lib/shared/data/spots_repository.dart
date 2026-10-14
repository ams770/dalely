import 'package:hive_ce/hive_ce.dart';

import '../constants/spot_categories.dart';
import '../constants/storage_keys.dart';
import '../models/spot.dart';

/// The only place that reads/writes the spots box.
class SpotsRepository {
  const SpotsRepository(this._box);

  final Box<Spot> _box;

  List<Spot> getAll() => _box.values.toList(growable: false);

  Spot? getById(String id) => _box.get(id);

  /// Emits the full list after every change.
  Stream<List<Spot>> watch() => _box.watch().map((_) => getAll());

  Future<void> save(Spot spot) => _box.put(spot.id, spot);

  Future<void> delete(String id) => _box.delete(id);

  /// Overwrites the single car spot.
  Future<Spot> parkCar({
    required double latitude,
    required double longitude,
  }) async {
    final car = Spot(
      id: StorageKeys.carId,
      name: '',
      category: SpotCategory.car,
      latitude: latitude,
      longitude: longitude,
      savedAt: DateTime.now(),
      status: SpotStatus.parking,
    );
    await _box.put(car.id, car);
    return car;
  }

  /// Unique id for a new (non-car) spot.
  String newId() => DateTime.now().microsecondsSinceEpoch.toRadixString(36);
}
