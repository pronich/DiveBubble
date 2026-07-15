import 'package:flutter/material.dart';

import '../../../../data/repositories/profile_repository.dart';
import '../../../../domain/entities/profile.dart';
import 'profile_overview_card.dart';

/// Tap an organizer or participant anywhere in the app and this pops up as a sheet — same
/// ProfileOverviewCard look as the diver's own Profile screen (Overview), just reached via
/// a sheet instead of a full page push. No Edit button, no Certifications/Gear/settings.
Future<void> showDiverIdCard(
  BuildContext context, {
  required String userId,
  required ProfileRepository profileRepository,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _DiverIdCardSheet(userId: userId, profileRepository: profileRepository),
  );
}

class _DiverIdCardSheet extends StatefulWidget {
  const _DiverIdCardSheet({required this.userId, required this.profileRepository});

  final String userId;
  final ProfileRepository profileRepository;

  @override
  State<_DiverIdCardSheet> createState() => _DiverIdCardSheetState();
}

class _DiverIdCardSheetState extends State<_DiverIdCardSheet> {
  Profile? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final profile = await widget.profileRepository.getPublicProfile(widget.userId);
      if (mounted) setState(() => _profile = profile);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _isLoading
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: CircularProgressIndicator()),
              )
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text('Error: $_error', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  )
                : SingleChildScrollView(
                    child: ProfileOverviewCard(profile: _profile!),
                  ),
      ),
    );
  }
}
