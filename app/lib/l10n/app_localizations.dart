import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_da.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_sv.dart';

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
    Locale('da'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('ru'),
    Locale('sv'),
  ];

  /// The application's name, shown as the OS task-switcher/home-screen label. Not user-visible in-app UI — kept here mainly to prove the gen-l10n pipeline end to end before the real string-extraction pass (see the translations plan).
  ///
  /// In en, this message translates to:
  /// **'DiveBubble'**
  String get appTitle;

  /// Subtitle under the DiveBubble wordmark on the animated first-run intro screen.
  ///
  /// In en, this message translates to:
  /// **'Find dive trips, meet your buddies, and plan the logistics together.'**
  String get introSubtitle;

  /// Primary CTA button that opens the sign-in sheet — used on the intro screen and the guest Profile tab.
  ///
  /// In en, this message translates to:
  /// **'Dive in'**
  String get diveIn;

  /// Secondary button to skip an optional onboarding step (intro screen, certifications onboarding).
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// Title of the sign-in bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// Validation error shown when the diver taps 'Send code' with an empty email field.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterYourEmail;

  /// Validation error shown when the diver taps 'Verify' with an empty code field.
  ///
  /// In en, this message translates to:
  /// **'Enter the code we sent you'**
  String get enterCodeSentToYou;

  /// Sign-in button.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// Sign-in button, iOS only.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// Sign-in button that reveals the email/OTP form.
  ///
  /// In en, this message translates to:
  /// **'Continue with email'**
  String get continueWithEmail;

  /// Prompt shown above the OTP code field, naming the address the code was sent to.
  ///
  /// In en, this message translates to:
  /// **'Enter the code we sent to {email}'**
  String enterCodeSentTo(String email);

  /// Button that submits the email OTP code.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// Button that backs out of the OTP-code step to re-enter the email address.
  ///
  /// In en, this message translates to:
  /// **'Use a different email'**
  String get useADifferentEmail;

  /// Label of the email text field in the sign-in sheet.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Button that requests an email OTP code.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// Button that backs out of the email form to the Google/Apple/email choice.
  ///
  /// In en, this message translates to:
  /// **'Use a different sign-in method'**
  String get useADifferentSignInMethod;

  /// Headline on the push-notification permission onboarding screen.
  ///
  /// In en, this message translates to:
  /// **'Stay in the loop'**
  String get stayInTheLoop;

  /// Body copy on the push-notification permission onboarding screen.
  ///
  /// In en, this message translates to:
  /// **'Get notified about new messages, trip changes, and who\'s joining your rides. You can turn this off anytime in Profile settings.'**
  String get pushPermissionBody;

  /// Generic 'Continue' button, e.g. on the push-permission onboarding screen.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// Button to decline an optional permission request during onboarding (push notifications).
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// Headline on the certifications onboarding screen.
  ///
  /// In en, this message translates to:
  /// **'Add your certifications'**
  String get addYourCertifications;

  /// Body copy on the certifications onboarding screen.
  ///
  /// In en, this message translates to:
  /// **'Your level shows other divers you\'re ready for a trip, and some trips require a minimum level to join. You can add or change this anytime from your profile.'**
  String get certificationsOnboardingBody;

  /// Label of the certification level dropdown.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// Validation error shown when saving certifications without picking a level.
  ///
  /// In en, this message translates to:
  /// **'Please select a level'**
  String get pleaseSelectALevel;

  /// Placeholder hint text in the certification level dropdown.
  ///
  /// In en, this message translates to:
  /// **'Select level'**
  String get selectLevel;

  /// Label of the certification agency dropdown.
  ///
  /// In en, this message translates to:
  /// **'Agency (optional)'**
  String get agencyOptional;

  /// Placeholder value meaning no certification agency was chosen.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// Label of the certification number text field.
  ///
  /// In en, this message translates to:
  /// **'Certification number (optional)'**
  String get certificationNumberOptional;

  /// Button that saves the certifications onboarding step.
  ///
  /// In en, this message translates to:
  /// **'Save and continue'**
  String get saveAndContinue;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'da',
    'de',
    'en',
    'es',
    'ru',
    'sv',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'da':
      return AppLocalizationsDa();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'ru':
      return AppLocalizationsRu();
    case 'sv':
      return AppLocalizationsSv();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
