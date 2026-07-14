import 'package:flutter/material.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../features/onboarding/views/login_sheet.dart';

/// Ensures the user is authenticated before a gated action (Join, Create trip, etc.), prompting
/// login via [LoginSheet] if not already signed in. Returns the current user's id on success
/// (already signed in, or just completed sign-in), or null if they dismissed the prompt.
Future<String?> ensureSignedIn(
  BuildContext context,
  AuthRepository authRepository,
  ProfileRepository profileRepository,
) async {
  final existing = await authRepository.getValidAccessToken();
  if (existing != null) {
    return authRepository.currentUserId();
  }

  if (!context.mounted) return null;
  final signedIn = await LoginSheet.show(
    context,
    authRepository: authRepository,
    profileRepository: profileRepository,
  );
  if (!signedIn) return null;
  return authRepository.currentUserId();
}
