// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swedish (`sv`).
class AppLocalizationsSv extends AppLocalizations {
  AppLocalizationsSv([String locale = 'sv']) : super(locale);

  @override
  String get appTitle => 'DiveBubble';

  @override
  String get introSubtitle =>
      'Hitta dyktrip, träffa dina buddies och planera logistiken tillsammans.';

  @override
  String get diveIn => 'Kom igång';

  @override
  String get skipForNow => 'Hoppa över';

  @override
  String get signIn => 'Logga in';

  @override
  String get enterYourEmail => 'Ange din e-post';

  @override
  String get enterCodeSentToYou => 'Ange koden vi skickade';

  @override
  String get continueWithGoogle => 'Fortsätt med Google';

  @override
  String get continueWithApple => 'Fortsätt med Apple';

  @override
  String get continueWithEmail => 'Fortsätt med e-post';

  @override
  String enterCodeSentTo(String email) {
    return 'Ange koden som skickades till $email';
  }

  @override
  String get verify => 'Verifiera';

  @override
  String get useADifferentEmail => 'Använd en annan e-post';

  @override
  String get email => 'E-post';

  @override
  String get sendCode => 'Skicka kod';

  @override
  String get useADifferentSignInMethod => 'Använd en annan inloggningsmetod';

  @override
  String get stayInTheLoop => 'Håll dig uppdaterad';

  @override
  String get pushPermissionBody =>
      'Få aviseringar om nya meddelanden, ändringar i resor och vem som ansluter sig till din skjuts. Du kan stänga av det när som helst i profilinställningarna.';

  @override
  String get continueLabel => 'Fortsätt';

  @override
  String get notNow => 'Inte nu';

  @override
  String get addYourCertifications => 'Lägg till dina certifieringar';

  @override
  String get certificationsOnboardingBody =>
      'Din nivå visar andra dykare att du är redo för en resa, och vissa resor kräver en lägsta nivå för att delta. Du kan lägga till eller ändra det när som helst från din profil.';

  @override
  String get level => 'Nivå';

  @override
  String get pleaseSelectALevel => 'Välj en nivå';

  @override
  String get selectLevel => 'Välj nivå';

  @override
  String get agencyOptional => 'Organisation (valfritt)';

  @override
  String get notSet => 'Inte angivet';

  @override
  String get certificationNumberOptional => 'Certifieringsnummer (valfritt)';

  @override
  String get saveAndContinue => 'Spara och fortsätt';
}
