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

  @override
  String errorWithMessage(String error) {
    return 'Fel: $error';
  }

  @override
  String get cancel => 'Avbryt';

  @override
  String get delete => 'Ta bort';

  @override
  String get you => 'Du';

  @override
  String get diver => 'Dykare';

  @override
  String get searchBubbles => 'Sök bland Bubbles';

  @override
  String get noMatches => 'Inga träffar.';

  @override
  String get share => 'Dela';

  @override
  String get documentFallbackName => 'Dokument.pdf';

  @override
  String get copiedToClipboard => 'Kopierat';

  @override
  String get deleteThisMessageTitle => 'Ta bort det här meddelandet?';

  @override
  String get deleteThisMessageBody =>
      'Detta kan inte ångras — det tas bort för alla i detta Bubble.';

  @override
  String couldNotDeleteMessage(String error) {
    return 'Kunde inte ta bort meddelandet: $error';
  }

  @override
  String couldNotReact(String error) {
    return 'Kunde inte reagera: $error';
  }

  @override
  String get reply => 'Svara';

  @override
  String get copyText => 'Kopiera text';

  @override
  String get report => 'Anmäl';

  @override
  String get removeDocumentFirst =>
      'Ta bort dokumentet först för att lägga till foton.';

  @override
  String onlyNAttachmentsAllowed(int max) {
    return 'Endast $max bilagor tillåtna per meddelande.';
  }

  @override
  String get documentOnlyOnItsOwn =>
      'Ett dokument kan bara skickas för sig själv.';

  @override
  String get someFilesTooLarge => 'Vissa filer är för stora.';

  @override
  String couldNotSendAttachment(String error) {
    return 'Kunde inte skicka bilagan: $error';
  }

  @override
  String get noMessagesYet => 'Inga meddelanden än';

  @override
  String get tripCancelledReadOnly =>
      'Den här resan har ställts in — chatten är skrivskyddad.';

  @override
  String replyingTo(String name) {
    return 'Svarar till $name';
  }

  @override
  String get captionOptional => 'Bildtext (valfritt)';

  @override
  String get messageHint => 'Meddelande';

  @override
  String get messageDeleted => 'Meddelandet togs bort';

  @override
  String attachmentsCountLabel(int count) {
    return '📎 $count bilagor';
  }

  @override
  String get photoLabel => '📷 Foto';

  @override
  String get videoLabel => '🎬 Video';

  @override
  String get pdfLabel => '📄 PDF';

  @override
  String get newMessages => 'Nya meddelanden';

  @override
  String get productObserver => 'Product Observer';

  @override
  String get reportMessageTitle => 'Anmäl meddelande';

  @override
  String get detailsOptional => 'Detaljer (valfritt)';

  @override
  String get sendReport => 'Skicka anmälan';

  @override
  String get reportSentThankYou => 'Anmälan skickad — tack.';

  @override
  String couldNotSendReport(String error) {
    return 'Kunde inte skicka anmälan: $error';
  }

  @override
  String get thankYou => 'Tack!';

  @override
  String get giveFeedback => 'Ge feedback';

  @override
  String get howUsefulQuestion =>
      'Hur användbar var DiveBubble för den här resan?';

  @override
  String get whatDidHelpQuestion => 'Vad hjälpte DiveBubble dig med?';

  @override
  String get whatShouldImproveQuestion => 'Vad bör vi förbättra?';

  @override
  String get optionalHintText => 'Valfritt';

  @override
  String get canContactAboutFeedback => 'Får vi kontakta dig om din feedback?';

  @override
  String get submitFeedback => 'Skicka feedback';

  @override
  String couldNotSendFeedback(String error) {
    return 'Kunde inte skicka feedback: $error';
  }

  @override
  String get reportReasonSpam => 'Spam';

  @override
  String get reportReasonHarassment => 'Trakasserier';

  @override
  String get reportReasonInappropriateContent => 'Olämpligt innehåll';

  @override
  String get reportReasonOther => 'Annat';

  @override
  String get helpedWithTripInformation => 'Reseinformation';

  @override
  String get helpedWithChattingWithParticipants => 'Chatta med deltagare';

  @override
  String get helpedWithFindingTransport => 'Hitta transport';

  @override
  String get helpedWithFindingBuddy => 'Hitta buddy';

  @override
  String get helpedWithNothingYet => 'Inget än';

  @override
  String couldNotSharePhoto(String error) {
    return 'Kunde inte dela foto: $error';
  }

  @override
  String couldNotShareVideo(String error) {
    return 'Kunde inte dela video: $error';
  }

  @override
  String get couldNotLoadVideo => 'Kunde inte läsa in video';

  @override
  String couldNotLoadMedia(String error) {
    return 'Kunde inte läsa in media: $error';
  }

  @override
  String get noPhotosOrVideosSharedYet => 'Inga foton eller videor delade än';

  @override
  String couldNotLoadFiles(String error) {
    return 'Kunde inte läsa in filer: $error';
  }

  @override
  String get noFilesSharedYet => 'Inga filer delade än';

  @override
  String couldNotLoadLinks(String error) {
    return 'Kunde inte läsa in länkar: $error';
  }

  @override
  String get noLinksSharedYet => 'Inga länkar delade än';

  @override
  String get shareToABubble => 'Dela till ett Bubble';

  @override
  String get noBubblesYet => 'Inga Bubbles än';

  @override
  String get joinATripToShareInto =>
      'Gå med i en resa för att få ett Bubble att dela till.';

  @override
  String get bubblesTabTitle => 'Bubbles';

  @override
  String get diveLogTabTitle => 'Dykloggbok';

  @override
  String get profileTabTitle => 'Profil';

  @override
  String get signInToSeeYourTrips => 'Logga in för att se dina resor';

  @override
  String get logInToViewTripsBody =>
      'Logga in för att se resorna du gått med i och deras gruppchattar.';

  @override
  String get startYourFirstBubble => 'Starta ditt första Bubble';

  @override
  String get startYourFirstBubbleBody =>
      'Skapa en resa eller gå med via en kod — chatt, transport och resedetaljer på ett ställe.';

  @override
  String get createTrip => 'Skapa resa';

  @override
  String get joinTrip => 'Gå med';

  @override
  String get chatTabLabel => 'Chatt';

  @override
  String get transportTabLabel => 'Transport';

  @override
  String get buddyTabLabel => 'Buddy';

  @override
  String get expensesTabLabel => 'Utgifter';

  @override
  String get archive => 'Arkivera';

  @override
  String get unarchive => 'Återställ från arkiv';

  @override
  String get cancelTrip => 'Ställ in resa';

  @override
  String get leave => 'Lämna';

  @override
  String couldNotArchive(String error) {
    return 'Kunde inte arkivera: $error';
  }

  @override
  String couldNotUnarchive(String error) {
    return 'Kunde inte återställa från arkiv: $error';
  }

  @override
  String get leaveBubbleTitle => 'Lämna det här Bubble?';

  @override
  String get leaveBubbleBody =>
      'Du förlorar din plats och kan gå med igen senare om det finns plats.';

  @override
  String couldNotLeave(String error) {
    return 'Kunde inte lämna: $error';
  }

  @override
  String get cancelTripTitle => 'Ställa in den här resan?';

  @override
  String get cancelTripBody =>
      'Alla deltagare behåller Bubble för att se chatthistoriken, men ingen — inte heller du — kan längre skicka meddelanden, gå med eller ordna transport. Detta kan inte ångras.';

  @override
  String get neverMind => 'Strunt i det';

  @override
  String couldNotCancel(String error) {
    return 'Kunde inte ställa in: $error';
  }

  @override
  String get cancelledStatus => 'Inställd';

  @override
  String get pastStatus => 'Avslutad';

  @override
  String get activeStatus => 'Aktiv';

  @override
  String get archivedChats => 'Arkiverade chattar';

  @override
  String get noArchivedChats => 'Inga arkiverade chattar';

  @override
  String get archivedChatsEmptyBody =>
      'Bubbles du arkiverar visas här — svep eller återställ för att få tillbaka en.';

  @override
  String get typeOfferRide => 'Erbjuder skjuts';

  @override
  String get typeShareRental => 'Delar en hyrbil';

  @override
  String get carCancelledByOrganizer =>
      'Den här bilen ställdes in av arrangören.';

  @override
  String get noTransportWasArranged => 'Ingen transport ordnades';

  @override
  String get beFirstToShareTransport => 'Bli först med att dela transport';

  @override
  String get tripCancelledSimple => 'Den här resan har ställts in.';

  @override
  String get offerRideOrShareRental =>
      'Erbjud skjuts eller dela en hyrbil så att andra kan haka på.';

  @override
  String get addTransportInfo => 'Lägg till transport';

  @override
  String seatsTakenLabel(int joined, int total) {
    return '$joined av $total platser upptagna';
  }

  @override
  String get joinedStatus => 'Med';

  @override
  String get fullStatus => 'Fullt';

  @override
  String get organizerLabel => 'Arrangör';

  @override
  String get organizerYou => 'Arrangör · Du';

  @override
  String get joinedDivers => 'Anslutna dykare';

  @override
  String get noOneHasJoinedYet => 'Ingen har anslutit sig än';

  @override
  String get cancelCarOffer => 'Ställ in bil';

  @override
  String get leaveCar => 'Lämna bilen';

  @override
  String get join => 'Gå med';

  @override
  String get seatsOptional => 'Platser (valfritt)';

  @override
  String get detailsTimePickupOptional =>
      'Detaljer — tid, upphämtningsplats (valfritt)';

  @override
  String get add => 'Lägg till';

  @override
  String get buddyGroupCancelledByOrganizer =>
      'Den här buddygruppen ställdes in av arrangören.';

  @override
  String get noBuddyRequestsWereMade => 'Inga buddyförfrågningar gjordes';

  @override
  String get beFirstToLookForBuddy => 'Bli först med att leta efter en buddy';

  @override
  String get requestBuddySoOthersCanJoin =>
      'Efterlys en buddy så att andra kan följa med dig på det här dyket.';

  @override
  String get requestABuddy => 'Hitta buddy';

  @override
  String get buddyRequestTitle => 'Buddyförfrågan';

  @override
  String divesCountLabel(int count) {
    return '$count dyk';
  }

  @override
  String get creatorLabel => 'Skapare';

  @override
  String get creatorYou => 'Skapare · Du';

  @override
  String get groupLabel => 'Grupp';

  @override
  String get cancelBuddyRequest => 'Ställ in förfrågan';

  @override
  String get leaveBuddyGroup => 'Lämna gruppen';

  @override
  String get otherDiversWillSeeRequest =>
      'Andra dykare på den här resan ser din förfrågan och kan ansluta sig.';

  @override
  String get request => 'Skicka';
}
