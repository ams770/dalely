/// Hive box names, record keys and native-widget shared keys.
///
/// Widget keys are mirrored exactly in Swift (DalelyWidgets) and Kotlin (widgets).
abstract final class StorageKeys {
  static const String spotsBox = 'spots';
  static const String settingsBox = 'settings';
  static const String settingsRecord = 'app';

  /// Reserved id of the single car spot.
  static const String carId = 'car';

  // Native widget bridge.
  static const String appGroupId = 'group.com.dalely.app';
  static const String widgetCarLat = 'car_lat';
  static const String widgetCarLng = 'car_lng';
  static const String widgetCarSavedAt = 'car_saved_at';
  static const String widgetFavId = 'fav_id';
  static const String widgetFavName = 'fav_name';
  static const String widgetFavCategory = 'fav_category';
  static const String widgetFavLat = 'fav_lat';
  static const String widgetFavLng = 'fav_lng';
  static const String widgetUserLat = 'user_lat';
  static const String widgetUserLng = 'user_lng';
  static const String widgetLabelMyCar = 'label_my_car';
  static const String widgetLabelPark = 'label_park';
  static const String widgetLabelFindCar = 'label_find_car';
  static const String widgetLabelNoCar = 'label_no_car';
  static const String widgetLabelNoFavorite = 'label_no_favorite';
  static const String widgetLabelMeters = 'label_meters';
  static const String widgetLabelKilometers = 'label_kilometers';
  static const String widgetIsRtl = 'is_rtl';

  // Native widget kinds (iOS `kind`) and Android receiver class names.
  static const String iosCarWidget = 'CarWidget';
  static const String iosParkWidget = 'ParkWidget';
  static const String iosFindCarWidget = 'FindCarWidget';
  static const String iosFavoriteWidget = 'FavoriteSpotWidget';
  static const String androidCarWidget =
      'com.dalely.app.widgets.CarWidgetReceiver';
  static const String androidParkWidget =
      'com.dalely.app.widgets.ParkWidgetReceiver';
  static const String androidFindCarWidget =
      'com.dalely.app.widgets.FindCarWidgetReceiver';
  static const String androidFavoriteWidget =
      'com.dalely.app.widgets.FavoriteWidgetReceiver';

  // Widget & notification tap URIs (`feen://<host>`).
  static const String uriScheme = 'feen';
  static const String uriPark = 'park';
  static const String uriCar = 'car';
  static const String uriSpot = 'spot';
  static const String uriFoundCar = 'found_car';
  static const String uriOnMap = 'on_map';
}
