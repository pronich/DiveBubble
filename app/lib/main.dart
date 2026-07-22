import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'data/repositories/auth_repository.dart';
import 'data/repositories/chat_repository.dart';
import 'data/repositories/dive_center_repository.dart';
import 'data/repositories/gear_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'data/repositories/push_repository.dart';
import 'data/repositories/specialty_repository.dart';
import 'data/repositories/transport_repository.dart';
import 'data/repositories/trip_repository.dart';
import 'data/services/auth_api_service.dart';
import 'data/services/chat_api_service.dart';
import 'data/services/dive_center_api_service.dart';
import 'data/services/gear_api_service.dart';
import 'data/services/profile_api_service.dart';
import 'data/services/push_api_service.dart';
import 'data/services/push_preferences.dart';
import 'data/services/realtime_service.dart';
import 'data/services/specialty_api_service.dart';
import 'data/services/token_storage_service.dart';
import 'data/services/transport_api_service.dart';
import 'data/services/trip_api_service.dart';
import 'ui/core/navigation/root_shell.dart';
import 'ui/core/theme/app_theme.dart';
import 'ui/features/chats/view_models/chat_view_model.dart';
import 'ui/features/chats/views/trip_conversation_page.dart';
import 'ui/features/onboarding/views/app_entry_gate.dart';
import 'ui/features/transport/view_models/transport_view_model.dart';

// Build-time config via --dart-define, same pattern as admin/'s main.dart — a physical
// device can't reach the dev machine's `localhost`, so real-device runs need either the
// Mac's LAN IP or the deployed API passed explicitly. `flutter run` with no --dart-define
// still falls back to localhost (simulator/desktop convenience), but a `--release` build
// (App Store archive, TestFlight) falls back to the real production API instead — a release
// build shipped without remembering the flag must never silently point at localhost.
const _apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: kReleaseMode ? 'https://api.divebubble.io' : 'http://localhost:8080',
);
const _centrifugoWsUrl = String.fromEnvironment(
  'CENTRIFUGO_WS_URL',
  defaultValue: kReleaseMode
      ? 'wss://api.divebubble.io/connection/websocket'
      : 'ws://localhost:8000/connection/websocket',
);

// Google Cloud Console (project backing DiveBuddy) — iOS client identifies the app to Google,
// the Web (server) client is the ID token audience the backend verifies against.
const _googleIosClientId = '267576474476-t6kh8ps4pffq3ftfic3tghuqeg7hdj92.apps.googleusercontent.com';
const _googleServerClientId = '267576474476-ea5pbefve96l3oqd1j59oo276sskv54f.apps.googleusercontent.com';

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

  late final _authRepository = AuthRepository(
    googleIosClientId: _googleIosClientId,
    googleServerClientId: _googleServerClientId,
    apiService: AuthApiService(baseUrl: _apiBaseUrl),
    tokenStorage: TokenStorageService(),
  );
  late final _tripRepository = TripRepository(
    service: TripApiService(baseUrl: _apiBaseUrl, getAccessToken: _authRepository.getValidAccessToken),
  );
  late final _chatRepository = ChatRepository(
    service: ChatApiService(baseUrl: _apiBaseUrl, getAccessToken: _authRepository.getValidAccessToken),
  );
  late final _transportRepository = TransportRepository(
    service: TransportApiService(baseUrl: _apiBaseUrl, getAccessToken: _authRepository.getValidAccessToken),
  );
  late final _realtimeService = RealtimeService(
    wsUrl: _centrifugoWsUrl,
    getToken: _chatRepository.getRealtimeToken,
  );
  late final _profileRepository = ProfileRepository(
    service: ProfileApiService(baseUrl: _apiBaseUrl, getAccessToken: _authRepository.getValidAccessToken),
  );
  late final _specialtyRepository = SpecialtyRepository(
    service: SpecialtyApiService(baseUrl: _apiBaseUrl, getAccessToken: _authRepository.getValidAccessToken),
  );
  late final _gearRepository = GearRepository(
    service: GearApiService(baseUrl: _apiBaseUrl, getAccessToken: _authRepository.getValidAccessToken),
  );
  late final _diveCenterRepository = DiveCenterRepository(
    service: DiveCenterApiService(baseUrl: _apiBaseUrl, getAccessToken: _authRepository.getValidAccessToken),
  );
  late final _pushRepository = PushRepository(
    service: PushApiService(baseUrl: _apiBaseUrl, getAccessToken: _authRepository.getValidAccessToken),
  );

  @override
  void initState() {
    super.initState();
    _authRepository.addListener(_onAuthChanged);
    _setUpPushNotifications();
  }

  @override
  void dispose() {
    _authRepository.removeListener(_onAuthChanged);
    super.dispose();
  }

  void _onAuthChanged() => _syncPushTokenIfAuthorized();

  Future<void> _setUpPushNotifications() async {
    // iOS shows a system banner for a foreground notification-payload message only if asked —
    // otherwise a push that arrives while the app is open is silently swallowed.
    await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
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
      final settings = await FirebaseMessaging.instance.getNotificationSettings();
      if (settings.authorizationStatus != AuthorizationStatus.authorized) return;

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
        if (apnsToken == null) return; // gave up — next app resume/token-refresh retries
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
      await _pushRepository.registerToken(token: token, platform: defaultTargetPlatform == TargetPlatform.android ? 'android' : 'ios');
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
          builder: (_) => TripConversationPage(
            chatViewModel: ChatViewModel(
              repository: _chatRepository,
              realtimeService: _realtimeService,
              profileRepository: _profileRepository,
              tripId: trip.id,
              currentUserId: currentUserId,
            ),
            transportViewModel: TransportViewModel(
              repository: _transportRepository,
              authRepository: _authRepository,
              profileRepository: _profileRepository,
              pushRepository: _pushRepository,
              tripId: trip.id,
              currentUserId: currentUserId,
            ),
            tripTitle: trip.title,
            tripPhotoUrl: trip.photoUrl,
            tripRepository: _tripRepository,
            chatRepository: _chatRepository,
            transportRepository: _transportRepository,
            realtimeService: _realtimeService,
            authRepository: _authRepository,
            profileRepository: _profileRepository,
            pushRepository: _pushRepository,
            diveCenterRepository: _diveCenterRepository,
            initialHasTransportAlert: trip.hasTransportAlert,
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
          realtimeService: _realtimeService,
          authRepository: _authRepository,
          profileRepository: _profileRepository,
          specialtyRepository: _specialtyRepository,
          gearRepository: _gearRepository,
          diveCenterRepository: _diveCenterRepository,
          pushRepository: _pushRepository,
          currentUserId: currentUserId,
        ),
      ),
    );
  }
}
