import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('ar', 'EG'),
    Locale('ar', 'SA'),
    Locale('en'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Feen'**
  String get appTitle;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Where to?'**
  String get homeGreeting;

  /// No description provided for @savedSpotsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No saved spots} =1{1 saved spot} other{{count} saved spots}}'**
  String savedSpotsCount(int count);

  /// No description provided for @mapButton.
  ///
  /// In en, this message translates to:
  /// **'Map'**
  String get mapButton;

  /// No description provided for @settingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTooltip;

  /// No description provided for @backTooltip.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get backTooltip;

  /// No description provided for @myCar.
  ///
  /// In en, this message translates to:
  /// **'My car'**
  String get myCar;

  /// No description provided for @parkedAgo.
  ///
  /// In en, this message translates to:
  /// **'{time}    '**
  String parkedAgo(String time);

  /// No description provided for @noCarTitle.
  ///
  /// In en, this message translates to:
  /// **'Where did you park?'**
  String get noCarTitle;

  /// No description provided for @noCarMessage.
  ///
  /// In en, this message translates to:
  /// **'Tap Park here when you leave the car.'**
  String get noCarMessage;

  /// No description provided for @distanceAway.
  ///
  /// In en, this message translates to:
  /// **'{distance} away'**
  String distanceAway(String distance);

  /// No description provided for @openInMaps.
  ///
  /// In en, this message translates to:
  /// **'Open in Maps'**
  String get openInMaps;

  /// No description provided for @parkHere.
  ///
  /// In en, this message translates to:
  /// **'Park here'**
  String get parkHere;

  /// No description provided for @onMap.
  ///
  /// In en, this message translates to:
  /// **'On map'**
  String get onMap;

  /// No description provided for @foundMyCar.
  ///
  /// In en, this message translates to:
  /// **'Found my car'**
  String get foundMyCar;

  /// No description provided for @carCleared.
  ///
  /// In en, this message translates to:
  /// **'Car location cleared'**
  String get carCleared;

  /// No description provided for @savedSpots.
  ///
  /// In en, this message translates to:
  /// **'Saved spots'**
  String get savedSpots;

  /// No description provided for @shareAll.
  ///
  /// In en, this message translates to:
  /// **'Share all'**
  String get shareAll;

  /// No description provided for @showOnMap.
  ///
  /// In en, this message translates to:
  /// **'Show on map'**
  String get showOnMap;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @saveThisSpot.
  ///
  /// In en, this message translates to:
  /// **'Save this spot'**
  String get saveThisSpot;

  /// No description provided for @savedAgo.
  ///
  /// In en, this message translates to:
  /// **'Saved {time}'**
  String savedAgo(String time);

  /// No description provided for @timeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get timeJustNow;

  /// No description provided for @timeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 min ago} other{{count} min ago}}'**
  String timeMinutesAgo(int count);

  /// No description provided for @timeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 h ago} other{{count} h ago}}'**
  String timeHoursAgo(int count);

  /// No description provided for @timeYesterday.
  ///
  /// In en, this message translates to:
  /// **'yesterday'**
  String get timeYesterday;

  /// No description provided for @timeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day ago} other{{count} days ago}}'**
  String timeDaysAgo(int count);

  /// No description provided for @timeWeeksAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 week ago} other{{count} weeks ago}}'**
  String timeWeeksAgo(int count);

  /// No description provided for @timeMonthsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 month ago} other{{count} months ago}}'**
  String timeMonthsAgo(int count);

  /// No description provided for @timeYearsAgo.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 year ago} other{{count} years ago}}'**
  String timeYearsAgo(int count);

  /// No description provided for @distanceMeters.
  ///
  /// In en, this message translates to:
  /// **'{value} m'**
  String distanceMeters(String value);

  /// No description provided for @distanceKilometers.
  ///
  /// In en, this message translates to:
  /// **'{value} km'**
  String distanceKilometers(String value);

  /// No description provided for @emptySpotsTitle.
  ///
  /// In en, this message translates to:
  /// **'No spots yet'**
  String get emptySpotsTitle;

  /// No description provided for @emptySpotsMessage.
  ///
  /// In en, this message translates to:
  /// **'Save the places you want to find again — the market, home, the pharmacy…'**
  String get emptySpotsMessage;

  /// No description provided for @seeAllOnMap.
  ///
  /// In en, this message translates to:
  /// **'See all spots on map'**
  String get seeAllOnMap;

  /// No description provided for @myLocation.
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get myLocation;

  /// No description provided for @searchPlaceHint.
  ///
  /// In en, this message translates to:
  /// **'Search for a place'**
  String get searchPlaceHint;

  /// No description provided for @clearSearch.
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// No description provided for @movePinHint.
  ///
  /// In en, this message translates to:
  /// **'Move the map to place the pin'**
  String get movePinHint;

  /// No description provided for @nameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// No description provided for @nameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Pharmacy'**
  String get nameHint;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Give the spot a name'**
  String get nameRequired;

  /// No description provided for @saveHere.
  ///
  /// In en, this message translates to:
  /// **'Save here'**
  String get saveHere;

  /// No description provided for @savedLocallyNote.
  ///
  /// In en, this message translates to:
  /// **'Saved only on this phone. No account needed.'**
  String get savedLocallyNote;

  /// No description provided for @noSearchResults.
  ///
  /// In en, this message translates to:
  /// **'No places found'**
  String get noSearchResults;

  /// No description provided for @searchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search isn\'t available right now'**
  String get searchFailed;

  /// No description provided for @categoryCar.
  ///
  /// In en, this message translates to:
  /// **'Car'**
  String get categoryCar;

  /// No description provided for @categoryMarket.
  ///
  /// In en, this message translates to:
  /// **'Market'**
  String get categoryMarket;

  /// No description provided for @categoryHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get categoryHome;

  /// No description provided for @categoryPharmacy.
  ///
  /// In en, this message translates to:
  /// **'Pharmacy'**
  String get categoryPharmacy;

  /// No description provided for @categoryWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get categoryWork;

  /// No description provided for @categoryRestaurant.
  ///
  /// In en, this message translates to:
  /// **'Restaurant'**
  String get categoryRestaurant;

  /// No description provided for @categoryHospital.
  ///
  /// In en, this message translates to:
  /// **'Hospital'**
  String get categoryHospital;

  /// No description provided for @categorySchool.
  ///
  /// In en, this message translates to:
  /// **'School'**
  String get categorySchool;

  /// No description provided for @categoryGym.
  ///
  /// In en, this message translates to:
  /// **'Gym'**
  String get categoryGym;

  /// No description provided for @categoryMosque.
  ///
  /// In en, this message translates to:
  /// **'Mosque'**
  String get categoryMosque;

  /// No description provided for @categoryFuel.
  ///
  /// In en, this message translates to:
  /// **'Fuel'**
  String get categoryFuel;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get categoryOther;

  /// No description provided for @carSaved.
  ///
  /// In en, this message translates to:
  /// **'Car location saved'**
  String get carSaved;

  /// No description provided for @spotSaved.
  ///
  /// In en, this message translates to:
  /// **'{name} saved'**
  String spotSaved(String name);

  /// No description provided for @spotDeleted.
  ///
  /// In en, this message translates to:
  /// **'{name} deleted'**
  String spotDeleted(String name);

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @renameSpotTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename spot'**
  String get renameSpotTitle;

  /// No description provided for @showOnWidget.
  ///
  /// In en, this message translates to:
  /// **'Show on widget'**
  String get showOnWidget;

  /// No description provided for @removeFromWidget.
  ///
  /// In en, this message translates to:
  /// **'Remove from widget'**
  String get removeFromWidget;

  /// No description provided for @favoriteSet.
  ///
  /// In en, this message translates to:
  /// **'{name} is now on your widget'**
  String favoriteSet(String name);

  /// No description provided for @favoriteRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed from your widget'**
  String get favoriteRemoved;

  /// No description provided for @locationUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Can\'t get your location yet'**
  String get locationUnavailable;

  /// No description provided for @couldNotOpenMaps.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open a maps app'**
  String get couldNotOpenMaps;

  /// No description provided for @couldNotOpenLink.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the link'**
  String get couldNotOpenLink;

  /// No description provided for @permissionDeniedTitle.
  ///
  /// In en, this message translates to:
  /// **'Location is off for Feen'**
  String get permissionDeniedTitle;

  /// No description provided for @permissionDeniedMessage.
  ///
  /// In en, this message translates to:
  /// **'Allow location to see distances and park your car.'**
  String get permissionDeniedMessage;

  /// No description provided for @serviceDisabledTitle.
  ///
  /// In en, this message translates to:
  /// **'Location services are off'**
  String get serviceDisabledTitle;

  /// No description provided for @serviceDisabledMessage.
  ///
  /// In en, this message translates to:
  /// **'Turn on location to see where you are.'**
  String get serviceDisabledMessage;

  /// No description provided for @allow.
  ///
  /// In en, this message translates to:
  /// **'Allow'**
  String get allow;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @turnOn.
  ///
  /// In en, this message translates to:
  /// **'Turn on'**
  String get turnOn;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @appearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get appearance;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'Device language'**
  String get languageSystem;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageArabic.
  ///
  /// In en, this message translates to:
  /// **'العربية'**
  String get languageArabic;

  /// No description provided for @languageArabicEg.
  ///
  /// In en, this message translates to:
  /// **'Arabic (Egypt)'**
  String get languageArabicEg;

  /// No description provided for @languageArabicSa.
  ///
  /// In en, this message translates to:
  /// **'Arabic (Saudi Arabia)'**
  String get languageArabicSa;

  /// No description provided for @yourSpots.
  ///
  /// In en, this message translates to:
  /// **'Your spots'**
  String get yourSpots;

  /// No description provided for @shareAllAsText.
  ///
  /// In en, this message translates to:
  /// **'Share all spots as text'**
  String get shareAllAsText;

  /// No description provided for @about.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// No description provided for @website.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get website;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy policy'**
  String get privacyPolicy;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of use'**
  String get termsOfUse;

  /// No description provided for @contactSupport.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get contactSupport;

  /// No description provided for @rateApp.
  ///
  /// In en, this message translates to:
  /// **'Rate the app'**
  String get rateApp;

  /// No description provided for @versionFooter.
  ///
  /// In en, this message translates to:
  /// **'Version {version}. Your spots stay on this phone.'**
  String versionFooter(String version);

  /// No description provided for @nothingToShare.
  ///
  /// In en, this message translates to:
  /// **'No spots to share yet'**
  String get nothingToShare;

  /// No description provided for @shareSubject.
  ///
  /// In en, this message translates to:
  /// **'My spots'**
  String get shareSubject;

  /// No description provided for @favoriteBadge.
  ///
  /// In en, this message translates to:
  /// **'On widget'**
  String get favoriteBadge;

  /// No description provided for @widgetPark.
  ///
  /// In en, this message translates to:
  /// **'Park'**
  String get widgetPark;

  /// No description provided for @widgetFindCar.
  ///
  /// In en, this message translates to:
  /// **'Find car'**
  String get widgetFindCar;

  /// No description provided for @widgetNoCar.
  ///
  /// In en, this message translates to:
  /// **'No car saved'**
  String get widgetNoCar;

  /// No description provided for @widgetNoFavorite.
  ///
  /// In en, this message translates to:
  /// **'Pick a spot'**
  String get widgetNoFavorite;

  /// No description provided for @carArrivalTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re at your car!'**
  String get carArrivalTitle;

  /// No description provided for @carArrivalMessage.
  ///
  /// In en, this message translates to:
  /// **'You have returned to your parked car.'**
  String get carArrivalMessage;

  /// No description provided for @iFoundMyCar.
  ///
  /// In en, this message translates to:
  /// **'I found my car'**
  String get iFoundMyCar;

  /// No description provided for @cantSeeCar.
  ///
  /// In en, this message translates to:
  /// **'Haven\'t seen the car yet'**
  String get cantSeeCar;

  /// No description provided for @carFoundCelebration.
  ///
  /// In en, this message translates to:
  /// **'Great! Have a safe drive.'**
  String get carFoundCelebration;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboarding1Title.
  ///
  /// In en, this message translates to:
  /// **'Never forget where you parked'**
  String get onboarding1Title;

  /// No description provided for @onboarding1Body.
  ///
  /// In en, this message translates to:
  /// **'Save your car with one tap, then open it in Maps when you are ready to walk back. No more wandering around the car park.'**
  String get onboarding1Body;

  /// No description provided for @onboarding2Title.
  ///
  /// In en, this message translates to:
  /// **'All your places, one spot'**
  String get onboarding2Title;

  /// No description provided for @onboarding2Body.
  ///
  /// In en, this message translates to:
  /// **'Your market, home, pharmacy and more live in one list and on one map. Share any spot, or all of them, with a map link anytime.'**
  String get onboarding2Body;

  /// No description provided for @onboarding3Title.
  ///
  /// In en, this message translates to:
  /// **'Your places stay on your phone'**
  String get onboarding3Title;

  /// No description provided for @onboarding3Body.
  ///
  /// In en, this message translates to:
  /// **'Everything is saved only on this device and never sent anywhere. Allow location so you can save your car and see where you are.'**
  String get onboarding3Body;

  /// No description provided for @onboardingAllowLocation.
  ///
  /// In en, this message translates to:
  /// **'Allow location access'**
  String get onboardingAllowLocation;

  /// No description provided for @onboardingNotNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get onboardingNotNow;

  /// No description provided for @notificationParkingTitle.
  ///
  /// In en, this message translates to:
  /// **'Car parked'**
  String get notificationParkingTitle;

  /// No description provided for @notificationDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance: {distance}'**
  String notificationDistance(String distance);

  /// No description provided for @carTrackingNotificationSettingTitle.
  ///
  /// In en, this message translates to:
  /// **'Car distance notification'**
  String get carTrackingNotificationSettingTitle;

  /// No description provided for @carTrackingNotificationSettingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pinned live notification while walking to your parked car'**
  String get carTrackingNotificationSettingSubtitle;

  /// No description provided for @carTrackingWalkingTitle.
  ///
  /// In en, this message translates to:
  /// **'Your car is {distance} away'**
  String carTrackingWalkingTitle(String distance);

  /// No description provided for @carTrackingAboutMinutes.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{About 1 min walk} other{About {count} min walk}}'**
  String carTrackingAboutMinutes(int count);

  /// No description provided for @carTrackingLessThanMinute.
  ///
  /// In en, this message translates to:
  /// **'Less than a minute walk'**
  String get carTrackingLessThanMinute;

  /// No description provided for @carTrackingArrivedTitle.
  ///
  /// In en, this message translates to:
  /// **'Your car is right here'**
  String get carTrackingArrivedTitle;

  /// No description provided for @carTrackingArrivedBody.
  ///
  /// In en, this message translates to:
  /// **'You are within 15 m'**
  String get carTrackingArrivedBody;

  /// No description provided for @carTrackingLookingForLocation.
  ///
  /// In en, this message translates to:
  /// **'Looking for your location...'**
  String get carTrackingLookingForLocation;

  /// No description provided for @carTrackingWaitingForGps.
  ///
  /// In en, this message translates to:
  /// **'Waiting for GPS signal'**
  String get carTrackingWaitingForGps;

  /// No description provided for @carTrackingDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get carTrackingDone;

  /// No description provided for @carTrackingStop.
  ///
  /// In en, this message translates to:
  /// **'Stop tracking'**
  String get carTrackingStop;

  /// No description provided for @carTrackingTooFar.
  ///
  /// In en, this message translates to:
  /// **'Your car is too far for walking tracking'**
  String get carTrackingTooFar;

  /// No description provided for @carTrackingActiveBanner.
  ///
  /// In en, this message translates to:
  /// **'Tracking walk to car'**
  String get carTrackingActiveBanner;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when language+country codes are specified.
  switch (locale.languageCode) {
    case 'ar':
      {
        switch (locale.countryCode) {
          case 'EG':
            return AppLocalizationsArEg();
          case 'SA':
            return AppLocalizationsArSa();
        }
        break;
      }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
