// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'DiveBubble';

  @override
  String get introSubtitle =>
      'Find dive trips, meet your buddies, and plan the logistics together.';

  @override
  String get diveIn => 'Dive in';

  @override
  String get skipForNow => 'Skip for now';

  @override
  String get signIn => 'Sign in';

  @override
  String get enterYourEmail => 'Enter your email';

  @override
  String get enterCodeSentToYou => 'Enter the code we sent you';

  @override
  String get continueWithGoogle => 'Continue with Google';

  @override
  String get continueWithApple => 'Continue with Apple';

  @override
  String get continueWithEmail => 'Continue with email';

  @override
  String enterCodeSentTo(String email) {
    return 'Enter the code we sent to $email';
  }

  @override
  String get verify => 'Verify';

  @override
  String get useADifferentEmail => 'Use a different email';

  @override
  String get email => 'Email';

  @override
  String get sendCode => 'Send code';

  @override
  String get useADifferentSignInMethod => 'Use a different sign-in method';

  @override
  String get stayInTheLoop => 'Stay in the loop';

  @override
  String get pushPermissionBody =>
      'Get notified about new messages, trip changes, and who\'s joining your rides. You can turn this off anytime in Profile settings.';

  @override
  String get continueLabel => 'Continue';

  @override
  String get notNow => 'Not now';

  @override
  String get addYourCertifications => 'Add your certifications';

  @override
  String get certificationsOnboardingBody =>
      'Your level shows other divers you\'re ready for a trip, and some trips require a minimum level to join. You can add or change this anytime from your profile.';

  @override
  String get level => 'Level';

  @override
  String get pleaseSelectALevel => 'Please select a level';

  @override
  String get selectLevel => 'Select level';

  @override
  String get agencyOptional => 'Agency (optional)';

  @override
  String get notSet => 'Not set';

  @override
  String get certificationNumberOptional => 'Certification number (optional)';

  @override
  String get saveAndContinue => 'Save and continue';

  @override
  String errorWithMessage(String error) {
    return 'Error: $error';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get you => 'You';

  @override
  String get diver => 'Diver';

  @override
  String get searchBubbles => 'Search Bubbles';

  @override
  String get noMatches => 'No matches.';

  @override
  String get share => 'Share';

  @override
  String get documentFallbackName => 'Document.pdf';

  @override
  String get copiedToClipboard => 'Copied';

  @override
  String get deleteThisMessageTitle => 'Delete this message?';

  @override
  String get deleteThisMessageBody =>
      'This cannot be undone — it will be removed for everyone in this Bubble.';

  @override
  String couldNotDeleteMessage(String error) {
    return 'Could not delete message: $error';
  }

  @override
  String couldNotReact(String error) {
    return 'Could not react: $error';
  }

  @override
  String get reply => 'Reply';

  @override
  String get copyText => 'Copy text';

  @override
  String get report => 'Report';

  @override
  String get removeDocumentFirst => 'Remove the document first to add photos.';

  @override
  String onlyNAttachmentsAllowed(int max) {
    return 'Only $max attachments allowed per message.';
  }

  @override
  String get documentOnlyOnItsOwn => 'A document can only be sent on its own.';

  @override
  String get someFilesTooLarge => 'Some files are too large.';

  @override
  String couldNotSendAttachment(String error) {
    return 'Could not send attachment: $error';
  }

  @override
  String get noMessagesYet => 'No messages yet';

  @override
  String get tripCancelledReadOnly =>
      'This trip has been cancelled — the chat is read-only.';

  @override
  String replyingTo(String name) {
    return 'Replying to $name';
  }

  @override
  String get captionOptional => 'Caption (optional)';

  @override
  String get messageHint => 'Message';

  @override
  String get messageDeleted => 'Message deleted';

  @override
  String attachmentsCountLabel(int count) {
    return '📎 $count attachments';
  }

  @override
  String get photoLabel => '📷 Photo';

  @override
  String get videoLabel => '🎬 Video';

  @override
  String get pdfLabel => '📄 PDF';

  @override
  String get newMessages => 'New messages';

  @override
  String get productObserver => 'Product Observer';

  @override
  String get reportMessageTitle => 'Report message';

  @override
  String get detailsOptional => 'Details (optional)';

  @override
  String get sendReport => 'Send report';

  @override
  String get reportSentThankYou => 'Report sent — thank you.';

  @override
  String couldNotSendReport(String error) {
    return 'Could not send report: $error';
  }

  @override
  String get thankYou => 'Thank you!';

  @override
  String get giveFeedback => 'Give feedback';

  @override
  String get howUsefulQuestion => 'How useful was DiveBubble for this trip?';

  @override
  String get whatDidHelpQuestion => 'What did DiveBubble help you with?';

  @override
  String get whatShouldImproveQuestion => 'What should we improve?';

  @override
  String get optionalHintText => 'Optional';

  @override
  String get canContactAboutFeedback =>
      'Can we contact you about your feedback?';

  @override
  String get submitFeedback => 'Submit feedback';

  @override
  String couldNotSendFeedback(String error) {
    return 'Could not send feedback: $error';
  }

  @override
  String get reportReasonSpam => 'Spam';

  @override
  String get reportReasonHarassment => 'Harassment';

  @override
  String get reportReasonInappropriateContent => 'Inappropriate content';

  @override
  String get reportReasonOther => 'Other';

  @override
  String get helpedWithTripInformation => 'Trip information';

  @override
  String get helpedWithChattingWithParticipants => 'Chatting with participants';

  @override
  String get helpedWithFindingTransport => 'Finding transport';

  @override
  String get helpedWithFindingBuddy => 'Finding Buddy';

  @override
  String get helpedWithNothingYet => 'Nothing yet';

  @override
  String couldNotSharePhoto(String error) {
    return 'Could not share photo: $error';
  }

  @override
  String couldNotShareVideo(String error) {
    return 'Could not share video: $error';
  }

  @override
  String get couldNotLoadVideo => 'Could not load video';

  @override
  String couldNotLoadMedia(String error) {
    return 'Could not load media: $error';
  }

  @override
  String get noPhotosOrVideosSharedYet => 'No photos or videos shared yet';

  @override
  String couldNotLoadFiles(String error) {
    return 'Could not load files: $error';
  }

  @override
  String get noFilesSharedYet => 'No files shared yet';

  @override
  String couldNotLoadLinks(String error) {
    return 'Could not load links: $error';
  }

  @override
  String get noLinksSharedYet => 'No links shared yet';

  @override
  String get shareToABubble => 'Share to a Bubble';

  @override
  String get noBubblesYet => 'No Bubbles yet';

  @override
  String get joinATripToShareInto =>
      'Join a trip to get a Bubble you can share into.';

  @override
  String get bubblesTabTitle => 'Bubbles';

  @override
  String get diveLogTabTitle => 'Dive Log';

  @override
  String get profileTabTitle => 'Profile';

  @override
  String get signInToSeeYourTrips => 'Sign in to see your trips';

  @override
  String get logInToViewTripsBody =>
      'Log in to view the trips you\'ve joined and their group chats.';

  @override
  String get startYourFirstBubble => 'Start your first Bubble';

  @override
  String get startYourFirstBubbleBody =>
      'Create a trip or join one with a code — chat, transport, and trip details all in one place.';

  @override
  String get createTrip => 'Create trip';

  @override
  String get joinTrip => 'Join trip';

  @override
  String get chatTabLabel => 'Chat';

  @override
  String get transportTabLabel => 'Transport';

  @override
  String get buddyTabLabel => 'Buddy';

  @override
  String get expensesTabLabel => 'Expenses';

  @override
  String get archive => 'Archive';

  @override
  String get unarchive => 'Unarchive';

  @override
  String get cancelTrip => 'Cancel trip';

  @override
  String get leave => 'Leave';

  @override
  String couldNotArchive(String error) {
    return 'Could not archive: $error';
  }

  @override
  String couldNotUnarchive(String error) {
    return 'Could not unarchive: $error';
  }

  @override
  String get leaveBubbleTitle => 'Leave this Bubble?';

  @override
  String get leaveBubbleBody =>
      'You\'ll lose your spot and can rejoin later if there\'s room.';

  @override
  String couldNotLeave(String error) {
    return 'Could not leave: $error';
  }

  @override
  String get cancelTripTitle => 'Cancel this trip?';

  @override
  String get cancelTripBody =>
      'Every participant keeps the Bubble to see the chat history, but no one — including you — can send messages, join, or arrange transport anymore. This can\'t be undone.';

  @override
  String get neverMind => 'Never mind';

  @override
  String couldNotCancel(String error) {
    return 'Could not cancel: $error';
  }

  @override
  String get cancelledStatus => 'Cancelled';

  @override
  String get pastStatus => 'Past';

  @override
  String get activeStatus => 'Active';

  @override
  String get archivedChats => 'Archived Chats';

  @override
  String get noArchivedChats => 'No archived chats';

  @override
  String get archivedChatsEmptyBody =>
      'Bubbles you archive show up here — swipe or unarchive to bring one back.';

  @override
  String get typeOfferRide => 'Offering a ride';

  @override
  String get typeShareRental => 'Sharing a rental';

  @override
  String get carCancelledByOrganizer =>
      'This car was cancelled by the organizer.';

  @override
  String get noTransportWasArranged => 'No transport was arranged';

  @override
  String get beFirstToShareTransport => 'Be the first to share transport';

  @override
  String get tripCancelledSimple => 'This trip has been cancelled.';

  @override
  String get offerRideOrShareRental =>
      'Offer a ride or share a rental so others can join you.';

  @override
  String get addTransportInfo => 'Add transport info';

  @override
  String seatsTakenLabel(int joined, int total) {
    return '$joined of $total seats taken';
  }

  @override
  String get joinedStatus => 'Joined';

  @override
  String get fullStatus => 'Full';

  @override
  String get organizerLabel => 'Organizer';

  @override
  String get organizerYou => 'Organizer · You';

  @override
  String get joinedDivers => 'Joined divers';

  @override
  String get noOneHasJoinedYet => 'No one has joined yet';

  @override
  String get cancelCarOffer => 'Cancel car offer';

  @override
  String get leaveCar => 'Leave car';

  @override
  String get join => 'Join';

  @override
  String get seatsOptional => 'Seats (optional)';

  @override
  String get detailsTimePickupOptional =>
      'Details — time, pickup point (optional)';

  @override
  String get add => 'Add';

  @override
  String get buddyGroupCancelledByOrganizer =>
      'This buddy group was cancelled by the organizer.';

  @override
  String get noBuddyRequestsWereMade => 'No buddy requests were made';

  @override
  String get beFirstToLookForBuddy => 'Be the first to look for a buddy';

  @override
  String get requestBuddySoOthersCanJoin =>
      'Request a buddy so others can join you for this dive.';

  @override
  String get requestABuddy => 'Request a buddy';

  @override
  String get buddyRequestTitle => 'Buddy request';

  @override
  String divesCountLabel(int count) {
    return '$count dives';
  }

  @override
  String get creatorLabel => 'Creator';

  @override
  String get creatorYou => 'Creator · You';

  @override
  String get groupLabel => 'Group';

  @override
  String get cancelBuddyRequest => 'Cancel buddy request';

  @override
  String get leaveBuddyGroup => 'Leave buddy group';

  @override
  String get otherDiversWillSeeRequest =>
      'Other divers on this trip will see your request and can join you.';

  @override
  String get request => 'Request';

  @override
  String get about => 'About';

  @override
  String versionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get gearLockerTitle => 'Gear locker';

  @override
  String ownedOfTotalInLocker(int owned, int total) {
    return '$owned/$total in Locker';
  }

  @override
  String get clearCacheTitle => 'Clear cache?';

  @override
  String get clearCacheBody =>
      'This removes downloaded photos and files from this device. Nothing is deleted from the trip chats themselves — files are simply re-downloaded next time you open them.';

  @override
  String get clear => 'Clear';

  @override
  String get cacheCleared => 'Cache cleared.';

  @override
  String couldNotClearCache(String error) {
    return 'Could not clear cache: $error';
  }

  @override
  String get storageTitle => 'Storage';

  @override
  String get clearCacheRow => 'Clear cache';

  @override
  String get clearCacheSubtitle =>
      'Removes downloaded chat photos and files from this device';

  @override
  String couldNotUnblock(String error) {
    return 'Could not unblock: $error';
  }

  @override
  String get blockedUsersTitle => 'Blocked users';

  @override
  String get noBlockedUsers => 'No blocked users.';

  @override
  String get unblock => 'Unblock';

  @override
  String get copyEmailAddress => 'Copy email address';

  @override
  String get emailAddressCopied => 'Email address copied';

  @override
  String get legalTitle => 'Legal';

  @override
  String get termsOfService => 'Terms of Service';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get contactSupport => 'Contact support';

  @override
  String get addADive => 'Add a dive';

  @override
  String get updateLevelTitle => 'Update level';

  @override
  String get save => 'Save';

  @override
  String get addSpeciality => 'Add speciality';

  @override
  String get specialityName => 'Speciality name';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get pushNotificationsLabel => 'Push notifications';

  @override
  String get pushDisabledInSystemSettings =>
      'Disabled in system settings — enable DiveBubble notifications there first';

  @override
  String get tapToEnableNotifications => 'Tap to enable notifications';

  @override
  String get newMessagesTripUpdatesEtc => 'New messages, trip updates and more';

  @override
  String get verified => 'Verified';

  @override
  String get addCertificate => 'Add certificate';

  @override
  String get blockThisUserTitle => 'Block this user?';

  @override
  String get blockUserBody =>
      'You won\'t see their messages in shared trip chats anymore. You can undo this from Profile → Blocked users.';

  @override
  String get block => 'Block';

  @override
  String get blockUserTooltip => 'Block user';

  @override
  String get blockedManageBody => 'Blocked. Manage in Profile → Blocked users.';

  @override
  String couldNotBlockUser(String error) {
    return 'Could not block user: $error';
  }

  @override
  String get bioLabel => 'Bio';

  @override
  String get divesLabel => 'Dives';

  @override
  String get languagesLabel => 'Languages';

  @override
  String get memberSinceLabel => 'Member since';

  @override
  String get editProfileTitle => 'Edit profile';

  @override
  String get displayNameLabel => 'Display name';

  @override
  String get displayNameHelper =>
      'Shown to other divers instead of your real name';

  @override
  String get pleaseEnterDisplayName => 'Please enter a display name';

  @override
  String get locationLabel => 'Location';

  @override
  String get useCurrentLocationTooltip => 'Use current location';

  @override
  String get unloggedDivesLabel => 'Unlogged dives';

  @override
  String get unloggedDivesHelper =>
      'Dives you haven\'t added to your Dive Log — shown together with it as your total';

  @override
  String get allDivesAreLogged => 'All my dives are logged';

  @override
  String get selectLanguages => 'Select languages';

  @override
  String get zeroOutUnloggedDivesTitle => 'Zero out unlogged dives?';

  @override
  String get zeroOutUnloggedDivesBody =>
      'This clears the number above to 0. Your Dive Log entries are untouched — this only affects the manually-entered count.';

  @override
  String get zeroOut => 'Zero out';

  @override
  String get editDiveTitle => 'Edit Dive';

  @override
  String get addDiveTitle => 'Add Dive';

  @override
  String get importedDiveLockedNotice =>
      'This dive was imported from your dive computer — only the country, dive site, and notes can be edited.';

  @override
  String get dateLabel => 'Date';

  @override
  String get timeLabel => 'Time';

  @override
  String get maxDepthLabel => 'Max depth';

  @override
  String get avgDepthLabel => 'Avg depth';

  @override
  String get durationLabel => 'Duration';

  @override
  String get minTemperatureLabel => 'Min temperature';

  @override
  String get minTempLabel => 'Min temp';

  @override
  String get maxTempLabel => 'Max temp';

  @override
  String get countryLabel => 'Country';

  @override
  String get diveSiteLabel => 'Dive site';

  @override
  String get notesLabel => 'Notes';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get deleteThisDiveTitle => 'Delete this dive?';

  @override
  String get cantBeUndone => 'This can\'t be undone.';

  @override
  String get gearEssentialSection => 'ESSENTIAL';

  @override
  String get gearAdditionalSection => 'ADDITIONAL';

  @override
  String get addItem => 'Add item';

  @override
  String get gearOwned => 'Owned';

  @override
  String get gearMissing => 'Missing';

  @override
  String get gearUsuallyRent => 'Usually rent';

  @override
  String get addItemSheetBody =>
      'For anything beyond the essentials — torch, action camera, buoy...';

  @override
  String get itemNameLabel => 'Item name';

  @override
  String get gearItemBoots => 'Boots';

  @override
  String get gearItemFins => 'Fins';

  @override
  String get gearItemBcd => 'BCD';

  @override
  String get gearItemWetsuitShorty5mm => 'Wetsuit shorty 5mm';

  @override
  String get gearItemWetsuit5mm => 'Wetsuit 5mm';

  @override
  String get gearItemWetsuit7mm => 'Wetsuit 7mm';

  @override
  String get gearItemWetsuit9mm => 'Wetsuit 9mm';

  @override
  String get gearItemSemidrySuit => 'Semidry suit';

  @override
  String get gearItemDrySuit => 'Dry suit';

  @override
  String get gearItemHelmet => 'Helmet';

  @override
  String get gearItemGloves => 'Gloves';

  @override
  String get gearItemRegulator => 'Regulator';

  @override
  String get gearItemComputer => 'Computer';

  @override
  String get gearItemMask => 'Mask';

  @override
  String get shareToBubble => 'Share to Bubble';

  @override
  String get sourceLabel => 'Source';

  @override
  String get importedValue => 'Imported';

  @override
  String get manualValue => 'Manual';

  @override
  String diveOnDate(String date) {
    return 'Dive on $date';
  }

  @override
  String labelColonValue(String label, String value) {
    return '$label: $value';
  }

  @override
  String get sharedToBubble => 'Shared to Bubble';

  @override
  String couldNotShare(String error) {
    return 'Could not share: $error';
  }

  @override
  String get haventJoinedAnyBubblesYet =>
      'You haven\'t joined any Bubbles yet.';

  @override
  String selectedCountLabel(int count) {
    return '$count selected';
  }

  @override
  String get noDivesLoggedYet => 'No dives logged yet';

  @override
  String get addDiveOrImportBody =>
      'Add a dive by hand, or import a dive log file.';

  @override
  String deleteDivesConfirmTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count dives?',
      one: 'Delete $count dive?',
    );
    return '$_temp0';
  }

  @override
  String couldNotDeleteDivesError(int count, String error) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Could not delete $count dives: $error',
      one: 'Could not delete $count dive: $error',
    );
    return '$_temp0';
  }

  @override
  String couldNotDeleteWithError(String error) {
    return 'Could not delete: $error';
  }

  @override
  String get addADiveManually => 'Add a dive manually';

  @override
  String get importADiveLogFile => 'Import a dive log file';

  @override
  String get importFormatsSubtitle => 'UDDF, CSV, or a Diving Log 6 export';

  @override
  String get csvColumnFormatTitle => 'CSV column format';

  @override
  String get csvColumnFormatBody =>
      'First row must be a header with these column names (any order, only \"date\" is required):\n\ndate (YYYY-MM-DD)\ntime (HH:MM)\ncountry\nsite\nmax_depth_m\navg_depth_m\nduration_min\nmin_temp_c\nnotes';

  @override
  String get gotIt => 'Got it';

  @override
  String diveImportedSimple(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count dives imported',
      one: '$count dive imported',
    );
    return '$_temp0';
  }

  @override
  String diveImportedWithSkipped(int count, int skipped) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count new dives imported, $skipped already logged',
      one: '$count new dive imported, $skipped already logged',
    );
    return '$_temp0';
  }

  @override
  String couldNotImport(String error) {
    return 'Could not import: $error';
  }

  @override
  String get unknownError => 'unknown error';

  @override
  String get updateUnloggedCountPromptBody =>
      'If some of these were already counted in your profile, update it in Edit Profile.';

  @override
  String get editProfileAction => 'Edit Profile';

  @override
  String get depthLabel => 'Depth';

  @override
  String get temperatureLabel => 'Temperature';

  @override
  String get dragToInspectHint => 'Drag along the chart to inspect a point';

  @override
  String get done => 'Done';

  @override
  String get searchLanguages => 'Search languages';

  @override
  String get languageSettingsTitle => 'Language';

  @override
  String get systemDefault => 'System default';

  @override
  String get guest => 'Guest';

  @override
  String get certificationsSectionTitle => 'Certifications';

  @override
  String get update => 'Update';

  @override
  String get specialtiesSectionTitle => 'Specialties';

  @override
  String get gearSectionTitle => 'Gear';

  @override
  String get couldNotUploadPhoto => 'Could not upload photo';

  @override
  String get couldNotRemovePhoto => 'Could not remove photo';

  @override
  String get changePhoto => 'Change photo';

  @override
  String get removePhoto => 'Remove photo';

  @override
  String get diveOut => 'Dive out';

  @override
  String get deleteAccountTitle => 'Delete account?';

  @override
  String get deleteAccountBody =>
      'This permanently anonymizes your account and cancels any trips you organize. This can\'t be undone.';

  @override
  String couldNotDeleteAccount(String error) {
    return 'Could not delete account: $error';
  }

  @override
  String get deleteAccountRow => 'Delete account';

  @override
  String get noExpensesYet => 'No expenses yet';

  @override
  String get logSharedCostBody =>
      'Log a shared cost so everyone knows what they owe.';

  @override
  String get addExpenseCta => 'Add expense';

  @override
  String get addExpenseTitle => 'Add Expense';

  @override
  String get editExpenseTitle => 'Edit Expense';

  @override
  String get allSettledUp => 'All settled up';

  @override
  String get allSettledUpPeriod => 'All settled up.';

  @override
  String youAreOwedAmount(String amount) {
    return 'You are owed $amount';
  }

  @override
  String youOweAmount(String amount) {
    return 'You owe $amount';
  }

  @override
  String youOweName(String name) {
    return 'You owe $name';
  }

  @override
  String nameOwesYou(String name) {
    return '$name owes you';
  }

  @override
  String paidByAndDate(String name, String date) {
    return 'Paid by $name · $date';
  }

  @override
  String get balanceTitle => 'Balance';

  @override
  String get markSettled => 'Mark settled';

  @override
  String couldNotSettle(String error) {
    return 'Could not settle: $error';
  }

  @override
  String get titleFieldLabel => 'Title';

  @override
  String get amountLabel => 'Amount';

  @override
  String get paidByLabel => 'Paid by';

  @override
  String get splitEqual => 'Equal';

  @override
  String get splitShares => 'Shares';

  @override
  String get splitExact => 'Exact';

  @override
  String get splitBetweenLabel => 'Split between';

  @override
  String get fullyAssigned => 'Fully assigned';

  @override
  String remainingToAssign(String amount) {
    return 'Remaining to assign: $amount';
  }

  @override
  String get fillTitleAmountParticipant =>
      'Fill in a title, an amount, and at least one participant.';

  @override
  String get enterExactAmountForEveryone =>
      'Enter an exact amount for everyone selected.';

  @override
  String get exactAmountsMustAddUp => 'Exact amounts must add up to the total.';

  @override
  String get deleteExpenseTitle => 'Delete this expense?';

  @override
  String get deleteExpenseBody =>
      'This removes it from the balance for everyone. This can\'t be undone.';

  @override
  String get editTripTitle => 'Edit trip';

  @override
  String uploadUpToNPhotos(int max) {
    return 'Upload up to $max photos.';
  }

  @override
  String get titleIsRequired => 'Title is required';

  @override
  String get locationIsRequired => 'Location is required';

  @override
  String get dateIsRequired => 'Date is required';

  @override
  String get meetingTimeLabel => 'Meeting time';

  @override
  String get meetingTimeIsRequired => 'Meeting time is required';

  @override
  String get endDateOptionalLabel => 'End date (optional, multi-day trips)';

  @override
  String get meetingPointOptionalLabel => 'Meeting point (optional)';

  @override
  String get descriptionOptionalLabel => 'Description (optional)';

  @override
  String get requiredLevelLabel => 'Required level';

  @override
  String get openToAll => 'Open to all';

  @override
  String get minDepthMLabel => 'Min depth (m)';

  @override
  String get maxDepthMLabel => 'Max depth (m)';

  @override
  String get minDivesLabel => 'Min dives';

  @override
  String get maxDivesLabel => 'Max dives';

  @override
  String onlyNPhotosAllowed(int max) {
    return 'Only $max photos allowed per trip';
  }

  @override
  String get selectADate => 'Select a date';

  @override
  String get selectATime => 'Select a time';

  @override
  String get enterBookingCodeTitle => 'Enter booking code';

  @override
  String get bookingCodeDialogBody =>
      'Booked a dive-center trip on their own site? Enter the code they gave you to join its Bubble here.';

  @override
  String get bookingCodeLabel => 'Booking code';

  @override
  String get bookingCodeHint => 'e.g. 8XK2NPQ4';

  @override
  String get managePhotos => 'Manage photos';

  @override
  String get editButtonLabel => 'Edit';

  @override
  String get peopleTabLabel => 'People';

  @override
  String get mediaTabLabel => 'Media';

  @override
  String get filesTabLabel => 'Files';

  @override
  String get linksTabLabel => 'Links';

  @override
  String get meetingPointSectionLabel => 'MEETING POINT';

  @override
  String get aboutThisDive => 'About this dive';

  @override
  String get levelSectionLabel => 'LEVEL';

  @override
  String get depthSectionLabel => 'DEPTH';

  @override
  String get divesSectionLabel => 'DIVES';

  @override
  String get durationSectionLabel => 'DURATION';

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
    return 'Up to $max m';
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
      other: '$n dives',
      one: '$n dive',
    );
    return '$_temp0';
  }

  @override
  String diveCountRangeDives(int min, int max) {
    return '$min–$max dives';
  }

  @override
  String diveCountUpToDives(int max) {
    return 'Up to $max dives';
  }

  @override
  String diveCountMinPlusDives(int min) {
    return '$min+ dives';
  }

  @override
  String durationDaysPlural(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days',
      one: '$days day',
    );
    return '$_temp0';
  }

  @override
  String get diveCenterLabel => 'Dive center';

  @override
  String get bookNowLabel => 'Book now';

  @override
  String bookNowWithPrice(String price, String currency) {
    return 'Book now — $price $currency';
  }

  @override
  String get iHaveABookingCode => 'I have a booking code';

  @override
  String get privateTripAskOrganizer =>
      'This is a private trip — ask the organizer for an invite code or link.';

  @override
  String get iHaveAnInviteCode => 'I have an invite code';

  @override
  String get inviteCodeSectionLabel => 'INVITE CODE';

  @override
  String get shareInviteTooltip => 'Share invite';

  @override
  String get shareInviteLink => 'Share invite link';

  @override
  String get copyInviteLink => 'Copy invite link';

  @override
  String get copyBookingCode => 'Copy booking code';

  @override
  String get unmute => 'Unmute';

  @override
  String get mute => 'Mute';

  @override
  String get tripCancelledSnackbar => 'Trip cancelled';

  @override
  String get diveInToBubble => 'Dive in to Bubble';

  @override
  String participantsJoinedPlural(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people joined',
      one: '$count person joined',
    );
    return '$_temp0';
  }

  @override
  String participantsJoinedOfMaxPlural(int count, int max) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people out of $max joined',
      one: '$count person out of $max joined',
    );
    return '$_temp0';
  }

  @override
  String get agencyLabel => 'Agency';

  @override
  String get websiteLabel => 'Website';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get emailLabel => 'Email';
}
