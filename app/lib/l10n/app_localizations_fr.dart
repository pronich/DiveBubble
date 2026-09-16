// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'DiveBubble';

  @override
  String get introSubtitle =>
      'Trouve des sorties plongée, rencontre tes buddies et organise la logistique ensemble.';

  @override
  String get diveIn => 'C\'est parti';

  @override
  String get skipForNow => 'Plus tard';

  @override
  String get signIn => 'Connexion';

  @override
  String get enterYourEmail => 'Entre ton e-mail';

  @override
  String get enterCodeSentToYou => 'Entre le code qu\'on t\'a envoyé';

  @override
  String get continueWithGoogle => 'Continuer avec Google';

  @override
  String get continueWithApple => 'Continuer avec Apple';

  @override
  String get continueWithEmail => 'Continuer avec l\'e-mail';

  @override
  String enterCodeSentTo(String email) {
    return 'Entre le code envoyé à $email';
  }

  @override
  String get verify => 'Vérifier';

  @override
  String get useADifferentEmail => 'Utiliser une autre adresse e-mail';

  @override
  String get email => 'E-mail';

  @override
  String get sendCode => 'Envoyer le code';

  @override
  String get useADifferentSignInMethod => 'Utiliser un autre mode de connexion';

  @override
  String get stayInTheLoop => 'Reste informé';

  @override
  String get pushPermissionBody =>
      'Sois averti des nouveaux messages, des changements de trip et de qui rejoint tes trajets. Tu peux désactiver ça à tout moment dans les réglages du profil.';

  @override
  String get continueLabel => 'Continuer';

  @override
  String get notNow => 'Pas maintenant';

  @override
  String get addYourCertifications => 'Ajoute tes certifications';

  @override
  String get certificationsOnboardingBody =>
      'Ton niveau montre aux autres plongeurs que tu es prêt pour un trip, et certains trips demandent un niveau minimum pour y participer. Tu peux l\'ajouter ou le modifier à tout moment depuis ton profil.';

  @override
  String get level => 'Niveau';

  @override
  String get pleaseSelectALevel => 'Sélectionne un niveau';

  @override
  String get selectLevel => 'Sélectionner un niveau';

  @override
  String get agencyOptional => 'Organisme (optionnel)';

  @override
  String get notSet => 'Non défini';

  @override
  String get certificationNumberOptional =>
      'Numéro de certification (optionnel)';

  @override
  String get saveAndContinue => 'Enregistrer et continuer';

  @override
  String errorWithMessage(String error) {
    return 'Erreur : $error';
  }

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get you => 'Toi';

  @override
  String get diver => 'Plongeur';

  @override
  String get searchBubbles => 'Rechercher des Bubbles';

  @override
  String get noMatches => 'Aucun résultat.';

  @override
  String get share => 'Partager';

  @override
  String get documentFallbackName => 'Document.pdf';

  @override
  String get copiedToClipboard => 'Copié';

  @override
  String get deleteThisMessageTitle => 'Supprimer ce message ?';

  @override
  String get deleteThisMessageBody =>
      'Cette action est irréversible — il sera supprimé pour tout le monde dans ce Bubble.';

  @override
  String couldNotDeleteMessage(String error) {
    return 'Impossible de supprimer le message : $error';
  }

  @override
  String couldNotReact(String error) {
    return 'Impossible de réagir : $error';
  }

  @override
  String get reply => 'Répondre';

  @override
  String get copyText => 'Copier le texte';

  @override
  String get report => 'Signaler';

  @override
  String get removeDocumentFirst =>
      'Retire d\'abord le document pour ajouter des photos.';

  @override
  String onlyNAttachmentsAllowed(int max) {
    return 'Seulement $max pièces jointes autorisées par message.';
  }

  @override
  String get documentOnlyOnItsOwn =>
      'Un document ne peut être envoyé que seul.';

  @override
  String get someFilesTooLarge => 'Certains fichiers sont trop volumineux.';

  @override
  String couldNotSendAttachment(String error) {
    return 'Impossible d\'envoyer la pièce jointe : $error';
  }

  @override
  String get noMessagesYet => 'Pas encore de messages';

  @override
  String get tripCancelledReadOnly =>
      'Ce trip a été annulé — le chat est en lecture seule.';

  @override
  String replyingTo(String name) {
    return 'Réponse à $name';
  }

  @override
  String get captionOptional => 'Légende (optionnel)';

  @override
  String get messageHint => 'Message';

  @override
  String get messageDeleted => 'Message supprimé';

  @override
  String attachmentsCountLabel(int count) {
    return '📎 $count pièces jointes';
  }

  @override
  String get photoLabel => '📷 Photo';

  @override
  String get videoLabel => '🎬 Vidéo';

  @override
  String get pdfLabel => '📄 PDF';

  @override
  String get newMessages => 'Nouveaux messages';

  @override
  String get productObserver => 'Product Observer';

  @override
  String get reportMessageTitle => 'Signaler le message';

  @override
  String get detailsOptional => 'Détails (optionnel)';

  @override
  String get sendReport => 'Envoyer le signalement';

  @override
  String get reportSentThankYou => 'Signalement envoyé — merci.';

  @override
  String couldNotSendReport(String error) {
    return 'Impossible d\'envoyer le signalement : $error';
  }

  @override
  String get thankYou => 'Merci !';

  @override
  String get giveFeedback => 'Donner ton avis';

  @override
  String get howUsefulQuestion =>
      'DiveBubble t\'a-t-il été utile pour ce trip ?';

  @override
  String get whatDidHelpQuestion => 'Avec quoi DiveBubble t\'a-t-il aidé ?';

  @override
  String get whatShouldImproveQuestion => 'Que devrions-nous améliorer ?';

  @override
  String get optionalHintText => 'Optionnel';

  @override
  String get canContactAboutFeedback =>
      'Peut-on te contacter à propos de ton avis ?';

  @override
  String get submitFeedback => 'Envoyer l\'avis';

  @override
  String couldNotSendFeedback(String error) {
    return 'Impossible d\'envoyer l\'avis : $error';
  }

  @override
  String get reportReasonSpam => 'Spam';

  @override
  String get reportReasonHarassment => 'Harcèlement';

  @override
  String get reportReasonInappropriateContent => 'Contenu inapproprié';

  @override
  String get reportReasonOther => 'Autre';

  @override
  String get helpedWithTripInformation => 'Informations sur le trip';

  @override
  String get helpedWithChattingWithParticipants =>
      'Discuter avec les participants';

  @override
  String get helpedWithFindingTransport => 'Trouver un transport';

  @override
  String get helpedWithFindingBuddy => 'Trouver un buddy';

  @override
  String get helpedWithNothingYet => 'Rien pour l\'instant';

  @override
  String couldNotSharePhoto(String error) {
    return 'Impossible de partager la photo : $error';
  }

  @override
  String couldNotShareVideo(String error) {
    return 'Impossible de partager la vidéo : $error';
  }

  @override
  String get couldNotLoadVideo => 'Impossible de charger la vidéo';

  @override
  String couldNotLoadMedia(String error) {
    return 'Impossible de charger les médias : $error';
  }

  @override
  String get noPhotosOrVideosSharedYet =>
      'Aucune photo ou vidéo partagée pour l\'instant';

  @override
  String couldNotLoadFiles(String error) {
    return 'Impossible de charger les fichiers : $error';
  }

  @override
  String get noFilesSharedYet => 'Aucun fichier partagé pour l\'instant';

  @override
  String couldNotLoadLinks(String error) {
    return 'Impossible de charger les liens : $error';
  }

  @override
  String get noLinksSharedYet => 'Aucun lien partagé pour l\'instant';

  @override
  String get shareToABubble => 'Partager dans un Bubble';

  @override
  String get noBubblesYet => 'Pas encore de Bubbles';

  @override
  String get joinATripToShareInto =>
      'Rejoins un trip pour avoir un Bubble dans lequel partager.';

  @override
  String get bubblesTabTitle => 'Bubbles';

  @override
  String get diveLogTabTitle => 'Carnet';

  @override
  String get profileTabTitle => 'Profil';

  @override
  String get signInToSeeYourTrips => 'Connecte-toi pour voir tes trips';

  @override
  String get logInToViewTripsBody =>
      'Connecte-toi pour voir les trips que tu as rejoints et leurs chats de groupe.';

  @override
  String get startYourFirstBubble => 'Lance ton premier Bubble';

  @override
  String get startYourFirstBubbleBody =>
      'Crée un trip ou rejoins-en un avec un code — chat, transport et détails du trip au même endroit.';

  @override
  String get createTrip => 'Créer un trip';

  @override
  String get joinTrip => 'Rejoindre';

  @override
  String get chatTabLabel => 'Chat';

  @override
  String get transportTabLabel => 'Transport';

  @override
  String get buddyTabLabel => 'Buddy';

  @override
  String get expensesTabLabel => 'Dépenses';

  @override
  String get archive => 'Archiver';

  @override
  String get unarchive => 'Désarchiver';

  @override
  String get cancelTrip => 'Annuler le trip';

  @override
  String get leave => 'Quitter';

  @override
  String couldNotArchive(String error) {
    return 'Impossible d\'archiver : $error';
  }

  @override
  String couldNotUnarchive(String error) {
    return 'Impossible de désarchiver : $error';
  }

  @override
  String get leaveBubbleTitle => 'Quitter ce Bubble ?';

  @override
  String get leaveBubbleBody =>
      'Tu perdras ta place et pourras la reprendre plus tard s\'il reste de la place.';

  @override
  String couldNotLeave(String error) {
    return 'Impossible de quitter : $error';
  }

  @override
  String get cancelTripTitle => 'Annuler ce trip ?';

  @override
  String get cancelTripBody =>
      'Chaque participant garde le Bubble pour voir l\'historique du chat, mais personne — toi y compris — ne pourra plus envoyer de messages, rejoindre ou organiser de transport. Cette action est irréversible.';

  @override
  String get neverMind => 'Laisser tomber';

  @override
  String couldNotCancel(String error) {
    return 'Impossible d\'annuler : $error';
  }

  @override
  String get cancelledStatus => 'Annulé';

  @override
  String get pastStatus => 'Passé';

  @override
  String get activeStatus => 'Actif';

  @override
  String get archivedChats => 'Chats archivés';

  @override
  String get noArchivedChats => 'Aucun chat archivé';

  @override
  String get archivedChatsEmptyBody =>
      'Les Bubbles que tu archives apparaissent ici — glisse ou désarchive pour en récupérer un.';

  @override
  String get typeOfferRide => 'Je propose une place';

  @override
  String get typeShareRental => 'Je partage une location';

  @override
  String get carCancelledByOrganizer =>
      'Cette voiture a été annulée par l\'organisateur.';

  @override
  String get noTransportWasArranged => 'Aucun transport n\'a été organisé';

  @override
  String get beFirstToShareTransport =>
      'Sois le premier à partager un transport';

  @override
  String get tripCancelledSimple => 'Ce trip a été annulé.';

  @override
  String get offerRideOrShareRental =>
      'Propose une place ou partage une location pour que d\'autres te rejoignent.';

  @override
  String get addTransportInfo => 'Ajouter un transport';

  @override
  String seatsTakenLabel(int joined, int total) {
    return '$joined places prises sur $total';
  }

  @override
  String get joinedStatus => 'Inscrit';

  @override
  String get fullStatus => 'Complet';

  @override
  String get organizerLabel => 'Organisateur';

  @override
  String get organizerYou => 'Organisateur · Toi';

  @override
  String get joinedDivers => 'Plongeurs inscrits';

  @override
  String get noOneHasJoinedYet => 'Personne n\'a encore rejoint';

  @override
  String get cancelCarOffer => 'Annuler la voiture';

  @override
  String get leaveCar => 'Quitter la voiture';

  @override
  String get join => 'Rejoindre';

  @override
  String get seatsOptional => 'Places (optionnel)';

  @override
  String get detailsTimePickupOptional =>
      'Détails — horaire, point de rendez-vous (optionnel)';

  @override
  String get add => 'Ajouter';

  @override
  String get buddyGroupCancelledByOrganizer =>
      'Ce groupe buddy a été annulé par l\'organisateur.';

  @override
  String get noBuddyRequestsWereMade =>
      'Aucune demande de buddy n\'a été faite';

  @override
  String get beFirstToLookForBuddy => 'Sois le premier à chercher un buddy';

  @override
  String get requestBuddySoOthersCanJoin =>
      'Demande un buddy pour que d\'autres puissent te rejoindre pour cette plongée.';

  @override
  String get requestABuddy => 'Demander un buddy';

  @override
  String get buddyRequestTitle => 'Demande de buddy';

  @override
  String divesCountLabel(int count) {
    return '$count plongées';
  }

  @override
  String get creatorLabel => 'Créateur';

  @override
  String get creatorYou => 'Créateur · Toi';

  @override
  String get groupLabel => 'Groupe';

  @override
  String get cancelBuddyRequest => 'Annuler la demande';

  @override
  String get leaveBuddyGroup => 'Quitter le groupe';

  @override
  String get otherDiversWillSeeRequest =>
      'Les autres plongeurs de ce trip verront ta demande et pourront te rejoindre.';

  @override
  String get request => 'Envoyer';

  @override
  String get about => 'À propos';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get gearLockerTitle => 'Casier matériel';

  @override
  String ownedOfTotalInLocker(int owned, int total) {
    return '$owned/$total dans le casier';
  }

  @override
  String get clearCacheTitle => 'Vider le cache ?';

  @override
  String get clearCacheBody =>
      'Cela supprime les photos et fichiers téléchargés sur cet appareil. Rien n\'est supprimé des chats de trip eux-mêmes — les fichiers seront simplement retéléchargés la prochaine fois que tu les ouvres.';

  @override
  String get clear => 'Vider';

  @override
  String get cacheCleared => 'Cache vidé.';

  @override
  String couldNotClearCache(String error) {
    return 'Impossible de vider le cache : $error';
  }

  @override
  String get storageTitle => 'Stockage';

  @override
  String get clearCacheRow => 'Vider le cache';

  @override
  String get clearCacheSubtitle =>
      'Supprime les photos et fichiers de chat téléchargés sur cet appareil';

  @override
  String couldNotUnblock(String error) {
    return 'Impossible de débloquer : $error';
  }

  @override
  String get blockedUsersTitle => 'Utilisateurs bloqués';

  @override
  String get noBlockedUsers => 'Aucun utilisateur bloqué.';

  @override
  String get unblock => 'Débloquer';

  @override
  String get copyEmailAddress => 'Copier l\'adresse e-mail';

  @override
  String get emailAddressCopied => 'Adresse e-mail copiée';

  @override
  String get legalTitle => 'Mentions légales';

  @override
  String get termsOfService => 'Conditions d\'utilisation';

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get contactSupport => 'Contacter le support';

  @override
  String get addADive => 'Ajouter une plongée';

  @override
  String get updateLevelTitle => 'Mettre à jour le niveau';

  @override
  String get save => 'Enregistrer';

  @override
  String get addSpeciality => 'Ajouter une spécialité';

  @override
  String get specialityName => 'Nom de la spécialité';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get pushNotificationsLabel => 'Notifications push';

  @override
  String get pushDisabledInSystemSettings =>
      'Désactivées dans les réglages système — active d\'abord les notifications DiveBubble là-bas';

  @override
  String get tapToEnableNotifications =>
      'Appuie pour activer les notifications';

  @override
  String get newMessagesTripUpdatesEtc =>
      'Nouveaux messages, mises à jour des trips et plus';

  @override
  String get verified => 'Vérifié';

  @override
  String get addCertificate => 'Ajouter un certificat';

  @override
  String get blockThisUserTitle => 'Bloquer cet utilisateur ?';

  @override
  String get blockUserBody =>
      'Tu ne verras plus ses messages dans les chats de trip partagés. Tu peux annuler ça depuis Profil → Utilisateurs bloqués.';

  @override
  String get block => 'Bloquer';

  @override
  String get blockUserTooltip => 'Bloquer l\'utilisateur';

  @override
  String get blockedManageBody =>
      'Bloqué. Gère ça dans Profil → Utilisateurs bloqués.';

  @override
  String couldNotBlockUser(String error) {
    return 'Impossible de bloquer l\'utilisateur : $error';
  }

  @override
  String get bioLabel => 'Bio';

  @override
  String get divesLabel => 'Plongées';

  @override
  String get languagesLabel => 'Langues';

  @override
  String get memberSinceLabel => 'Membre depuis';

  @override
  String get editProfileTitle => 'Modifier le profil';

  @override
  String get displayNameLabel => 'Nom affiché';

  @override
  String get displayNameHelper =>
      'Affiché aux autres plongeurs à la place de ton vrai nom';

  @override
  String get pleaseEnterDisplayName => 'Merci d\'indiquer un nom affiché';

  @override
  String get locationLabel => 'Localisation';

  @override
  String get useCurrentLocationTooltip => 'Utiliser la position actuelle';

  @override
  String get unloggedDivesLabel => 'Plongées non enregistrées';

  @override
  String get unloggedDivesHelper =>
      'Plongées que tu n\'as pas ajoutées à ton carnet — comptabilisées avec lui dans ton total';

  @override
  String get allDivesAreLogged => 'Toutes mes plongées sont enregistrées';

  @override
  String get selectLanguages => 'Sélectionner des langues';

  @override
  String get zeroOutUnloggedDivesTitle =>
      'Remettre à zéro les plongées non enregistrées ?';

  @override
  String get zeroOutUnloggedDivesBody =>
      'Cela remet le nombre ci-dessus à 0. Tes entrées de carnet ne sont pas affectées — seul le nombre saisi manuellement change.';

  @override
  String get zeroOut => 'Remettre à zéro';

  @override
  String get editDiveTitle => 'Modifier la plongée';

  @override
  String get addDiveTitle => 'Ajouter une plongée';

  @override
  String get importedDiveLockedNotice =>
      'Cette plongée a été importée depuis ton ordinateur de plongée — seuls le pays, le site et les notes peuvent être modifiés.';

  @override
  String get dateLabel => 'Date';

  @override
  String get timeLabel => 'Heure';

  @override
  String get maxDepthLabel => 'Profondeur max.';

  @override
  String get avgDepthLabel => 'Profondeur moy.';

  @override
  String get durationLabel => 'Durée';

  @override
  String get minTemperatureLabel => 'Température min.';

  @override
  String get minTempLabel => 'Temp. min.';

  @override
  String get maxTempLabel => 'Temp. max.';

  @override
  String get countryLabel => 'Pays';

  @override
  String get diveSiteLabel => 'Site de plongée';

  @override
  String get notesLabel => 'Notes';

  @override
  String get saveChanges => 'Enregistrer les modifications';

  @override
  String get deleteThisDiveTitle => 'Supprimer cette plongée ?';

  @override
  String get cantBeUndone => 'Cette action est irréversible.';

  @override
  String get gearEssentialSection => 'ESSENTIEL';

  @override
  String get gearAdditionalSection => 'SUPPLÉMENTAIRE';

  @override
  String get addItem => 'Ajouter un élément';

  @override
  String get gearOwned => 'Possédé';

  @override
  String get gearMissing => 'Manquant';

  @override
  String get gearUsuallyRent => 'Généralement loué';

  @override
  String get addItemSheetBody =>
      'Pour tout ce qui dépasse l\'essentiel — lampe, caméra d\'action, bouée...';

  @override
  String get itemNameLabel => 'Nom de l\'élément';

  @override
  String get gearItemBoots => 'Chaussons';

  @override
  String get gearItemFins => 'Palmes';

  @override
  String get gearItemBcd => 'BCD';

  @override
  String get gearItemWetsuitShorty5mm => 'Combinaison shorty 5mm';

  @override
  String get gearItemWetsuit5mm => 'Combinaison 5mm';

  @override
  String get gearItemWetsuit7mm => 'Combinaison 7mm';

  @override
  String get gearItemWetsuit9mm => 'Combinaison 9mm';

  @override
  String get gearItemSemidrySuit => 'Combinaison semi-étanche';

  @override
  String get gearItemDrySuit => 'Combinaison étanche';

  @override
  String get gearItemHelmet => 'Casque';

  @override
  String get gearItemGloves => 'Gants';

  @override
  String get gearItemRegulator => 'Détendeur';

  @override
  String get gearItemComputer => 'Ordinateur de plongée';

  @override
  String get gearItemMask => 'Masque';

  @override
  String get shareToBubble => 'Partager dans Bubble';

  @override
  String get sourceLabel => 'Source';

  @override
  String get importedValue => 'Importée';

  @override
  String get manualValue => 'Manuelle';

  @override
  String diveOnDate(String date) {
    return 'Plongée du $date';
  }

  @override
  String labelColonValue(String label, String value) {
    return '$label : $value';
  }

  @override
  String get sharedToBubble => 'Partagé dans Bubble';

  @override
  String couldNotShare(String error) {
    return 'Impossible de partager : $error';
  }

  @override
  String get haventJoinedAnyBubblesYet =>
      'Tu n\'as encore rejoint aucun Bubble.';

  @override
  String selectedCountLabel(int count) {
    return '$count sélectionné(s)';
  }

  @override
  String get noDivesLoggedYet => 'Aucune plongée enregistrée pour l\'instant';

  @override
  String get addDiveOrImportBody =>
      'Ajoute une plongée manuellement, ou importe un fichier de carnet de plongée.';

  @override
  String deleteDivesConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Supprimer $count plongées ?',
      one: 'Supprimer $count plongée ?',
    );
    return '$_temp0';
  }

  @override
  String couldNotDeleteDivesError(int count, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Impossible de supprimer $count plongées : $error',
      one: 'Impossible de supprimer $count plongée : $error',
    );
    return '$_temp0';
  }

  @override
  String couldNotDeleteWithError(String error) {
    return 'Impossible de supprimer : $error';
  }

  @override
  String get addADiveManually => 'Ajouter une plongée manuellement';

  @override
  String get importADiveLogFile => 'Importer un fichier de carnet de plongée';

  @override
  String get importFormatsSubtitle => 'UDDF, CSV, ou un export Diving Log 6';

  @override
  String get csvColumnFormatTitle => 'Format des colonnes CSV';

  @override
  String get csvColumnFormatBody =>
      'La première ligne doit être un en-tête avec ces noms de colonnes (dans n\'importe quel ordre, seul \"date\" est requis) :\n\ndate (AAAA-MM-JJ)\ntime (HH:MM)\ncountry\nsite\nmax_depth_m\navg_depth_m\nduration_min\nmin_temp_c\nnotes';

  @override
  String get gotIt => 'Compris';

  @override
  String diveImportedSimple(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count plongées importées',
      one: '$count plongée importée',
    );
    return '$_temp0';
  }

  @override
  String diveImportedWithSkipped(int count, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count nouvelles plongées importées, $skipped déjà enregistrées',
      one: '$count nouvelle plongée importée, $skipped déjà enregistrée',
    );
    return '$_temp0';
  }

  @override
  String couldNotImport(String error) {
    return 'Impossible d\'importer : $error';
  }

  @override
  String get unknownError => 'erreur inconnue';

  @override
  String get updateUnloggedCountPromptBody =>
      'Si certaines étaient déjà comptées dans ton profil, mets-le à jour dans Modifier le profil.';

  @override
  String get editProfileAction => 'Modifier le profil';

  @override
  String get depthLabel => 'Profondeur';

  @override
  String get temperatureLabel => 'Température';

  @override
  String get dragToInspectHint =>
      'Fais glisser le long du graphique pour inspecter un point';

  @override
  String get done => 'Terminé';

  @override
  String get searchLanguages => 'Rechercher des langues';

  @override
  String get languageSettingsTitle => 'Langue';

  @override
  String get systemDefault => 'Par défaut du système';

  @override
  String get guest => 'Invité';

  @override
  String get certificationsSectionTitle => 'Certifications';

  @override
  String get update => 'Mettre à jour';

  @override
  String get specialtiesSectionTitle => 'Spécialités';

  @override
  String get gearSectionTitle => 'Matériel';

  @override
  String get couldNotUploadPhoto => 'Impossible d\'envoyer la photo';

  @override
  String get couldNotRemovePhoto => 'Impossible de supprimer la photo';

  @override
  String get changePhoto => 'Changer la photo';

  @override
  String get removePhoto => 'Supprimer la photo';

  @override
  String get diveOut => 'Se déconnecter';

  @override
  String get deleteAccountTitle => 'Supprimer le compte ?';

  @override
  String get deleteAccountBody =>
      'Cela anonymise définitivement ton compte et annule tous les trips que tu organises. Cette action est irréversible.';

  @override
  String couldNotDeleteAccount(String error) {
    return 'Impossible de supprimer le compte : $error';
  }

  @override
  String get deleteAccountRow => 'Supprimer le compte';

  @override
  String get noExpensesYet => 'Pas encore de dépenses';

  @override
  String get logSharedCostBody =>
      'Enregistre une dépense partagée pour que tout le monde sache ce qu\'il doit.';

  @override
  String get addExpenseCta => 'Ajouter une dépense';

  @override
  String get addExpenseTitle => 'Ajouter une dépense';

  @override
  String get editExpenseTitle => 'Modifier la dépense';

  @override
  String get allSettledUp => 'Tout est réglé';

  @override
  String get allSettledUpPeriod => 'Tout est réglé.';

  @override
  String youAreOwedAmount(String amount) {
    return 'On te doit $amount';
  }

  @override
  String youOweAmount(String amount) {
    return 'Tu dois $amount';
  }

  @override
  String youOweName(String name) {
    return 'Tu dois à $name';
  }

  @override
  String nameOwesYou(String name) {
    return '$name te doit';
  }

  @override
  String paidByAndDate(String name, String date) {
    return 'Payé par $name · $date';
  }

  @override
  String get balanceTitle => 'Solde';

  @override
  String get markSettled => 'Marquer comme réglé';

  @override
  String couldNotSettle(String error) {
    return 'Impossible de régler : $error';
  }

  @override
  String get titleFieldLabel => 'Titre';

  @override
  String get amountLabel => 'Montant';

  @override
  String get paidByLabel => 'Payé par';

  @override
  String get splitEqual => 'Égal';

  @override
  String get splitShares => 'Parts';

  @override
  String get splitExact => 'Exact';

  @override
  String get splitBetweenLabel => 'Répartir entre';

  @override
  String get fullyAssigned => 'Entièrement réparti';

  @override
  String remainingToAssign(String amount) {
    return 'Reste à répartir : $amount';
  }

  @override
  String get fillTitleAmountParticipant =>
      'Renseigne un titre, un montant et au moins un participant.';

  @override
  String get enterExactAmountForEveryone =>
      'Indique un montant exact pour chaque personne sélectionnée.';

  @override
  String get exactAmountsMustAddUp =>
      'Les montants exacts doivent correspondre au total.';

  @override
  String get deleteExpenseTitle => 'Supprimer cette dépense ?';

  @override
  String get deleteExpenseBody =>
      'Elle sera retirée du solde pour tout le monde. Cette action est irréversible.';

  @override
  String get editTripTitle => 'Modifier le trip';

  @override
  String uploadUpToNPhotos(int max) {
    return 'Ajoute jusqu\'à $max photos.';
  }

  @override
  String get titleIsRequired => 'Le titre est obligatoire';

  @override
  String get locationIsRequired => 'Le lieu est obligatoire';

  @override
  String get dateIsRequired => 'La date est obligatoire';

  @override
  String get meetingTimeLabel => 'Heure de rendez-vous';

  @override
  String get meetingTimeIsRequired => 'L\'heure de rendez-vous est obligatoire';

  @override
  String get endDateOptionalLabel =>
      'Date de fin (optionnel, trips de plusieurs jours)';

  @override
  String get meetingPointOptionalLabel => 'Point de rendez-vous (optionnel)';

  @override
  String get descriptionOptionalLabel => 'Description (optionnel)';

  @override
  String get requiredLevelLabel => 'Niveau requis';

  @override
  String get openToAll => 'Ouvert à tous';

  @override
  String get minDepthMLabel => 'Profondeur min. (m)';

  @override
  String get maxDepthMLabel => 'Profondeur max. (m)';

  @override
  String get minDivesLabel => 'Plongées min.';

  @override
  String get maxDivesLabel => 'Plongées max.';

  @override
  String onlyNPhotosAllowed(int max) {
    return 'Seulement $max photos autorisées par trip';
  }

  @override
  String get selectADate => 'Sélectionner une date';

  @override
  String get selectATime => 'Sélectionner une heure';

  @override
  String get enterBookingCodeTitle => 'Entrer le code de réservation';

  @override
  String get bookingCodeDialogBody =>
      'Tu as réservé un trip auprès d\'un centre de plongée sur son propre site ? Entre le code qu\'on t\'a donné pour rejoindre son Bubble ici.';

  @override
  String get bookingCodeLabel => 'Code de réservation';

  @override
  String get bookingCodeHint => 'par ex. 8XK2NPQ4';

  @override
  String get managePhotos => 'Photos';

  @override
  String get editButtonLabel => 'Modifier';

  @override
  String get peopleTabLabel => 'Participants';

  @override
  String get mediaTabLabel => 'Médias';

  @override
  String get filesTabLabel => 'Fichiers';

  @override
  String get linksTabLabel => 'Liens';

  @override
  String get meetingPointSectionLabel => 'POINT DE RENDEZ-VOUS';

  @override
  String get aboutThisDive => 'À propos de cette plongée';

  @override
  String get levelSectionLabel => 'NIVEAU';

  @override
  String get depthSectionLabel => 'PROFONDEUR';

  @override
  String get divesSectionLabel => 'PLONGÉES';

  @override
  String get durationSectionLabel => 'DURÉE';

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
    return 'Jusqu\'à $max m';
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
      other: '$n plongées',
      one: '$n plongée',
    );
    return '$_temp0';
  }

  @override
  String diveCountRangeDives(int min, int max) {
    return '$min–$max plongées';
  }

  @override
  String diveCountUpToDives(int max) {
    return 'Jusqu\'à $max plongées';
  }

  @override
  String diveCountMinPlusDives(int min) {
    return '$min+ plongées';
  }

  @override
  String durationDaysPlural(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days jours',
      one: '$days jour',
    );
    return '$_temp0';
  }

  @override
  String get diveCenterLabel => 'Centre de plongée';

  @override
  String get bookNowLabel => 'Réserver';

  @override
  String bookNowWithPrice(String price, String currency) {
    return 'Réserver — $price $currency';
  }

  @override
  String get iHaveABookingCode => 'J\'ai un code de réservation';

  @override
  String get privateTripAskOrganizer =>
      'Ce trip est privé — demande à l\'organisateur un code ou un lien d\'invitation.';

  @override
  String get iHaveAnInviteCode => 'J\'ai un code d\'invitation';

  @override
  String get inviteCodeSectionLabel => 'CODE D\'INVITATION';

  @override
  String get shareInviteTooltip => 'Partager l\'invitation';

  @override
  String get shareInviteLink => 'Partager le lien d\'invitation';

  @override
  String get copyInviteLink => 'Copier le lien d\'invitation';

  @override
  String get copyBookingCode => 'Copier le code de réservation';

  @override
  String get unmute => 'Réactiver le son';

  @override
  String get mute => 'Couper le son';

  @override
  String get tripCancelledSnackbar => 'Trip annulé';

  @override
  String get diveInToBubble => 'Aller au Bubble';

  @override
  String participantsJoinedPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personnes inscrites',
      one: '$count personne inscrite',
    );
    return '$_temp0';
  }

  @override
  String participantsJoinedOfMaxPlural(int count, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personnes sur $max inscrites',
      one: '$count personne sur $max inscrite',
    );
    return '$_temp0';
  }

  @override
  String get agencyLabel => 'Organisme';

  @override
  String get websiteLabel => 'Site web';

  @override
  String get phoneLabel => 'Téléphone';

  @override
  String get emailLabel => 'E-mail';
}
