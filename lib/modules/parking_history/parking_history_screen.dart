import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

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
import '../../shared/widgets/circle_icon_button.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/info_pill.dart';
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
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _HistoryHeader(onClose: onClose),
            const Expanded(child: _HistoryBody()),
          ],
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

    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.clearHistory),
        content: Text(l10n.clearHistoryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(true);
              spotsCubit.clearParkingHistory();
             
            },
            style: TextButton.styleFrom(
              foregroundColor: context.colorScheme.error,
            ),
            child: Text(l10n.clearHistory),
          ),
        ],
      ),
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
      onDismissed: (_) {
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
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            AdaptiveNavigation.openMap(
              context,
              spotId: spot.id,
              onlyShowSpot: true,
            );
          },
          borderRadius: AppDimens.borderRadiusLarge,
          child: Padding(
            padding: const EdgeInsetsDirectional.all(AppDimens.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateStr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
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
                    DistancePill(spot: spot, showSuffix: false),
                  ],
                ),
                Divider(height: AppDimens.space24),
                Row(
                  children: [
                    Expanded(
                      child: _ActionPill(
                        icon: CupertinoIcons.map,
                        label: l10n.openInMaps,
                        onPressed: () {
                          const MapsLauncher().openDirections(
                            latitude: spot.latitude,
                            longitude: spot.longitude,
                            label: l10n.myCar,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: AppDimens.space8),
                    Expanded(
                      child: _ActionPill(
                        icon: Icons.share_outlined,
                        label: l10n.share,
                        onPressed: () {
                          const ShareService().shareSpot(spot, l10n: l10n);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return OutlinedButton(
      onPressed: onPressed,
      style: theme.outlinedButtonTheme.style?.copyWith(
        padding: const WidgetStatePropertyAll(
          EdgeInsetsDirectional.symmetric(
            horizontal: AppDimens.space8,
            vertical: AppDimens.space8,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: AppDimens.space6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
