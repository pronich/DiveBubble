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

  @override
  String errorWithMessage(String error) {
    return 'Fejl: $error';
  }

  @override
  String get cancel => 'Annuller';

  @override
  String get delete => 'Slet';

  @override
  String get you => 'Dig';

  @override
  String get diver => 'Dykker';

  @override
  String get searchBubbles => 'Søg i Bubbles';

  @override
  String get noMatches => 'Ingen resultater.';

  @override
  String get share => 'Del';

  @override
  String get documentFallbackName => 'Dokument.pdf';

  @override
  String get copiedToClipboard => 'Kopieret';

  @override
  String get deleteThisMessageTitle => 'Slet denne besked?';

  @override
  String get deleteThisMessageBody =>
      'Dette kan ikke fortrydes — den fjernes for alle i dette Bubble.';

  @override
  String couldNotDeleteMessage(String error) {
    return 'Kunne ikke slette beskeden: $error';
  }

  @override
  String couldNotReact(String error) {
    return 'Kunne ikke reagere: $error';
  }

  @override
  String get reply => 'Svar';

  @override
  String get copyText => 'Kopiér tekst';

  @override
  String get report => 'Anmeld';

  @override
  String get removeDocumentFirst =>
      'Fjern dokumentet først for at tilføje fotos.';

  @override
  String onlyNAttachmentsAllowed(int max) {
    return 'Kun $max vedhæftninger tilladt pr. besked.';
  }

  @override
  String get documentOnlyOnItsOwn => 'Et dokument kan kun sendes alene.';

  @override
  String get someFilesTooLarge => 'Nogle filer er for store.';

  @override
  String couldNotSendAttachment(String error) {
    return 'Kunne ikke sende vedhæftning: $error';
  }

  @override
  String get noMessagesYet => 'Ingen beskeder endnu';

  @override
  String get tripCancelledReadOnly =>
      'Denne tur er blevet aflyst — chatten er skrivebeskyttet.';

  @override
  String replyingTo(String name) {
    return 'Svarer til $name';
  }

  @override
  String get captionOptional => 'Billedtekst (valgfrit)';

  @override
  String get messageHint => 'Besked';

  @override
  String get messageDeleted => 'Besked slettet';

  @override
  String attachmentsCountLabel(int count) {
    return '📎 $count vedhæftninger';
  }

  @override
  String get photoLabel => '📷 Foto';

  @override
  String get videoLabel => '🎬 Video';

  @override
  String get pdfLabel => '📄 PDF';

  @override
  String get newMessages => 'Nye beskeder';

  @override
  String get productObserver => 'Product Observer';

  @override
  String get reportMessageTitle => 'Anmeld besked';

  @override
  String get detailsOptional => 'Detaljer (valgfrit)';

  @override
  String get sendReport => 'Send anmeldelse';

  @override
  String get reportSentThankYou => 'Anmeldelse sendt — tak.';

  @override
  String couldNotSendReport(String error) {
    return 'Kunne ikke sende anmeldelse: $error';
  }

  @override
  String get thankYou => 'Tak!';

  @override
  String get giveFeedback => 'Giv feedback';

  @override
  String get howUsefulQuestion => 'Hvor nyttig var DiveBubble for denne tur?';

  @override
  String get whatDidHelpQuestion => 'Hvad hjalp DiveBubble dig med?';

  @override
  String get whatShouldImproveQuestion => 'Hvad bør vi forbedre?';

  @override
  String get optionalHintText => 'Valgfrit';

  @override
  String get canContactAboutFeedback => 'Må vi kontakte dig om din feedback?';

  @override
  String get submitFeedback => 'Send feedback';

  @override
  String couldNotSendFeedback(String error) {
    return 'Kunne ikke sende feedback: $error';
  }

  @override
  String get reportReasonSpam => 'Spam';

  @override
  String get reportReasonHarassment => 'Chikane';

  @override
  String get reportReasonInappropriateContent => 'Upassende indhold';

  @override
  String get reportReasonOther => 'Andet';

  @override
  String get helpedWithTripInformation => 'Turinformation';

  @override
  String get helpedWithChattingWithParticipants => 'Chat med deltagere';

  @override
  String get helpedWithFindingTransport => 'Finde transport';

  @override
  String get helpedWithFindingBuddy => 'Finde buddy';

  @override
  String get helpedWithNothingYet => 'Intet endnu';

  @override
  String couldNotSharePhoto(String error) {
    return 'Kunne ikke dele foto: $error';
  }

  @override
  String couldNotShareVideo(String error) {
    return 'Kunne ikke dele video: $error';
  }

  @override
  String get couldNotLoadVideo => 'Kunne ikke indlæse video';

  @override
  String couldNotLoadMedia(String error) {
    return 'Kunne ikke indlæse medier: $error';
  }

  @override
  String get noPhotosOrVideosSharedYet =>
      'Ingen fotos eller videoer delt endnu';

  @override
  String couldNotLoadFiles(String error) {
    return 'Kunne ikke indlæse filer: $error';
  }

  @override
  String get noFilesSharedYet => 'Ingen filer delt endnu';

  @override
  String couldNotLoadLinks(String error) {
    return 'Kunne ikke indlæse links: $error';
  }

  @override
  String get noLinksSharedYet => 'Ingen links delt endnu';

  @override
  String get shareToABubble => 'Del til et Bubble';

  @override
  String get noBubblesYet => 'Ingen Bubbles endnu';

  @override
  String get joinATripToShareInto =>
      'Tilmeld dig en tur for at få et Bubble at dele til.';

  @override
  String get bubblesTabTitle => 'Bubbles';

  @override
  String get diveLogTabTitle => 'Dykkerlog';

  @override
  String get profileTabTitle => 'Profil';

  @override
  String get signInToSeeYourTrips => 'Log ind for at se dine ture';

  @override
  String get logInToViewTripsBody =>
      'Log ind for at se de ture, du har tilmeldt dig, og deres gruppechats.';

  @override
  String get startYourFirstBubble => 'Start dit første Bubble';

  @override
  String get startYourFirstBubbleBody =>
      'Opret en tur, eller tilmeld dig med en kode — chat, transport og turdetaljer samlet ét sted.';

  @override
  String get createTrip => 'Opret tur';

  @override
  String get joinTrip => 'Deltag';

  @override
  String get chatTabLabel => 'Chat';

  @override
  String get transportTabLabel => 'Transport';

  @override
  String get buddyTabLabel => 'Buddy';

  @override
  String get expensesTabLabel => 'Udgifter';

  @override
  String get archive => 'Arkivér';

  @override
  String get unarchive => 'Fjern fra arkiv';

  @override
  String get cancelTrip => 'Aflys tur';

  @override
  String get leave => 'Forlad';

  @override
  String couldNotArchive(String error) {
    return 'Kunne ikke arkivere: $error';
  }

  @override
  String couldNotUnarchive(String error) {
    return 'Kunne ikke fjerne fra arkiv: $error';
  }

  @override
  String get leaveBubbleTitle => 'Forlad dette Bubble?';

  @override
  String get leaveBubbleBody =>
      'Du mister din plads og kan tilmelde dig igen senere, hvis der er plads.';

  @override
  String couldNotLeave(String error) {
    return 'Kunne ikke forlade: $error';
  }

  @override
  String get cancelTripTitle => 'Aflys denne tur?';

  @override
  String get cancelTripBody =>
      'Alle deltagere beholder Bubble\'en for at se chathistorikken, men ingen — heller ikke dig — kan sende beskeder, tilmelde sig eller arrangere transport længere. Dette kan ikke fortrydes.';

  @override
  String get neverMind => 'Fortryd';

  @override
  String couldNotCancel(String error) {
    return 'Kunne ikke aflyse: $error';
  }

  @override
  String get cancelledStatus => 'Aflyst';

  @override
  String get pastStatus => 'Afsluttet';

  @override
  String get activeStatus => 'Aktiv';

  @override
  String get archivedChats => 'Arkiverede chats';

  @override
  String get noArchivedChats => 'Ingen arkiverede chats';

  @override
  String get archivedChatsEmptyBody =>
      'Bubbles, du arkiverer, vises her — swipe eller fjern fra arkiv for at hente en tilbage.';
}
