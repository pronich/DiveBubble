import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_da.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_ru.dart';
import 'app_localizations_sv.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('da'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('ru'),
    Locale('sv'),
  ];

  /// The application's name, shown as the OS task-switcher/home-screen label. Not user-visible in-app UI — kept here mainly to prove the gen-l10n pipeline end to end before the real string-extraction pass (see the translations plan).
  ///
  /// In en, this message translates to:
  /// **'DiveBubble'**
  String get appTitle;

  /// Subtitle under the DiveBubble wordmark on the animated first-run intro screen.
  ///
  /// In en, this message translates to:
  /// **'Find dive trips, meet your buddies, and plan the logistics together.'**
  String get introSubtitle;

  /// Primary CTA button that opens the sign-in sheet — used on the intro screen and the guest Profile tab.
  ///
  /// In en, this message translates to:
  /// **'Dive in'**
  String get diveIn;

  /// Secondary button to skip an optional onboarding step (intro screen, certifications onboarding).
  ///
  /// In en, this message translates to:
  /// **'Skip for now'**
  String get skipForNow;

  /// Title of the sign-in bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// Validation error shown when the diver taps 'Send code' with an empty email field.
  ///
  /// In en, this message translates to:
  /// **'Enter your email'**
  String get enterYourEmail;

  /// Validation error shown when the diver taps 'Verify' with an empty code field.
  ///
  /// In en, this message translates to:
  /// **'Enter the code we sent you'**
  String get enterCodeSentToYou;

  /// Sign-in button.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get continueWithGoogle;

  /// Sign-in button, iOS only.
  ///
  /// In en, this message translates to:
  /// **'Continue with Apple'**
  String get continueWithApple;

  /// Sign-in button that reveals the email/OTP form.
  ///
  /// In en, this message translates to:
  /// **'Continue with email'**
  String get continueWithEmail;

  /// Prompt shown above the OTP code field, naming the address the code was sent to.
  ///
  /// In en, this message translates to:
  /// **'Enter the code we sent to {email}'**
  String enterCodeSentTo(String email);

  /// Button that submits the email OTP code.
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// Button that backs out of the OTP-code step to re-enter the email address.
  ///
  /// In en, this message translates to:
  /// **'Use a different email'**
  String get useADifferentEmail;

  /// Label of the email text field in the sign-in sheet.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Button that requests an email OTP code.
  ///
  /// In en, this message translates to:
  /// **'Send code'**
  String get sendCode;

  /// Button that backs out of the email form to the Google/Apple/email choice.
  ///
  /// In en, this message translates to:
  /// **'Use a different sign-in method'**
  String get useADifferentSignInMethod;

  /// Headline on the push-notification permission onboarding screen.
  ///
  /// In en, this message translates to:
  /// **'Stay in the loop'**
  String get stayInTheLoop;

  /// Body copy on the push-notification permission onboarding screen.
  ///
  /// In en, this message translates to:
  /// **'Get notified about new messages, trip changes, and who\'s joining your rides. You can turn this off anytime in Profile settings.'**
  String get pushPermissionBody;

  /// Generic 'Continue' button, e.g. on the push-permission onboarding screen.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// Button to decline an optional permission request during onboarding (push notifications).
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// Headline on the certifications onboarding screen.
  ///
  /// In en, this message translates to:
  /// **'Add your certifications'**
  String get addYourCertifications;

  /// Body copy on the certifications onboarding screen.
  ///
  /// In en, this message translates to:
  /// **'Your level shows other divers you\'re ready for a trip, and some trips require a minimum level to join. You can add or change this anytime from your profile.'**
  String get certificationsOnboardingBody;

  /// Label of the certification level dropdown.
  ///
  /// In en, this message translates to:
  /// **'Level'**
  String get level;

  /// Validation error shown when saving certifications without picking a level.
  ///
  /// In en, this message translates to:
  /// **'Please select a level'**
  String get pleaseSelectALevel;

  /// Placeholder hint text in the certification level dropdown.
  ///
  /// In en, this message translates to:
  /// **'Select level'**
  String get selectLevel;

  /// Label of the certification agency dropdown.
  ///
  /// In en, this message translates to:
  /// **'Agency (optional)'**
  String get agencyOptional;

  /// Placeholder value meaning no certification agency was chosen.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notSet;

  /// Label of the certification number text field.
  ///
  /// In en, this message translates to:
  /// **'Certification number (optional)'**
  String get certificationNumberOptional;

  /// Button that saves the certifications onboarding step.
  ///
  /// In en, this message translates to:
  /// **'Save and continue'**
  String get saveAndContinue;

  /// Generic inline error display, reused across many screens.
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String errorWithMessage(String error);

  /// Generic Cancel button/action, reused across confirmation dialogs.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Generic Delete action, reused for the message context-menu item and its confirmation dialog button.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Fallback sender name used when referring to the current user themselves (e.g. 'Replying to You').
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get you;

  /// Fallback display name for a participant with no profile name set.
  ///
  /// In en, this message translates to:
  /// **'Diver'**
  String get diver;

  /// Search field hint text on My Trips and Choose Bubble screens.
  ///
  /// In en, this message translates to:
  /// **'Search Bubbles'**
  String get searchBubbles;

  /// Shown when a Bubbles search query has no results.
  ///
  /// In en, this message translates to:
  /// **'No matches.'**
  String get noMatches;

  /// Tooltip on the share button in the photo/video attachment preview screens.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// Placeholder filename shown when a PDF attachment has no filename of its own.
  ///
  /// In en, this message translates to:
  /// **'Document.pdf'**
  String get documentFallbackName;

  /// Snackbar shown after copying a message's text.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copiedToClipboard;

  /// Title of the delete-message confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Delete this message?'**
  String get deleteThisMessageTitle;

  /// Body of the delete-message confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone — it will be removed for everyone in this Bubble.'**
  String get deleteThisMessageBody;

  /// Snackbar shown when deleting a message fails.
  ///
  /// In en, this message translates to:
  /// **'Could not delete message: {error}'**
  String couldNotDeleteMessage(String error);

  /// Snackbar shown when adding/removing a reaction fails.
  ///
  /// In en, this message translates to:
  /// **'Could not react: {error}'**
  String couldNotReact(String error);

  /// Message context-menu action.
  ///
  /// In en, this message translates to:
  /// **'Reply'**
  String get reply;

  /// Message context-menu action.
  ///
  /// In en, this message translates to:
  /// **'Copy text'**
  String get copyText;

  /// Message context-menu action that opens the report sheet.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get report;

  /// Snackbar shown when trying to add a photo while a PDF is already staged in the composer.
  ///
  /// In en, this message translates to:
  /// **'Remove the document first to add photos.'**
  String get removeDocumentFirst;

  /// Snackbar shown when trying to attach more than the per-message attachment limit.
  ///
  /// In en, this message translates to:
  /// **'Only {max} attachments allowed per message.'**
  String onlyNAttachmentsAllowed(int max);

  /// Snackbar shown when trying to add a PDF alongside other pending attachments.
  ///
  /// In en, this message translates to:
  /// **'A document can only be sent on its own.'**
  String get documentOnlyOnItsOwn;

  /// Snackbar shown when one or more picked attachments exceed the size cap.
  ///
  /// In en, this message translates to:
  /// **'Some files are too large.'**
  String get someFilesTooLarge;

  /// Snackbar shown when uploading/sending an attachment fails.
  ///
  /// In en, this message translates to:
  /// **'Could not send attachment: {error}'**
  String couldNotSendAttachment(String error);

  /// Empty state for a Bubble's chat with no messages yet.
  ///
  /// In en, this message translates to:
  /// **'No messages yet'**
  String get noMessagesYet;

  /// Banner shown above a disabled composer once the trip is cancelled.
  ///
  /// In en, this message translates to:
  /// **'This trip has been cancelled — the chat is read-only.'**
  String get tripCancelledReadOnly;

  /// Label above the composer's reply preview chip, naming who's being replied to.
  ///
  /// In en, this message translates to:
  /// **'Replying to {name}'**
  String replyingTo(String name);

  /// Composer hint text when attachments are staged (the text field becomes a caption).
  ///
  /// In en, this message translates to:
  /// **'Caption (optional)'**
  String get captionOptional;

  /// Composer hint text for a plain text message (no attachments staged).
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageHint;

  /// Shown in place of a deleted message's body, and as its reply-preview text.
  ///
  /// In en, this message translates to:
  /// **'Message deleted'**
  String get messageDeleted;

  /// Reply-preview text for a message with multiple attachments and no text body.
  ///
  /// In en, this message translates to:
  /// **'📎 {count} attachments'**
  String attachmentsCountLabel(int count);

  /// Reply-preview text for a message that's a single photo with no text body.
  ///
  /// In en, this message translates to:
  /// **'📷 Photo'**
  String get photoLabel;

  /// Reply-preview text for a message that's a single video with no text body.
  ///
  /// In en, this message translates to:
  /// **'🎬 Video'**
  String get videoLabel;

  /// Reply-preview text for a message that's a single PDF with no text body.
  ///
  /// In en, this message translates to:
  /// **'📄 PDF'**
  String get pdfLabel;

  /// Pill button that appears when new messages arrived below the current scroll position.
  ///
  /// In en, this message translates to:
  /// **'New messages'**
  String get newMessages;

  /// Suffix appended to a sender's name when they're a product observer (e.g. 'Nikolai | Product Observer').
  ///
  /// In en, this message translates to:
  /// **'Product Observer'**
  String get productObserver;

  /// Title of the report-message sheet.
  ///
  /// In en, this message translates to:
  /// **'Report message'**
  String get reportMessageTitle;

  /// Label of the free-text details field on the report-message sheet.
  ///
  /// In en, this message translates to:
  /// **'Details (optional)'**
  String get detailsOptional;

  /// Button that submits the report-message sheet.
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get sendReport;

  /// Snackbar shown after successfully reporting a message.
  ///
  /// In en, this message translates to:
  /// **'Report sent — thank you.'**
  String get reportSentThankYou;

  /// Snackbar shown when reporting a message fails.
  ///
  /// In en, this message translates to:
  /// **'Could not send report: {error}'**
  String couldNotSendReport(String error);

  /// Shown after feedback is submitted, both as a chip on the prompt and a snackbar.
  ///
  /// In en, this message translates to:
  /// **'Thank you!'**
  String get thankYou;

  /// Button on a trip-feedback prompt system message.
  ///
  /// In en, this message translates to:
  /// **'Give feedback'**
  String get giveFeedback;

  /// Star-rating question on the feedback sheet.
  ///
  /// In en, this message translates to:
  /// **'How useful was DiveBubble for this trip?'**
  String get howUsefulQuestion;

  /// Checklist question on the feedback sheet.
  ///
  /// In en, this message translates to:
  /// **'What did DiveBubble help you with?'**
  String get whatDidHelpQuestion;

  /// Free-text question on the feedback sheet.
  ///
  /// In en, this message translates to:
  /// **'What should we improve?'**
  String get whatShouldImproveQuestion;

  /// Hint text of the feedback sheet's free-text comment field.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get optionalHintText;

  /// Checkbox label on the feedback sheet.
  ///
  /// In en, this message translates to:
  /// **'Can we contact you about your feedback?'**
  String get canContactAboutFeedback;

  /// Button that submits the feedback sheet.
  ///
  /// In en, this message translates to:
  /// **'Submit feedback'**
  String get submitFeedback;

  /// Snackbar shown when submitting feedback fails.
  ///
  /// In en, this message translates to:
  /// **'Could not send feedback: {error}'**
  String couldNotSendFeedback(String error);

  /// Report-message reason choice label (the value sent to the backend stays the fixed English canonical string).
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get reportReasonSpam;

  /// Report-message reason choice label (the value sent to the backend stays the fixed English canonical string).
  ///
  /// In en, this message translates to:
  /// **'Harassment'**
  String get reportReasonHarassment;

  /// Report-message reason choice label (the value sent to the backend stays the fixed English canonical string).
  ///
  /// In en, this message translates to:
  /// **'Inappropriate content'**
  String get reportReasonInappropriateContent;

  /// Report-message reason choice label (the value sent to the backend stays the fixed English canonical string).
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reportReasonOther;

  /// Feedback 'what helped' checklist option label (the value sent to the backend stays the fixed English canonical string).
  ///
  /// In en, this message translates to:
  /// **'Trip information'**
  String get helpedWithTripInformation;

  /// Feedback 'what helped' checklist option label (the value sent to the backend stays the fixed English canonical string).
  ///
  /// In en, this message translates to:
  /// **'Chatting with participants'**
  String get helpedWithChattingWithParticipants;

  /// Feedback 'what helped' checklist option label (the value sent to the backend stays the fixed English canonical string).
  ///
  /// In en, this message translates to:
  /// **'Finding transport'**
  String get helpedWithFindingTransport;

  /// Feedback 'what helped' checklist option label (the value sent to the backend stays the fixed English canonical string).
  ///
  /// In en, this message translates to:
  /// **'Finding Buddy'**
  String get helpedWithFindingBuddy;

  /// Feedback 'what helped' checklist option label, exclusive with the others (the value sent to the backend stays the fixed English canonical string).
  ///
  /// In en, this message translates to:
  /// **'Nothing yet'**
  String get helpedWithNothingYet;

  /// Snackbar shown when sharing a photo attachment fails.
  ///
  /// In en, this message translates to:
  /// **'Could not share photo: {error}'**
  String couldNotSharePhoto(String error);

  /// Snackbar shown when sharing a video attachment fails.
  ///
  /// In en, this message translates to:
  /// **'Could not share video: {error}'**
  String couldNotShareVideo(String error);

  /// Shown in place of a video attachment that failed to load.
  ///
  /// In en, this message translates to:
  /// **'Could not load video'**
  String get couldNotLoadVideo;

  /// Shown when Bubble Info's Media tab fails to load.
  ///
  /// In en, this message translates to:
  /// **'Could not load media: {error}'**
  String couldNotLoadMedia(String error);

  /// Empty state for Bubble Info's Media tab.
  ///
  /// In en, this message translates to:
  /// **'No photos or videos shared yet'**
  String get noPhotosOrVideosSharedYet;

  /// Shown when Bubble Info's Files tab fails to load.
  ///
  /// In en, this message translates to:
  /// **'Could not load files: {error}'**
  String couldNotLoadFiles(String error);

  /// Empty state for Bubble Info's Files tab.
  ///
  /// In en, this message translates to:
  /// **'No files shared yet'**
  String get noFilesSharedYet;

  /// Shown when Bubble Info's Links tab fails to load.
  ///
  /// In en, this message translates to:
  /// **'Could not load links: {error}'**
  String couldNotLoadLinks(String error);

  /// Empty state for Bubble Info's Links tab.
  ///
  /// In en, this message translates to:
  /// **'No links shared yet'**
  String get noLinksSharedYet;

  /// Title of the Share-to-DiveBubble Bubble picker screen.
  ///
  /// In en, this message translates to:
  /// **'Share to a Bubble'**
  String get shareToABubble;

  /// Empty state on the Bubble picker when the diver has no joined trips.
  ///
  /// In en, this message translates to:
  /// **'No Bubbles yet'**
  String get noBubblesYet;

  /// Empty state subtitle on the Bubble picker.
  ///
  /// In en, this message translates to:
  /// **'Join a trip to get a Bubble you can share into.'**
  String get joinATripToShareInto;

  /// Bubbles bottom-nav tab label and My Trips screen title.
  ///
  /// In en, this message translates to:
  /// **'Bubbles'**
  String get bubblesTabTitle;

  /// Dive Log bottom-nav tab label.
  ///
  /// In en, this message translates to:
  /// **'Dive Log'**
  String get diveLogTabTitle;

  /// Profile bottom-nav tab label.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTabTitle;

  /// Empty-state title on My Trips when signed out.
  ///
  /// In en, this message translates to:
  /// **'Sign in to see your trips'**
  String get signInToSeeYourTrips;

  /// Empty-state subtitle on My Trips when signed out.
  ///
  /// In en, this message translates to:
  /// **'Log in to view the trips you\'ve joined and their group chats.'**
  String get logInToViewTripsBody;

  /// Empty-state title on My Trips when signed in with no trips yet.
  ///
  /// In en, this message translates to:
  /// **'Start your first Bubble'**
  String get startYourFirstBubble;

  /// Empty-state subtitle on My Trips when signed in with no trips yet.
  ///
  /// In en, this message translates to:
  /// **'Create a trip or join one with a code — chat, transport, and trip details all in one place.'**
  String get startYourFirstBubbleBody;

  /// Button on the My Trips header that opens trip creation.
  ///
  /// In en, this message translates to:
  /// **'Create trip'**
  String get createTrip;

  /// Button on the My Trips header that opens the join-by-code dialog.
  ///
  /// In en, this message translates to:
  /// **'Join trip'**
  String get joinTrip;

  /// Pill tab label inside a Bubble.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get chatTabLabel;

  /// Pill tab label inside a Bubble.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get transportTabLabel;

  /// Pill tab label inside a Bubble.
  ///
  /// In en, this message translates to:
  /// **'Buddy'**
  String get buddyTabLabel;

  /// Pill tab label inside a Bubble.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expensesTabLabel;

  /// Long-press menu action on a Bubbles-list row.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get archive;

  /// Long-press menu action on an archived Bubbles-list row.
  ///
  /// In en, this message translates to:
  /// **'Unarchive'**
  String get unarchive;

  /// Long-press menu action and confirmation-dialog button for cancelling a trip.
  ///
  /// In en, this message translates to:
  /// **'Cancel trip'**
  String get cancelTrip;

  /// Long-press menu action and confirmation-dialog button for leaving a trip.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get leave;

  /// Snackbar shown when archiving a trip fails.
  ///
  /// In en, this message translates to:
  /// **'Could not archive: {error}'**
  String couldNotArchive(String error);

  /// Snackbar shown when unarchiving a trip fails.
  ///
  /// In en, this message translates to:
  /// **'Could not unarchive: {error}'**
  String couldNotUnarchive(String error);

  /// Title of the leave-trip confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Leave this Bubble?'**
  String get leaveBubbleTitle;

  /// Body of the leave-trip confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'You\'ll lose your spot and can rejoin later if there\'s room.'**
  String get leaveBubbleBody;

  /// Snackbar shown when leaving a trip fails.
  ///
  /// In en, this message translates to:
  /// **'Could not leave: {error}'**
  String couldNotLeave(String error);

  /// Title of the cancel-trip confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Cancel this trip?'**
  String get cancelTripTitle;

  /// Body of the cancel-trip confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Every participant keeps the Bubble to see the chat history, but no one — including you — can send messages, join, or arrange transport anymore. This can\'t be undone.'**
  String get cancelTripBody;

  /// Dismiss button on the cancel-trip confirmation dialog.
  ///
  /// In en, this message translates to:
  /// **'Never mind'**
  String get neverMind;

  /// Snackbar shown when cancelling a trip fails.
  ///
  /// In en, this message translates to:
  /// **'Could not cancel: {error}'**
  String couldNotCancel(String error);

  /// Trip-row status pill.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get cancelledStatus;

  /// Trip-row status pill.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get pastStatus;

  /// Trip-row status pill.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get activeStatus;

  /// Title of the Archived Chats screen, also shown on its pinned/reveal row in My Trips.
  ///
  /// In en, this message translates to:
  /// **'Archived Chats'**
  String get archivedChats;

  /// Empty-state title on the Archived Chats screen.
  ///
  /// In en, this message translates to:
  /// **'No archived chats'**
  String get noArchivedChats;

  /// Empty-state subtitle on the Archived Chats screen.
  ///
  /// In en, this message translates to:
  /// **'Bubbles you archive show up here — swipe or unarchive to bring one back.'**
  String get archivedChatsEmptyBody;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'da',
    'de',
    'en',
    'es',
    'ru',
    'sv',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'da':
      return AppLocalizationsDa();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'ru':
      return AppLocalizationsRu();
    case 'sv':
      return AppLocalizationsSv();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
