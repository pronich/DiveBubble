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

  @override
  String get about => 'Om appen';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get gearLockerTitle => 'Utrustningsskåp';

  @override
  String ownedOfTotalInLocker(int owned, int total) {
    return '$owned/$total i skåpet';
  }

  @override
  String get clearCacheTitle => 'Rensa cache?';

  @override
  String get clearCacheBody =>
      'Detta tar bort nedladdade foton och filer från den här enheten. Inget tas bort från själva resechattarna — filer laddas bara ner igen nästa gång du öppnar dem.';

  @override
  String get clear => 'Rensa';

  @override
  String get cacheCleared => 'Cachen rensad.';

  @override
  String couldNotClearCache(String error) {
    return 'Kunde inte rensa cachen: $error';
  }

  @override
  String get storageTitle => 'Lagring';

  @override
  String get clearCacheRow => 'Rensa cache';

  @override
  String get clearCacheSubtitle =>
      'Tar bort nedladdade chattfoton och -filer från den här enheten';

  @override
  String couldNotUnblock(String error) {
    return 'Kunde inte häva blockering: $error';
  }

  @override
  String get blockedUsersTitle => 'Blockerade användare';

  @override
  String get noBlockedUsers => 'Inga blockerade användare.';

  @override
  String get unblock => 'Häv blockering';

  @override
  String get copyEmailAddress => 'Kopiera e-postadress';

  @override
  String get emailAddressCopied => 'E-postadress kopierad';

  @override
  String get legalTitle => 'Juridiskt';

  @override
  String get termsOfService => 'Användarvillkor';

  @override
  String get privacyPolicy => 'Integritetspolicy';

  @override
  String get contactSupport => 'Kontakta support';

  @override
  String get addADive => 'Lägg till ett dyk';

  @override
  String get updateLevelTitle => 'Uppdatera nivå';

  @override
  String get save => 'Spara';

  @override
  String get addSpeciality => 'Lägg till specialitet';

  @override
  String get specialityName => 'Namn på specialitet';

  @override
  String get notificationsTitle => 'Aviseringar';

  @override
  String get pushNotificationsLabel => 'Push-aviseringar';

  @override
  String get pushDisabledInSystemSettings =>
      'Inaktiverat i systeminställningarna — aktivera DiveBubble-aviseringar där först';

  @override
  String get tapToEnableNotifications => 'Tryck för att aktivera aviseringar';

  @override
  String get newMessagesTripUpdatesEtc =>
      'Nya meddelanden, resändringar och mer';

  @override
  String get verified => 'Verifierad';

  @override
  String get addCertificate => 'Lägg till certifikat';

  @override
  String get blockThisUserTitle => 'Blockera den här användaren?';

  @override
  String get blockUserBody =>
      'Du kommer inte längre se deras meddelanden i delade resechattar. Du kan ångra detta från Profil → Blockerade användare.';

  @override
  String get block => 'Blockera';

  @override
  String get blockUserTooltip => 'Blockera användare';

  @override
  String get blockedManageBody =>
      'Blockerad. Hantera under Profil → Blockerade användare.';

  @override
  String couldNotBlockUser(String error) {
    return 'Kunde inte blockera användaren: $error';
  }

  @override
  String get bioLabel => 'Bio';

  @override
  String get divesLabel => 'Dyk';

  @override
  String get languagesLabel => 'Språk';

  @override
  String get memberSinceLabel => 'Medlem sedan';

  @override
  String get editProfileTitle => 'Redigera profil';

  @override
  String get displayNameLabel => 'Visningsnamn';

  @override
  String get displayNameHelper =>
      'Visas för andra dykare istället för ditt riktiga namn';

  @override
  String get pleaseEnterDisplayName => 'Ange ett visningsnamn';

  @override
  String get locationLabel => 'Plats';

  @override
  String get useCurrentLocationTooltip => 'Använd nuvarande plats';

  @override
  String get unloggedDivesLabel => 'Ologgade dyk';

  @override
  String get unloggedDivesHelper =>
      'Dyk du inte har lagt till i din dykloggbok — visas tillsammans med den som ditt totala antal';

  @override
  String get allDivesAreLogged => 'Alla mina dyk är loggade';

  @override
  String get selectLanguages => 'Välj språk';

  @override
  String get zeroOutUnloggedDivesTitle => 'Nollställa ologgade dyk?';

  @override
  String get zeroOutUnloggedDivesBody =>
      'Detta nollställer talet ovan. Dina loggboksposter påverkas inte — endast det manuellt angivna antalet ändras.';

  @override
  String get zeroOut => 'Nollställ';

  @override
  String get editDiveTitle => 'Redigera dyk';

  @override
  String get addDiveTitle => 'Lägg till dyk';

  @override
  String get importedDiveLockedNotice =>
      'Det här dyket importerades från din dykdator — endast land, dykplats och anteckningar kan redigeras.';

  @override
  String get dateLabel => 'Datum';

  @override
  String get timeLabel => 'Tid';

  @override
  String get maxDepthLabel => 'Maxdjup';

  @override
  String get avgDepthLabel => 'Snittdjup';

  @override
  String get durationLabel => 'Varaktighet';

  @override
  String get minTemperatureLabel => 'Min. temperatur';

  @override
  String get minTempLabel => 'Min. temp.';

  @override
  String get maxTempLabel => 'Max. temp.';

  @override
  String get countryLabel => 'Land';

  @override
  String get diveSiteLabel => 'Dykplats';

  @override
  String get notesLabel => 'Anteckningar';

  @override
  String get saveChanges => 'Spara ändringar';

  @override
  String get deleteThisDiveTitle => 'Ta bort det här dyket?';

  @override
  String get cantBeUndone => 'Detta kan inte ångras.';

  @override
  String get gearEssentialSection => 'GRUNDLÄGGANDE';

  @override
  String get gearAdditionalSection => 'ÖVRIGT';

  @override
  String get addItem => 'Lägg till föremål';

  @override
  String get gearOwned => 'Har';

  @override
  String get gearMissing => 'Saknas';

  @override
  String get gearUsuallyRent => 'Hyr oftast';

  @override
  String get addItemSheetBody =>
      'För allt utöver det grundläggande — lampa, actionkamera, boj...';

  @override
  String get itemNameLabel => 'Namn på föremål';

  @override
  String get gearItemBoots => 'Dykstövlar';

  @override
  String get gearItemFins => 'Fenor';

  @override
  String get gearItemBcd => 'BCD';

  @override
  String get gearItemWetsuitShorty5mm => 'Shorty-våtdräkt 5mm';

  @override
  String get gearItemWetsuit5mm => 'Våtdräkt 5mm';

  @override
  String get gearItemWetsuit7mm => 'Våtdräkt 7mm';

  @override
  String get gearItemWetsuit9mm => 'Våtdräkt 9mm';

  @override
  String get gearItemSemidrySuit => 'Halvtorrdräkt';

  @override
  String get gearItemDrySuit => 'Torrdräkt';

  @override
  String get gearItemHelmet => 'Hjälm';

  @override
  String get gearItemGloves => 'Handskar';

  @override
  String get gearItemRegulator => 'Regulator';

  @override
  String get gearItemComputer => 'Dykdator';

  @override
  String get gearItemMask => 'Mask';

  @override
  String get shareToBubble => 'Dela till Bubble';

  @override
  String get sourceLabel => 'Källa';

  @override
  String get importedValue => 'Importerat';

  @override
  String get manualValue => 'Manuellt';

  @override
  String diveOnDate(String date) {
    return 'Dyk den $date';
  }

  @override
  String labelColonValue(String label, String value) {
    return '$label: $value';
  }

  @override
  String get sharedToBubble => 'Delat till Bubble';

  @override
  String couldNotShare(String error) {
    return 'Kunde inte dela: $error';
  }

  @override
  String get haventJoinedAnyBubblesYet =>
      'Du har inte gått med i något Bubble än.';

  @override
  String selectedCountLabel(int count) {
    return '$count valda';
  }

  @override
  String get noDivesLoggedYet => 'Inga dyk loggade än';

  @override
  String get addDiveOrImportBody =>
      'Lägg till ett dyk för hand, eller importera en dykloggfil.';

  @override
  String deleteDivesConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ta bort $count dyk?',
      one: 'Ta bort $count dyk?',
    );
    return '$_temp0';
  }

  @override
  String couldNotDeleteDivesError(int count, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kunde inte ta bort $count dyk: $error',
      one: 'Kunde inte ta bort $count dyk: $error',
    );
    return '$_temp0';
  }

  @override
  String couldNotDeleteWithError(String error) {
    return 'Kunde inte ta bort: $error';
  }

  @override
  String get addADiveManually => 'Lägg till ett dyk manuellt';

  @override
  String get importADiveLogFile => 'Importera en dykloggfil';

  @override
  String get importFormatsSubtitle =>
      'UDDF, CSV eller en export från Diving Log 6';

  @override
  String get csvColumnFormatTitle => 'CSV-kolumnformat';

  @override
  String get csvColumnFormatBody =>
      'Första raden måste vara en rubrikrad med dessa kolumnnamn (valfri ordning, endast \"date\" krävs):\n\ndate (ÅÅÅÅ-MM-DD)\ntime (TT:MM)\ncountry\nsite\nmax_depth_m\navg_depth_m\nduration_min\nmin_temp_c\nnotes';

  @override
  String get gotIt => 'Uppfattat';

  @override
  String diveImportedSimple(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dyk importerade',
      one: '$count dyk importerat',
    );
    return '$_temp0';
  }

  @override
  String diveImportedWithSkipped(int count, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nya dyk importerade, $skipped redan loggade',
      one: '$count nytt dyk importerat, $skipped redan loggat',
    );
    return '$_temp0';
  }

  @override
  String couldNotImport(String error) {
    return 'Kunde inte importera: $error';
  }

  @override
  String get unknownError => 'okänt fel';

  @override
  String get updateUnloggedCountPromptBody =>
      'Om några av dessa redan räknats i din profil, uppdatera den under Redigera profil.';

  @override
  String get editProfileAction => 'Redigera profil';

  @override
  String get depthLabel => 'Djup';

  @override
  String get temperatureLabel => 'Temperatur';

  @override
  String get dragToInspectHint =>
      'Dra längs grafen för att inspektera en punkt';

  @override
  String get done => 'Klar';

  @override
  String get searchLanguages => 'Sök språk';

  @override
  String get languageSettingsTitle => 'Språk';

  @override
  String get systemDefault => 'Systemstandard';

  @override
  String get guest => 'Gäst';

  @override
  String get certificationsSectionTitle => 'Certifieringar';

  @override
  String get update => 'Uppdatera';

  @override
  String get specialtiesSectionTitle => 'Specialiteter';

  @override
  String get gearSectionTitle => 'Utrustning';

  @override
  String get couldNotUploadPhoto => 'Kunde inte ladda upp foto';

  @override
  String get couldNotRemovePhoto => 'Kunde inte ta bort foto';

  @override
  String get changePhoto => 'Byt foto';

  @override
  String get removePhoto => 'Ta bort foto';

  @override
  String get diveOut => 'Logga ut';

  @override
  String get deleteAccountTitle => 'Ta bort konto?';

  @override
  String get deleteAccountBody =>
      'Detta anonymiserar ditt konto permanent och ställer in alla resor du arrangerar. Detta kan inte ångras.';

  @override
  String couldNotDeleteAccount(String error) {
    return 'Kunde inte ta bort kontot: $error';
  }

  @override
  String get deleteAccountRow => 'Ta bort konto';

  @override
  String get noExpensesYet => 'Inga utgifter än';

  @override
  String get logSharedCostBody =>
      'Registrera en delad kostnad så att alla vet vad de är skyldiga.';

  @override
  String get addExpenseCta => 'Lägg till utgift';

  @override
  String get addExpenseTitle => 'Lägg till utgift';

  @override
  String get editExpenseTitle => 'Redigera utgift';

  @override
  String get allSettledUp => 'Allt är reglerat';

  @override
  String get allSettledUpPeriod => 'Allt är reglerat.';

  @override
  String youAreOwedAmount(String amount) {
    return 'Du får $amount';
  }

  @override
  String youOweAmount(String amount) {
    return 'Du är skyldig $amount';
  }

  @override
  String youOweName(String name) {
    return 'Du är skyldig $name';
  }

  @override
  String nameOwesYou(String name) {
    return '$name är skyldig dig';
  }

  @override
  String paidByAndDate(String name, String date) {
    return 'Betalat av $name · $date';
  }

  @override
  String get balanceTitle => 'Saldo';

  @override
  String get markSettled => 'Markera som reglerad';

  @override
  String couldNotSettle(String error) {
    return 'Kunde inte reglera: $error';
  }

  @override
  String get titleFieldLabel => 'Titel';

  @override
  String get amountLabel => 'Belopp';

  @override
  String get paidByLabel => 'Betalat av';

  @override
  String get splitEqual => 'Lika';

  @override
  String get splitShares => 'Andelar';

  @override
  String get splitExact => 'Exakt';

  @override
  String get splitBetweenLabel => 'Dela mellan';

  @override
  String get fullyAssigned => 'Helt fördelat';

  @override
  String remainingToAssign(String amount) {
    return 'Kvar att fördela: $amount';
  }

  @override
  String get fillTitleAmountParticipant =>
      'Fyll i en titel, ett belopp och minst en deltagare.';

  @override
  String get enterExactAmountForEveryone =>
      'Ange ett exakt belopp för alla valda.';

  @override
  String get exactAmountsMustAddUp =>
      'De exakta beloppen måste summera till totalbeloppet.';

  @override
  String get deleteExpenseTitle => 'Ta bort den här utgiften?';

  @override
  String get deleteExpenseBody =>
      'Den tas bort från saldot för alla. Detta kan inte ångras.';

  @override
  String get editTripTitle => 'Redigera resa';

  @override
  String uploadUpToNPhotos(int max) {
    return 'Ladda upp upp till $max foton.';
  }

  @override
  String get titleIsRequired => 'Titel krävs';

  @override
  String get locationIsRequired => 'Plats krävs';

  @override
  String get dateIsRequired => 'Datum krävs';

  @override
  String get meetingTimeLabel => 'Mötestid';

  @override
  String get meetingTimeIsRequired => 'Mötestid krävs';

  @override
  String get endDateOptionalLabel => 'Slutdatum (valfritt, flerdagarsresor)';

  @override
  String get meetingPointOptionalLabel => 'Mötesplats (valfritt)';

  @override
  String get descriptionOptionalLabel => 'Beskrivning (valfritt)';

  @override
  String get requiredLevelLabel => 'Nödvändig nivå';

  @override
  String get openToAll => 'Öppen för alla';

  @override
  String get minDepthMLabel => 'Min. djup (m)';

  @override
  String get maxDepthMLabel => 'Max. djup (m)';

  @override
  String get minDivesLabel => 'Min. dyk';

  @override
  String get maxDivesLabel => 'Max. dyk';

  @override
  String onlyNPhotosAllowed(int max) {
    return 'Endast $max foton tillåtna per resa';
  }

  @override
  String get selectADate => 'Välj ett datum';

  @override
  String get selectATime => 'Välj en tid';

  @override
  String get enterBookingCodeTitle => 'Ange bokningskod';

  @override
  String get bookingCodeDialogBody =>
      'Bokade du en resa hos ett dykcenter på deras egen webbplats? Ange koden du fick för att gå med i deras Bubble här.';

  @override
  String get bookingCodeLabel => 'Bokningskod';

  @override
  String get bookingCodeHint => 't.ex. 8XK2NPQ4';

  @override
  String get managePhotos => 'Hantera foton';

  @override
  String get editButtonLabel => 'Redigera';

  @override
  String get peopleTabLabel => 'Personer';

  @override
  String get mediaTabLabel => 'Media';

  @override
  String get filesTabLabel => 'Filer';

  @override
  String get linksTabLabel => 'Länkar';

  @override
  String get meetingPointSectionLabel => 'MÖTESPLATS';

  @override
  String get aboutThisDive => 'Om det här dyket';

  @override
  String get levelSectionLabel => 'NIVÅ';

  @override
  String get depthSectionLabel => 'DJUP';

  @override
  String get divesSectionLabel => 'DYK';

  @override
  String get durationSectionLabel => 'VARAKTIGHET';

  @override
  String depthExactMeters(int value) {
    return '$value m';
  }

  @override
  String depthRangeMeters(int min, int max) {
    return '$min–$max m';
  }

  @override
  String depthUpToMeters(int max) {
    return 'Upp till $max m';
  }

  @override
  String depthMinPlusMeters(int min) {
    return '$min+ m';
  }

  @override
  String diveCountExactPlural(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: '$n dyk',
      one: '$n dyk',
    );
    return '$_temp0';
  }

  @override
  String diveCountRangeDives(int min, int max) {
    return '$min–$max dyk';
  }

  @override
  String diveCountUpToDives(int max) {
    return 'Upp till $max dyk';
  }

  @override
  String diveCountMinPlusDives(int min) {
    return '$min+ dyk';
  }

  @override
  String durationDaysPlural(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days dagar',
      one: '$days dag',
    );
    return '$_temp0';
  }

  @override
  String get diveCenterLabel => 'Dykcenter';

  @override
  String get bookNowLabel => 'Boka nu';

  @override
  String bookNowWithPrice(String price, String currency) {
    return 'Boka nu — $price $currency';
  }

  @override
  String get iHaveABookingCode => 'Jag har en bokningskod';

  @override
  String get privateTripAskOrganizer =>
      'Det här är en privat resa — be arrangören om en inbjudningskod eller länk.';

  @override
  String get iHaveAnInviteCode => 'Jag har en inbjudningskod';

  @override
  String get inviteCodeSectionLabel => 'INBJUDNINGSKOD';

  @override
  String get shareInviteTooltip => 'Dela inbjudan';

  @override
  String get shareInviteLink => 'Dela inbjudningslänk';

  @override
  String get copyInviteLink => 'Kopiera inbjudningslänk';

  @override
  String get copyBookingCode => 'Kopiera bokningskod';

  @override
  String get unmute => 'Slå på ljud';

  @override
  String get mute => 'Tysta';

  @override
  String get tripCancelledSnackbar => 'Resan inställd';

  @override
  String get diveInToBubble => 'Gå till Bubble';

  @override
  String participantsJoinedPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personer har gått med',
      one: '$count person har gått med',
    );
    return '$_temp0';
  }

  @override
  String participantsJoinedOfMaxPlural(int count, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count av $max personer har gått med',
      one: '$count av $max person har gått med',
    );
    return '$_temp0';
  }

  @override
  String get agencyLabel => 'Organisation';

  @override
  String get websiteLabel => 'Webbplats';

  @override
  String get phoneLabel => 'Telefon';

  @override
  String get emailLabel => 'E-post';
}
