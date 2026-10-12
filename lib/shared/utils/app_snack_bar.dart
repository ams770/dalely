import 'package:flutter/material.dart';

final GlobalKey<ScaffoldMessengerState> mainScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

abstract final class AppSnackBar {
  static const Duration defaultDuration = Duration(seconds: 3);

  static void show(
    BuildContext context, {
    required Widget content,
    Duration duration = defaultDuration,
    SnackBarAction? action,
  }) {
    final messenger =
        mainScaffoldMessengerKey.currentState ??
        ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: content,
        duration: duration,
        action: action,
        margin: .symmetric(horizontal: 20, vertical: 100),
      ),
    );
  }
}
