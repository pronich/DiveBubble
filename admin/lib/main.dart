import 'package:flutter/material.dart';

import 'data/repositories/auth_repository.dart';
import 'data/repositories/dive_center_repository.dart';
import 'data/repositories/profile_repository.dart';
import 'data/repositories/trip_repository.dart';
import 'data/services/auth_api_service.dart';
import 'data/services/dive_center_api_service.dart';
import 'data/services/profile_api_service.dart';
import 'data/services/token_storage_service.dart';
import 'data/services/trip_api_service.dart';
import 'ui/core/root_gate.dart';
import 'ui/core/theme/app_theme.dart';

const _apiBaseUrl = 'http://localhost:8080';

// Same Web OAuth client app/ already uses for its own ID-token audience — a web build has
// no separate native-app identity to keep distinct from it, unlike app/'s iOS client id.
const _googleWebClientId = '267576474476-ea5pbefve96l3oqd1j59oo276sskv54f.apps.googleusercontent.com';

void main() {
  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authRepository = AuthRepository(
      googleWebClientId: _googleWebClientId,
      apiService: AuthApiService(baseUrl: _apiBaseUrl),
      tokenStorage: TokenStorageService(),
    );
    final diveCenterRepository = DiveCenterRepository(
      service: DiveCenterApiService(baseUrl: _apiBaseUrl, getAccessToken: authRepository.getValidAccessToken),
    );
    final tripRepository = TripRepository(
      service: TripApiService(baseUrl: _apiBaseUrl, getAccessToken: authRepository.getValidAccessToken),
    );
    final profileRepository = ProfileRepository(
      service: ProfileApiService(baseUrl: _apiBaseUrl, getAccessToken: authRepository.getValidAccessToken),
    );

    return MaterialApp(
      title: 'DiveBubble Business',
      theme: AdminTheme.light,
      debugShowCheckedModeBanner: false,
      home: RootGate(
        authRepository: authRepository,
        diveCenterRepository: diveCenterRepository,
        tripRepository: tripRepository,
        profileRepository: profileRepository,
      ),
    );
  }
}
