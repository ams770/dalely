import 'package:hive_ce/hive_ce.dart';

import '../../constants/spot_categories.dart';
import '../spot.dart';

/// Hand-written adapter for [Spot]. Type id `0` is permanent.
///
/// Layout: field count, then fields in this exact order. New fields are only
/// ever appended and read with a default when the stored count is smaller.
class SpotAdapter extends TypeAdapter<Spot> {
  static const int _fieldCount = 8;

  @override
  final int typeId = 0;

  @override
  Spot read(BinaryReader reader) {
    final count = reader.readByte();
    final id = reader.readString();
    final name = reader.readString();
    final category = SpotCategory.fromName(reader.readString());
    final latitude = reader.readDouble();
    final longitude = reader.readDouble();
    final savedAt = DateTime.fromMillisecondsSinceEpoch(reader.readInt());
    final status = count > 6
        ? SpotStatus.fromName(reader.readString())
        : SpotStatus.none;
    final parkedDurationMs = count > 7 ? reader.readInt() : null;
    final parkedDuration = parkedDurationMs != null && parkedDurationMs >= 0
        ? Duration(milliseconds: parkedDurationMs)
        : null;

    // Skip fields written by newer app versions.
    for (var i = _fieldCount; i < count; i++) {
      reader.read();
    }
    return Spot(
      id: id,
      name: name,
      category: category,
      latitude: latitude,
      longitude: longitude,
      savedAt: savedAt,
      status: status,
      parkedDuration: parkedDuration,
    );
  }

  @override
  void write(BinaryWriter writer, Spot obj) {
    writer
      ..writeByte(_fieldCount)
      ..writeString(obj.id)
      ..writeString(obj.name)
      ..writeString(obj.category.name)
      ..writeDouble(obj.latitude)
      ..writeDouble(obj.longitude)
      ..writeInt(obj.savedAt.millisecondsSinceEpoch)
      ..writeString(obj.status.name)
      ..writeInt(obj.parkedDuration?.inMilliseconds ?? -1);
  }
}
