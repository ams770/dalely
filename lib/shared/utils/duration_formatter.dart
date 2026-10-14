import '../l10n/generated/app_localizations.dart';

abstract final class DurationFormatter {
  /// Formats a [Duration] into a stopwatch / timer string (e.g. "00:14:32" or "1 d 02:15:30").
  static String formatTimer(Duration duration) {
    final clamped = duration.isNegative ? Duration.zero : duration;
    final seconds = clamped.inSeconds % 60;
    final minutes = clamped.inMinutes % 60;
    final hours = clamped.inHours % 24;
    final days = clamped.inDays;

    final hStr = hours.toString().padLeft(2, '0');
    final mStr = minutes.toString().padLeft(2, '0');
    final sStr = seconds.toString().padLeft(2, '0');

    if (days > 0) {
      return '$days d $hStr:$mStr:$sStr';
    }
    return '$hStr:$mStr:$sStr';
  }

  /// Formats a [Duration] into a friendly localized human-readable string:
  /// - Under 1 minute: "Less than a minute" / "أقل من دقيقة"
  /// - Under 60 minutes: "X minutes" / "دقيقتين" / "X دقائق"
  /// - Under 24 hours: "X hours" / "X hours, Y minutes"
  /// - 1 day or more: "X days" / "X days, Y hours"
  static String formatHuman(Duration duration, AppLocalizations l10n) {
    final clamped = duration.isNegative ? Duration.zero : duration;
    final totalMinutes = clamped.inMinutes;

    if (totalMinutes < 1) {
      return l10n.durationLessThanMinute;
    }

    if (totalMinutes < 60) {
      return l10n.durationMinutes(totalMinutes);
    }

    final days = clamped.inDays;
    final hours = clamped.inHours % 24;
    final minutes = clamped.inMinutes % 60;

    if (days == 0) {
      final hStr = l10n.durationHours(hours);
      if (minutes == 0) {
        return hStr;
      }
      final mStr = l10n.durationMinutes(minutes);
      return l10n.durationHoursAndMinutes(hStr, mStr);
    } else {
      final dStr = l10n.durationDays(days);
      if (hours == 0) {
        return dStr;
      }
      final hStr = l10n.durationHours(hours);
      return l10n.durationDaysAndHours(dStr, hStr);
    }
  }
}

