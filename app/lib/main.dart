import 'package:flutter/material.dart';

import 'data/repositories/auth_repository.dart';
import 'data/repositories/chat_repository.dart';
import 'data/repositories/transport_repository.dart';
import 'data/repositories/trip_repository.dart';
import 'data/services/auth_api_service.dart';
import 'data/services/chat_api_service.dart';
import 'data/services/realtime_service.dart';
import 'data/services/token_storage_service.dart';
import 'data/services/transport_api_service.dart';
import 'data/services/trip_api_service.dart';
import 'data/services/user_identity_service.dart';
import 'ui/core/navigation/root_shell.dart';
import 'ui/core/theme/app_theme.dart';
import 'ui/features/onboarding/views/app_entry_gate.dart';

const _apiBaseUrl = 'http://localhost:8080';
const _centrifugoWsUrl = 'ws://localhost:8000/connection/websocket';

// Google Cloud Console (project backing DiveBuddy) — iOS client identifies the app to Google,
// the Web (server) client is the ID token audience the backend verifies against.
const _googleIosClientId = '267576474476-t6kh8ps4pffq3ftfic3tghuqeg7hdj92.apps.googleusercontent.com';
const _googleServerClientId = '267576474476-ea5pbefve96l3oqd1j59oo276sskv54f.apps.googleusercontent.com';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final userId = await UserIdentityService().getOrCreateId();
  runApp(MyApp(userId: userId));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context) {
    final tripRepository = TripRepository(
      service: TripApiService(baseUrl: _apiBaseUrl, userId: userId),
    );
    final chatRepository = ChatRepository(
      service: ChatApiService(baseUrl: _apiBaseUrl, userId: userId),
    );
    final transportRepository = TransportRepository(
      service: TransportApiService(baseUrl: _apiBaseUrl, userId: userId),
    );
    final realtimeService = RealtimeService(
      wsUrl: _centrifugoWsUrl,
      getToken: chatRepository.getRealtimeToken,
    );
    final authRepository = AuthRepository(
      googleIosClientId: _googleIosClientId,
      googleServerClientId: _googleServerClientId,
      apiService: AuthApiService(baseUrl: _apiBaseUrl),
      tokenStorage: TokenStorageService(),
    );

    return MaterialApp(
      title: 'DiveBuddy',
      theme: AppTheme.light,
      home: AppEntryGate(
        authRepository: authRepository,
        rootShellBuilder: (context) => RootShell(
          tripRepository: tripRepository,
          chatRepository: chatRepository,
          transportRepository: transportRepository,
          realtimeService: realtimeService,
          currentUserId: userId,
        ),
      ),
    );
  }
}
