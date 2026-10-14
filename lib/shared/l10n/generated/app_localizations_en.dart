// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Dalely';

  @override
  String get homeGreeting => 'Where to?';

  @override
  String savedSpotsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count saved spots',
      one: '1 saved spot',
      zero: 'No saved spots',
    );
    return '$_temp0';
  }

  @override
  String get mapButton => 'Map';

  @override
  String get settingsTooltip => 'Settings';

  @override
  String get backTooltip => 'Back';

  @override
  String get myCar => 'My car';

  @override
  String parkedAgo(String time) {
    return '$time    ';
  }

  @override
  String get noCarTitle => 'Where did you park?';

  @override
  String get noCarMessage => 'Not parked';

  @override
  String distanceAway(String distance) {
    return '$distance away';
  }

  @override
  String get openInMaps => 'Open in Maps';

  @override
  String get parkHere => 'park here';

  @override
  String get onMap => 'On map';

  @override
  String get foundMyCar => 'found it';

  @override
  String get carCleared => 'Car location cleared';

  @override
  String get savedSpots => 'Saved spots';

  @override
  String get shareAll => 'Share all';

  @override
  String get showOnMap => 'Show on map';

  @override
  String get myMap => 'my map';

  @override
  String get openMap => 'open map';

  @override
  String get whereMyCarTitle => 'find my car';

  @override
  String get share => 'Share';

  @override
  String get saveThisSpot => 'Save new spot';

  @override
  String get addSpot => 'Add spot';

  @override
  String savedAgo(String time) {
    return 'Saved $time';
  }

  @override
  String get timeJustNow => 'just now';

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count min ago',
      one: '1 min ago',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count h ago',
      one: '1 h ago',
    );
    return '$_temp0';
  }

  @override
  String get timeYesterday => 'yesterday';

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String timeWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count weeks ago',
      one: '1 week ago',
    );
    return '$_temp0';
  }

  @override
  String timeMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count months ago',
      one: '1 month ago',
    );
    return '$_temp0';
  }

  @override
  String timeYearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count years ago',
      one: '1 year ago',
    );
    return '$_temp0';
  }

  @override
  String distanceMeters(String value) {
    return '$value m';
  }

  @override
  String distanceKilometers(String value) {
    return '$value km';
  }

  @override
  String get emptySpotsTitle => 'No spots yet';

  @override
  String get emptySpotsMessage =>
      'Save the places you want to find again — the market, home, the pharmacy…';

  @override
  String get seeAllOnMap => 'See all spots on map';

  @override
  String get myLocation => 'My location';

  @override
  String get searchPlaceHint => 'Search for a place';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get movePinHint => 'Move the map to place the pin';

  @override
  String get nameLabel => 'Name';

  @override
  String get nameHint => 'e.g. Pharmacy';

  @override
  String get nameRequired => 'Give the spot a name';

  @override
  String get saveHere => 'Save here';

  @override
  String get savedLocallyNote => 'Saved only on this phone. No account needed.';

  @override
  String get noSearchResults => 'No places found';

  @override
  String get searchFailed => 'Search isn\'t available right now';

  @override
  String get categoryCar => 'Car';

  @override
  String get categoryMarket => 'Market';

  @override
  String get categoryHome => 'Home';

  @override
  String get categoryPharmacy => 'Pharmacy';

  @override
  String get categoryWork => 'Work';

  @override
  String get categoryRestaurant => 'Restaurant';

  @override
  String get categoryHospital => 'Hospital';

  @override
  String get categorySchool => 'School';

  @override
  String get categoryGym => 'Gym';

  @override
  String get categoryMosque => 'Mosque';

  @override
  String get categoryFuel => 'Fuel';

  @override
  String get categoryPark => 'Park';

  @override
  String get categoryClub => 'Club';

  @override
  String get categoryBeautyCenter => 'Beauty Center';

  @override
  String get categoryOther => 'None';

  @override
  String get carSaved => 'Car location saved';

  @override
  String spotSaved(String name) {
    return '$name saved';
  }

  @override
  String spotDeleted(String name) {
    return '$name deleted';
  }

  @override
  String get undo => 'Undo';

  @override
  String get delete => 'Delete';

  @override
  String get rename => 'Rename';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get renameSpotTitle => 'Rename spot';

  @override
  String get showOnWidget => 'Show on widget';

  @override
  String get removeFromWidget => 'Remove from widget';

  @override
  String favoriteSet(String name) {
    return '$name is now on your widget';
  }

  @override
  String get favoriteRemoved => 'Removed from your widget';

  @override
  String get locationUnavailable => 'Can\'t get your location yet';

  @override
  String get couldNotOpenMaps => 'Couldn\'t open a maps app';

  @override
  String get couldNotOpenLink => 'Couldn\'t open the link';

  @override
  String get permissionDeniedTitle => 'Location is off for Dalely';

  @override
  String get permissionDeniedMessage =>
      'Allow location to see distances and park your car.';

  @override
  String get serviceDisabledTitle => 'Location services are off';

  @override
  String get serviceDisabledMessage => 'Turn on location to see where you are.';

  @override
  String get allow => 'Allow';

  @override
  String get openSettings => 'Open settings';

  @override
  String get turnOn => 'Turn on';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appearance => 'Appearance';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'Device language';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageArabicEg => 'العربية (مصر)';

  @override
  String get languageArabicSa => 'العربية (السعودية)';

  @override
  String get yourSpots => 'Your spots';

  @override
  String get shareAllAsText => 'Share all spots as text';

  @override
  String get about => 'About';

  @override
  String get website => 'Website';

  @override
  String get privacyPolicy => 'Privacy policy';

  @override
  String get contactWhatsApp => 'Contact via WhatsApp';

  @override
  String get contactSupport => 'Contact support';

  @override
  String get rateApp => 'Rate the app';

  @override
  String versionFooter(String version) {
    return 'Version $version. Your spots stay on this phone.';
  }

  @override
  String get nothingToShare => 'No spots to share yet';

  @override
  String get shareSubject => 'My spots';

  @override
  String get favoriteBadge => 'On widget';

  @override
  String get widgetPark => 'Park';

  @override
  String get widgetFindCar => 'Find car';

  @override
  String get widgetNoCar => 'No car saved';

  @override
  String get widgetNoFavorite => 'Pick a spot';

  @override
  String get carArrivalTitle => 'You\'re at your car!';

  @override
  String get carArrivalMessage => 'You have returned to your parked car.';

  @override
  String get iFoundMyCar => 'I found my car';

  @override
  String get cantSeeCar => 'Haven\'t seen the car yet';

  @override
  String get carFoundCelebration => 'Great! Have a safe drive.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboarding1Title => 'Never forget where you parked';

  @override
  String get onboarding1Body =>
      'Save your car with one tap, then open it in Maps when you are ready to walk back. No more wandering around the car park.';

  @override
  String get onboarding2Title => 'All your places, one spot';

  @override
  String get onboarding2Body =>
      'Your market, home, pharmacy and more live in one list and on one map. Share any spot, or all of them, with a map link anytime.';

  @override
  String get onboarding3Title => 'Your places stay on your phone';

  @override
  String get onboarding3Body =>
      'Everything is saved only on this device and never sent anywhere. Allow location so you can save your car and see where you are.';

  @override
  String get onboardingAllowLocation => 'Allow location access';

  @override
  String get onboardingNotNow => 'Not now';

  @override
  String get notificationParkingTitle => 'Car parked';

  @override
  String notificationDistance(String distance) {
    return 'Distance: $distance';
  }

  @override
  String get carTrackingNotificationSettingTitle => 'Car distance notification';

  @override
  String get carTrackingNotificationSettingSubtitle =>
      'Pinned live notification while walking to your parked car';

  @override
  String carTrackingWalkingTitle(String distance) {
    return 'Your car is $distance away';
  }

  @override
  String carTrackingAboutMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'About $count min walk',
      one: 'About 1 min walk',
    );
    return '$_temp0';
  }

  @override
  String get carTrackingLessThanMinute => 'Less than a minute walk';

  @override
  String get carTrackingArrivedTitle => 'Your car is right here';

  @override
  String get carTrackingArrivedBody => 'You are within 15 m';

  @override
  String get carTrackingLookingForLocation => 'Looking for your location...';

  @override
  String get carTrackingWaitingForGps => 'Waiting for GPS signal';

  @override
  String get carTrackingDone => 'Done';

  @override
  String get carTrackingStop => 'Stop tracking';

  @override
  String get carTrackingTooFar => 'Your car is too far for walking tracking';

  @override
  String get carTrackingActiveBanner => 'Tracking walk to car';

  @override
  String get searchSpots => 'Search spots';

  @override
  String get searchSpotsPlaceholder => 'Search by name or category...';

  @override
  String get noSpotsFound => 'No matching spots';

  @override
  String get noSpotsFoundDesc => 'Try typing a different name or category';

  @override
  String get exportData => 'Export data';

  @override
  String get exportSpotsTitle => 'Export spots';

  @override
  String get exportAsExcel => 'Export as Excel (CSV)';

  @override
  String get exportAsExcelSubtitle =>
      'Spreadsheet with coordinates & map links';

  @override
  String get exportAsText => 'Export as text';

  @override
  String get exportAsTextSubtitle => 'Formatted list with map links';

  @override
  String get exportSubject => 'Dalely spots';
}
