import 'package:flutter/material.dart';

import 'data/repositories/chat_repository.dart';
import 'data/repositories/trip_repository.dart';
import 'data/services/chat_api_service.dart';
import 'data/services/trip_api_service.dart';
import 'data/services/user_identity_service.dart';
import 'ui/core/navigation/root_shell.dart';
import 'ui/core/theme/app_theme.dart';

const _apiBaseUrl = 'http://localhost:8080';

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

    return MaterialApp(
      title: 'DiveBuddy',
      theme: AppTheme.light,
      home: RootShell(
        tripRepository: tripRepository,
        chatRepository: chatRepository,
        currentUserId: userId,
      ),
    );
  }
}
