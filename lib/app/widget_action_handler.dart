import 'notification_action_router.dart';

/// Legacy alias for [NotificationActionRouter], maintaining backward compatibility.
class WidgetActionHandler extends NotificationActionRouter {
  WidgetActionHandler({
    required super.navigatorKey,
    super.homeWidgetService,
    super.methodChannel,
    super.eventChannel,
    super.currentRouteGetter,
  });
}
