import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';

import '../../models/location_access.dart';
import '../../services/heading_service.dart';
import '../../services/location_service.dart';
import 'location_state.dart';

class LocationCubit extends Cubit<LocationState> {
  LocationCubit({
    required this.locationService,
    required this.headingService,
  }) : super(const LocationState()) {
    _lifecycleListener = AppLifecycleListener(
      onResume: _startStreams,
      onPause: _stopStreams,
    );
    _init();
  }

  final LocationService locationService;
  final HeadingService headingService;
  late final AppLifecycleListener _lifecycleListener;

  StreamSubscription? _positionSubscription;
  StreamSubscription? _headingSubscription;

  Future<void> _init() async {
    final access = await locationService.checkPermission();
    if (isClosed) return;
    emit(state.copyWith(access: access));

    if (access == LocationAccess.granted) {
      final last = await locationService.getLastKnownPosition();
      if (!isClosed && last != null && state.position == null) {
        emit(state.copyWith(position: last));
      }
      _startStreams();
      unawaited(
        locationService.getCurrentPosition().then((pos) {
          if (!isClosed && pos != null) {
            emit(state.copyWith(position: pos));
          }
        }),
      );
    }
  }

  Future<LocationAccess> requestPermission() async {
    emit(state.copyWith(isLoading: true));
    final access = await locationService.requestPermission();
    if (isClosed) return access;

    emit(state.copyWith(access: access, isLoading: false));
    if (access == LocationAccess.granted) {
      _startStreams();
      final last = await locationService.getLastKnownPosition();
      if (!isClosed && last != null && state.position == null) {
        emit(state.copyWith(position: last));
      }
      final current = await locationService.getCurrentPosition();
      if (!isClosed && current != null) {
        emit(state.copyWith(position: current));
      }
    } else {
      _stopStreams();
    }
    return access;
  }

  /// Returns the current position if already available, or actively requests permission
  /// and fetches fresh/cached coordinates.
  Future<Position?> getOrAcquirePosition() async {
    if (state.position != null) {
      return state.position;
    }

    var access = state.access;
    if (access != LocationAccess.granted) {
      access = await requestPermission();
      if (access != LocationAccess.granted) {
        return null;
      }
    }

    if (state.position != null) {
      return state.position;
    }

    final last = await locationService.getLastKnownPosition();
    if (last != null && !isClosed) {
      emit(state.copyWith(position: last));
    }

    final current = await locationService.getCurrentPosition();
    if (current != null && !isClosed) {
      emit(state.copyWith(position: current));
      return current;
    }

    return last ?? state.position;
  }

  Future<void> refreshLocation() async {
    final access = await locationService.checkPermission();
    if (isClosed) return;
    emit(state.copyWith(access: access));

    if (access == LocationAccess.granted) {
      final current = await locationService.getCurrentPosition();
      if (!isClosed && current != null) {
        emit(state.copyWith(position: current));
      }
    }
  }

  void _startStreams() {
    if (state.access != LocationAccess.granted) return;

    _positionSubscription?.cancel();
    _positionSubscription = locationService
        .getPositionStream(distanceFilter: 5)
        .listen((position) {
      if (!isClosed) {
        emit(state.copyWith(position: position));
      }
    });

    _headingSubscription?.cancel();
    final headingStream = headingService.events;
    if (headingStream != null) {
      _headingSubscription = headingStream.listen((heading) {
        if (!isClosed) {
          emit(state.copyWith(heading: heading));
        }
      });
    }
  }

  void _stopStreams() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _headingSubscription?.cancel();
    _headingSubscription = null;
  }

  Future<void> openAppSettings() => locationService.openAppSettings();
  Future<void> openLocationSettings() => locationService.openLocationSettings();

  @override
  Future<void> close() {
    _stopStreams();
    _lifecycleListener.dispose();
    return super.close();
  }
}
