import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../shared/constants/spot_categories.dart';
import '../../../shared/cubits/location/location_cubit.dart';
import '../../../shared/cubits/spots/spots_cubit.dart';
import '../../../shared/models/location_access.dart';
import '../../../shared/models/place_result.dart';
import '../../../shared/services/place_search_service.dart';
import 'save_spot_state.dart';

class SaveSpotCubit extends Cubit<SaveSpotState> {
  SaveSpotCubit({
    required this.spotsCubit,
    required this.locationCubit,
    required this.placeSearchService,
    SpotCategory initialCategory = SpotCategory.market,
  })  : nameController = TextEditingController(),
        searchController = TextEditingController(),
        super(
          SaveSpotState(
            category: initialCategory,
            target: locationCubit.state.latLng ?? const LatLng(30.0444, 31.2357),
          ),
        ) {
    _init();
  }

  final SpotsCubit spotsCubit;
  final LocationCubit locationCubit;
  final PlaceSearchService placeSearchService;

  final TextEditingController nameController;
  final TextEditingController searchController;

  GoogleMapController? _mapController;
  Timer? _searchDebounce;

  void _init() {
    nameController.addListener(() {
      final text = nameController.text;
      if (text != state.name && !isClosed) {
        emit(state.copyWith(name: text));
      }
    });

    searchController.addListener(() {
      final query = searchController.text;
      if (query != state.searchQuery) {
        _onSearchQueryChanged(query);
      }
    });

    // If current location is available, center target to it
    final userPos = locationCubit.state.latLng;
    if (userPos != null) {
      emit(state.copyWith(target: userPos));
    }
  }

  void onMapCreated(GoogleMapController controller) {
    _mapController = controller;
    final userPos = locationCubit.state.latLng;
    if (userPos != null) {
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(userPos, 16.0),
      );
    }
  }

  void onCameraMoveStarted() {
    if (!state.isCameraMoving && !isClosed) {
      emit(state.copyWith(isCameraMoving: true, showResults: false));
    }
  }

  void onCameraMove(CameraPosition position) {
    emit(state.copyWith(target: position.target));
  }

  void onCameraIdle() {
    if (state.isCameraMoving && !isClosed) {
      emit(state.copyWith(isCameraMoving: false));
    }
  }

  void setCategory(SpotCategory category) {
    emit(state.copyWith(category: category));
  }

  void _onSearchQueryChanged(String query) {
    _searchDebounce?.cancel();
    if (query.trim().isEmpty) {
      emit(
        state.copyWith(
          searchQuery: '',
          searchResults: const [],
          showResults: false,
          isSearching: false,
        ),
      );
      return;
    }

    emit(state.copyWith(searchQuery: query, isSearching: true, showResults: true));

    _searchDebounce = Timer(const Duration(milliseconds: 500), () async {
      final results = await placeSearchService.search(query);
      if (!isClosed) {
        emit(
          state.copyWith(
            searchResults: results,
            isSearching: false,
            showResults: true,
          ),
        );
      }
    });
  }

  void selectPlaceResult(PlaceResult result) {
    searchController.text = result.title;
    if (nameController.text.trim().isEmpty) {
      nameController.text = result.title;
    }

    emit(
      state.copyWith(
        target: result.latLng,
        showResults: false,
        name: nameController.text,
      ),
    );

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(result.latLng, 16.0),
    );
  }

  void clearSearch() {
    searchController.clear();
    emit(
      state.copyWith(
        searchQuery: '',
        searchResults: const [],
        showResults: false,
      ),
    );
  }

  void hideSearchResults() {
    if (state.showResults) {
      emit(state.copyWith(showResults: false));
    }
  }

  Future<void> snapToCurrentLocation() async {
    var pos = locationCubit.state.latLng;
    if (pos == null) {
      final access = await locationCubit.requestPermission();
      if (access != LocationAccess.granted) return;
      pos = locationCubit.state.latLng;
    }

    if (pos != null) {
      emit(state.copyWith(target: pos));
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(pos, 16.5),
      );
    }
  }

  Future<bool> saveSpot() async {
    if (!state.canSave) return false;

    emit(state.copyWith(status: SaveSpotStatus.saving));

    try {
      await spotsCubit.saveSpot(
        name: state.name,
        category: state.category,
        latitude: state.target.latitude,
        longitude: state.target.longitude,
      );

      if (!isClosed) {
        emit(state.copyWith(status: SaveSpotStatus.success));
      }
      return true;
    } catch (e) {
      if (!isClosed) {
        emit(
          state.copyWith(
            status: SaveSpotStatus.failure,
            errorMessage: e.toString(),
          ),
        );
      }
      return false;
    }
  }

  @override
  Future<void> close() {
    _searchDebounce?.cancel();
    nameController.dispose();
    searchController.dispose();
    _mapController?.dispose();
    return super.close();
  }
}
