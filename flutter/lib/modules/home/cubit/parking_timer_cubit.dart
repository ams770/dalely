import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'parking_timer_state.dart';

class ParkingTimerCubit extends Cubit<ParkingTimerState> {
  ParkingTimerCubit({
    required this.savedAt,
    Duration Function()? nowProvider,
  })  : _nowProvider = nowProvider,
        super(ParkingTimerState(
          elapsed: (nowProvider != null)
              ? nowProvider()
              : DateTime.now().difference(savedAt),
        )) {
    _startTimer();
  }

  final DateTime savedAt;
  final Duration Function()? _nowProvider;
  Timer? _timer;

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!isClosed) {
        final elapsed = (_nowProvider != null)
            ? _nowProvider()
            : DateTime.now().difference(savedAt);
        emit(state.copyWith(elapsed: elapsed));
      }
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
