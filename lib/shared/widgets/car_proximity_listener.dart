import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../app/app_router.dart';
import '../cubits/car_proximity/car_proximity_cubit.dart';
import '../cubits/car_proximity/car_proximity_state.dart';
import '../cubits/location/location_cubit.dart';
import '../cubits/location/location_state.dart';
import '../cubits/spots/spots_cubit.dart';
import '../cubits/spots/spots_state.dart';
import '../utils/context_ext.dart';
import 'car_arrival_dialog.dart';

/// Wraps UI trees with background proximity detection to alert the user
/// with [CarArrivalDialog] when they return in front of their parked car.
class CarProximityListener extends StatelessWidget {
  const CarProximityListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<LocationCubit, LocationState>(
          listenWhen: (prev, curr) => prev.position != curr.position,
          listener: (context, locationState) {
            final spotsState = context.read<SpotsCubit>().state;
            final l10n = context.l10n;
            context.read<CarProximityCubit>().checkProximity(
                  car: spotsState.car,
                  userLatitude: locationState.position?.latitude,
                  userLongitude: locationState.position?.longitude,
                  arrivalTitle: l10n.carArrivalTitle,
                  arrivalBody: l10n.carArrivalMessage,
                  onMapActionText: l10n.onMap,
                  foundCarActionText: l10n.foundMyCar,
                );
          },
        ),
        BlocListener<SpotsCubit, SpotsState>(
          listenWhen: (prev, curr) => prev.car != curr.car,
          listener: (context, spotsState) {
            final locationState = context.read<LocationCubit>().state;
            final l10n = context.l10n;
            context.read<CarProximityCubit>().checkProximity(
                  car: spotsState.car,
                  userLatitude: locationState.position?.latitude,
                  userLongitude: locationState.position?.longitude,
                  arrivalTitle: l10n.carArrivalTitle,
                  arrivalBody: l10n.carArrivalMessage,
                  onMapActionText: l10n.onMap,
                  foundCarActionText: l10n.foundMyCar,
                );
          },
        ),
        BlocListener<CarProximityCubit, CarProximityState>(
          listenWhen: (prev, curr) =>
              !prev.shouldShowDialog && curr.shouldShowDialog,
          listener: (context, _) {
            final proximityCubit = context.read<CarProximityCubit>();
            final spotsCubit = context.read<SpotsCubit>();
            final car = spotsCubit.state.car;
            if (car == null) return;

            proximityCubit.onDialogOpened();

            showDialog<void>(
              context: context,
              useSafeArea: false,
              barrierDismissible: true,
              builder: (dialogContext) => CarArrivalDialog(
                onFoundCar: () async {
                  final previousCar = car;
                  proximityCubit.onFoundCar();
                  await spotsCubit.clearCar();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.carCleared),
                        action: SnackBarAction(
                          label: context.l10n.undo,
                          onPressed: () {
                            spotsCubit.restoreSpot(previousCar);
                          },
                        ),
                      ),
                    );
                  }
                },
                onCantSeeCar: () {
                  proximityCubit.onCantSeeCar();
                  Navigator.of(context).pushNamed(
                    AppRouter.spotsMap,
                    arguments: car.id,
                  );
                },
              ),
            ).then((_) {
              proximityCubit.onDialogDismissed();
            });
          },
        ),
      ],
      child: child,
    );
  }
}
