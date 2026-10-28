import 'package:flutter/material.dart';

import '../../../shared/theme/app_dimens.dart';
import '../../../shared/utils/context_ext.dart';

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({
    super.key,
    required this.imageAsset,
    required this.title,
    required this.body,
  });

  final String imageAsset;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;

    return Padding(
      padding: const EdgeInsetsDirectional.symmetric(
        horizontal: AppDimens.space24,
      ),
      child: Column(
        children: [
          // Illustration
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 300,
                  maxWidth: 300,
                ),
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDimens.space16),

          // Title
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 24,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: AppDimens.space12),

          // Body Description
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.45,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: AppDimens.space16),
        ],
      ),
    );
  }
}
