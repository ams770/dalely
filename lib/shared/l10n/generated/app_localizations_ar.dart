// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'فين';

  @override
  String get homeGreeting => 'على فين؟';

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
    return 'ركنتها $time';
  }

  @override
  String get noCarTitle => 'أين ركنت سيارتك؟';

  @override
  String get noCarMessage => 'اضغط «اركن هنا» عندما تترك السيارة.';

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
  String get share => 'مشاركة';

  @override
  String get saveThisSpot => 'احفظ هذا المكان';

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
  String get categoryOther => 'أخرى';

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
  String get permissionDeniedTitle => 'الموقع غير مفعّل لتطبيق فين';

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
  String get termsOfUse => 'شروط الاستخدام';

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
  String get cantSeeCar => 'لا أستطيع رؤية السيارة';

  @override
  String get carFoundCelebration => 'تم! نتمنى لك قيادة آمنة.';
}
