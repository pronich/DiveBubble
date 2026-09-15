// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Danish (`da`).
class AppLocalizationsDa extends AppLocalizations {
  AppLocalizationsDa([String locale = 'da']) : super(locale);

  @override
  String get appTitle => 'DiveBubble';

  @override
  String get introSubtitle =>
      'Find dyveture, mød dine buddies, og planlæg logistikken sammen.';

  @override
  String get diveIn => 'Kom i gang';

  @override
  String get skipForNow => 'Spring over';

  @override
  String get signIn => 'Log ind';

  @override
  String get enterYourEmail => 'Indtast din e-mail';

  @override
  String get enterCodeSentToYou => 'Indtast den kode, vi sendte';

  @override
  String get continueWithGoogle => 'Fortsæt med Google';

  @override
  String get continueWithApple => 'Fortsæt med Apple';

  @override
  String get continueWithEmail => 'Fortsæt med e-mail';

  @override
  String enterCodeSentTo(String email) {
    return 'Indtast koden sendt til $email';
  }

  @override
  String get verify => 'Bekræft';

  @override
  String get useADifferentEmail => 'Brug en anden e-mail';

  @override
  String get email => 'E-mail';

  @override
  String get sendCode => 'Send kode';

  @override
  String get useADifferentSignInMethod => 'Brug en anden loginmetode';

  @override
  String get stayInTheLoop => 'Hold dig opdateret';

  @override
  String get pushPermissionBody =>
      'Få besked om nye beskeder, ændringer i ture, og hvem der tilslutter sig dine ture. Du kan altid slå det fra i profilindstillingerne.';

  @override
  String get continueLabel => 'Fortsæt';

  @override
  String get notNow => 'Ikke nu';

  @override
  String get addYourCertifications => 'Tilføj dine certificeringer';

  @override
  String get certificationsOnboardingBody =>
      'Dit niveau viser andre dykkere, at du er klar til en tur, og nogle ture kræver et minimumsniveau for at deltage. Du kan altid tilføje eller ændre det fra din profil.';

  @override
  String get level => 'Niveau';

  @override
  String get pleaseSelectALevel => 'Vælg venligst et niveau';

  @override
  String get selectLevel => 'Vælg niveau';

  @override
  String get agencyOptional => 'Organisation (valgfrit)';

  @override
  String get notSet => 'Ikke angivet';

  @override
  String get certificationNumberOptional => 'Certificeringsnummer (valgfrit)';

  @override
  String get saveAndContinue => 'Gem og fortsæt';
}
