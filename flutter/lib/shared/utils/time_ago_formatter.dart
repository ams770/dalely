import '../l10n/generated/app_localizations.dart';

abstract final class TimeAgoFormatter {
  /// Formats a timestamp into a localized relative string (e.g. "Parked 2 h ago").
  static String format(DateTime dateTime, AppLocalizations l10n) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return l10n.timeJustNow;
    }

    final minutes = difference.inMinutes;
    if (minutes < 60) {
      return l10n.timeMinutesAgo(minutes);
    }

    final hours = difference.inHours;
    if (hours < 24) {
      return l10n.timeHoursAgo(hours);
    }

    final days = difference.inDays;
    if (days == 1) {
      return l10n.timeYesterday;
    }
    if (days < 7) {
      return l10n.timeDaysAgo(days);
    }

    final weeks = (days / 7).floor();
    if (weeks < 4) {
      return l10n.timeWeeksAgo(weeks);
    }

    final months = (days / 30).floor();
    if (months < 12) {
      return l10n.timeMonthsAgo(months);
    }

    final years = (days / 365).floor();
    return l10n.timeYearsAgo(years);
  }
}
