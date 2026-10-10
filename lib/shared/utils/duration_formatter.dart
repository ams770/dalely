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
}
