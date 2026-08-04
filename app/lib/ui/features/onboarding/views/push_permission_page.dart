import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/push_repository.dart';
import '../../profile/view_models/profile_view_model.dart';
import '../../profile/views/edit_profile_page.dart';

/// Second step of new-account onboarding (see LoginSheet) — same "explain before asking"
/// reasoning as LocationPermissionPage. This is the one place in the app that ever calls
/// FirebaseMessaging.requestPermission() for a brand-new account; everywhere else
/// (main.dart's auto-sync on sign-in/token-refresh, NotificationsSettingsPage) either only
/// checks an already-decided status or is a settings toggle the diver tapped themselves.
class PushPermissionPage extends StatefulWidget {
  const PushPermissionPage({
    super.key,
    required this.profileRepository,
    required this.pushRepository,
    this.initialLocation,
    this.standalone = false,
  });

  final ProfileRepository profileRepository;
  final PushRepository pushRepository;
  // Resolved on the previous step (LocationPermissionPage) if the diver granted location —
  // prefilled into Edit Profile here rather than letting it auto-detect again, since that
  // auto-detect is skipped during onboarding (see EditProfilePage.initState).
  final String? initialLocation;
  // True when shown to a returning diver on a device that's never decided push permission
  // (new phone, reinstall) rather than as part of new-account onboarding — just asks and
  // pops, skipping the location/profile/certificates chain that follows it for new accounts.
  final bool standalone;

  @override
  State<PushPermissionPage> createState() => _PushPermissionPageState();
}

class _PushPermissionPageState extends State<PushPermissionPage> {
  bool _requesting = false;

  Future<void> _continue() async {
    if (widget.standalone) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    var profile = await widget.profileRepository.getProfile();
    if (widget.initialLocation != null && widget.initialLocation!.isNotEmpty) {
      profile = profile.copyWith(location: widget.initialLocation);
    }
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
  }

  Future<void> _enableNotifications() async {
    setState(() => _requesting = true);
    try {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus != AuthorizationStatus.denied) {
        // iOS-only gotcha: the APNS device token arrives asynchronously after
        // requestPermission() — calling getToken() before it lands throws. Same poll
        // main.dart's own token-refresh path uses.
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
      // Best-effort — worst case this device just doesn't get pushes until the diver
      // later enables it from NotificationsSettingsPage.
    }
    // Diver may have already tapped "Not now" and left while this was in flight — calling
    // _continue() again here would push onto a Navigator that's no longer in the tree.
    if (!mounted) return;
    setState(() => _requesting = false);
    await _continue();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              Text('Stay in the loop', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                "Get notified about new messages, trip changes, and who's joining your rides. "
                'You can turn this off anytime in Profile settings.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _requesting ? null : _enableNotifications,
                child: _requesting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Continue'),
              ),
              const SizedBox(height: 8),
              // Stays tappable even mid-request — push permission must stay optional and
              // never block onboarding (see App Store Guideline 4.5.4 rejection).
              TextButton(onPressed: _continue, child: const Text('Not now')),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
