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
      'Opret dyveture, mød dine buddies, og planlæg logistikken sammen.';

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

  @override
  String get typeOfferRide => 'Tilbyder et lift';

  @override
  String get typeShareRental => 'Deler en lejebil';

  @override
  String get carCancelledByOrganizer => 'Denne bil blev aflyst af arrangøren.';

  @override
  String get noTransportWasArranged => 'Der blev ikke arrangeret transport';

  @override
  String get beFirstToShareTransport => 'Vær den første til at dele transport';

  @override
  String get tripCancelledSimple => 'Denne tur er blevet aflyst.';

  @override
  String get offerRideOrShareRental =>
      'Tilbyd et lift eller del en lejebil, så andre kan tilslutte sig.';

  @override
  String get addTransportInfo => 'Tilføj transport';

  @override
  String seatsTakenLabel(int joined, int total) {
    return '$joined af $total pladser optaget';
  }

  @override
  String get joinedStatus => 'Tilmeldt';

  @override
  String get fullStatus => 'Fuld';

  @override
  String get organizerLabel => 'Arrangør';

  @override
  String get organizerYou => 'Arrangør · Dig';

  @override
  String get joinedDivers => 'Tilmeldte dykkere';

  @override
  String get noOneHasJoinedYet => 'Ingen har tilmeldt sig endnu';

  @override
  String get cancelCarOffer => 'Aflys bil';

  @override
  String get leaveCar => 'Forlad bil';

  @override
  String get join => 'Tilslut';

  @override
  String get seatsOptional => 'Pladser (valgfrit)';

  @override
  String get detailsTimePickupOptional =>
      'Detaljer — tidspunkt, afhentningssted (valgfrit)';

  @override
  String get add => 'Tilføj';

  @override
  String get buddyGroupCancelledByOrganizer =>
      'Denne buddy-gruppe blev aflyst af arrangøren.';

  @override
  String get noBuddyRequestsWereMade => 'Der blev ikke lavet buddy-anmodninger';

  @override
  String get beFirstToLookForBuddy =>
      'Vær den første til at lede efter en buddy';

  @override
  String get requestBuddySoOthersCanJoin =>
      'Anmod om en buddy, så andre kan tilslutte sig dig til dette dyk.';

  @override
  String get requestABuddy => 'Find buddy';

  @override
  String get buddyRequestTitle => 'Buddy-anmodning';

  @override
  String divesCountLabel(int count) {
    return '$count dyk';
  }

  @override
  String get creatorLabel => 'Opretter';

  @override
  String get creatorYou => 'Opretter · Dig';

  @override
  String get groupLabel => 'Gruppe';

  @override
  String get cancelBuddyRequest => 'Aflys anmodning';

  @override
  String get leaveBuddyGroup => 'Forlad gruppe';

  @override
  String get otherDiversWillSeeRequest =>
      'Andre dykkere på denne tur ser din anmodning og kan tilslutte sig.';

  @override
  String get request => 'Send';

  @override
  String get about => 'Om appen';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get gearLockerTitle => 'Udstyrsskab';

  @override
  String ownedOfTotalInLocker(int owned, int total) {
    return '$owned/$total i skabet';
  }

  @override
  String get clearCacheTitle => 'Ryd cache?';

  @override
  String get clearCacheBody =>
      'Dette fjerner downloadede fotos og filer fra denne enhed. Intet slettes fra selve turchattene — filer downloades bare igen, næste gang du åbner dem.';

  @override
  String get clear => 'Ryd';

  @override
  String get cacheCleared => 'Cache ryddet.';

  @override
  String couldNotClearCache(String error) {
    return 'Kunne ikke rydde cache: $error';
  }

  @override
  String get storageTitle => 'Lagerplads';

  @override
  String get clearCacheRow => 'Ryd cache';

  @override
  String get clearCacheSubtitle =>
      'Fjerner downloadede chatfotos og -filer fra denne enhed';

  @override
  String couldNotUnblock(String error) {
    return 'Kunne ikke fjerne blokering: $error';
  }

  @override
  String get blockedUsersTitle => 'Blokerede brugere';

  @override
  String get noBlockedUsers => 'Ingen blokerede brugere.';

  @override
  String get unblock => 'Fjern blokering';

  @override
  String get copyEmailAddress => 'Kopiér e-mailadresse';

  @override
  String get emailAddressCopied => 'E-mailadresse kopieret';

  @override
  String get legalTitle => 'Juridisk';

  @override
  String get termsOfService => 'Servicevilkår';

  @override
  String get privacyPolicy => 'Privatlivspolitik';

  @override
  String get contactSupport => 'Kontakt support';

  @override
  String get addADive => 'Tilføj et dyk';

  @override
  String get updateLevelTitle => 'Opdater niveau';

  @override
  String get save => 'Gem';

  @override
  String get addSpeciality => 'Tilføj speciale';

  @override
  String get specialityName => 'Navn på speciale';

  @override
  String get notificationsTitle => 'Notifikationer';

  @override
  String get pushNotificationsLabel => 'Push-notifikationer';

  @override
  String get pushDisabledInSystemSettings =>
      'Deaktiveret i systemindstillinger — aktivér DiveBubble-notifikationer der først';

  @override
  String get tapToEnableNotifications => 'Tryk for at aktivere notifikationer';

  @override
  String get newMessagesTripUpdatesEtc =>
      'Nye beskeder, ændringer i ture og mere';

  @override
  String get verified => 'Bekræftet';

  @override
  String get addCertificate => 'Tilføj certifikat';

  @override
  String get blockThisUserTitle => 'Blokér denne bruger?';

  @override
  String get blockUserBody =>
      'Du vil ikke længere se deres beskeder i delte turchats. Du kan fortryde dette fra Profil → Blokerede brugere.';

  @override
  String get block => 'Blokér';

  @override
  String get blockUserTooltip => 'Blokér bruger';

  @override
  String get blockedManageBody =>
      'Blokeret. Administrer under Profil → Blokerede brugere.';

  @override
  String couldNotBlockUser(String error) {
    return 'Kunne ikke blokere bruger: $error';
  }

  @override
  String get bioLabel => 'Bio';

  @override
  String get divesLabel => 'Dyk';

  @override
  String get languagesLabel => 'Sprog';

  @override
  String get memberSinceLabel => 'Medlem siden';

  @override
  String get editProfileTitle => 'Rediger profil';

  @override
  String get displayNameLabel => 'Visningsnavn';

  @override
  String get displayNameHelper =>
      'Vises til andre dykkere i stedet for dit rigtige navn';

  @override
  String get pleaseEnterDisplayName => 'Indtast venligst et visningsnavn';

  @override
  String get locationLabel => 'Placering';

  @override
  String get useCurrentLocationTooltip => 'Brug nuværende placering';

  @override
  String get unloggedDivesLabel => 'Ikke-loggede dyk';

  @override
  String get unloggedDivesHelper =>
      'Dyk du ikke har tilføjet til din dykkerlog — vises sammen med den som dit samlede antal';

  @override
  String get allDivesAreLogged => 'Alle mine dyk er logget';

  @override
  String get selectLanguages => 'Vælg sprog';

  @override
  String get zeroOutUnloggedDivesTitle => 'Nulstil ikke-loggede dyk?';

  @override
  String get zeroOutUnloggedDivesBody =>
      'Dette sætter tallet ovenfor til 0. Dine dykkerlog-poster berøres ikke — kun det manuelt indtastede antal ændres.';

  @override
  String get zeroOut => 'Nulstil';

  @override
  String get editDiveTitle => 'Rediger dyk';

  @override
  String get addDiveTitle => 'Tilføj dyk';

  @override
  String get importedDiveLockedNotice =>
      'Dette dyk blev importeret fra din dykkercomputer — kun land, dykkested og noter kan redigeres.';

  @override
  String get dateLabel => 'Dato';

  @override
  String get timeLabel => 'Tid';

  @override
  String get maxDepthLabel => 'Maks. dybde';

  @override
  String get avgDepthLabel => 'Gns. dybde';

  @override
  String get durationLabel => 'Varighed';

  @override
  String get minTemperatureLabel => 'Min. temperatur';

  @override
  String get minTempLabel => 'Min. temp.';

  @override
  String get maxTempLabel => 'Maks. temp.';

  @override
  String get countryLabel => 'Land';

  @override
  String get diveSiteLabel => 'Dykkested';

  @override
  String get notesLabel => 'Noter';

  @override
  String get saveChanges => 'Gem ændringer';

  @override
  String get deleteThisDiveTitle => 'Slet dette dyk?';

  @override
  String get cantBeUndone => 'Dette kan ikke fortrydes.';

  @override
  String get gearEssentialSection => 'ESSENTIELT';

  @override
  String get gearAdditionalSection => 'YDERLIGERE';

  @override
  String get addItem => 'Tilføj genstand';

  @override
  String get gearOwned => 'Har';

  @override
  String get gearMissing => 'Mangler';

  @override
  String get gearUsuallyRent => 'Lejer normalt';

  @override
  String get addItemSheetBody =>
      'Til alt ud over det essentielle — lygte, actionkamera, bøje...';

  @override
  String get itemNameLabel => 'Navn på genstand';

  @override
  String get gearItemBoots => 'Støvler';

  @override
  String get gearItemFins => 'Finner';

  @override
  String get gearItemBcd => 'BCD';

  @override
  String get gearItemWetsuitShorty5mm => 'Shorty-våddragt 5mm';

  @override
  String get gearItemWetsuit5mm => 'Våddragt 5mm';

  @override
  String get gearItemWetsuit7mm => 'Våddragt 7mm';

  @override
  String get gearItemWetsuit9mm => 'Våddragt 9mm';

  @override
  String get gearItemSemidrySuit => 'Semitør dragt';

  @override
  String get gearItemDrySuit => 'Tørdragt';

  @override
  String get gearItemHelmet => 'Hjelm';

  @override
  String get gearItemGloves => 'Handsker';

  @override
  String get gearItemRegulator => 'Regulator';

  @override
  String get gearItemComputer => 'Dykkercomputer';

  @override
  String get gearItemMask => 'Maske';

  @override
  String get shareToBubble => 'Del til Bubble';

  @override
  String get sourceLabel => 'Kilde';

  @override
  String get importedValue => 'Importeret';

  @override
  String get manualValue => 'Manuel';

  @override
  String diveOnDate(String date) {
    return 'Dyk den $date';
  }

  @override
  String labelColonValue(String label, String value) {
    return '$label: $value';
  }

  @override
  String get sharedToBubble => 'Delt til Bubble';

  @override
  String couldNotShare(String error) {
    return 'Kunne ikke dele: $error';
  }

  @override
  String get haventJoinedAnyBubblesYet =>
      'Du er ikke tilmeldt nogen Bubbles endnu.';

  @override
  String selectedCountLabel(int count) {
    return '$count valgt';
  }

  @override
  String get noDivesLoggedYet => 'Ingen dyk logget endnu';

  @override
  String get addDiveOrImportBody =>
      'Tilføj et dyk manuelt, eller importér en dykkerlogfil.';

  @override
  String deleteDivesConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Slet $count dyk?',
      one: 'Slet $count dyk?',
    );
    return '$_temp0';
  }

  @override
  String couldNotDeleteDivesError(int count, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kunne ikke slette $count dyk: $error',
      one: 'Kunne ikke slette $count dyk: $error',
    );
    return '$_temp0';
  }

  @override
  String couldNotDeleteWithError(String error) {
    return 'Kunne ikke slette: $error';
  }

  @override
  String get addADiveManually => 'Tilføj et dyk manuelt';

  @override
  String get importADiveLogFile => 'Importér en dykkerlogfil';

  @override
  String get importFormatsSubtitle => 'UDDF, CSV eller en Diving Log 6-eksport';

  @override
  String get csvColumnFormatTitle => 'CSV-kolonneformat';

  @override
  String get csvColumnFormatBody =>
      'Første række skal være en header med disse kolonnenavne (i vilkårlig rækkefølge, kun \"date\" er påkrævet):\n\ndate (ÅÅÅÅ-MM-DD)\ntime (TT:MM)\ncountry\nsite\nmax_depth_m\navg_depth_m\nduration_min\nmin_temp_c\nnotes';

  @override
  String get gotIt => 'Forstået';

  @override
  String diveImportedSimple(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dyk importeret',
      one: '$count dyk importeret',
    );
    return '$_temp0';
  }

  @override
  String diveImportedWithSkipped(int count, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nye dyk importeret, $skipped allerede logget',
      one: '$count nyt dyk importeret, $skipped allerede logget',
    );
    return '$_temp0';
  }

  @override
  String couldNotImport(String error) {
    return 'Kunne ikke importere: $error';
  }

  @override
  String get unknownError => 'ukendt fejl';

  @override
  String get updateUnloggedCountPromptBody =>
      'Hvis nogle af disse allerede var talt med i din profil, så opdater den under Rediger profil.';

  @override
  String get editProfileAction => 'Rediger profil';

  @override
  String get depthLabel => 'Dybde';

  @override
  String get temperatureLabel => 'Temperatur';

  @override
  String get dragToInspectHint => 'Træk langs grafen for at se et punkt';

  @override
  String get done => 'Færdig';

  @override
  String get searchLanguages => 'Søg sprog';

  @override
  String get languageSettingsTitle => 'Sprog';

  @override
  String get guest => 'Gæst';

  @override
  String get certificationsSectionTitle => 'Certificeringer';

  @override
  String get update => 'Opdater';

  @override
  String get specialtiesSectionTitle => 'Specialer';

  @override
  String get gearSectionTitle => 'Udstyr';

  @override
  String get couldNotUploadPhoto => 'Kunne ikke uploade foto';

  @override
  String get couldNotRemovePhoto => 'Kunne ikke fjerne foto';

  @override
  String get changePhoto => 'Skift foto';

  @override
  String get removePhoto => 'Fjern foto';

  @override
  String get diveOut => 'Log ud';

  @override
  String get deleteAccountTitle => 'Slet konto?';

  @override
  String get deleteAccountBody =>
      'Dette anonymiserer permanent din konto og aflyser alle ture, du arrangerer. Dette kan ikke fortrydes.';

  @override
  String couldNotDeleteAccount(String error) {
    return 'Kunne ikke slette konto: $error';
  }

  @override
  String get deleteAccountRow => 'Slet konto';

  @override
  String get noExpensesYet => 'Ingen udgifter endnu';

  @override
  String get logSharedCostBody =>
      'Registrer en delt udgift, så alle ved, hvad de skylder.';

  @override
  String get addExpenseCta => 'Tilføj udgift';

  @override
  String get addExpenseTitle => 'Tilføj udgift';

  @override
  String get editExpenseTitle => 'Rediger udgift';

  @override
  String get allSettledUp => 'Alt er gjort op';

  @override
  String get allSettledUpPeriod => 'Alt er gjort op.';

  @override
  String youAreOwedAmount(String amount) {
    return 'Du får $amount';
  }

  @override
  String youOweAmount(String amount) {
    return 'Du skylder $amount';
  }

  @override
  String youOweName(String name) {
    return 'Du skylder $name';
  }

  @override
  String nameOwesYou(String name) {
    return '$name skylder dig';
  }

  @override
  String paidByAndDate(String name, String date) {
    return 'Betalt af $name · $date';
  }

  @override
  String get balanceTitle => 'Balance';

  @override
  String get markSettled => 'Markér som betalt';

  @override
  String couldNotSettle(String error) {
    return 'Kunne ikke gøre op: $error';
  }

  @override
  String get titleFieldLabel => 'Titel';

  @override
  String get amountLabel => 'Beløb';

  @override
  String get paidByLabel => 'Betalt af';

  @override
  String get splitEqual => 'Ligeligt';

  @override
  String get splitShares => 'Andele';

  @override
  String get splitExact => 'Præcist';

  @override
  String get splitBetweenLabel => 'Del mellem';

  @override
  String get fullyAssigned => 'Fuldt fordelt';

  @override
  String remainingToAssign(String amount) {
    return 'Resterer at fordele: $amount';
  }

  @override
  String get fillTitleAmountParticipant =>
      'Udfyld en titel, et beløb og mindst én deltager.';

  @override
  String get enterExactAmountForEveryone =>
      'Indtast et præcist beløb for alle valgte.';

  @override
  String get exactAmountsMustAddUp =>
      'De præcise beløb skal give summen af det samlede beløb.';

  @override
  String get deleteExpenseTitle => 'Slet denne udgift?';

  @override
  String get deleteExpenseBody =>
      'Den fjernes fra balancen for alle. Dette kan ikke fortrydes.';

  @override
  String get editTripTitle => 'Rediger tur';

  @override
  String uploadUpToNPhotos(int max) {
    return 'Upload op til $max fotos.';
  }

  @override
  String get titleIsRequired => 'Titel er påkrævet';

  @override
  String get locationIsRequired => 'Sted er påkrævet';

  @override
  String get dateIsRequired => 'Dato er påkrævet';

  @override
  String get meetingTimeLabel => 'Mødetidspunkt';

  @override
  String get meetingTimeIsRequired => 'Mødetidspunkt er påkrævet';

  @override
  String get endDateOptionalLabel => 'Slutdato (valgfrit, ture med flere dage)';

  @override
  String get meetingPointOptionalLabel => 'Mødested (valgfrit)';

  @override
  String get descriptionOptionalLabel => 'Beskrivelse (valgfrit)';

  @override
  String get requiredLevelLabel => 'Krævet niveau';

  @override
  String get openToAll => 'Åben for alle';

  @override
  String get minDepthMLabel => 'Min. dybde (m)';

  @override
  String get maxDepthMLabel => 'Maks. dybde (m)';

  @override
  String get minDivesLabel => 'Min. dyk';

  @override
  String get maxDivesLabel => 'Maks. dyk';

  @override
  String onlyNPhotosAllowed(int max) {
    return 'Kun $max fotos tilladt pr. tur';
  }

  @override
  String get selectADate => 'Vælg en dato';

  @override
  String get selectATime => 'Vælg et tidspunkt';

  @override
  String get enterBookingCodeTitle => 'Indtast bookingkode';

  @override
  String get bookingCodeDialogBody =>
      'Har du booket en tur hos et dykkercenter på deres egen side? Indtast koden, du fik, for at deltage i dens Bubble her.';

  @override
  String get bookingCodeLabel => 'Bookingkode';

  @override
  String get bookingCodeHint => 'f.eks. 8XK2NPQ4';

  @override
  String get managePhotos => 'Administrer fotos';

  @override
  String get editButtonLabel => 'Rediger';

  @override
  String get peopleTabLabel => 'Personer';

  @override
  String get mediaTabLabel => 'Medier';

  @override
  String get filesTabLabel => 'Filer';

  @override
  String get linksTabLabel => 'Links';

  @override
  String get meetingPointSectionLabel => 'MØDESTED';

  @override
  String get aboutThisDive => 'Om dette dyk';

  @override
  String get levelSectionLabel => 'NIVEAU';

  @override
  String get depthSectionLabel => 'DYBDE';

  @override
  String get divesSectionLabel => 'DYK';

  @override
  String get durationSectionLabel => 'VARIGHED';

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
    return 'Op til $max m';
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
    return 'Op til $max dyk';
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
      other: '$days dage',
      one: '$days dag',
    );
    return '$_temp0';
  }

  @override
  String get diveCenterLabel => 'Dykkercenter';

  @override
  String get bookNowLabel => 'Book nu';

  @override
  String bookNowWithPrice(String price, String currency) {
    return 'Book nu — $price $currency';
  }

  @override
  String get iHaveABookingCode => 'Jeg har en bookingkode';

  @override
  String get privateTripAskOrganizer =>
      'Dette er en privat tur — bed arrangøren om en invitationskode eller et link.';

  @override
  String get iHaveAnInviteCode => 'Jeg har en invitationskode';

  @override
  String get inviteCodeSectionLabel => 'INVITATIONSKODE';

  @override
  String get shareInviteTooltip => 'Del invitation';

  @override
  String get shareInviteLink => 'Del invitationslink';

  @override
  String get copyInviteLink => 'Kopiér invitationslink';

  @override
  String get copyBookingCode => 'Kopiér bookingkode';

  @override
  String get unmute => 'Slå lyd til';

  @override
  String get mute => 'Slå lyd fra';

  @override
  String get tripCancelledSnackbar => 'Tur aflyst';

  @override
  String get diveInToBubble => 'Gå til Bubble';

  @override
  String participantsJoinedPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personer tilmeldt',
      one: '$count person tilmeldt',
    );
    return '$_temp0';
  }

  @override
  String participantsJoinedOfMaxPlural(int count, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count af $max personer tilmeldt',
      one: '$count af $max person tilmeldt',
    );
    return '$_temp0';
  }

  @override
  String get agencyLabel => 'Organisation';

  @override
  String get websiteLabel => 'Website';

  @override
  String get phoneLabel => 'Telefon';

  @override
  String get emailLabel => 'E-mail';

  @override
  String systemDefaultWithLanguage(String name) {
    return '$name (systemstandard)';
  }

  @override
  String get chooseYourLanguageTitle => 'Vælg dit sprog';

  @override
  String get chooseYourLanguageBody =>
      'Du kan altid ændre dette senere i profilindstillingerne.';
}
