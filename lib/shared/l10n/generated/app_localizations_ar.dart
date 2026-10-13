// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'دليلى';

  @override
  String get homeGreeting => 'على دليلى؟';

  @override
  String savedSpotsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مكان محفوظ',
      many: '$count مكانًا محفوظًا',
      few: '$count أماكن محفوظة',
      two: 'مكانان محفوظان',
      one: 'مكان واحد محفوظ',
      zero: 'لا توجد أماكن محفوظة',
    );
    return '$_temp0';
  }

  @override
  String get mapButton => 'الخريطة';

  @override
  String get settingsTooltip => 'الإعدادات';

  @override
  String get backTooltip => 'رجوع';

  @override
  String get myCar => 'سيارتي';

  @override
  String parkedAgo(String time) {
    return '$time     ';
  }

  @override
  String get noCarTitle => 'أين ركنت سيارتك؟';

  @override
  String get noCarMessage => 'غير مركونة';

  @override
  String distanceAway(String distance) {
    return 'على بُعد $distance';
  }

  @override
  String get openInMaps => 'افتح في الخرائط';

  @override
  String get parkHere => 'اركن هنا';

  @override
  String get onMap => 'على الخريطة';

  @override
  String get foundMyCar => 'وجدت سيارتي';

  @override
  String get carCleared => 'تم مسح موقع السيارة';

  @override
  String get savedSpots => 'الأماكن المحفوظة';

  @override
  String get shareAll => 'مشاركة الكل';

  @override
  String get showOnMap => 'على الخريطة';

  @override
  String get openMap => 'افتح الخريطة';

  @override
  String get whereMyCarTitle => 'وين سيارتى؟';

  @override
  String get share => 'مشاركة';

  @override
  String get saveThisSpot => 'ضيف مكان جديد';

  @override
  String get addSpot => 'إضافة مكان';

  @override
  String savedAgo(String time) {
    return 'حُفظ $time';
  }

  @override
  String get timeJustNow => 'الآن';

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count دقيقة',
      many: 'منذ $count دقيقة',
      few: 'منذ $count دقائق',
      two: 'منذ دقيقتين',
      one: 'منذ دقيقة',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count ساعة',
      many: 'منذ $count ساعة',
      few: 'منذ $count ساعات',
      two: 'منذ ساعتين',
      one: 'منذ ساعة',
    );
    return '$_temp0';
  }

  @override
  String get timeYesterday => 'أمس';

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count يوم',
      many: 'منذ $count يومًا',
      few: 'منذ $count أيام',
      two: 'منذ يومين',
      one: 'منذ يوم',
    );
    return '$_temp0';
  }

  @override
  String timeWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count أسبوع',
      many: 'منذ $count أسبوعًا',
      few: 'منذ $count أسابيع',
      two: 'منذ أسبوعين',
      one: 'منذ أسبوع',
    );
    return '$_temp0';
  }

  @override
  String timeMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count شهر',
      many: 'منذ $count شهرًا',
      few: 'منذ $count أشهر',
      two: 'منذ شهرين',
      one: 'منذ شهر',
    );
    return '$_temp0';
  }

  @override
  String timeYearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count سنة',
      many: 'منذ $count سنة',
      few: 'منذ $count سنوات',
      two: 'منذ سنتين',
      one: 'منذ سنة',
    );
    return '$_temp0';
  }

  @override
  String distanceMeters(String value) {
    return '$value م';
  }

  @override
  String distanceKilometers(String value) {
    return '$value كم';
  }

  @override
  String get emptySpotsTitle => 'لا توجد أماكن بعد';

  @override
  String get emptySpotsMessage =>
      'احفظ الأماكن التي تريد العودة إليها — السوق، البيت، الصيدلية…';

  @override
  String get seeAllOnMap => 'عرض كل الأماكن على الخريطة';

  @override
  String get myLocation => 'موقعي';

  @override
  String get searchPlaceHint => 'ابحث عن مكان';

  @override
  String get clearSearch => 'مسح البحث';

  @override
  String get movePinHint => 'حرّك الخريطة لوضع الدبوس';

  @override
  String get nameLabel => 'الاسم';

  @override
  String get nameHint => 'مثال: الصيدلية';

  @override
  String get nameRequired => 'أعطِ المكان اسمًا';

  @override
  String get saveHere => 'احفظ هنا';

  @override
  String get savedLocallyNote => 'يُحفظ على هذا الهاتف فقط. لا حاجة لحساب.';

  @override
  String get noSearchResults => 'لم يتم العثور على أماكن';

  @override
  String get searchFailed => 'البحث غير متاح حاليًا';

  @override
  String get categoryCar => 'سيارة';

  @override
  String get categoryMarket => 'سوق';

  @override
  String get categoryHome => 'البيت';

  @override
  String get categoryPharmacy => 'صيدلية';

  @override
  String get categoryWork => 'العمل';

  @override
  String get categoryRestaurant => 'مطعم';

  @override
  String get categoryHospital => 'مستشفى';

  @override
  String get categorySchool => 'مدرسة';

  @override
  String get categoryGym => 'نادي رياضي';

  @override
  String get categoryMosque => 'مسجد';

  @override
  String get categoryFuel => 'محطة وقود';

  @override
  String get categoryPark => 'حديقة';

  @override
  String get categoryClub => 'نادي';

  @override
  String get categoryBeautyCenter => 'مركز تجميل';

  @override
  String get categoryOther => 'بدون';

  @override
  String get carSaved => 'تم حفظ موقع السيارة';

  @override
  String spotSaved(String name) {
    return 'تم حفظ $name';
  }

  @override
  String spotDeleted(String name) {
    return 'تم حذف $name';
  }

  @override
  String get undo => 'تراجع';

  @override
  String get delete => 'حذف';

  @override
  String get rename => 'إعادة تسمية';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get renameSpotTitle => 'إعادة تسمية المكان';

  @override
  String get showOnWidget => 'إظهار في الودجت';

  @override
  String get removeFromWidget => 'إزالة من الودجت';

  @override
  String favoriteSet(String name) {
    return '$name يظهر الآن في الودجت';
  }

  @override
  String get favoriteRemoved => 'تمت الإزالة من الودجت';

  @override
  String get locationUnavailable => 'تعذّر تحديد موقعك بعد';

  @override
  String get couldNotOpenMaps => 'تعذّر فتح تطبيق الخرائط';

  @override
  String get couldNotOpenLink => 'تعذّر فتح الرابط';

  @override
  String get permissionDeniedTitle => 'الموقع غير مفعّل لتطبيق دليلى';

  @override
  String get permissionDeniedMessage =>
      'اسمح بالوصول إلى الموقع لرؤية المسافات وركن سيارتك.';

  @override
  String get serviceDisabledTitle => 'خدمات الموقع متوقفة';

  @override
  String get serviceDisabledMessage => 'فعّل خدمات الموقع لمعرفة مكانك.';

  @override
  String get allow => 'السماح';

  @override
  String get openSettings => 'فتح الإعدادات';

  @override
  String get turnOn => 'تفعيل';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get appearance => 'المظهر';

  @override
  String get theme => 'السمة';

  @override
  String get themeSystem => 'النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get language => 'اللغة';

  @override
  String get languageSystem => 'لغة الجهاز';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageArabicEg => 'عربي (مصر)';

  @override
  String get languageArabicSa => 'عربي (السعودية)';

  @override
  String get yourSpots => 'أماكنك';

  @override
  String get shareAllAsText => 'مشاركة كل الأماكن كنص';

  @override
  String get about => 'حول التطبيق';

  @override
  String get website => 'الموقع الإلكتروني';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get contactWhatsApp => 'تواصل عبر واتساب';

  @override
  String get contactSupport => 'تواصل مع الدعم';

  @override
  String get rateApp => 'قيّم التطبيق';

  @override
  String versionFooter(String version) {
    return 'الإصدار $version. أماكنك تبقى على هذا الهاتف.';
  }

  @override
  String get nothingToShare => 'لا توجد أماكن للمشاركة بعد';

  @override
  String get shareSubject => 'أماكني';

  @override
  String get favoriteBadge => 'في الودجت';

  @override
  String get widgetPark => 'اركن';

  @override
  String get widgetFindCar => 'سيارتي';

  @override
  String get widgetNoCar => 'لا توجد سيارة محفوظة';

  @override
  String get widgetNoFavorite => 'اختر مكانًا';

  @override
  String get carArrivalTitle => 'أنت أمام سيارتك!';

  @override
  String get carArrivalMessage => 'لقد وصلت إلى موقع سيارتك المركونة.';

  @override
  String get iFoundMyCar => 'وجدت سيارتي';

  @override
  String get cantSeeCar => 'لم أرَ السيارة بعد';

  @override
  String get carFoundCelebration => 'تم! نتمنى لك قيادة آمنة.';

  @override
  String get onboardingSkip => 'تخطي';

  @override
  String get onboardingNext => 'التالي';

  @override
  String get onboarding1Title => 'لا تنسَ أين أوقفت سيارتك';

  @override
  String get onboarding1Body =>
      'احفظ مكان سيارتك بضغطة واحدة، وافتحه في الخرائط عندما تريد العودة. لا مزيد من البحث والحيرة.';

  @override
  String get onboarding2Title => 'كل أماكنك في مكان واحد';

  @override
  String get onboarding2Body =>
      'سوبرماركتك، منزلك، الصيدلية والمزيد في قائمة واحدة وعلى خريطة واحدة. شارك أي مكان برابط في أي وقت.';

  @override
  String get onboarding3Title => 'أماكنك تظل على هاتفك فقط';

  @override
  String get onboarding3Body =>
      'كل شيء محفوظ محلياً على هذا الجهاز ولا يُرسل لأي مكان. اسمح بالوصول للموقع لحفظ سيارتك ومعرفة مكانك.';

  @override
  String get onboardingAllowLocation => 'السماح بالوصول للموقع';

  @override
  String get onboardingNotNow => 'ليس الآن';

  @override
  String get notificationParkingTitle => 'السيارة مركونة';

  @override
  String notificationDistance(String distance) {
    return 'المسافة: $distance';
  }

  @override
  String get carTrackingNotificationSettingTitle => 'إشعار المسافة إلى السيارة';

  @override
  String get carTrackingNotificationSettingSubtitle =>
      'إشعار مباشر مثبت أثناء المشي نحو سيارتك';

  @override
  String carTrackingWalkingTitle(String distance) {
    return 'سيارتك على بعد $distance';
  }

  @override
  String carTrackingAboutMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'حوالي $count دقيقة سيرًا',
      many: 'حوالي $count دقيقة سيرًا',
      few: 'حوالي $count دقائق سيرًا',
      two: 'حوالي دقيقتين سيرًا',
      one: 'حوالي دقيقة سيرًا',
    );
    return '$_temp0';
  }

  @override
  String get carTrackingLessThanMinute => 'أقل من دقيقة سيرًا';

  @override
  String get carTrackingArrivedTitle => 'سيارتك هنا';

  @override
  String get carTrackingArrivedBody => 'أنت على بعد أقل من 15 م';

  @override
  String get carTrackingLookingForLocation => 'جارٍ تحديد موقعك...';

  @override
  String get carTrackingWaitingForGps => 'في انتظار إشارة GPS';

  @override
  String get carTrackingDone => 'تم';

  @override
  String get carTrackingStop => 'إيقاف التتبع';

  @override
  String get carTrackingTooFar => 'سيارتك بعيدة جدًا لتتبع المشي';

  @override
  String get carTrackingActiveBanner => 'جارٍ تتبع المشي إلى السيارة';

  @override
  String get searchSpots => 'البحث في الأماكن';

  @override
  String get searchSpotsPlaceholder => 'ابحث بالاسم أو الفئة...';

  @override
  String get noSpotsFound => 'لم يتم العثور على أماكن';

  @override
  String get noSpotsFoundDesc => 'جرّب البحث باسم أو فئة أخرى';

  @override
  String get exportData => 'تصدير البيانات';

  @override
  String get exportSpotsTitle => 'تصدير الأماكن';

  @override
  String get exportAsExcel => 'تصدير كملف Excel (CSV)';

  @override
  String get exportAsExcelSubtitle =>
      'جدول بيانات مع الإحداثيات وروابط الخرائط';

  @override
  String get exportAsText => 'تصدير كنص';

  @override
  String get exportAsTextSubtitle => 'قائمة منسقة مع روابط الخرائط';

  @override
  String get exportSubject => 'أماكن دليلى';
}

/// The translations for Arabic, as used in Egypt (`ar_EG`).
class AppLocalizationsArEg extends AppLocalizationsAr {
  AppLocalizationsArEg() : super('ar_EG');

  @override
  String get appTitle => 'دليلى';

  @override
  String get homeGreeting => 'على فين؟';

  @override
  String savedSpotsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مكان محفوظ',
      many: '$count مكان محفوظ',
      few: '$count أماكن محفوظة',
      two: 'مكانين محفوظين',
      one: 'مكان واحد محفوظ',
      zero: 'مفيش أماكن محفوظة',
    );
    return '$_temp0';
  }

  @override
  String get mapButton => 'الخريطة';

  @override
  String get settingsTooltip => 'الإعدادات';

  @override
  String get backTooltip => 'رجوع';

  @override
  String get myCar => 'عربيتي';

  @override
  String parkedAgo(String time) {
    return '$time';
  }

  @override
  String get noCarTitle => 'ركنت عربيتك فين؟';

  @override
  String get noCarMessage => 'مش مركونة';

  @override
  String distanceAway(String distance) {
    return 'على بُعد $distance';
  }

  @override
  String get openInMaps => 'افتح في الخريطة';

  @override
  String get parkHere => 'اركن هنا';

  @override
  String get onMap => 'على الخريطة';

  @override
  String get foundMyCar => 'لقيت عربيتي';

  @override
  String get carCleared => 'تم مسح موقع العربية';

  @override
  String get savedSpots => 'الأماكن المحفوظة';

  @override
  String get shareAll => 'مشاركة الكل';

  @override
  String get showOnMap => 'على الخريطة';

  @override
  String get openMap => 'افتح الخريطة';

  @override
  String get whereMyCarTitle => 'عربيتي فين؟';

  @override
  String get share => 'مشاركة';

  @override
  String get saveThisSpot => 'ضيف مكان جديد';

  @override
  String get addSpot => 'ضيف مكان';

  @override
  String savedAgo(String time) {
    return 'اتحفظ $time';
  }

  @override
  String get timeJustNow => 'دلوقتي';

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'من $count دقيقة',
      many: 'من $count دقيقة',
      few: 'من $count دقائق',
      two: 'من دقيقتين',
      one: 'من دقيقة',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'من $count ساعة',
      many: 'من $count ساعة',
      few: 'من $count ساعات',
      two: 'من ساعتين',
      one: 'من ساعة',
    );
    return '$_temp0';
  }

  @override
  String get timeYesterday => 'إمبارح';

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'من $count يوم',
      many: 'من $count يوم',
      few: 'من $count أيام',
      two: 'من يومين',
      one: 'من يوم',
    );
    return '$_temp0';
  }

  @override
  String timeWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'من $count أسبوع',
      many: 'من $count أسبوع',
      few: 'من $count أسابيع',
      two: 'من أسبوعين',
      one: 'من أسبوع',
    );
    return '$_temp0';
  }

  @override
  String timeMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'من $count شهر',
      many: 'من $count شهر',
      few: 'من $count شهور',
      two: 'من شهرين',
      one: 'من شهر',
    );
    return '$_temp0';
  }

  @override
  String timeYearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'من $count سنة',
      many: 'من $count سنة',
      few: 'من $count سنين',
      two: 'من سنتين',
      one: 'من سنة',
    );
    return '$_temp0';
  }

  @override
  String distanceMeters(String value) {
    return '$value م';
  }

  @override
  String distanceKilometers(String value) {
    return '$value كم';
  }

  @override
  String get emptySpotsTitle => 'مفيش أماكن لسه';

  @override
  String get emptySpotsMessage =>
      'احفظ الأماكن اللي عايز ترجعلها تاني — السوبر ماركت، البيت، الصيدلية…';

  @override
  String get seeAllOnMap => 'شوف كل الأماكن على الخريطة';

  @override
  String get myLocation => 'موقعي';

  @override
  String get searchPlaceHint => 'دور على مكان';

  @override
  String get clearSearch => 'مسح البحث';

  @override
  String get movePinHint => 'حرك الخريطة عشان تحط الدبوس';

  @override
  String get nameLabel => 'الاسم';

  @override
  String get nameHint => 'مثال: الصيدلية';

  @override
  String get nameRequired => 'اكتب اسم للمكان';

  @override
  String get saveHere => 'احفظ هنا';

  @override
  String get savedLocallyNote => 'محفوظ على الموبايل ده بس. من غير حساب.';

  @override
  String get noSearchResults => 'ملقيناش أماكن';

  @override
  String get searchFailed => 'البحث مش شغال دلوقتي';

  @override
  String get categoryCar => 'عربية';

  @override
  String get categoryMarket => 'سوبر ماركت';

  @override
  String get categoryHome => 'البيت';

  @override
  String get categoryPharmacy => 'صيدلية';

  @override
  String get categoryWork => 'الشغل';

  @override
  String get categoryRestaurant => 'مطعم';

  @override
  String get categoryHospital => 'مستشفى';

  @override
  String get categorySchool => 'مدرسة';

  @override
  String get categoryGym => 'جيم';

  @override
  String get categoryMosque => 'جامع';

  @override
  String get categoryFuel => 'بنزينة';

  @override
  String get categoryPark => 'حديقة';

  @override
  String get categoryClub => 'نادي';

  @override
  String get categoryBeautyCenter => 'بيوتي سنتر';

  @override
  String get categoryOther => 'بدون';

  @override
  String get carSaved => 'تم حفظ موقع العربية';

  @override
  String spotSaved(String name) {
    return 'تم حفظ $name';
  }

  @override
  String spotDeleted(String name) {
    return 'تم مسح $name';
  }

  @override
  String get undo => 'تراجع';

  @override
  String get delete => 'مسح';

  @override
  String get rename => 'تغيير الاسم';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get renameSpotTitle => 'تغيير اسم المكان';

  @override
  String get showOnWidget => 'إظهار في الودجت';

  @override
  String get removeFromWidget => 'إزالة من الودجت';

  @override
  String favoriteSet(String name) {
    return '$name بيظهر دلوقتي في الودجت';
  }

  @override
  String get favoriteRemoved => 'اتشال من الودجت';

  @override
  String get locationUnavailable => 'مش عارفين نحدد موقعك لسه';

  @override
  String get couldNotOpenMaps => 'مش عارفين نفتح تطبيق الخرائط';

  @override
  String get couldNotOpenLink => 'مش عارفين نفتح الرابط';

  @override
  String get permissionDeniedTitle => 'الموقع مقفول لتطبيق فين';

  @override
  String get permissionDeniedMessage =>
      'اسمح للتطبيق بالوصول للموقع عشان تشوف المسافات وتركن عربيتك.';

  @override
  String get serviceDisabledTitle => 'خدمات الموقع مقفولة';

  @override
  String get serviceDisabledMessage => 'شغّل خدمات الموقع عشان تعرف مكانك.';

  @override
  String get allow => 'السماح';

  @override
  String get openSettings => 'فتح الإعدادات';

  @override
  String get turnOn => 'تشغيل';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get appearance => 'المظهر';

  @override
  String get theme => 'السمة';

  @override
  String get themeSystem => 'النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get language => 'اللغة';

  @override
  String get languageSystem => 'لغة الجهاز';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageArabicEg => 'عربي (مصر)';

  @override
  String get languageArabicSa => 'عربي (السعودية)';

  @override
  String get yourSpots => 'أماكنك';

  @override
  String get shareAllAsText => 'مشاركة كل الأماكن كنص';

  @override
  String get about => 'عن التطبيق';

  @override
  String get website => 'الموقع الإلكتروني';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get contactWhatsApp => 'تواصل عبر واتساب';

  @override
  String get contactSupport => 'تواصل مع الدعم';

  @override
  String get rateApp => 'قيّم التطبيق';

  @override
  String versionFooter(String version) {
    return 'الإصدار $version. أماكنك بتفضل على الموبايل ده بس.';
  }

  @override
  String get nothingToShare => 'مفيش أماكن للمشاركة لسه';

  @override
  String get shareSubject => 'أماكني';

  @override
  String get favoriteBadge => 'في الودجت';

  @override
  String get widgetPark => 'اركن';

  @override
  String get widgetFindCar => 'عربيتي';

  @override
  String get widgetNoCar => 'مفيش عربية محفوظة';

  @override
  String get widgetNoFavorite => 'اختار مكان';

  @override
  String get carArrivalTitle => 'أنت قدام عربيتك!';

  @override
  String get carArrivalMessage => 'وصلت لمكان عربيتك المركونة.';

  @override
  String get iFoundMyCar => 'لقيت عربيتي';

  @override
  String get cantSeeCar => 'لسه مشوفتش العربيه';

  @override
  String get carFoundCelebration => 'تم! طريق السلامة.';

  @override
  String get onboardingSkip => 'تخطي';

  @override
  String get onboardingNext => 'التالي';

  @override
  String get onboarding1Title => 'مش هتنسى ركنت فين أبداً';

  @override
  String get onboarding1Body =>
      'احفظ مكان عربيتك بضغطة واحدة، وافتحها في الخرايط لما ترجع. مفيش تدوير على العربية تاني.';

  @override
  String get onboarding2Title => 'كل أماكنك في حتة واحدة';

  @override
  String get onboarding2Body =>
      'السوبرماركت، البيت، الصيدلية وكل مشاويرك في قايمة وخريطة واحدة. شير أي مكان بلينك في أي وقت.';

  @override
  String get onboarding3Title => 'أماكنك بتفضل على موبايلك بس';

  @override
  String get onboarding3Body =>
      'كل حاجة متسجلة على موبايلك ومبتروحش لأي سيرفر. اسمح بالموقع عشان تحفظ عربيتك وتشوف مكانك.';

  @override
  String get onboardingAllowLocation => 'السماح بالوصول للموقع';

  @override
  String get onboardingNotNow => 'مش دلوقتي';

  @override
  String get notificationParkingTitle => 'العربية مركونة';

  @override
  String notificationDistance(String distance) {
    return 'المسافة: $distance';
  }

  @override
  String get searchSpots => 'دور في الأماكن';

  @override
  String get searchSpotsPlaceholder => 'دور بالاسم أو الفئة...';

  @override
  String get noSpotsFound => 'ملقناش أماكن';

  @override
  String get noSpotsFoundDesc => 'جرب تدور باسم أو فئة تانية';
}

/// The translations for Arabic, as used in Saudi Arabia (`ar_SA`).
class AppLocalizationsArSa extends AppLocalizationsAr {
  AppLocalizationsArSa() : super('ar_SA');

  @override
  String get appTitle => 'دليلى';

  @override
  String get homeGreeting => 'وين رايح؟';

  @override
  String savedSpotsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مكان محفوظ',
      many: '$count مكانًا محفوظًا',
      few: '$count أماكن محفوظة',
      two: 'مكانان محفوظان',
      one: 'مكان واحد محفوظ',
      zero: 'لا توجد أماكن محفوظة',
    );
    return '$_temp0';
  }

  @override
  String get mapButton => 'الخريطة';

  @override
  String get settingsTooltip => 'الإعدادات';

  @override
  String get backTooltip => 'رجوع';

  @override
  String get myCar => 'سيارتي';

  @override
  String parkedAgo(String time) {
    return '$time';
  }

  @override
  String get noCarTitle => 'أين وقفت سيارتك؟';

  @override
  String get noCarMessage => 'مو واقفة';

  @override
  String distanceAway(String distance) {
    return 'على بُعد $distance';
  }

  @override
  String get openInMaps => 'افتح في الخرائط';

  @override
  String get parkHere => 'وقف هنا';

  @override
  String get onMap => 'على الخريطة';

  @override
  String get foundMyCar => 'لقيت سيارتي';

  @override
  String get carCleared => 'تم مسح موقع السيارة';

  @override
  String get savedSpots => 'الأماكن المحفوظة';

  @override
  String get shareAll => 'مشاركة الكل';

  @override
  String get showOnMap => 'على الخريطة';

  @override
  String get openMap => 'افتح الخريطة';

  @override
  String get whereMyCarTitle => 'وين سيارتى؟';

  @override
  String get share => 'مشاركة';

  @override
  String get saveThisSpot => 'أضف مكان جديد';

  @override
  String get addSpot => 'أضف مكان';

  @override
  String savedAgo(String time) {
    return 'حُفظ $time';
  }

  @override
  String get timeJustNow => 'الآن';

  @override
  String timeMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count دقيقة',
      many: 'منذ $count دقيقة',
      few: 'منذ $count دقائق',
      two: 'منذ دقيقتين',
      one: 'منذ دقيقة',
    );
    return '$_temp0';
  }

  @override
  String timeHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count ساعة',
      many: 'منذ $count ساعة',
      few: 'منذ $count ساعات',
      two: 'منذ ساعتين',
      one: 'منذ ساعة',
    );
    return '$_temp0';
  }

  @override
  String get timeYesterday => 'أمس';

  @override
  String timeDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count يوم',
      many: 'منذ $count يومًا',
      few: 'منذ $count أيام',
      two: 'منذ يومين',
      one: 'منذ يوم',
    );
    return '$_temp0';
  }

  @override
  String timeWeeksAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count أسبوع',
      many: 'منذ $count أسبوعًا',
      few: 'منذ $count أسابيع',
      two: 'منذ أسبوعين',
      one: 'منذ أسبوع',
    );
    return '$_temp0';
  }

  @override
  String timeMonthsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count شهر',
      many: 'منذ $count شهرًا',
      few: 'منذ $count أشهر',
      two: 'منذ شهرين',
      one: 'منذ شهر',
    );
    return '$_temp0';
  }

  @override
  String timeYearsAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'منذ $count سنة',
      many: 'منذ $count سنة',
      few: 'منذ $count سنوات',
      two: 'منذ سنتين',
      one: 'منذ سنة',
    );
    return '$_temp0';
  }

  @override
  String distanceMeters(String value) {
    return '$value م';
  }

  @override
  String distanceKilometers(String value) {
    return '$value كم';
  }

  @override
  String get emptySpotsTitle => 'لا توجد أماكن بعد';

  @override
  String get emptySpotsMessage =>
      'احفظ الأماكن التي تريد العودة إليها — السوق، البيت، الصيدلية…';

  @override
  String get seeAllOnMap => 'عرض كل الأماكن على الخريطة';

  @override
  String get myLocation => 'موقعي';

  @override
  String get searchPlaceHint => 'ابحث عن مكان';

  @override
  String get clearSearch => 'مسح البحث';

  @override
  String get movePinHint => 'حرّك الخريطة لوضع الدبوس';

  @override
  String get nameLabel => 'الاسم';

  @override
  String get nameHint => 'مثال: الصيدلية';

  @override
  String get nameRequired => 'أعطِ المكان اسمًا';

  @override
  String get saveHere => 'احفظ هنا';

  @override
  String get savedLocallyNote => 'يُحفظ على هذا الجوال فقط. بدون حساب.';

  @override
  String get noSearchResults => 'لم يتم العثور على أماكن';

  @override
  String get searchFailed => 'البحث غير متاح حاليًا';

  @override
  String get categoryCar => 'سيارة';

  @override
  String get categoryMarket => 'بقالة / سوق';

  @override
  String get categoryHome => 'البيت';

  @override
  String get categoryPharmacy => 'صيدلية';

  @override
  String get categoryWork => 'الدوام';

  @override
  String get categoryRestaurant => 'مطعم';

  @override
  String get categoryHospital => 'مستشفى';

  @override
  String get categorySchool => 'مدرسة';

  @override
  String get categoryGym => 'نادي رياضي';

  @override
  String get categoryMosque => 'مسجد';

  @override
  String get categoryFuel => 'محطة وقود';

  @override
  String get categoryPark => 'حديقة';

  @override
  String get categoryClub => 'نادي';

  @override
  String get categoryBeautyCenter => 'مركز تجميل';

  @override
  String get categoryOther => 'بدون';

  @override
  String get carSaved => 'تم حفظ موقع السيارة';

  @override
  String spotSaved(String name) {
    return 'تم حفظ $name';
  }

  @override
  String spotDeleted(String name) {
    return 'تم حذف $name';
  }

  @override
  String get undo => 'تراجع';

  @override
  String get delete => 'حذف';

  @override
  String get rename => 'إعادة تسمية';

  @override
  String get cancel => 'إلغاء';

  @override
  String get save => 'حفظ';

  @override
  String get renameSpotTitle => 'إعادة تسمية المكان';

  @override
  String get showOnWidget => 'إظهار في الودجت';

  @override
  String get removeFromWidget => 'إزالة من الودجت';

  @override
  String favoriteSet(String name) {
    return '$name يظهر الآن في الودجت';
  }

  @override
  String get favoriteRemoved => 'تمت الإزالة من الودجت';

  @override
  String get locationUnavailable => 'تعذّر تحديد موقعك بعد';

  @override
  String get couldNotOpenMaps => 'تعذّر فتح تطبيق الخرائط';

  @override
  String get couldNotOpenLink => 'تعذّر فتح الرابط';

  @override
  String get permissionDeniedTitle => 'الموقع غير مفعّل لتطبيق دليلى';

  @override
  String get permissionDeniedMessage =>
      'اسمح بالوصول إلى الموقع لرؤية المسافات وموقع سيارتك.';

  @override
  String get serviceDisabledTitle => 'خدمات الموقع متوقفة';

  @override
  String get serviceDisabledMessage => 'فعّل خدمات الموقع لمعرفة مكانك.';

  @override
  String get allow => 'السماح';

  @override
  String get openSettings => 'فتح الإعدادات';

  @override
  String get turnOn => 'تفعيل';

  @override
  String get settingsTitle => 'الإعدادات';

  @override
  String get appearance => 'المظهر';

  @override
  String get theme => 'السمة';

  @override
  String get themeSystem => 'النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get language => 'اللغة';

  @override
  String get languageSystem => 'لغة الجهاز';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'العربية';

  @override
  String get languageArabicEg => 'عربي (مصر)';

  @override
  String get languageArabicSa => 'عربي (السعودية)';

  @override
  String get yourSpots => 'أماكنك';

  @override
  String get shareAllAsText => 'مشاركة كل الأماكن كنص';

  @override
  String get about => 'حول التطبيق';

  @override
  String get website => 'الموقع الإلكتروني';

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get contactWhatsApp => 'تواصل عبر واتساب';

  @override
  String get contactSupport => 'تواصل مع الدعم';

  @override
  String get rateApp => 'قيّم التطبيق';

  @override
  String versionFooter(String version) {
    return 'الإصدار $version. أماكنك تبقى على هذا الجوال.';
  }

  @override
  String get nothingToShare => 'لا توجد أماكن للمشاركة بعد';

  @override
  String get shareSubject => 'أماكني';

  @override
  String get favoriteBadge => 'في الودجت';

  @override
  String get widgetPark => 'وقف';

  @override
  String get widgetFindCar => 'سيارتي';

  @override
  String get widgetNoCar => 'لا توجد سيارة محفوظة';

  @override
  String get widgetNoFavorite => 'اختر مكانًا';

  @override
  String get carArrivalTitle => 'أنت عند سيارتك!';

  @override
  String get carArrivalMessage => 'لقد وصلت إلى موقع سيارتك.';

  @override
  String get iFoundMyCar => 'لقيت سيارتي';

  @override
  String get cantSeeCar => 'لسه ما شفت السيارة';

  @override
  String get carFoundCelebration => 'تم! درب السلامة.';

  @override
  String get onboardingSkip => 'تخطي';

  @override
  String get onboardingNext => 'التالي';

  @override
  String get onboarding1Title => 'ما راح تنسى وين وقفت سيارتك';

  @override
  String get onboarding1Body =>
      'احفظ مكان سيارتك بضغطة زر، وافتحها في الخرايط وقت ما ترجع. وداعاً للبحث واللف في المواقف.';

  @override
  String get onboarding2Title => 'كل أماكنك بمكان واحد';

  @override
  String get onboarding2Body =>
      'البقالة، البيت، الصيدلية وكل مشاويرك بقائمة وخريطة وحدة. شارك أي موقع برابط بأي وقت.';

  @override
  String get onboarding3Title => 'أماكنك محفوظة بجهازك بس';

  @override
  String get onboarding3Body =>
      'كل بياناتك محفوظة بجهازك وما تنرسل لأي مكان. اسمح بالموقع عشان تحفظ سيارتك وتشوف وين أنت.';

  @override
  String get onboardingAllowLocation => 'السماح بالوصول للموقع';

  @override
  String get onboardingNotNow => 'مو الحين';

  @override
  String get notificationParkingTitle => 'السيارة موقفة';

  @override
  String notificationDistance(String distance) {
    return 'المسافة: $distance';
  }

  @override
  String get searchSpots => 'ابحث في الأماكن';

  @override
  String get searchSpotsPlaceholder => 'ابحث باسم المكان أو الفئة...';

  @override
  String get noSpotsFound => 'ما لقينا أماكن';

  @override
  String get noSpotsFoundDesc => 'جرّب تبحث باسم أو تصنيف ثاني';
}
