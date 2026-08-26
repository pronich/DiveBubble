import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'data/repositories/auth_repository.dart';
import 'data/repositories/buddy_repository.dart';
import 'data/repositories/chat_repository.dart';
import 'data/repositories/dive_center_repository.dart';
import 'data/repositories/dive_log_repository.dart';
import 'data/repositories/expense_repository.dart';
import 'data/repositories/gear_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'data/repositories/push_repository.dart';
import 'data/repositories/specialty_repository.dart';
import 'data/repositories/transport_repository.dart';
import 'data/repositories/trip_repository.dart';
import 'data/services/auth_api_service.dart';
import 'data/services/buddy_api_service.dart';
import 'data/services/chat_api_service.dart';
import 'data/services/dive_center_api_service.dart';
import 'data/services/dive_log_api_service.dart';
import 'data/services/expense_api_service.dart';
import 'data/services/gear_api_service.dart';
import 'data/services/profile_api_service.dart';
import 'data/services/push_api_service.dart';
import 'data/services/push_preferences.dart';
import 'data/services/realtime_service.dart';
import 'data/services/specialty_api_service.dart';
import 'data/services/token_storage_service.dart';
import 'data/services/transport_api_service.dart';
import 'data/services/trip_api_service.dart';
import 'ui/core/auth/ensure_signed_in.dart';
import 'ui/core/navigation/root_shell.dart';
import 'ui/core/theme/app_theme.dart';
import 'ui/core/widgets/shared_media_classifier.dart';
import 'ui/features/chats/views/choose_bubble_page.dart';
import 'ui/features/chats/views/trip_conversation_page.dart';
import 'ui/features/onboarding/views/app_entry_gate.dart';
import 'ui/features/trips/view_models/trip_view_model.dart';
import 'ui/features/trips/views/trip_page.dart';

// Build-time config via --dart-define, same pattern as admin/'s main.dart — a physical
// device can't reach the dev machine's `localhost`, so real-device runs need either the
// Mac's LAN IP or the deployed API passed explicitly. `flutter run` with no --dart-define
// still falls back to localhost (simulator/desktop convenience), but a `--release` build
// (App Store archive, TestFlight) falls back to the real production API instead — a release
// build shipped without remembering the flag must never silently point at localhost.
const _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: kReleaseMode
      ? 'https://api.divebubble.io'
      : 'http://localhost:8080',
);
const _centrifugoWsUrl = String.fromEnvironment(
  'CENTRIFUGO_WS_URL',
  defaultValue: kReleaseMode
      ? 'wss://api.divebubble.io/connection/websocket'
      : 'ws://localhost:8000/connection/websocket',
);

// Google Cloud Console project divebubble-a96e2 (the Firebase-linked project, same one push
// notifications already use) — iOS client identifies the app to Google, the Web (server)
// client is the ID token audience the backend verifies against. The backend accepts this
// alongside the older client id from before this migration (see GOOGLE_SERVER_CLIENT_IDS)
// so already-shipped app builds keep working until they update.
const _googleIosClientId =
    '583379001701-1kncasa92pin9ib1laae9obn5t9mum14.apps.googleusercontent.com';
const _googleServerClientId =
    '583379001701-i0nsfpnl2l4c7cis0t1cbhl7i6kupk3s.apps.googleusercontent.com';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Lets a push notification tap push a route from outside any particular widget's
  // BuildContext — main.dart is the one place that already holds every repository, so
  // deep-linking happens here rather than threading push state through RootShell.
  final _navigatorKey = GlobalKey<NavigatorState>();

  final _appLinks = AppLinks();
  StreamSubscription<Uri>? _linkSubscription;
  StreamSubscription<List<SharedMediaFile>>? _shareSubscription;

  late final _authRepository = AuthRepository(
    googleIosClientId: _googleIosClientId,
    googleServerClientId: _googleServerClientId,
    apiService: AuthApiService(baseUrl: _apiBaseUrl),
    tokenStorage: TokenStorageService(),
  );
  late final _tripRepository = TripRepository(
    service: TripApiService(
      baseUrl: _apiBaseUrl,
      getAccessToken: _authRepository.getValidAccessToken,
    ),
  );
  late final _chatRepository = ChatRepository(
    service: ChatApiService(
      baseUrl: _apiBaseUrl,
      getAccessToken: _authRepository.getValidAccessToken,
    ),
  );
  late final _transportRepository = TransportRepository(
    service: TransportApiService(
      baseUrl: _apiBaseUrl,
      getAccessToken: _authRepository.getValidAccessToken,
    ),
  );
  late final _buddyRepository = BuddyRepository(
    service: BuddyApiService(
      baseUrl: _apiBaseUrl,
      getAccessToken: _authRepository.getValidAccessToken,
    ),
  );
  late final _expenseRepository = ExpenseRepository(
    service: ExpenseApiService(
      baseUrl: _apiBaseUrl,
      getAccessToken: _authRepository.getValidAccessToken,
    ),
  );
  late final _diveLogRepository = DiveLogRepository(
    service: DiveLogApiService(
      baseUrl: _apiBaseUrl,
      getAccessToken: _authRepository.getValidAccessToken,
    ),
  );
  late final _realtimeService = RealtimeService(
    wsUrl: _centrifugoWsUrl,
    getToken: _chatRepository.getRealtimeToken,
  );
  late final _profileRepository = ProfileRepository(
    service: ProfileApiService(
      baseUrl: _apiBaseUrl,
      getAccessToken: _authRepository.getValidAccessToken,
    ),
  );
  late final _specialtyRepository = SpecialtyRepository(
    service: SpecialtyApiService(
      baseUrl: _apiBaseUrl,
      getAccessToken: _authRepository.getValidAccessToken,
    ),
  );
  late final _gearRepository = GearRepository(
    service: GearApiService(
      baseUrl: _apiBaseUrl,
      getAccessToken: _authRepository.getValidAccessToken,
    ),
  );
  late final _diveCenterRepository = DiveCenterRepository(
    service: DiveCenterApiService(
      baseUrl: _apiBaseUrl,
      getAccessToken: _authRepository.getValidAccessToken,
    ),
  );
  late final _pushRepository = PushRepository(
    service: PushApiService(
      baseUrl: _apiBaseUrl,
      getAccessToken: _authRepository.getValidAccessToken,
    ),
  );

  @override
  void initState() {
    super.initState();
    _authRepository.addListener(_onAuthChanged);
    _setUpPushNotifications();
    _setUpDeepLinks();
    _setUpShareToApp();
  }

  @override
  void dispose() {
    _authRepository.removeListener(_onAuthChanged);
    _linkSubscription?.cancel();
    _shareSubscription?.cancel();
    super.dispose();
  }

  // Invite links (divebubble.io/join/{code}) — Universal Links (iOS) / App Links (Android).
  // uriLinkStream alone covers both cold start (its first event is the launching link) and
  // warm (app already running) — this is app_links' own documented pattern, not a getInitialLink
  // + uriLinkStream split; calling both would double-handle the cold-start link.
  Future<void> _setUpDeepLinks() async {
    _linkSubscription = _appLinks.uriLinkStream.listen(
      _handleIncomingLink,
      onError: (e) => debugPrint('deep link: stream error: $e'),
    );
  }

  void _handleIncomingLink(Uri uri) {
    final segments = uri.pathSegments;
    if (segments.length == 2 && segments[0] == 'join') {
      _openTripFromInviteLink(segments[1]);
    }
  }

  Future<void> _openTripFromInviteLink(String code) async {
    try {
      final trip = await _tripRepository.resolveTripByCode(code);
      final currentUserId = await _authRepository.currentUserId() ?? '';
      await _navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => TripPage(
            viewModel: TripViewModel(
              repository: _tripRepository,
              authRepository: _authRepository,
              profileRepository: _profileRepository,
              pushRepository: _pushRepository,
              diveCenterRepository: _diveCenterRepository,
              tripId: trip.id,
              currentUserId: currentUserId,
            ),
            tripRepository: _tripRepository,
            chatRepository: _chatRepository,
            transportRepository: _transportRepository,
            buddyRepository: _buddyRepository,
            realtimeService: _realtimeService,
            diveCenterRepository: _diveCenterRepository,
            expenseRepository: _expenseRepository,
            entryCode: code,
          ),
        ),
      );
    } catch (e) {
      // Invalid/expired code, or offline — no trip to show, nothing useful to recover into.
      debugPrint('deep link: could not resolve invite code: $e');
    }
  }

  // Share-to-DiveBubble — photos/video/PDF shared from another app's OS share sheet. The
  // package's own example (unlike app_links' single-stream pattern) uses getMediaStream for
  // warm sharing plus a separate getInitialMedia for cold start, paired with reset() so the
  // cold-start share isn't also redelivered through the stream afterward.
  Future<void> _setUpShareToApp() async {
    _shareSubscription = ReceiveSharingIntent.instance.getMediaStream().listen(
      _handleSharedMedia,
      onError: (e) => debugPrint('share: stream error: $e'),
    );
    try {
      final initial = await ReceiveSharingIntent.instance.getInitialMedia();
      if (initial.isNotEmpty) await _handleSharedMedia(initial);
      ReceiveSharingIntent.instance.reset();
    } catch (e) {
      debugPrint('share: could not read initial media: $e');
    }
  }

  Future<void> _handleSharedMedia(List<SharedMediaFile> files) async {
    if (files.isEmpty) return;
    final attachments = await classifySharedMedia(files);
    if (attachments.isEmpty) return;

    final context = _navigatorKey.currentContext;
    if (context == null) return;
    // Share-to-DiveBubble has no sensible "preview" state the way an invite link does —
    // picking a Bubble to share into requires an account, so gate here rather than letting
    // ChooseBubblePage's own trip fetch fail with an auth error.
    final userId = await ensureSignedIn(
      context,
      _authRepository,
      _profileRepository,
      _pushRepository,
    );
    if (userId == null || !context.mounted) return;

    await _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => ChooseBubblePage(
          attachments: attachments,
          tripRepository: _tripRepository,
          chatRepository: _chatRepository,
          transportRepository: _transportRepository,
          buddyRepository: _buddyRepository,
          realtimeService: _realtimeService,
          authRepository: _authRepository,
          profileRepository: _profileRepository,
          pushRepository: _pushRepository,
          diveCenterRepository: _diveCenterRepository,
          expenseRepository: _expenseRepository,
          currentUserId: userId,
        ),
      ),
    );
  }

  void _onAuthChanged() => _syncPushTokenIfAuthorized();

  Future<void> _setUpPushNotifications() async {
    // iOS shows a system banner for a foreground notification-payload message only if asked —
    // otherwise a push that arrives while the app is open is silently swallowed.
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    FirebaseMessaging.instance.onTokenRefresh.listen(_registerToken);
    FirebaseMessaging.onMessageOpenedApp.listen(_openTripFromPush);
    // A push that launched the app from fully terminated (not just backgrounded) doesn't
    // fire onMessageOpenedApp — this is the cold-start equivalent of that same tap.
    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) _openTripFromPush(initialMessage);

    // Covers a returning already-signed-in user (no auth-change event fires on a silent
    // token restore, only on an explicit sign-in) — see _onAuthChanged's own comment.
    _syncPushTokenIfAuthorized();
  }

  // Deliberately passive — never calls requestPermission(), which is what actually shows
  // the OS prompt. For a brand-new account, that prompt now only ever appears from the
  // explicit PushPermissionPage step in LoginSheet's onboarding chain (with its own "why"
  // explained first); this just re-syncs the token for an already-decided diver on sign-in,
  // token refresh, or app resume, so a permission granted once doesn't need re-asking.
  Future<void> _syncPushTokenIfAuthorized() async {
    if (await _authRepository.currentUserId() == null) return;
    // Respects an explicit opt-out from NotificationsSettingsPage — a sign-in/token-refresh
    // event must never silently undo that.
    if (!await PushPreferences.isEnabled()) return;

    try {
      final settings = await FirebaseMessaging.instance
          .getNotificationSettings();
      if (settings.authorizationStatus != AuthorizationStatus.authorized)
        return;

      // iOS-only gotcha: the APNS device token arrives from Apple asynchronously — calling
      // getToken() before it lands throws apns-token-not-set, even when already authorized
      // (e.g. right after a cold start). Poll briefly rather than assuming it's instant.
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        var apnsToken = await FirebaseMessaging.instance.getAPNSToken();
        var attempts = 0;
        while (apnsToken == null && attempts < 10) {
          await Future.delayed(const Duration(milliseconds: 500));
          apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          attempts++;
        }
        if (apnsToken == null)
          return; // gave up — next app resume/token-refresh retries
      }

      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _registerToken(token);
    } catch (e) {
      // Best-effort — push setup must never crash the app it's supposed to be a nicety for.
      debugPrint('push: could not sync push token: $e');
    }
  }

  Future<void> _registerToken(String token) async {
    // A token-refresh event fires regardless of the diver's own preference — must not
    // silently re-enable push after an explicit opt-out via NotificationsSettingsPage.
    if (!await PushPreferences.isEnabled()) return;
    try {
      await _pushRepository.registerToken(
        token: token,
        platform: defaultTargetPlatform == TargetPlatform.android
            ? 'android'
            : 'ios',
      );
    } catch (e) {
      // Best-effort — a failed registration just means this device misses pushes until the
      // next token refresh or sign-in retries it, not something worth surfacing to the diver.
      debugPrint('push: token registration failed: $e');
    }
  }

  Future<void> _openTripFromPush(RemoteMessage message) async {
    final tripId = message.data['tripId'];
    if (tripId == null) return;

    try {
      final trip = await _tripRepository.getTrip(tripId);
      final currentUserId = await _authRepository.currentUserId() ?? '';
      _tripRepository.markRead(trip.id).catchError((_) {});
      await _navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => TripConversationPage.forTrip(
            trip: trip,
            currentUserId: currentUserId,
            tripRepository: _tripRepository,
            chatRepository: _chatRepository,
            transportRepository: _transportRepository,
            buddyRepository: _buddyRepository,
            realtimeService: _realtimeService,
            authRepository: _authRepository,
            profileRepository: _profileRepository,
            pushRepository: _pushRepository,
            diveCenterRepository: _diveCenterRepository,
            expenseRepository: _expenseRepository,
          ),
        ),
      );
    } catch (e) {
      // Best-effort — a failed deep-link (e.g. trip fetch failed) means the tap does
      // nothing, not a crash. The diver can still find the trip from Bubbles directly.
      debugPrint('push: could not open trip from notification: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'DiveBubble',
      theme: AppTheme.light,
      debugShowCheckedModeBanner: false,
      home: AppEntryGate(
        authRepository: _authRepository,
        profileRepository: _profileRepository,
        pushRepository: _pushRepository,
        rootShellBuilder: (context, currentUserId) => RootShell(
          tripRepository: _tripRepository,
          chatRepository: _chatRepository,
          transportRepository: _transportRepository,
          buddyRepository: _buddyRepository,
          realtimeService: _realtimeService,
          authRepository: _authRepository,
          profileRepository: _profileRepository,
          specialtyRepository: _specialtyRepository,
          gearRepository: _gearRepository,
          diveCenterRepository: _diveCenterRepository,
          expenseRepository: _expenseRepository,
          diveLogRepository: _diveLogRepository,
          pushRepository: _pushRepository,
          currentUserId: currentUserId,
        ),
      ),
    );
  }
}
