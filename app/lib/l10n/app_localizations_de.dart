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

  @override
  String errorWithMessage(String error) {
    return 'Fehler: $error';
  }

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get you => 'Du';

  @override
  String get diver => 'Taucher';

  @override
  String get searchBubbles => 'Bubbles durchsuchen';

  @override
  String get noMatches => 'Keine Treffer.';

  @override
  String get share => 'Teilen';

  @override
  String get documentFallbackName => 'Dokument.pdf';

  @override
  String get copiedToClipboard => 'Kopiert';

  @override
  String get deleteThisMessageTitle => 'Diese Nachricht löschen?';

  @override
  String get deleteThisMessageBody =>
      'Das kann nicht rückgängig gemacht werden — sie wird für alle in diesem Bubble entfernt.';

  @override
  String couldNotDeleteMessage(String error) {
    return 'Nachricht konnte nicht gelöscht werden: $error';
  }

  @override
  String couldNotReact(String error) {
    return 'Reaktion fehlgeschlagen: $error';
  }

  @override
  String get reply => 'Antworten';

  @override
  String get copyText => 'Text kopieren';

  @override
  String get report => 'Melden';

  @override
  String get removeDocumentFirst =>
      'Entferne zuerst das Dokument, um Fotos hinzuzufügen.';

  @override
  String onlyNAttachmentsAllowed(int max) {
    return 'Pro Nachricht sind nur $max Anhänge erlaubt.';
  }

  @override
  String get documentOnlyOnItsOwn =>
      'Ein Dokument kann nur allein gesendet werden.';

  @override
  String get someFilesTooLarge => 'Einige Dateien sind zu groß.';

  @override
  String couldNotSendAttachment(String error) {
    return 'Anhang konnte nicht gesendet werden: $error';
  }

  @override
  String get noMessagesYet => 'Noch keine Nachrichten';

  @override
  String get tripCancelledReadOnly =>
      'Dieser Trip wurde storniert — der Chat ist schreibgeschützt.';

  @override
  String replyingTo(String name) {
    return 'Antwort an $name';
  }

  @override
  String get captionOptional => 'Bildunterschrift (optional)';

  @override
  String get messageHint => 'Nachricht';

  @override
  String get messageDeleted => 'Nachricht gelöscht';

  @override
  String attachmentsCountLabel(int count) {
    return '📎 $count Anhänge';
  }

  @override
  String get photoLabel => '📷 Foto';

  @override
  String get videoLabel => '🎬 Video';

  @override
  String get pdfLabel => '📄 PDF';

  @override
  String get newMessages => 'Neue Nachrichten';

  @override
  String get productObserver => 'Product Observer';

  @override
  String get reportMessageTitle => 'Nachricht melden';

  @override
  String get detailsOptional => 'Details (optional)';

  @override
  String get sendReport => 'Meldung senden';

  @override
  String get reportSentThankYou => 'Meldung gesendet — danke.';

  @override
  String couldNotSendReport(String error) {
    return 'Meldung konnte nicht gesendet werden: $error';
  }

  @override
  String get thankYou => 'Danke!';

  @override
  String get giveFeedback => 'Feedback geben';

  @override
  String get howUsefulQuestion =>
      'Wie hilfreich war DiveBubble für diesen Trip?';

  @override
  String get whatDidHelpQuestion => 'Wobei hat dir DiveBubble geholfen?';

  @override
  String get whatShouldImproveQuestion => 'Was sollten wir verbessern?';

  @override
  String get optionalHintText => 'Optional';

  @override
  String get canContactAboutFeedback =>
      'Dürfen wir dich zu deinem Feedback kontaktieren?';

  @override
  String get submitFeedback => 'Feedback senden';

  @override
  String couldNotSendFeedback(String error) {
    return 'Feedback konnte nicht gesendet werden: $error';
  }

  @override
  String get reportReasonSpam => 'Spam';

  @override
  String get reportReasonHarassment => 'Belästigung';

  @override
  String get reportReasonInappropriateContent => 'Unangemessener Inhalt';

  @override
  String get reportReasonOther => 'Anderes';

  @override
  String get helpedWithTripInformation => 'Trip-Informationen';

  @override
  String get helpedWithChattingWithParticipants => 'Chatten mit Teilnehmern';

  @override
  String get helpedWithFindingTransport => 'Transport finden';

  @override
  String get helpedWithFindingBuddy => 'Buddy finden';

  @override
  String get helpedWithNothingYet => 'Noch nichts';

  @override
  String couldNotSharePhoto(String error) {
    return 'Foto konnte nicht geteilt werden: $error';
  }

  @override
  String couldNotShareVideo(String error) {
    return 'Video konnte nicht geteilt werden: $error';
  }

  @override
  String get couldNotLoadVideo => 'Video konnte nicht geladen werden';

  @override
  String couldNotLoadMedia(String error) {
    return 'Medien konnten nicht geladen werden: $error';
  }

  @override
  String get noPhotosOrVideosSharedYet =>
      'Noch keine Fotos oder Videos geteilt';

  @override
  String couldNotLoadFiles(String error) {
    return 'Dateien konnten nicht geladen werden: $error';
  }

  @override
  String get noFilesSharedYet => 'Noch keine Dateien geteilt';

  @override
  String couldNotLoadLinks(String error) {
    return 'Links konnten nicht geladen werden: $error';
  }

  @override
  String get noLinksSharedYet => 'Noch keine Links geteilt';

  @override
  String get shareToABubble => 'In einem Bubble teilen';

  @override
  String get noBubblesYet => 'Noch keine Bubbles';

  @override
  String get joinATripToShareInto =>
      'Tritt einem Trip bei, um einen Bubble zum Teilen zu haben.';

  @override
  String get bubblesTabTitle => 'Bubbles';

  @override
  String get diveLogTabTitle => 'Logbuch';

  @override
  String get profileTabTitle => 'Profil';

  @override
  String get signInToSeeYourTrips => 'Melde dich an, um deine Trips zu sehen';

  @override
  String get logInToViewTripsBody =>
      'Melde dich an, um die Trips zu sehen, denen du beigetreten bist, und ihre Gruppenchats.';

  @override
  String get startYourFirstBubble => 'Starte deinen ersten Bubble';

  @override
  String get startYourFirstBubbleBody =>
      'Erstelle einen Trip oder tritt mit einem Code bei — Chat, Transport und Trip-Details an einem Ort.';

  @override
  String get createTrip => 'Trip erstellen';

  @override
  String get joinTrip => 'Trip beitreten';

  @override
  String get chatTabLabel => 'Chat';

  @override
  String get transportTabLabel => 'Transport';

  @override
  String get buddyTabLabel => 'Buddy';

  @override
  String get expensesTabLabel => 'Ausgaben';

  @override
  String get archive => 'Archivieren';

  @override
  String get unarchive => 'Aus Archiv holen';

  @override
  String get cancelTrip => 'Trip stornieren';

  @override
  String get leave => 'Verlassen';

  @override
  String couldNotArchive(String error) {
    return 'Konnte nicht archiviert werden: $error';
  }

  @override
  String couldNotUnarchive(String error) {
    return 'Konnte nicht aus dem Archiv geholt werden: $error';
  }

  @override
  String get leaveBubbleTitle => 'Diesen Bubble verlassen?';

  @override
  String get leaveBubbleBody =>
      'Du verlierst deinen Platz und kannst später wieder beitreten, falls noch Platz ist.';

  @override
  String couldNotLeave(String error) {
    return 'Verlassen fehlgeschlagen: $error';
  }

  @override
  String get cancelTripTitle => 'Diesen Trip stornieren?';

  @override
  String get cancelTripBody =>
      'Alle Teilnehmer behalten den Bubble, um den Chatverlauf zu sehen, aber niemand — auch du nicht — kann noch Nachrichten senden, beitreten oder Transport organisieren. Das kann nicht rückgängig gemacht werden.';

  @override
  String get neverMind => 'Doch nicht';

  @override
  String couldNotCancel(String error) {
    return 'Stornieren fehlgeschlagen: $error';
  }

  @override
  String get cancelledStatus => 'Storniert';

  @override
  String get pastStatus => 'Vergangen';

  @override
  String get activeStatus => 'Aktiv';

  @override
  String get archivedChats => 'Archivierte Chats';

  @override
  String get noArchivedChats => 'Keine archivierten Chats';

  @override
  String get archivedChatsEmptyBody =>
      'Bubbles, die du archivierst, erscheinen hier — wische oder hole sie aus dem Archiv, um sie zurückzuholen.';

  @override
  String get typeOfferRide => 'Biete eine Mitfahrgelegenheit an';

  @override
  String get typeShareRental => 'Teile einen Mietwagen';

  @override
  String get carCancelledByOrganizer =>
      'Dieses Auto wurde vom Organisator storniert.';

  @override
  String get noTransportWasArranged => 'Es wurde kein Transport organisiert';

  @override
  String get beFirstToShareTransport => 'Sei der Erste, der Transport teilt';

  @override
  String get tripCancelledSimple => 'Dieser Trip wurde storniert.';

  @override
  String get offerRideOrShareRental =>
      'Biete eine Mitfahrgelegenheit an oder teile einen Mietwagen, damit andere sich anschließen können.';

  @override
  String get addTransportInfo => 'Transport hinzufügen';

  @override
  String seatsTakenLabel(int joined, int total) {
    return '$joined von $total Plätzen belegt';
  }

  @override
  String get joinedStatus => 'Beigetreten';

  @override
  String get fullStatus => 'Voll';

  @override
  String get organizerLabel => 'Organisator';

  @override
  String get organizerYou => 'Organisator · Du';

  @override
  String get joinedDivers => 'Beigetretene Taucher';

  @override
  String get noOneHasJoinedYet => 'Noch niemand beigetreten';

  @override
  String get cancelCarOffer => 'Auto stornieren';

  @override
  String get leaveCar => 'Auto verlassen';

  @override
  String get join => 'Beitreten';

  @override
  String get seatsOptional => 'Plätze (optional)';

  @override
  String get detailsTimePickupOptional =>
      'Details — Uhrzeit, Abholort (optional)';

  @override
  String get add => 'Hinzufügen';

  @override
  String get buddyGroupCancelledByOrganizer =>
      'Diese Buddy-Gruppe wurde vom Organisator storniert.';

  @override
  String get noBuddyRequestsWereMade =>
      'Es wurden keine Buddy-Anfragen gestellt';

  @override
  String get beFirstToLookForBuddy => 'Sei der Erste, der einen Buddy sucht';

  @override
  String get requestBuddySoOthersCanJoin =>
      'Suche einen Buddy, damit andere sich dir für diesen Tauchgang anschließen können.';

  @override
  String get requestABuddy => 'Buddy suchen';

  @override
  String get buddyRequestTitle => 'Buddy-Anfrage';

  @override
  String divesCountLabel(int count) {
    return '$count Tauchgänge';
  }

  @override
  String get creatorLabel => 'Ersteller';

  @override
  String get creatorYou => 'Ersteller · Du';

  @override
  String get groupLabel => 'Gruppe';

  @override
  String get cancelBuddyRequest => 'Anfrage stornieren';

  @override
  String get leaveBuddyGroup => 'Gruppe verlassen';

  @override
  String get otherDiversWillSeeRequest =>
      'Andere Taucher auf diesem Trip sehen deine Anfrage und können sich anschließen.';

  @override
  String get request => 'Senden';

  @override
  String get about => 'Über die App';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get gearLockerTitle => 'Ausrüstung';

  @override
  String ownedOfTotalInLocker(int owned, int total) {
    return '$owned/$total vorhanden';
  }

  @override
  String get clearCacheTitle => 'Cache leeren?';

  @override
  String get clearCacheBody =>
      'Dies entfernt heruntergeladene Fotos und Dateien von diesem Gerät. In den Trip-Chats selbst wird nichts gelöscht — Dateien werden beim nächsten Öffnen einfach erneut heruntergeladen.';

  @override
  String get clear => 'Leeren';

  @override
  String get cacheCleared => 'Cache geleert.';

  @override
  String couldNotClearCache(String error) {
    return 'Cache konnte nicht geleert werden: $error';
  }

  @override
  String get storageTitle => 'Speicher';

  @override
  String get clearCacheRow => 'Cache leeren';

  @override
  String get clearCacheSubtitle =>
      'Entfernt heruntergeladene Chat-Fotos und -Dateien von diesem Gerät';

  @override
  String couldNotUnblock(String error) {
    return 'Entsperren fehlgeschlagen: $error';
  }

  @override
  String get blockedUsersTitle => 'Blockierte Nutzer';

  @override
  String get noBlockedUsers => 'Keine blockierten Nutzer.';

  @override
  String get unblock => 'Entsperren';

  @override
  String get copyEmailAddress => 'E-Mail-Adresse kopieren';

  @override
  String get emailAddressCopied => 'E-Mail-Adresse kopiert';

  @override
  String get legalTitle => 'Rechtliches';

  @override
  String get termsOfService => 'Nutzungsbedingungen';

  @override
  String get privacyPolicy => 'Datenschutzerklärung';

  @override
  String get contactSupport => 'Support kontaktieren';

  @override
  String get addADive => 'Tauchgang hinzufügen';

  @override
  String get updateLevelTitle => 'Level aktualisieren';

  @override
  String get save => 'Speichern';

  @override
  String get addSpeciality => 'Spezialisierung hinzufügen';

  @override
  String get specialityName => 'Name der Spezialisierung';

  @override
  String get notificationsTitle => 'Benachrichtigungen';

  @override
  String get pushNotificationsLabel => 'Push-Benachrichtigungen';

  @override
  String get pushDisabledInSystemSettings =>
      'In den Systemeinstellungen deaktiviert — aktiviere dort zuerst DiveBubble-Benachrichtigungen';

  @override
  String get tapToEnableNotifications =>
      'Tippen, um Benachrichtigungen zu aktivieren';

  @override
  String get newMessagesTripUpdatesEtc =>
      'Neue Nachrichten, Trip-Änderungen und mehr';

  @override
  String get verified => 'Verifiziert';

  @override
  String get addCertificate => 'Zertifikat hinzufügen';

  @override
  String get blockThisUserTitle => 'Diesen Nutzer blockieren?';

  @override
  String get blockUserBody =>
      'Du siehst seine Nachrichten in gemeinsamen Trip-Chats nicht mehr. Das kannst du unter Profil → Blockierte Nutzer rückgängig machen.';

  @override
  String get block => 'Blockieren';

  @override
  String get blockUserTooltip => 'Nutzer blockieren';

  @override
  String get blockedManageBody =>
      'Blockiert. Verwalten unter Profil → Blockierte Nutzer.';

  @override
  String couldNotBlockUser(String error) {
    return 'Nutzer konnte nicht blockiert werden: $error';
  }

  @override
  String get bioLabel => 'Bio';

  @override
  String get divesLabel => 'Tauchgänge';

  @override
  String get languagesLabel => 'Sprachen';

  @override
  String get memberSinceLabel => 'Mitglied seit';

  @override
  String get editProfileTitle => 'Profil bearbeiten';

  @override
  String get displayNameLabel => 'Anzeigename';

  @override
  String get displayNameHelper =>
      'Wird anderen Tauchern statt deines echten Namens angezeigt';

  @override
  String get pleaseEnterDisplayName => 'Bitte gib einen Anzeigenamen ein';

  @override
  String get locationLabel => 'Standort';

  @override
  String get useCurrentLocationTooltip => 'Aktuellen Standort verwenden';

  @override
  String get unloggedDivesLabel => 'Nicht geloggte Tauchgänge';

  @override
  String get unloggedDivesHelper =>
      'Tauchgänge, die du nicht in dein Logbuch eingetragen hast — werden zusammen mit ihm als Gesamtzahl angezeigt';

  @override
  String get allDivesAreLogged => 'Alle meine Tauchgänge sind geloggt';

  @override
  String get selectLanguages => 'Sprachen auswählen';

  @override
  String get zeroOutUnloggedDivesTitle =>
      'Nicht geloggte Tauchgänge auf null setzen?';

  @override
  String get zeroOutUnloggedDivesBody =>
      'Dies setzt die Zahl oben auf 0. Deine Logbucheinträge bleiben unberührt — nur die manuell eingegebene Zahl ändert sich.';

  @override
  String get zeroOut => 'Auf null setzen';

  @override
  String get editDiveTitle => 'Tauchgang bearbeiten';

  @override
  String get addDiveTitle => 'Tauchgang hinzufügen';

  @override
  String get importedDiveLockedNotice =>
      'Dieser Tauchgang wurde von deinem Tauchcomputer importiert — nur Land, Tauchplatz und Notizen können bearbeitet werden.';

  @override
  String get dateLabel => 'Datum';

  @override
  String get timeLabel => 'Uhrzeit';

  @override
  String get maxDepthLabel => 'Max. Tiefe';

  @override
  String get avgDepthLabel => 'Ø Tiefe';

  @override
  String get durationLabel => 'Dauer';

  @override
  String get minTemperatureLabel => 'Min. Temperatur';

  @override
  String get minTempLabel => 'Min. Temp.';

  @override
  String get maxTempLabel => 'Max. Temp.';

  @override
  String get countryLabel => 'Land';

  @override
  String get diveSiteLabel => 'Tauchplatz';

  @override
  String get notesLabel => 'Notizen';

  @override
  String get saveChanges => 'Änderungen speichern';

  @override
  String get deleteThisDiveTitle => 'Diesen Tauchgang löschen?';

  @override
  String get cantBeUndone => 'Das kann nicht rückgängig gemacht werden.';

  @override
  String get gearEssentialSection => 'ESSENZIELL';

  @override
  String get gearAdditionalSection => 'ZUSÄTZLICH';

  @override
  String get addItem => 'Gegenstand hinzufügen';

  @override
  String get gearOwned => 'Vorhanden';

  @override
  String get gearMissing => 'Fehlt';

  @override
  String get gearUsuallyRent => 'Meist geliehen';

  @override
  String get addItemSheetBody =>
      'Für alles über das Wesentliche hinaus — Lampe, Actionkamera, Boje...';

  @override
  String get itemNameLabel => 'Name des Gegenstands';

  @override
  String get gearItemBoots => 'Füßlinge';

  @override
  String get gearItemFins => 'Flossen';

  @override
  String get gearItemBcd => 'BCD';

  @override
  String get gearItemWetsuitShorty5mm => 'Shorty-Neoprenanzug 5mm';

  @override
  String get gearItemWetsuit5mm => 'Neoprenanzug 5mm';

  @override
  String get gearItemWetsuit7mm => 'Neoprenanzug 7mm';

  @override
  String get gearItemWetsuit9mm => 'Neoprenanzug 9mm';

  @override
  String get gearItemSemidrySuit => 'Halbtrockenanzug';

  @override
  String get gearItemDrySuit => 'Trockenanzug';

  @override
  String get gearItemHelmet => 'Helm';

  @override
  String get gearItemGloves => 'Handschuhe';

  @override
  String get gearItemRegulator => 'Atemregler';

  @override
  String get gearItemComputer => 'Tauchcomputer';

  @override
  String get gearItemMask => 'Maske';

  @override
  String get shareToBubble => 'In Bubble teilen';

  @override
  String get sourceLabel => 'Quelle';

  @override
  String get importedValue => 'Importiert';

  @override
  String get manualValue => 'Manuell';

  @override
  String diveOnDate(String date) {
    return 'Tauchgang am $date';
  }

  @override
  String labelColonValue(String label, String value) {
    return '$label: $value';
  }

  @override
  String get sharedToBubble => 'In Bubble geteilt';

  @override
  String couldNotShare(String error) {
    return 'Teilen fehlgeschlagen: $error';
  }

  @override
  String get haventJoinedAnyBubblesYet =>
      'Du bist noch keinem Bubble beigetreten.';

  @override
  String selectedCountLabel(int count) {
    return '$count ausgewählt';
  }

  @override
  String get noDivesLoggedYet => 'Noch keine Tauchgänge geloggt';

  @override
  String get addDiveOrImportBody =>
      'Füge einen Tauchgang manuell hinzu oder importiere eine Logbuchdatei.';

  @override
  String deleteDivesConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tauchgänge löschen?',
      one: '$count Tauchgang löschen?',
    );
    return '$_temp0';
  }

  @override
  String couldNotDeleteDivesError(int count, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tauchgänge konnten nicht gelöscht werden: $error',
      one: '$count Tauchgang konnte nicht gelöscht werden: $error',
    );
    return '$_temp0';
  }

  @override
  String couldNotDeleteWithError(String error) {
    return 'Löschen fehlgeschlagen: $error';
  }

  @override
  String get addADiveManually => 'Tauchgang manuell hinzufügen';

  @override
  String get importADiveLogFile => 'Logbuchdatei importieren';

  @override
  String get importFormatsSubtitle => 'UDDF, CSV oder ein Diving-Log-6-Export';

  @override
  String get csvColumnFormatTitle => 'CSV-Spaltenformat';

  @override
  String get csvColumnFormatBody =>
      'Die erste Zeile muss eine Kopfzeile mit diesen Spaltennamen sein (beliebige Reihenfolge, nur \"date\" ist erforderlich):\n\ndate (JJJJ-MM-TT)\ntime (HH:MM)\ncountry\nsite\nmax_depth_m\navg_depth_m\nduration_min\nmin_temp_c\nnotes';

  @override
  String get gotIt => 'Verstanden';

  @override
  String diveImportedSimple(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tauchgänge importiert',
      one: '$count Tauchgang importiert',
    );
    return '$_temp0';
  }

  @override
  String diveImportedWithSkipped(int count, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count neue Tauchgänge importiert, $skipped bereits geloggt',
      one: '$count neuer Tauchgang importiert, $skipped bereits geloggt',
    );
    return '$_temp0';
  }

  @override
  String couldNotImport(String error) {
    return 'Import fehlgeschlagen: $error';
  }

  @override
  String get unknownError => 'unbekannter Fehler';

  @override
  String get updateUnloggedCountPromptBody =>
      'Falls einige davon schon in deinem Profil gezählt wurden, aktualisiere es unter Profil bearbeiten.';

  @override
  String get editProfileAction => 'Profil bearbeiten';

  @override
  String get depthLabel => 'Tiefe';

  @override
  String get temperatureLabel => 'Temperatur';

  @override
  String get dragToInspectHint =>
      'Über die Grafik ziehen, um einen Punkt zu untersuchen';

  @override
  String get done => 'Fertig';

  @override
  String get searchLanguages => 'Sprachen suchen';

  @override
  String get languageSettingsTitle => 'Sprache';

  @override
  String get systemDefault => 'Systemstandard';

  @override
  String get guest => 'Gast';

  @override
  String get certificationsSectionTitle => 'Zertifizierungen';

  @override
  String get update => 'Aktualisieren';

  @override
  String get specialtiesSectionTitle => 'Spezialisierungen';

  @override
  String get gearSectionTitle => 'Ausrüstung';

  @override
  String get couldNotUploadPhoto => 'Foto konnte nicht hochgeladen werden';

  @override
  String get couldNotRemovePhoto => 'Foto konnte nicht entfernt werden';

  @override
  String get changePhoto => 'Foto ändern';

  @override
  String get removePhoto => 'Foto entfernen';

  @override
  String get diveOut => 'Abmelden';

  @override
  String get deleteAccountTitle => 'Konto löschen?';

  @override
  String get deleteAccountBody =>
      'Dies anonymisiert dein Konto dauerhaft und storniert alle von dir organisierten Trips. Das kann nicht rückgängig gemacht werden.';

  @override
  String couldNotDeleteAccount(String error) {
    return 'Konto konnte nicht gelöscht werden: $error';
  }

  @override
  String get deleteAccountRow => 'Konto löschen';

  @override
  String get noExpensesYet => 'Noch keine Ausgaben';

  @override
  String get logSharedCostBody =>
      'Erfasse eine gemeinsame Ausgabe, damit jeder weiß, was er schuldet.';

  @override
  String get addExpenseCta => 'Ausgabe hinzufügen';

  @override
  String get addExpenseTitle => 'Ausgabe hinzufügen';

  @override
  String get editExpenseTitle => 'Ausgabe bearbeiten';

  @override
  String get allSettledUp => 'Alles ausgeglichen';

  @override
  String get allSettledUpPeriod => 'Alles ausgeglichen.';

  @override
  String youAreOwedAmount(String amount) {
    return 'Dir werden $amount geschuldet';
  }

  @override
  String youOweAmount(String amount) {
    return 'Du schuldest $amount';
  }

  @override
  String youOweName(String name) {
    return 'Du schuldest $name';
  }

  @override
  String nameOwesYou(String name) {
    return '$name schuldet dir';
  }

  @override
  String paidByAndDate(String name, String date) {
    return 'Bezahlt von $name · $date';
  }

  @override
  String get balanceTitle => 'Bilanz';

  @override
  String get markSettled => 'Als ausgeglichen markieren';

  @override
  String couldNotSettle(String error) {
    return 'Ausgleichen fehlgeschlagen: $error';
  }

  @override
  String get titleFieldLabel => 'Titel';

  @override
  String get amountLabel => 'Betrag';

  @override
  String get paidByLabel => 'Bezahlt von';

  @override
  String get splitEqual => 'Gleich';

  @override
  String get splitShares => 'Anteile';

  @override
  String get splitExact => 'Genau';

  @override
  String get splitBetweenLabel => 'Aufteilen zwischen';

  @override
  String get fullyAssigned => 'Vollständig zugewiesen';

  @override
  String remainingToAssign(String amount) {
    return 'Noch zuzuweisen: $amount';
  }

  @override
  String get fillTitleAmountParticipant =>
      'Gib einen Titel, einen Betrag und mindestens einen Teilnehmer an.';

  @override
  String get enterExactAmountForEveryone =>
      'Gib für jeden Ausgewählten einen genauen Betrag ein.';

  @override
  String get exactAmountsMustAddUp =>
      'Die genauen Beträge müssen der Gesamtsumme entsprechen.';

  @override
  String get deleteExpenseTitle => 'Diese Ausgabe löschen?';

  @override
  String get deleteExpenseBody =>
      'Sie wird für alle aus der Bilanz entfernt. Das kann nicht rückgängig gemacht werden.';

  @override
  String get editTripTitle => 'Trip bearbeiten';

  @override
  String uploadUpToNPhotos(int max) {
    return 'Lade bis zu $max Fotos hoch.';
  }

  @override
  String get titleIsRequired => 'Titel ist erforderlich';

  @override
  String get locationIsRequired => 'Ort ist erforderlich';

  @override
  String get dateIsRequired => 'Datum ist erforderlich';

  @override
  String get meetingTimeLabel => 'Treffzeit';

  @override
  String get meetingTimeIsRequired => 'Treffzeit ist erforderlich';

  @override
  String get endDateOptionalLabel =>
      'Enddatum (optional, für mehrtägige Trips)';

  @override
  String get meetingPointOptionalLabel => 'Treffpunkt (optional)';

  @override
  String get descriptionOptionalLabel => 'Beschreibung (optional)';

  @override
  String get requiredLevelLabel => 'Erforderliches Level';

  @override
  String get openToAll => 'Offen für alle';

  @override
  String get minDepthMLabel => 'Min. Tiefe (m)';

  @override
  String get maxDepthMLabel => 'Max. Tiefe (m)';

  @override
  String get minDivesLabel => 'Min. Tauchgänge';

  @override
  String get maxDivesLabel => 'Max. Tauchgänge';

  @override
  String onlyNPhotosAllowed(int max) {
    return 'Nur $max Fotos pro Trip erlaubt';
  }

  @override
  String get selectADate => 'Datum auswählen';

  @override
  String get selectATime => 'Uhrzeit auswählen';

  @override
  String get enterBookingCodeTitle => 'Buchungscode eingeben';

  @override
  String get bookingCodeDialogBody =>
      'Hast du einen Trip direkt auf der Website eines Tauchcenters gebucht? Gib den Code ein, den du erhalten hast, um seinem Bubble beizutreten.';

  @override
  String get bookingCodeLabel => 'Buchungscode';

  @override
  String get bookingCodeHint => 'z. B. 8XK2NPQ4';
}
