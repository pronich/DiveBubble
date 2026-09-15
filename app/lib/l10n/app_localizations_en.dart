// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'DiveBubble';

  @override
  String get introSubtitle =>
      'Find dive trips, meet your buddies, and plan the logistics together.';

  @override
  String get diveIn => 'Dive in';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get signIn => 'Sign in';

  @override
  String get enterYourEmail => 'Enter your email';

  @override
  String get enterCodeSentToYou => 'Enter the code we sent you';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get continueWithEmail => 'Continue with email';

  @override
  String enterCodeSentTo(String email) {
    return 'Enter the code we sent to $email';
  }

  @override
  String get verify => 'Verify';

  @override
  String get useADifferentEmail => 'Use a different email';

  @override
  String get email => 'Email';

  @override
  String get sendCode => 'Send code';

  @override
  String get useADifferentSignInMethod => 'Use a different sign-in method';

  @override
  String get stayInTheLoop => 'Stay in the loop';

  @override
  String get pushPermissionBody =>
      'Get notified about new messages, trip changes, and who\'s joining your rides. You can turn this off anytime in Profile settings.';

  @override
  String get continueLabel => 'Continue';

  @override
  String get notNow => 'Not now';

  @override
  String get addYourCertifications => 'Add your certifications';

  @override
  String get certificationsOnboardingBody =>
      'Your level shows other divers you\'re ready for a trip, and some trips require a minimum level to join. You can add or change this anytime from your profile.';

  @override
  String get level => 'Level';

  @override
  String get pleaseSelectALevel => 'Please select a level';

  @override
  String get selectLevel => 'Select level';

  @override
  String get agencyOptional => 'Agency (optional)';

  @override
  String get notSet => 'Not set';

  @override
  String get certificationNumberOptional => 'Certification number (optional)';

  @override
  String get saveAndContinue => 'Save and continue';
}
