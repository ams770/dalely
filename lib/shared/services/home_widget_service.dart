import 'dart:async';
import 'package:home_widget/home_widget.dart';

import '../constants/storage_keys.dart';
import '../models/spot.dart';

class HomeWidgetService {
  const HomeWidgetService();

  /// Sets the app group id on iOS.
  Future<void> init() async {
    await HomeWidget.setAppGroupId(StorageKeys.appGroupId);
  }

  /// Stream of URIs triggered by widget clicks.
  Stream<Uri?> get widgetClicked => HomeWidget.widgetClicked;

  /// Retrieves initial launch URI if launched from a widget.
  Future<Uri?> initiallyLaunchedFromHomeWidget() =>
      HomeWidget.initiallyLaunchedFromHomeWidget();

  /// Updates shared widget data and requests widget updates.
  Future<void> syncWidgetData({
    required Spot? car,
    required Spot? favoriteSpot,
    double? userLat,
    double? userLng,
    bool isRtl = false,
  }) async {
    try {
      // Car data
      if (car != null) {
        await HomeWidget.saveWidgetData<double>(
          StorageKeys.widgetCarLat,
          car.latitude,
        );
        await HomeWidget.saveWidgetData<double>(
          StorageKeys.widgetCarLng,
          car.longitude,
        );
        await HomeWidget.saveWidgetData<int>(
          StorageKeys.widgetCarSavedAt,
          car.savedAt.millisecondsSinceEpoch,
        );
      } else {
        await HomeWidget.saveWidgetData<double>(
          StorageKeys.widgetCarLat,
          null,
        );
        await HomeWidget.saveWidgetData<double>(
          StorageKeys.widgetCarLng,
          null,
        );
        await HomeWidget.saveWidgetData<int>(
          StorageKeys.widgetCarSavedAt,
          null,
        );
      }

      // Favorite spot data
      if (favoriteSpot != null) {
        await HomeWidget.saveWidgetData<String>(
          StorageKeys.widgetFavId,
          favoriteSpot.id,
        );
        await HomeWidget.saveWidgetData<String>(
          StorageKeys.widgetFavName,
          favoriteSpot.name,
        );
        await HomeWidget.saveWidgetData<String>(
          StorageKeys.widgetFavCategory,
          favoriteSpot.category.name,
        );
        await HomeWidget.saveWidgetData<double>(
          StorageKeys.widgetFavLat,
          favoriteSpot.latitude,
        );
        await HomeWidget.saveWidgetData<double>(
          StorageKeys.widgetFavLng,
          favoriteSpot.longitude,
        );
      } else {
        await HomeWidget.saveWidgetData<String>(
          StorageKeys.widgetFavId,
          null,
        );
        await HomeWidget.saveWidgetData<String>(
          StorageKeys.widgetFavName,
          null,
        );
        await HomeWidget.saveWidgetData<String>(
          StorageKeys.widgetFavCategory,
          null,
        );
        await HomeWidget.saveWidgetData<double>(
          StorageKeys.widgetFavLat,
          null,
        );
        await HomeWidget.saveWidgetData<double>(
          StorageKeys.widgetFavLng,
          null,
        );
      }

      // User location (for widget distance estimation)
      if (userLat != null && userLng != null) {
        await HomeWidget.saveWidgetData<double>(
          StorageKeys.widgetUserLat,
          userLat,
        );
        await HomeWidget.saveWidgetData<double>(
          StorageKeys.widgetUserLng,
          userLng,
        );
      }

      await HomeWidget.saveWidgetData<bool>(
        StorageKeys.widgetIsRtl,
        isRtl,
      );

      // Trigger native widget redraws
      await HomeWidget.updateWidget(
        name: StorageKeys.iosCarWidget,
        iOSName: StorageKeys.iosCarWidget,
        androidName: StorageKeys.androidCarWidget,
      );
      await HomeWidget.updateWidget(
        name: StorageKeys.iosParkWidget,
        iOSName: StorageKeys.iosParkWidget,
        androidName: StorageKeys.androidParkWidget,
      );
      await HomeWidget.updateWidget(
        name: StorageKeys.iosFindCarWidget,
        iOSName: StorageKeys.iosFindCarWidget,
        androidName: StorageKeys.androidFindCarWidget,
      );
      await HomeWidget.updateWidget(
        name: StorageKeys.iosFavoriteWidget,
        iOSName: StorageKeys.iosFavoriteWidget,
        androidName: StorageKeys.androidFavoriteWidget,
      );
    } catch (_) {
      // Ignored if platform widgets are not registered yet
    }
  }
}
