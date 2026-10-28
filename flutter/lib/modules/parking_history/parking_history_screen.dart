import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../shared/constants/spot_categories.dart';
import '../../shared/cubits/adaptive_nav/adaptive_nav_cubit.dart';
import '../../shared/cubits/spots/spots_cubit.dart';
import '../../shared/cubits/spots/spots_state.dart';
import '../../shared/models/spot.dart';
import '../../shared/services/maps_launcher.dart';
import '../../shared/services/share_service.dart';
import '../../shared/theme/app_dimens.dart';
import '../../shared/utils/adaptive_navigation.dart';
import '../../shared/utils/app_snack_bar.dart';
import '../../shared/utils/context_ext.dart';
import '../../shared/utils/duration_formatter.dart';
import '../../shared/widgets/adaptive/adaptive_ui.dart';
import '../../shared/widgets/adaptive_expand_listener.dart';
import '../../shared/widgets/category_badge.dart';
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/info_pill.dart';
import '../../shared/widgets/spot_adaptive_menu.dart';
import 'cubit/parking_history_cubit.dart';

class ParkingHistoryScreen extends StatelessWidget {
  const ParkingHistoryScreen({super.key, this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ParkingHistoryCubit>(
      create: (context) => ParkingHistoryCubit(
        spotsCubit: context.read<SpotsCubit>(),
      ),
      child: _ParkingHistoryView(onClose: onClose),
    );
  }
}

class _ParkingHistoryView extends StatelessWidget {
  const _ParkingHistoryView({this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return AdaptiveExpandListener(
      enabled: onClose == null,
      onExpandToTwoPane: () {
        AdaptiveNavCubit? navCubit;
        try {
          navCubit = context.read<AdaptiveNavCubit>();
        } catch (_) {}
        navCubit?.openParkingHistory();
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _HistoryHeader(onClose: onClose),
              const Expanded(child: _HistoryBody()),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({this.onClose});

  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppDimens.space16,
        AppDimens.space12,
        AppDimens.space16,
        AppDimens.space12,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleIconButton(
            icon: const BackButtonIcon(),
            tooltip: l10n.backTooltip,
            onPressed: () {
              if (onClose != null) {
                onClose!();
              } else if (Navigator.canPop(context)) {
                Navigator.of(context).pop();
              }
            },
          ),
          Text(
            l10n.parkingHistory,
            style: context.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          BlocSelector<SpotsCubit, SpotsState, bool>(
            selector: (state) => state.parkingHistory.isNotEmpty,
            builder: (context, hasHistory) {
              if (!hasHistory) {
                return const SizedBox(
                  width: AppDimens.iconButtonSize,
                  height: AppDimens.iconButtonSize,
                );
              }

              return CircleIconButton(
                icon: const Icon(Icons.delete_sweep_outlined),
                tooltip: l10n.clearHistory,
                onPressed: () => _confirmClearHistory(context),
              );
            },
          ),
        ],
      ),
    );
  }

  void _confirmClearHistory(BuildContext context) {
    final l10n = context.l10n;
    final spotsCubit = context.read<SpotsCubit>();

    AdaptiveAlertDialog.show(
      context: context,
      title: l10n.clearHistory,
      message: l10n.clearHistoryConfirm,
      actions: [
        AlertAction(
          title: l10n.cancel,
          onPressed: () {},
          style: AlertActionStyle.cancel,
        ),
        AlertAction(
          title: l10n.clearHistory,
          onPressed: () {
            spotsCubit.clearParkingHistory();
          },
          style: AlertActionStyle.destructive,
        ),
      ],
    );
  }
}

class _HistoryBody extends StatelessWidget {
  const _HistoryBody();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ParkingHistoryCubit>();
    final visibleCount = context.select<ParkingHistoryCubit, int>(
      (c) => c.state.visibleCount,
    );

    return BlocBuilder<SpotsCubit, SpotsState>(
      buildWhen: (prev, curr) => prev.parkingHistory != curr.parkingHistory,
      builder: (context, state) {
        final history = state.parkingHistory;

        if (history.isEmpty) {
          return EmptyState(
            title: context.l10n.noParkingHistoryTitle,
            message: context.l10n.noParkingHistoryMessage,
          );
        }

        final displayedSpots = history.take(visibleCount).toList();

        return ListView.builder(
          controller: cubit.scrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsetsDirectional.fromSTEB(
            AppDimens.space16,
            AppDimens.space8,
            AppDimens.space16,
            AppDimens.space24,
          ),
          itemCount: displayedSpots.length,
          itemBuilder: (context, index) {
            final spot = displayedSpots[index];
            return Padding(
              padding: const EdgeInsetsDirectional.only(
                bottom: AppDimens.space12,
              ),
              child: _HistoryCard(spot: spot),
            );
          },
        );
      },
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.spot});

  final Spot spot;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = context.l10n;
    final locale = Localizations.localeOf(context).toString();
    final dateStr = DateFormat.yMMMd(locale).add_jm().format(spot.savedAt);
    final spotsCubit = context.read<SpotsCubit>();

    void handleOpenInMaps() {
      const MapsLauncher().openDirections(
        latitude: spot.latitude,
        longitude: spot.longitude,
        label: l10n.myCar,
      );
    }

    void handleShare() {
      const ShareService().shareSpot(spot, l10n: l10n);
    }

    void handleDelete() {
      spotsCubit.deleteSpot(spot.id);
      AppSnackBar.show(
        context,
        content: Text(l10n.spotDeleted(l10n.myCar)),
        action: SnackBarAction(
          label: l10n.undo,
          onPressed: () {
            spotsCubit.restoreSpot(spot);
          },
        ),
      );
    }

    return Dismissible(
      key: ValueKey('parking_${spot.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: AlignmentDirectional.centerEnd,
        padding: const EdgeInsetsDirectional.only(end: AppDimens.space20),
        decoration: BoxDecoration(
          color: context.colorScheme.error,
          borderRadius: AppDimens.borderRadiusLarge,
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: AppDimens.iconLarge,
        ),
      ),
      onDismissed: (_) => handleDelete(),
      child: Builder(
        builder: (cardContext) => Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            borderRadius: AppDimens.borderRadiusLarge,
            onTap: () {
              Feedback.forTap(cardContext);
              AdaptiveNavigation.openMap(
                context,
                spotId: spot.id,
                onlyShowSpot: true,
              );
            },
            onLongPress: () {
              Feedback.forLongPress(cardContext);
              SpotAdaptiveMenu.show(
                context: cardContext,
                spot: spot,
                onShare: handleShare,
                onOpenInMaps: handleOpenInMaps,
                onDelete: handleDelete,
              );
            },
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(
                AppDimens.space16,
                AppDimens.space12,
                AppDimens.space12,
                AppDimens.space12,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const CategoryBadge(category: SpotCategory.car),
                  const SizedBox(width: AppDimens.space12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          dateStr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: AppDimens.space4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule_rounded,
                              size: AppDimens.iconSmall,
                              color: theme.colorScheme.primary,
                            ),
                            const SizedBox(width: AppDimens.space4),
                            Flexible(
                              child: Text(
                                DurationFormatter.formatHuman(
                                  spot.calculatedParkedDuration,
                                  l10n,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppDimens.space8),
                  DistancePill(spot: spot, showSuffix: false),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

