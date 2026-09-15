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
}
