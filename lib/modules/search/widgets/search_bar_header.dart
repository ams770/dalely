import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../shared/theme/app_dimens.dart';
import '../../../shared/utils/context_ext.dart';
import '../../../shared/widgets/circle_icon_button.dart';
import '../cubit/search_spots_cubit.dart';
import '../cubit/search_spots_state.dart';

class SearchBarHeader extends StatelessWidget {
  const SearchBarHeader({super.key, this.onBack});

  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const .fromSTEB(
        AppDimens.space16,
        AppDimens.space16,
        AppDimens.space16,
        AppDimens.space16,
      ),
      child: Row(
        children: [
          CircleIconButton(
            icon: const BackButtonIcon(),
            tooltip: context.l10n.backTooltip,
            onPressed: onBack ?? () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
