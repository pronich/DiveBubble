import 'package:flutter/material.dart';

import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/push_repository.dart';
import '../../../../data/services/location_service.dart';
import '../../profile/view_models/profile_view_model.dart';
import '../../profile/views/edit_profile_page.dart';
import 'push_permission_page.dart';

/// Unwired as of the B2C pivot (2026-09-15) — its "show nearby trips" pitch was Explore's, which is no longer reachable. Left in place in case a location-driven feature returns.
class LocationPermissionPage extends StatefulWidget {
  const LocationPermissionPage({
    super.key,
    required this.profileRepository,
    required this.pushRepository,
    required this.needsPush,
    required this.isNewUser,
  });

  final ProfileRepository profileRepository;
  final PushRepository pushRepository;
  // Chains straight into PushPermissionPage instead of popping, so the two explanation screens slide one into the next.
  final bool needsPush;
  final bool isNewUser;

  @override
  State<LocationPermissionPage> createState() => _LocationPermissionPageState();
}

class _LocationPermissionPageState extends State<LocationPermissionPage> {
  final _locationService = LocationService();
  bool _requesting = false;

  Future<void> _finish({String? resolvedLocation}) async {
    if (widget.needsPush) {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PushPermissionPage(
            profileRepository: widget.profileRepository,
            pushRepository: widget.pushRepository,
            isNewUser: widget.isNewUser,
          ),
        ),
      );
      if (mounted) Navigator.of(context).pop();
      return;
    }
    if (widget.isNewUser) {
      var profile = await widget.profileRepository.getProfile();
      if (resolvedLocation != null && resolvedLocation.isNotEmpty) {
        profile = profile.copyWith(location: resolvedLocation);
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
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _enableLocation() async {
    setState(() => _requesting = true);
    // Threaded forward as a prefill instead of relying on Edit Profile's own auto-detect, which is skipped during onboarding so "Not now" doesn't get silently re-asked later.
    final resolved = await _locationService.currentCityCountry();
    // Diver may have already tapped "Not now" and left while this was in flight — calling _finish() again would push onto a Navigator no longer in the tree.
    if (!mounted) return;
    setState(() => _requesting = false);
    await _finish(resolvedLocation: resolved);
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
                    : const Text('Continue'),
              ),
              const SizedBox(height: 8),
              // Stays tappable even mid-request — geocoding can stall, and a diver must always have a way out (App Store Guideline 2.1(a)).
              TextButton(onPressed: () => _finish(), child: const Text('Not now')),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
