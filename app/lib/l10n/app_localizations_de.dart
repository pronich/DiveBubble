// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'DiveBubble';

  @override
  String get introSubtitle =>
      'Finde Tauchtrips, triff deine Buddys und plant die Logistik gemeinsam.';

  @override
  String get diveIn => 'Loslegen';

  @override
  String get skipForNow => 'Später';

  @override
  String get signIn => 'Anmelden';

  @override
  String get enterYourEmail => 'Gib deine E-Mail-Adresse ein';

  @override
  String get enterCodeSentToYou => 'Gib den gesendeten Code ein';

  @override
  String get continueWithGoogle => 'Weiter mit Google';

  @override
  String get continueWithApple => 'Weiter mit Apple';

  @override
  String get continueWithEmail => 'Weiter mit E-Mail';

  @override
  String enterCodeSentTo(String email) {
    return 'Gib den Code ein, der an $email gesendet wurde';
  }

  @override
  String get verify => 'Bestätigen';

  @override
  String get useADifferentEmail => 'Andere E-Mail-Adresse verwenden';

  @override
  String get email => 'E-Mail';

  @override
  String get sendCode => 'Code senden';

  @override
  String get useADifferentSignInMethod => 'Andere Anmeldemethode verwenden';

  @override
  String get stayInTheLoop => 'Bleib auf dem Laufenden';

  @override
  String get pushPermissionBody =>
      'Erhalte Benachrichtigungen zu neuen Nachrichten, Änderungen an Trips und wer deiner Fahrt beitritt. Du kannst dies jederzeit in den Profileinstellungen deaktivieren.';

  @override
  String get continueLabel => 'Weiter';

  @override
  String get notNow => 'Nicht jetzt';

  @override
  String get addYourCertifications => 'Füge deine Zertifizierungen hinzu';

  @override
  String get certificationsOnboardingBody =>
      'Dein Level zeigt anderen Tauchern, dass du bereit für einen Trip bist, und manche Trips erfordern ein Mindestlevel. Du kannst dies jederzeit in deinem Profil ändern.';

  @override
  String get level => 'Level';

  @override
  String get pleaseSelectALevel => 'Bitte wähle ein Level aus';

  @override
  String get selectLevel => 'Level auswählen';

  @override
  String get agencyOptional => 'Verband (optional)';

  @override
  String get notSet => 'Nicht festgelegt';

  @override
  String get certificationNumberOptional => 'Zertifikatsnummer (optional)';

  @override
  String get saveAndContinue => 'Speichern und weiter';
}
