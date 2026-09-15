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
}
