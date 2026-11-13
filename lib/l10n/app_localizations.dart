import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
  static const List<Locale> supportedLocales = <Locale>[Locale('ko')];

  /// No description provided for @appTitle.
  ///
  /// In ko, this message translates to:
  /// **'헬스가드'**
  String get appTitle;

  /// No description provided for @login.
  ///
  /// In ko, this message translates to:
  /// **'로그인'**
  String get login;

  /// No description provided for @id.
  ///
  /// In ko, this message translates to:
  /// **'아이디'**
  String get id;

  /// No description provided for @user_number.
  ///
  /// In ko, this message translates to:
  /// **'근로자번호'**
  String get user_number;

  /// No description provided for @password.
  ///
  /// In ko, this message translates to:
  /// **'비밀번호'**
  String get password;

  /// No description provided for @sir.
  ///
  /// In ko, this message translates to:
  /// **'님'**
  String get sir;

  /// No description provided for @work_start.
  ///
  /// In ko, this message translates to:
  /// **'업무 시작하기'**
  String get work_start;

  /// No description provided for @work_rest.
  ///
  /// In ko, this message translates to:
  /// **'휴식하기'**
  String get work_rest;

  /// No description provided for @rest_start.
  ///
  /// In ko, this message translates to:
  /// **'휴식 시작'**
  String get rest_start;

  /// No description provided for @pause.
  ///
  /// In ko, this message translates to:
  /// **'일시정지'**
  String get pause;

  /// No description provided for @work_end.
  ///
  /// In ko, this message translates to:
  /// **'근무종료'**
  String get work_end;

  /// No description provided for @work_history.
  ///
  /// In ko, this message translates to:
  /// **'근무기록'**
  String get work_history;

  /// No description provided for @emergency.
  ///
  /// In ko, this message translates to:
  /// **'긴급 SOS'**
  String get emergency;

  /// No description provided for @connect_pic.
  ///
  /// In ko, this message translates to:
  /// **'담당자 연결'**
  String get connect_pic;

  /// No description provided for @bpm.
  ///
  /// In ko, this message translates to:
  /// **'심박수'**
  String get bpm;

  /// No description provided for @temperature.
  ///
  /// In ko, this message translates to:
  /// **'체온'**
  String get temperature;

  /// No description provided for @spo2.
  ///
  /// In ko, this message translates to:
  /// **'산소포화도'**
  String get spo2;

  /// No description provided for @is_fall.
  ///
  /// In ko, this message translates to:
  /// **'낙상여부'**
  String get is_fall;

  /// No description provided for @close.
  ///
  /// In ko, this message translates to:
  /// **'닫기'**
  String get close;

  /// No description provided for @notice.
  ///
  /// In ko, this message translates to:
  /// **'주의'**
  String get notice;

  /// No description provided for @warning.
  ///
  /// In ko, this message translates to:
  /// **'경고'**
  String get warning;

  /// No description provided for @danger.
  ///
  /// In ko, this message translates to:
  /// **'위험'**
  String get danger;

  /// No description provided for @alarm.
  ///
  /// In ko, this message translates to:
  /// **'알람'**
  String get alarm;

  /// No description provided for @color_blue.
  ///
  /// In ko, this message translates to:
  /// **'#2760F4'**
  String get color_blue;

  /// No description provided for @color_appbar.
  ///
  /// In ko, this message translates to:
  /// **'#1E2A38'**
  String get color_appbar;

  /// No description provided for @color_orange.
  ///
  /// In ko, this message translates to:
  /// **'#D87706'**
  String get color_orange;

  /// No description provided for @color_yellow_light.
  ///
  /// In ko, this message translates to:
  /// **'#F9FDE6'**
  String get color_yellow_light;

  /// No description provided for @color_green.
  ///
  /// In ko, this message translates to:
  /// **'#14A44F'**
  String get color_green;

  /// No description provided for @color_red.
  ///
  /// In ko, this message translates to:
  /// **'#DD2527'**
  String get color_red;

  /// No description provided for @color_notice_bg.
  ///
  /// In ko, this message translates to:
  /// **'#FFC83D'**
  String get color_notice_bg;

  /// No description provided for @color_warning_bg.
  ///
  /// In ko, this message translates to:
  /// **'#FF8A1F'**
  String get color_warning_bg;

  /// No description provided for @color_danger_bg.
  ///
  /// In ko, this message translates to:
  /// **'#C8102E'**
  String get color_danger_bg;

  /// No description provided for @color_alert_text.
  ///
  /// In ko, this message translates to:
  /// **'#2B2100'**
  String get color_alert_text;

  /// No description provided for @font_size.
  ///
  /// In ko, this message translates to:
  /// **'20.0'**
  String get font_size;

  /// No description provided for @font_size_sub.
  ///
  /// In ko, this message translates to:
  /// **'15.0'**
  String get font_size_sub;

  /// No description provided for @font_size_big.
  ///
  /// In ko, this message translates to:
  /// **'30.0'**
  String get font_size_big;

  /// No description provided for @font_size_mega.
  ///
  /// In ko, this message translates to:
  /// **'40.0'**
  String get font_size_mega;
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
      <String>['ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
