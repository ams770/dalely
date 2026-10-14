import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/app_router.dart';
import '../cubits/adaptive_nav/adaptive_nav_cubit.dart';
import 'adaptive_layout_ext.dart';

import '../models/spot.dart';

abstract final class AdaptiveNavigation {
  static void openMap(BuildContext context, {String? spotId}) {
    if (context.isWideScreen) {
      context.read<AdaptiveNavCubit>().showMap(spotId: spotId);
    } else {
      Navigator.of(context).pushNamed(AppRouter.spotsMap, arguments: spotId);
    }
  }

  static void openSaveSpot(BuildContext context) {
    if (context.isWideScreen) {
      context.read<AdaptiveNavCubit>().openSaveSpot();
    } else {
      Navigator.of(context).pushNamed(AppRouter.saveSpot);
    }
  }

  static void openEditSpot(BuildContext context, Spot spot) {
    if (context.isWideScreen) {
      context.read<AdaptiveNavCubit>().openEditSpot(spot);
    } else {
      Navigator.of(context).pushNamed(
        AppRouter.saveSpot,
        arguments: SaveSpotArgs(
          target: spot.latLng,
          name: spot.name,
          editingSpot: spot,
        ),
      );
    }
  }

  static void openSettings(BuildContext context) {
    if (context.isWideScreen) {
      context.read<AdaptiveNavCubit>().openSettings();
    } else {
      Navigator.of(context).pushNamed(AppRouter.settings);
    }
  }

  static void openSearch(BuildContext context) {
    if (context.isWideScreen) {
      context.read<AdaptiveNavCubit>().openSearch();
    } else {
      Navigator.of(context).pushNamed(AppRouter.search);
    }
  }

  static void openParkingHistory(BuildContext context) {
    if (context.isWideScreen) {
      context.read<AdaptiveNavCubit>().openParkingHistory();
    } else {
      Navigator.of(context).pushNamed(AppRouter.parkingHistory);
    }
  }
}
