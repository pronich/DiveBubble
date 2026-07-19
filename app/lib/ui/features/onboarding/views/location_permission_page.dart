import 'package:flutter/material.dart';

import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/push_repository.dart';
import '../../../../data/services/location_service.dart';
import 'push_permission_page.dart';

/// First step of new-account onboarding (see LoginSheet) — explains why DiveBubble wants
/// location before the OS permission dialog appears, rather than firing it silently later
/// the moment the diver first opens Edit Profile (the old behavior).
class LocationPermissionPage extends StatefulWidget {
  const LocationPermissionPage({super.key, required this.profileRepository, required this.pushRepository});

  final ProfileRepository profileRepository;
  final PushRepository pushRepository;

  @override
  State<LocationPermissionPage> createState() => _LocationPermissionPageState();
}

class _LocationPermissionPageState extends State<LocationPermissionPage> {
  final _locationService = LocationService();
  bool _requesting = false;

  Future<void> _continue({String? resolvedLocation}) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PushPermissionPage(
          profileRepository: widget.profileRepository,
          pushRepository: widget.pushRepository,
          initialLocation: resolvedLocation,
        ),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _enableLocation() async {
    setState(() => _requesting = true);
    // Triggers the OS permission dialog (see LocationService). Threaded forward as a
    // prefill rather than relying on Edit Profile's own auto-detect — that's now skipped
    // during onboarding specifically so tapping "Not now" here doesn't get silently
    // re-asked a screen later (see EditProfilePage.initState's own comment).
    final resolved = await _locationService.currentCityCountry();
    if (mounted) setState(() => _requesting = false);
    await _continue(resolvedLocation: resolved);
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
              Icon(Icons.location_on_outlined, size: 56, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Text('Find trips near you', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                "We'll use your location to show nearby trips and suggest your city on your "
                'profile. You can always change or remove it later.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _requesting ? null : _enableLocation,
                child: _requesting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Enable location'),
              ),
              const SizedBox(height: 8),
              TextButton(onPressed: _requesting ? null : () => _continue(), child: const Text('Not now')),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
