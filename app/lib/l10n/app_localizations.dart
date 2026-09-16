import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_da.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
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
    Locale('fr'),
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

  /// Transport offer type label/choice-chip.
  ///
  /// In en, this message translates to:
  /// **'Offering a ride'**
  String get typeOfferRide;

  /// Transport offer type label/choice-chip.
  ///
  /// In en, this message translates to:
  /// **'Sharing a rental'**
  String get typeShareRental;

  /// Snackbar shown when the car you were viewing/in gets dissolved by its organizer.
  ///
  /// In en, this message translates to:
  /// **'This car was cancelled by the organizer.'**
  String get carCancelledByOrganizer;

  /// Empty-state title on the Transport tab of a cancelled trip.
  ///
  /// In en, this message translates to:
  /// **'No transport was arranged'**
  String get noTransportWasArranged;

  /// Empty-state title on the Transport tab with no offers yet.
  ///
  /// In en, this message translates to:
  /// **'Be the first to share transport'**
  String get beFirstToShareTransport;

  /// Empty-state subtitle on the Transport/Buddy tabs of a cancelled trip.
  ///
  /// In en, this message translates to:
  /// **'This trip has been cancelled.'**
  String get tripCancelledSimple;

  /// Empty-state subtitle on the Transport tab with no offers yet.
  ///
  /// In en, this message translates to:
  /// **'Offer a ride or share a rental so others can join you.'**
  String get offerRideOrShareRental;

  /// CTA button and add-offer sheet title on the Transport tab.
  ///
  /// In en, this message translates to:
  /// **'Add transport info'**
  String get addTransportInfo;

  /// Shown on a transport offer row when it specifies a seat count.
  ///
  /// In en, this message translates to:
  /// **'{joined} of {total} seats taken'**
  String seatsTakenLabel(int joined, int total);

  /// Status pill on a transport offer/buddy request row once the diver has joined it.
  ///
  /// In en, this message translates to:
  /// **'Joined'**
  String get joinedStatus;

  /// Status pill on a transport offer/buddy request row once it has no room left.
  ///
  /// In en, this message translates to:
  /// **'Full'**
  String get fullStatus;

  /// Fallback name and role label for a transport offer's creator.
  ///
  /// In en, this message translates to:
  /// **'Organizer'**
  String get organizerLabel;

  /// Role label for a transport offer's creator when it's the current user.
  ///
  /// In en, this message translates to:
  /// **'Organizer · You'**
  String get organizerYou;

  /// Heading above the list of divers who joined a transport offer.
  ///
  /// In en, this message translates to:
  /// **'Joined divers'**
  String get joinedDivers;

  /// Empty state under a transport offer's or buddy request's joined-divers list.
  ///
  /// In en, this message translates to:
  /// **'No one has joined yet'**
  String get noOneHasJoinedYet;

  /// Button an organizer uses to dissolve their own transport offer.
  ///
  /// In en, this message translates to:
  /// **'Cancel car offer'**
  String get cancelCarOffer;

  /// Button a joiner uses to leave a transport offer.
  ///
  /// In en, this message translates to:
  /// **'Leave car'**
  String get leaveCar;

  /// Short join button on a transport offer/buddy request tile and detail sheet.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get join;

  /// Label of the seat-count field when adding a transport offer.
  ///
  /// In en, this message translates to:
  /// **'Seats (optional)'**
  String get seatsOptional;

  /// Label of the free-text details field when adding a transport offer.
  ///
  /// In en, this message translates to:
  /// **'Details — time, pickup point (optional)'**
  String get detailsTimePickupOptional;

  /// Submit button when adding a transport offer.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Snackbar shown when the buddy group you were viewing/in gets dissolved by its organizer.
  ///
  /// In en, this message translates to:
  /// **'This buddy group was cancelled by the organizer.'**
  String get buddyGroupCancelledByOrganizer;

  /// Empty-state title on the Buddy tab of a cancelled trip.
  ///
  /// In en, this message translates to:
  /// **'No buddy requests were made'**
  String get noBuddyRequestsWereMade;

  /// Empty-state title on the Buddy tab with no requests yet.
  ///
  /// In en, this message translates to:
  /// **'Be the first to look for a buddy'**
  String get beFirstToLookForBuddy;

  /// Empty-state subtitle on the Buddy tab with no requests yet.
  ///
  /// In en, this message translates to:
  /// **'Request a buddy so others can join you for this dive.'**
  String get requestBuddySoOthersCanJoin;

  /// CTA button and add-request sheet title on the Buddy tab.
  ///
  /// In en, this message translates to:
  /// **'Request a buddy'**
  String get requestABuddy;

  /// Header text on the buddy-request detail sheet.
  ///
  /// In en, this message translates to:
  /// **'Buddy request'**
  String get buddyRequestTitle;

  /// Shown next to a buddy request creator's certification level.
  ///
  /// In en, this message translates to:
  /// **'{count} dives'**
  String divesCountLabel(int count);

  /// Role label for a buddy request's creator.
  ///
  /// In en, this message translates to:
  /// **'Creator'**
  String get creatorLabel;

  /// Role label for a buddy request's creator when it's the current user.
  ///
  /// In en, this message translates to:
  /// **'Creator · You'**
  String get creatorYou;

  /// Heading above the list of divers who joined a buddy request.
  ///
  /// In en, this message translates to:
  /// **'Group'**
  String get groupLabel;

  /// Button a creator uses to dissolve their own buddy request.
  ///
  /// In en, this message translates to:
  /// **'Cancel buddy request'**
  String get cancelBuddyRequest;

  /// Button a joiner uses to leave a buddy group.
  ///
  /// In en, this message translates to:
  /// **'Leave buddy group'**
  String get leaveBuddyGroup;

  /// Body text on the add-buddy-request confirmation sheet.
  ///
  /// In en, this message translates to:
  /// **'Other divers on this trip will see your request and can join you.'**
  String get otherDiversWillSeeRequest;

  /// Submit button when creating a buddy request.
  ///
  /// In en, this message translates to:
  /// **'Request'**
  String get request;

  /// About page title and Profile settings row label.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// App version shown at the bottom of the About page.
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String versionLabel(String version);

  /// Gear Locker page title, and the summary card's own label on Profile.
  ///
  /// In en, this message translates to:
  /// **'Gear locker'**
  String get gearLockerTitle;

  /// Gear summary card subtitle.
  ///
  /// In en, this message translates to:
  /// **'{owned}/{total} in Locker'**
  String ownedOfTotalInLocker(int owned, int total);

  /// Storage settings confirmation dialog title.
  ///
  /// In en, this message translates to:
  /// **'Clear cache?'**
  String get clearCacheTitle;

  /// Storage settings confirmation dialog body.
  ///
  /// In en, this message translates to:
  /// **'This removes downloaded photos and files from this device. Nothing is deleted from the trip chats themselves — files are simply re-downloaded next time you open them.'**
  String get clearCacheBody;

  /// Confirm button on the clear-cache dialog.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Snackbar shown after successfully clearing the attachment cache.
  ///
  /// In en, this message translates to:
  /// **'Cache cleared.'**
  String get cacheCleared;

  /// Snackbar shown when clearing the attachment cache fails.
  ///
  /// In en, this message translates to:
  /// **'Could not clear cache: {error}'**
  String couldNotClearCache(String error);

  /// Storage settings page title and Profile settings row label.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get storageTitle;

  /// Storage settings list tile title.
  ///
  /// In en, this message translates to:
  /// **'Clear cache'**
  String get clearCacheRow;

  /// Storage settings list tile subtitle.
  ///
  /// In en, this message translates to:
  /// **'Removes downloaded chat photos and files from this device'**
  String get clearCacheSubtitle;

  /// Snackbar shown when unblocking a user fails.
  ///
  /// In en, this message translates to:
  /// **'Could not unblock: {error}'**
  String couldNotUnblock(String error);

  /// Blocked Users page title and Profile settings row label.
  ///
  /// In en, this message translates to:
  /// **'Blocked users'**
  String get blockedUsersTitle;

  /// Empty state on the Blocked Users page.
  ///
  /// In en, this message translates to:
  /// **'No blocked users.'**
  String get noBlockedUsers;

  /// Button next to a blocked user's name.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblock;

  /// Option in the contact-support picker sheet.
  ///
  /// In en, this message translates to:
  /// **'Copy email address'**
  String get copyEmailAddress;

  /// Snackbar after copying the support email address.
  ///
  /// In en, this message translates to:
  /// **'Email address copied'**
  String get emailAddressCopied;

  /// Legal page title and Profile settings row label.
  ///
  /// In en, this message translates to:
  /// **'Legal'**
  String get legalTitle;

  /// Legal page list item.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get termsOfService;

  /// Legal page list item.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Legal page list item.
  ///
  /// In en, this message translates to:
  /// **'Contact support'**
  String get contactSupport;

  /// CTA on the empty Dive Log deck teaser and the Dive Log list's empty state.
  ///
  /// In en, this message translates to:
  /// **'Add a dive'**
  String get addADive;

  /// Title of the sheet for changing certification level.
  ///
  /// In en, this message translates to:
  /// **'Update level'**
  String get updateLevelTitle;

  /// Generic Save button, e.g. on the update-level sheet.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Empty-state tile label and add-specialty sheet title.
  ///
  /// In en, this message translates to:
  /// **'Add speciality'**
  String get addSpeciality;

  /// Free-text field label shown when adding an 'Other' specialty.
  ///
  /// In en, this message translates to:
  /// **'Speciality name'**
  String get specialityName;

  /// Notifications settings page title and Profile settings row label.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// Switch label on the notifications settings page.
  ///
  /// In en, this message translates to:
  /// **'Push notifications'**
  String get pushNotificationsLabel;

  /// Subtitle shown when push was denied at the OS level.
  ///
  /// In en, this message translates to:
  /// **'Disabled in system settings — enable DiveBubble notifications there first'**
  String get pushDisabledInSystemSettings;

  /// Subtitle shown when push permission hasn't been decided yet.
  ///
  /// In en, this message translates to:
  /// **'Tap to enable notifications'**
  String get tapToEnableNotifications;

  /// Default subtitle on the push-notifications switch.
  ///
  /// In en, this message translates to:
  /// **'New messages, trip updates and more'**
  String get newMessagesTripUpdatesEtc;

  /// Badge on a verified certification level or specialty card.
  ///
  /// In en, this message translates to:
  /// **'Verified'**
  String get verified;

  /// Empty-state tile label, and the Level stat's own fallback CTA on Profile Overview.
  ///
  /// In en, this message translates to:
  /// **'Add certificate'**
  String get addCertificate;

  /// Confirmation dialog title on the diver ID card sheet.
  ///
  /// In en, this message translates to:
  /// **'Block this user?'**
  String get blockThisUserTitle;

  /// Confirmation dialog body on the diver ID card sheet.
  ///
  /// In en, this message translates to:
  /// **'You won\'t see their messages in shared trip chats anymore. You can undo this from Profile → Blocked users.'**
  String get blockUserBody;

  /// Destructive confirm button on the block-user dialog.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get block;

  /// Tooltip on the block icon button on the diver ID card sheet.
  ///
  /// In en, this message translates to:
  /// **'Block user'**
  String get blockUserTooltip;

  /// Snackbar shown after successfully blocking a user.
  ///
  /// In en, this message translates to:
  /// **'Blocked. Manage in Profile → Blocked users.'**
  String get blockedManageBody;

  /// Snackbar shown when blocking a user fails.
  ///
  /// In en, this message translates to:
  /// **'Could not block user: {error}'**
  String couldNotBlockUser(String error);

  /// Bio field label/section title, both on Edit Profile and Profile Overview.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bioLabel;

  /// Dive-count stat tile label on Profile Overview.
  ///
  /// In en, this message translates to:
  /// **'Dives'**
  String get divesLabel;

  /// Spoken-languages field label — profile info row, language picker page title, and edit-profile field.
  ///
  /// In en, this message translates to:
  /// **'Languages'**
  String get languagesLabel;

  /// Profile info row label.
  ///
  /// In en, this message translates to:
  /// **'Member since'**
  String get memberSinceLabel;

  /// Edit Profile page title and the button that opens it from Profile Overview.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfileTitle;

  /// Edit Profile field label.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayNameLabel;

  /// Edit Profile field helper text.
  ///
  /// In en, this message translates to:
  /// **'Shown to other divers instead of your real name'**
  String get displayNameHelper;

  /// Edit Profile validation error.
  ///
  /// In en, this message translates to:
  /// **'Please enter a display name'**
  String get pleaseEnterDisplayName;

  /// Location field/row label — Edit Profile field and Dive Log detail info row.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get locationLabel;

  /// Tooltip on the location auto-detect button on Edit Profile.
  ///
  /// In en, this message translates to:
  /// **'Use current location'**
  String get useCurrentLocationTooltip;

  /// Edit Profile field label.
  ///
  /// In en, this message translates to:
  /// **'Unlogged dives'**
  String get unloggedDivesLabel;

  /// Edit Profile field helper text.
  ///
  /// In en, this message translates to:
  /// **'Dives you haven\'t added to your Dive Log — shown together with it as your total'**
  String get unloggedDivesHelper;

  /// Edit Profile switch label.
  ///
  /// In en, this message translates to:
  /// **'All my dives are logged'**
  String get allDivesAreLogged;

  /// Placeholder shown on Edit Profile's language field when none are picked.
  ///
  /// In en, this message translates to:
  /// **'Select languages'**
  String get selectLanguages;

  /// Confirmation dialog title on Edit Profile.
  ///
  /// In en, this message translates to:
  /// **'Zero out unlogged dives?'**
  String get zeroOutUnloggedDivesTitle;

  /// Confirmation dialog body on Edit Profile.
  ///
  /// In en, this message translates to:
  /// **'This clears the number above to 0. Your Dive Log entries are untouched — this only affects the manually-entered count.'**
  String get zeroOutUnloggedDivesBody;

  /// Confirm button on the zero-out-unlogged-dives dialog.
  ///
  /// In en, this message translates to:
  /// **'Zero out'**
  String get zeroOut;

  /// Page title when editing an existing dive log entry.
  ///
  /// In en, this message translates to:
  /// **'Edit Dive'**
  String get editDiveTitle;

  /// Page title and submit button when adding a new dive log entry.
  ///
  /// In en, this message translates to:
  /// **'Add Dive'**
  String get addDiveTitle;

  /// Notice shown when editing an imported (read-only measurements) dive log entry.
  ///
  /// In en, this message translates to:
  /// **'This dive was imported from your dive computer — only the country, dive site, and notes can be edited.'**
  String get importedDiveLockedNotice;

  /// Dive log entry field label.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get dateLabel;

  /// Dive log entry field label.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get timeLabel;

  /// Dive log entry field label and detail-page stat label.
  ///
  /// In en, this message translates to:
  /// **'Max depth'**
  String get maxDepthLabel;

  /// Dive log detail-page stat label.
  ///
  /// In en, this message translates to:
  /// **'Avg depth'**
  String get avgDepthLabel;

  /// Dive log entry field label and detail-page stat label.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get durationLabel;

  /// Dive log entry field label (full word, unlike the detail page's shorter 'Min temp').
  ///
  /// In en, this message translates to:
  /// **'Min temperature'**
  String get minTemperatureLabel;

  /// Dive log detail-page stat label (shortened form).
  ///
  /// In en, this message translates to:
  /// **'Min temp'**
  String get minTempLabel;

  /// Dive log detail-page stat label.
  ///
  /// In en, this message translates to:
  /// **'Max temp'**
  String get maxTempLabel;

  /// Dive log entry field label.
  ///
  /// In en, this message translates to:
  /// **'Country'**
  String get countryLabel;

  /// Dive log entry field label.
  ///
  /// In en, this message translates to:
  /// **'Dive site'**
  String get diveSiteLabel;

  /// Dive log entry field label and detail-page section heading.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// Submit button when editing an existing dive log entry.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get saveChanges;

  /// Confirmation dialog title for deleting one dive log entry.
  ///
  /// In en, this message translates to:
  /// **'Delete this dive?'**
  String get deleteThisDiveTitle;

  /// Generic confirmation dialog body for an irreversible delete.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be undone.'**
  String get cantBeUndone;

  /// Gear Locker section header.
  ///
  /// In en, this message translates to:
  /// **'ESSENTIAL'**
  String get gearEssentialSection;

  /// Gear Locker section header.
  ///
  /// In en, this message translates to:
  /// **'ADDITIONAL'**
  String get gearAdditionalSection;

  /// Gear Locker add-item button and sheet title.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get addItem;

  /// Gear status pill.
  ///
  /// In en, this message translates to:
  /// **'Owned'**
  String get gearOwned;

  /// Gear status pill.
  ///
  /// In en, this message translates to:
  /// **'Missing'**
  String get gearMissing;

  /// Gear status pill.
  ///
  /// In en, this message translates to:
  /// **'Usually rent'**
  String get gearUsuallyRent;

  /// Add-gear-item sheet body copy.
  ///
  /// In en, this message translates to:
  /// **'For anything beyond the essentials — torch, action camera, buoy...'**
  String get addItemSheetBody;

  /// Add-gear-item sheet field label.
  ///
  /// In en, this message translates to:
  /// **'Item name'**
  String get itemNameLabel;

  /// Essential gear item display label (matched by a stable English key server-side, safe to translate).
  ///
  /// In en, this message translates to:
  /// **'Boots'**
  String get gearItemBoots;

  /// Essential gear item display label.
  ///
  /// In en, this message translates to:
  /// **'Fins'**
  String get gearItemFins;

  /// Essential gear item display label — a universal dive-industry acronym, kept as-is.
  ///
  /// In en, this message translates to:
  /// **'BCD'**
  String get gearItemBcd;

  /// Essential gear item display label.
  ///
  /// In en, this message translates to:
  /// **'Wetsuit shorty 5mm'**
  String get gearItemWetsuitShorty5mm;

  /// Essential gear item display label.
  ///
  /// In en, this message translates to:
  /// **'Wetsuit 5mm'**
  String get gearItemWetsuit5mm;

  /// Essential gear item display label.
  ///
  /// In en, this message translates to:
  /// **'Wetsuit 7mm'**
  String get gearItemWetsuit7mm;

  /// Essential gear item display label.
  ///
  /// In en, this message translates to:
  /// **'Wetsuit 9mm'**
  String get gearItemWetsuit9mm;

  /// Essential gear item display label.
  ///
  /// In en, this message translates to:
  /// **'Semidry suit'**
  String get gearItemSemidrySuit;

  /// Essential gear item display label.
  ///
  /// In en, this message translates to:
  /// **'Dry suit'**
  String get gearItemDrySuit;

  /// Essential gear item display label.
  ///
  /// In en, this message translates to:
  /// **'Helmet'**
  String get gearItemHelmet;

  /// Essential gear item display label.
  ///
  /// In en, this message translates to:
  /// **'Gloves'**
  String get gearItemGloves;

  /// Essential gear item display label.
  ///
  /// In en, this message translates to:
  /// **'Regulator'**
  String get gearItemRegulator;

  /// Essential gear item display label.
  ///
  /// In en, this message translates to:
  /// **'Computer'**
  String get gearItemComputer;

  /// Essential gear item display label.
  ///
  /// In en, this message translates to:
  /// **'Mask'**
  String get gearItemMask;

  /// Tooltip and sheet title for sharing a dive log entry into a Bubble chat.
  ///
  /// In en, this message translates to:
  /// **'Share to Bubble'**
  String get shareToBubble;

  /// Dive log detail info row label.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get sourceLabel;

  /// Dive log detail 'Source' row value for an imported entry.
  ///
  /// In en, this message translates to:
  /// **'Imported'**
  String get importedValue;

  /// Dive log detail 'Source' row value for a manually-entered entry.
  ///
  /// In en, this message translates to:
  /// **'Manual'**
  String get manualValue;

  /// First line of the dive-log-entry text shared into a Bubble chat.
  ///
  /// In en, this message translates to:
  /// **'Dive on {date}'**
  String diveOnDate(String date);

  /// Generic 'Label: value' line, used to compose the shared dive-log-entry text.
  ///
  /// In en, this message translates to:
  /// **'{label}: {value}'**
  String labelColonValue(String label, String value);

  /// Snackbar shown after sharing a dive log entry into a Bubble chat.
  ///
  /// In en, this message translates to:
  /// **'Shared to Bubble'**
  String get sharedToBubble;

  /// Snackbar shown when sharing a dive log entry fails.
  ///
  /// In en, this message translates to:
  /// **'Could not share: {error}'**
  String couldNotShare(String error);

  /// Empty state on the share-to-Bubble sheet.
  ///
  /// In en, this message translates to:
  /// **'You haven\'t joined any Bubbles yet.'**
  String get haventJoinedAnyBubblesYet;

  /// AppBar title while multi-selecting dive log entries.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCountLabel(int count);

  /// Empty state title on the Dive Log list.
  ///
  /// In en, this message translates to:
  /// **'No dives logged yet'**
  String get noDivesLoggedYet;

  /// Empty state subtitle on the Dive Log list.
  ///
  /// In en, this message translates to:
  /// **'Add a dive by hand, or import a dive log file.'**
  String get addDiveOrImportBody;

  /// Confirmation dialog title for bulk-deleting selected dive log entries.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Delete {count} dive?} other{Delete {count} dives?}}'**
  String deleteDivesConfirmTitle(int count);

  /// Snackbar shown when a bulk dive-log delete partially fails.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Could not delete {count} dive: {error}} other{Could not delete {count} dives: {error}}}'**
  String couldNotDeleteDivesError(int count, String error);

  /// Snackbar shown when a single dive-log swipe-delete fails.
  ///
  /// In en, this message translates to:
  /// **'Could not delete: {error}'**
  String couldNotDeleteWithError(String error);

  /// Add-dive choice sheet option.
  ///
  /// In en, this message translates to:
  /// **'Add a dive manually'**
  String get addADiveManually;

  /// Add-dive choice sheet option.
  ///
  /// In en, this message translates to:
  /// **'Import a dive log file'**
  String get importADiveLogFile;

  /// Add-dive choice sheet option subtitle.
  ///
  /// In en, this message translates to:
  /// **'UDDF, CSV, or a Diving Log 6 export'**
  String get importFormatsSubtitle;

  /// Add-dive choice sheet option and info dialog title.
  ///
  /// In en, this message translates to:
  /// **'CSV column format'**
  String get csvColumnFormatTitle;

  /// CSV import format info dialog body — the column names themselves are literal, required CSV headers and stay in English in every language.
  ///
  /// In en, this message translates to:
  /// **'First row must be a header with these column names (any order, only \"date\" is required):\n\ndate (YYYY-MM-DD)\ntime (HH:MM)\ncountry\nsite\nmax_depth_m\navg_depth_m\nduration_min\nmin_temp_c\nnotes'**
  String get csvColumnFormatBody;

  /// Dismiss button on the CSV format info dialog.
  ///
  /// In en, this message translates to:
  /// **'Got it'**
  String get gotIt;

  /// Snackbar after importing a dive log file with nothing skipped.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} dive imported} other{{count} dives imported}}'**
  String diveImportedSimple(int count);

  /// Snackbar after importing a dive log file where some entries were already logged.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} new dive imported, {skipped} already logged} other{{count} new dives imported, {skipped} already logged}}'**
  String diveImportedWithSkipped(int count, int skipped);

  /// Snackbar shown when importing a dive log file fails.
  ///
  /// In en, this message translates to:
  /// **'Could not import: {error}'**
  String couldNotImport(String error);

  /// Fallback error text when no specific message is available.
  ///
  /// In en, this message translates to:
  /// **'unknown error'**
  String get unknownError;

  /// Snackbar shown after logging the first dive log entry.
  ///
  /// In en, this message translates to:
  /// **'If some of these were already counted in your profile, update it in Edit Profile.'**
  String get updateUnloggedCountPromptBody;

  /// SnackBarAction label pointing to Edit Profile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfileAction;

  /// Dive profile chart section label.
  ///
  /// In en, this message translates to:
  /// **'Depth'**
  String get depthLabel;

  /// Dive profile chart section label.
  ///
  /// In en, this message translates to:
  /// **'Temperature'**
  String get temperatureLabel;

  /// Dive profile chart hint shown before the diver touches it.
  ///
  /// In en, this message translates to:
  /// **'Drag along the chart to inspect a point'**
  String get dragToInspectHint;

  /// Confirm button on the language picker page.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Search field hint on the spoken-languages picker page.
  ///
  /// In en, this message translates to:
  /// **'Search languages'**
  String get searchLanguages;

  /// App-language settings page title and its Profile settings row label.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSettingsTitle;

  /// Placeholder name shown on the signed-out Profile tab.
  ///
  /// In en, this message translates to:
  /// **'Guest'**
  String get guest;

  /// Profile section heading.
  ///
  /// In en, this message translates to:
  /// **'Certifications'**
  String get certificationsSectionTitle;

  /// Button that opens the update-level sheet from Profile.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// Profile section heading.
  ///
  /// In en, this message translates to:
  /// **'Specialties'**
  String get specialtiesSectionTitle;

  /// Profile section heading.
  ///
  /// In en, this message translates to:
  /// **'Gear'**
  String get gearSectionTitle;

  /// Fallback snackbar text when uploading an avatar/certification/specialty photo fails without a specific message.
  ///
  /// In en, this message translates to:
  /// **'Could not upload photo'**
  String get couldNotUploadPhoto;

  /// Fallback snackbar text when removing the avatar fails without a specific message.
  ///
  /// In en, this message translates to:
  /// **'Could not remove photo'**
  String get couldNotRemovePhoto;

  /// Avatar options sheet action.
  ///
  /// In en, this message translates to:
  /// **'Change photo'**
  String get changePhoto;

  /// Avatar options sheet action.
  ///
  /// In en, this message translates to:
  /// **'Remove photo'**
  String get removePhoto;

  /// Sign-out row label on Profile.
  ///
  /// In en, this message translates to:
  /// **'Dive out'**
  String get diveOut;

  /// Delete-account confirmation dialog title.
  ///
  /// In en, this message translates to:
  /// **'Delete account?'**
  String get deleteAccountTitle;

  /// Delete-account confirmation dialog body.
  ///
  /// In en, this message translates to:
  /// **'This permanently anonymizes your account and cancels any trips you organize. This can\'t be undone.'**
  String get deleteAccountBody;

  /// Snackbar shown when account deletion fails.
  ///
  /// In en, this message translates to:
  /// **'Could not delete account: {error}'**
  String couldNotDeleteAccount(String error);

  /// Delete-account row label on Profile.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccountRow;

  /// Empty-state title on the Expenses tab.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet'**
  String get noExpensesYet;

  /// Empty-state subtitle on the Expenses tab with no expenses yet.
  ///
  /// In en, this message translates to:
  /// **'Log a shared cost so everyone knows what they owe.'**
  String get logSharedCostBody;

  /// Empty-state CTA button on the Expenses tab.
  ///
  /// In en, this message translates to:
  /// **'Add expense'**
  String get addExpenseCta;

  /// Add-expense page title and its submit button.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get addExpenseTitle;

  /// Edit-expense page title.
  ///
  /// In en, this message translates to:
  /// **'Edit Expense'**
  String get editExpenseTitle;

  /// Balance card label when the diver's net position is zero.
  ///
  /// In en, this message translates to:
  /// **'All settled up'**
  String get allSettledUp;

  /// Empty state inside the balance detail sheet once nothing is left to settle.
  ///
  /// In en, this message translates to:
  /// **'All settled up.'**
  String get allSettledUpPeriod;

  /// Balance card label when the trip owes the diver money.
  ///
  /// In en, this message translates to:
  /// **'You are owed {amount}'**
  String youAreOwedAmount(String amount);

  /// Balance card label when the diver owes the trip money.
  ///
  /// In en, this message translates to:
  /// **'You owe {amount}'**
  String youOweAmount(String amount);

  /// Balance detail sheet settlement row, when the diver is the one who owes.
  ///
  /// In en, this message translates to:
  /// **'You owe {name}'**
  String youOweName(String name);

  /// Balance detail sheet settlement row, when the other person owes the diver.
  ///
  /// In en, this message translates to:
  /// **'{name} owes you'**
  String nameOwesYou(String name);

  /// Expense row subtitle.
  ///
  /// In en, this message translates to:
  /// **'Paid by {name} · {date}'**
  String paidByAndDate(String name, String date);

  /// Balance detail sheet title.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balanceTitle;

  /// Button that records a suggested transfer as paid.
  ///
  /// In en, this message translates to:
  /// **'Mark settled'**
  String get markSettled;

  /// Snackbar shown when marking a settlement fails.
  ///
  /// In en, this message translates to:
  /// **'Could not settle: {error}'**
  String couldNotSettle(String error);

  /// Expense title field label.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get titleFieldLabel;

  /// Expense amount field label.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// Expense payer dropdown label.
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get paidByLabel;

  /// Expense split-type segmented button option (canonical backend value 'equal' is unaffected).
  ///
  /// In en, this message translates to:
  /// **'Equal'**
  String get splitEqual;

  /// Expense split-type segmented button option (canonical backend value 'shares' is unaffected).
  ///
  /// In en, this message translates to:
  /// **'Shares'**
  String get splitShares;

  /// Expense split-type segmented button option (canonical backend value 'exact' is unaffected).
  ///
  /// In en, this message translates to:
  /// **'Exact'**
  String get splitExact;

  /// Section label above the participant checklist on the add/edit expense page.
  ///
  /// In en, this message translates to:
  /// **'Split between'**
  String get splitBetweenLabel;

  /// Shown when an exact split's per-person amounts add up to the total.
  ///
  /// In en, this message translates to:
  /// **'Fully assigned'**
  String get fullyAssigned;

  /// Shown when an exact split's per-person amounts don't yet add up to the total.
  ///
  /// In en, this message translates to:
  /// **'Remaining to assign: {amount}'**
  String remainingToAssign(String amount);

  /// Validation error when saving an expense with missing required fields.
  ///
  /// In en, this message translates to:
  /// **'Fill in a title, an amount, and at least one participant.'**
  String get fillTitleAmountParticipant;

  /// Validation error for an incomplete exact split.
  ///
  /// In en, this message translates to:
  /// **'Enter an exact amount for everyone selected.'**
  String get enterExactAmountForEveryone;

  /// Validation error when an exact split's amounts don't sum to the expense total.
  ///
  /// In en, this message translates to:
  /// **'Exact amounts must add up to the total.'**
  String get exactAmountsMustAddUp;

  /// Delete-expense confirmation dialog title.
  ///
  /// In en, this message translates to:
  /// **'Delete this expense?'**
  String get deleteExpenseTitle;

  /// Delete-expense confirmation dialog body.
  ///
  /// In en, this message translates to:
  /// **'This removes it from the balance for everyone. This can\'t be undone.'**
  String get deleteExpenseBody;

  /// Create/Edit Trip page title when editing an existing trip.
  ///
  /// In en, this message translates to:
  /// **'Edit trip'**
  String get editTripTitle;

  /// Hint above the photo grid on trip creation.
  ///
  /// In en, this message translates to:
  /// **'Upload up to {max} photos.'**
  String uploadUpToNPhotos(int max);

  /// Trip creation validation error.
  ///
  /// In en, this message translates to:
  /// **'Title is required'**
  String get titleIsRequired;

  /// Trip creation validation error.
  ///
  /// In en, this message translates to:
  /// **'Location is required'**
  String get locationIsRequired;

  /// Trip creation validation error.
  ///
  /// In en, this message translates to:
  /// **'Date is required'**
  String get dateIsRequired;

  /// Trip creation field label.
  ///
  /// In en, this message translates to:
  /// **'Meeting time'**
  String get meetingTimeLabel;

  /// Trip creation validation error.
  ///
  /// In en, this message translates to:
  /// **'Meeting time is required'**
  String get meetingTimeIsRequired;

  /// Trip creation field label.
  ///
  /// In en, this message translates to:
  /// **'End date (optional, multi-day trips)'**
  String get endDateOptionalLabel;

  /// Trip creation field label.
  ///
  /// In en, this message translates to:
  /// **'Meeting point (optional)'**
  String get meetingPointOptionalLabel;

  /// Trip creation field label.
  ///
  /// In en, this message translates to:
  /// **'Description (optional)'**
  String get descriptionOptionalLabel;

  /// Trip creation field label.
  ///
  /// In en, this message translates to:
  /// **'Required level'**
  String get requiredLevelLabel;

  /// Trip creation's 'no minimum certification level' option.
  ///
  /// In en, this message translates to:
  /// **'Open to all'**
  String get openToAll;

  /// Trip creation field label.
  ///
  /// In en, this message translates to:
  /// **'Min depth (m)'**
  String get minDepthMLabel;

  /// Trip creation field label.
  ///
  /// In en, this message translates to:
  /// **'Max depth (m)'**
  String get maxDepthMLabel;

  /// Trip creation field label.
  ///
  /// In en, this message translates to:
  /// **'Min dives'**
  String get minDivesLabel;

  /// Trip creation field label.
  ///
  /// In en, this message translates to:
  /// **'Max dives'**
  String get maxDivesLabel;

  /// Snackbar shown when picking more trip photos than the per-trip limit.
  ///
  /// In en, this message translates to:
  /// **'Only {max} photos allowed per trip'**
  String onlyNPhotosAllowed(int max);

  /// Placeholder on an unset date field.
  ///
  /// In en, this message translates to:
  /// **'Select a date'**
  String get selectADate;

  /// Placeholder on an unset time field.
  ///
  /// In en, this message translates to:
  /// **'Select a time'**
  String get selectATime;

  /// Join-by-code dialog title.
  ///
  /// In en, this message translates to:
  /// **'Enter booking code'**
  String get enterBookingCodeTitle;

  /// Join-by-code dialog explanatory body.
  ///
  /// In en, this message translates to:
  /// **'Booked a dive-center trip on their own site? Enter the code they gave you to join its Bubble here.'**
  String get bookingCodeDialogBody;

  /// Join-by-code dialog field label.
  ///
  /// In en, this message translates to:
  /// **'Booking code'**
  String get bookingCodeLabel;

  /// Join-by-code dialog field hint text — kept as a Latin-alphanumeric example code in every locale, since real booking codes are generated in that same format regardless of app language.
  ///
  /// In en, this message translates to:
  /// **'e.g. 8XK2NPQ4'**
  String get bookingCodeHint;

  /// Photo hero pill and Manage Photos page title.
  ///
  /// In en, this message translates to:
  /// **'Manage photos'**
  String get managePhotos;

  /// Photo hero pill that opens Edit Trip, organizer-only.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get editButtonLabel;

  /// Bubble Info tab label.
  ///
  /// In en, this message translates to:
  /// **'People'**
  String get peopleTabLabel;

  /// Bubble Info tab label.
  ///
  /// In en, this message translates to:
  /// **'Media'**
  String get mediaTabLabel;

  /// Bubble Info tab label.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get filesTabLabel;

  /// Bubble Info tab label.
  ///
  /// In en, this message translates to:
  /// **'Links'**
  String get linksTabLabel;

  /// All-caps section label on the trip info block.
  ///
  /// In en, this message translates to:
  /// **'MEETING POINT'**
  String get meetingPointSectionLabel;

  /// Trip description section heading.
  ///
  /// In en, this message translates to:
  /// **'About this dive'**
  String get aboutThisDive;

  /// All-caps info-tile label on the trip info grid.
  ///
  /// In en, this message translates to:
  /// **'LEVEL'**
  String get levelSectionLabel;

  /// All-caps info-tile label on the trip info grid.
  ///
  /// In en, this message translates to:
  /// **'DEPTH'**
  String get depthSectionLabel;

  /// All-caps info-tile label on the trip info grid.
  ///
  /// In en, this message translates to:
  /// **'DIVES'**
  String get divesSectionLabel;

  /// All-caps info-tile label on the trip info grid.
  ///
  /// In en, this message translates to:
  /// **'DURATION'**
  String get durationSectionLabel;

  /// Trip depth info tile when min and max depth match.
  ///
  /// In en, this message translates to:
  /// **'{value} m'**
  String depthExactMeters(int value);

  /// Trip depth info tile for a min/max range.
  ///
  /// In en, this message translates to:
  /// **'{min}–{max} m'**
  String depthRangeMeters(int min, int max);

  /// Trip depth info tile when only a max depth is set.
  ///
  /// In en, this message translates to:
  /// **'Up to {max} m'**
  String depthUpToMeters(int max);

  /// Trip depth info tile when only a min depth is set.
  ///
  /// In en, this message translates to:
  /// **'{min}+ m'**
  String depthMinPlusMeters(int min);

  /// Trip dive-count info tile when min and max dive count match.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{{n} dive} other{{n} dives}}'**
  String diveCountExactPlural(int n);

  /// Trip dive-count info tile for a min/max range.
  ///
  /// In en, this message translates to:
  /// **'{min}–{max} dives'**
  String diveCountRangeDives(int min, int max);

  /// Trip dive-count info tile when only a max is set.
  ///
  /// In en, this message translates to:
  /// **'Up to {max} dives'**
  String diveCountUpToDives(int max);

  /// Trip dive-count info tile when only a min is set.
  ///
  /// In en, this message translates to:
  /// **'{min}+ dives'**
  String diveCountMinPlusDives(int min);

  /// Trip duration info tile.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, one{{days} day} other{{days} days}}'**
  String durationDaysPlural(int days);

  /// Role label under a dive center's name — trip organizer card and dive center detail card.
  ///
  /// In en, this message translates to:
  /// **'Dive center'**
  String get diveCenterLabel;

  /// Button that opens a business trip's external booking URL, no price shown.
  ///
  /// In en, this message translates to:
  /// **'Book now'**
  String get bookNowLabel;

  /// Button that opens a business trip's external booking URL, with its price.
  ///
  /// In en, this message translates to:
  /// **'Book now — {price} {currency}'**
  String bookNowWithPrice(String price, String currency);

  /// Button that opens the join-by-code dialog from a business trip.
  ///
  /// In en, this message translates to:
  /// **'I have a booking code'**
  String get iHaveABookingCode;

  /// Explanatory text on a private trip a diver hasn't joined.
  ///
  /// In en, this message translates to:
  /// **'This is a private trip — ask the organizer for an invite code or link.'**
  String get privateTripAskOrganizer;

  /// Button that opens the join-by-code dialog from a private trip.
  ///
  /// In en, this message translates to:
  /// **'I have an invite code'**
  String get iHaveAnInviteCode;

  /// All-caps label above the organizer-only booking code.
  ///
  /// In en, this message translates to:
  /// **'INVITE CODE'**
  String get inviteCodeSectionLabel;

  /// Tooltip on the share-icon button next to the booking code.
  ///
  /// In en, this message translates to:
  /// **'Share invite'**
  String get shareInviteTooltip;

  /// Booking-code actions sheet option.
  ///
  /// In en, this message translates to:
  /// **'Share invite link'**
  String get shareInviteLink;

  /// Booking-code actions sheet option.
  ///
  /// In en, this message translates to:
  /// **'Copy invite link'**
  String get copyInviteLink;

  /// Booking-code actions sheet option.
  ///
  /// In en, this message translates to:
  /// **'Copy booking code'**
  String get copyBookingCode;

  /// Action pill on Bubble Info, when the Bubble is currently muted.
  ///
  /// In en, this message translates to:
  /// **'Unmute'**
  String get unmute;

  /// Action pill on Bubble Info, when the Bubble is currently unmuted.
  ///
  /// In en, this message translates to:
  /// **'Mute'**
  String get mute;

  /// Snackbar shown right after an organizer cancels their trip.
  ///
  /// In en, this message translates to:
  /// **'Trip cancelled'**
  String get tripCancelledSnackbar;

  /// Button on a joined trip's page that opens its Bubble chat.
  ///
  /// In en, this message translates to:
  /// **'Dive in to Bubble'**
  String get diveInToBubble;

  /// Participant count under the organizer card, trip has no seat cap.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} person joined} other{{count} people joined}}'**
  String participantsJoinedPlural(int count);

  /// Participant count under the organizer card, trip has a seat cap.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} person out of {max} joined} other{{count} people out of {max} joined}}'**
  String participantsJoinedOfMaxPlural(int count, int max);

  /// Dive center detail card info row label.
  ///
  /// In en, this message translates to:
  /// **'Agency'**
  String get agencyLabel;

  /// Dive center detail card info row label.
  ///
  /// In en, this message translates to:
  /// **'Website'**
  String get websiteLabel;

  /// Dive center detail card info row label.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// Dive center detail card info row label.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// Language picker's 'follow the device' option, naming which language that currently resolves to.
  ///
  /// In en, this message translates to:
  /// **'{name} (System default)'**
  String systemDefaultWithLanguage(String name);

  /// Onboarding language-selection step heading.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get chooseYourLanguageTitle;

  /// Onboarding language-selection step body copy.
  ///
  /// In en, this message translates to:
  /// **'You can always change this later in Profile settings.'**
  String get chooseYourLanguageBody;
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
    'fr',
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
    case 'fr':
      return AppLocalizationsFr();
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
