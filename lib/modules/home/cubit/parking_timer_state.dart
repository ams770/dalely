import '../../../shared/utils/duration_formatter.dart';

class ParkingTimerState {
  const ParkingTimerState({
    required this.elapsed,
  });

  final Duration elapsed;

  String get formattedElapsed => DurationFormatter.formatTimer(elapsed);

  ParkingTimerState copyWith({
    Duration? elapsed,
  }) {
    return ParkingTimerState(
      elapsed: elapsed ?? this.elapsed,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ParkingTimerState && other.elapsed == elapsed;

  @override
  int get hashCode => elapsed.hashCode;
}
