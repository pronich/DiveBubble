import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/push_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../profile/view_models/profile_view_model.dart';
import '../../profile/views/edit_profile_page.dart';

/// The one place in the app that calls FirebaseMessaging.requestPermission() from onboarding; shown only when the device hasn't decided this permission yet.
class PushPermissionPage extends StatefulWidget {
  const PushPermissionPage({
    super.key,
    required this.profileRepository,
    required this.pushRepository,
    required this.isNewUser,
  });

  final ProfileRepository profileRepository;
  final PushRepository pushRepository;
  final bool isNewUser;

  @override
  State<PushPermissionPage> createState() => _PushPermissionPageState();
}

class _PushPermissionPageState extends State<PushPermissionPage> {
  bool _requesting = false;

  Future<void> _finish() async {
    if (widget.isNewUser) {
      final profile = await widget.profileRepository.getProfile();
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => EditProfilePage(
            viewModel: ProfileViewModel(repository: widget.profileRepository),
            profile: profile,
            isOnboarding: true,
          ),
        ),
      );
      if (mounted) Navigator.of(context).pop();
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _enableNotifications() async {
    setState(() => _requesting = true);
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.denied) {
        // iOS-only: the APNS device token arrives asynchronously after requestPermission(), and calling getToken() before it lands throws.
        if (defaultTargetPlatform == TargetPlatform.iOS) {
          var apnsToken = await FirebaseMessaging.instance.getAPNSToken();
          var attempts = 0;
          while (apnsToken == null && attempts < 10) {
            await Future.delayed(const Duration(milliseconds: 500));
            apnsToken = await FirebaseMessaging.instance.getAPNSToken();
            attempts++;
          }
        }
        final token = await FirebaseMessaging.instance.getToken();
        if (token != null) {
          await widget.pushRepository.registerToken(
            token: token,
            platform: defaultTargetPlatform == TargetPlatform.android ? 'android' : 'ios',
          );
        }
      }
    } catch (_) {
      // Best-effort — worst case this device doesn't get pushes until enabled later from NotificationsSettingsPage.
    }
    // Diver may have already tapped "Not now" and left while this was in flight — calling _finish() again would push onto a Navigator no longer in the tree.
    if (!mounted) return;
    setState(() => _requesting = false);
    await _finish();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              Icon(Icons.notifications_none, size: 56, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Text(l10n.stayInTheLoop, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                l10n.pushPermissionBody,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _requesting ? null : _enableNotifications,
                child: _requesting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l10n.continueLabel),
              ),
              const SizedBox(height: 8),
              // Stays tappable even mid-request — push permission must stay optional and never block onboarding (App Store Guideline 4.5.4).
              TextButton(onPressed: _finish, child: Text(l10n.notNow)),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
