import 'package:flutter/material.dart';

import '../../../../data/repositories/profile_repository.dart';
import '../../../../domain/entities/profile.dart';
import 'profile_overview_card.dart';

/// Read-only view of another diver's Overview — reached by tapping an organizer or a
/// joined-divers row. No Edit button, no Certifications/Specialties/Gear (those stay
/// private to the diver's own profile), no settings rows.
class PublicProfilePage extends StatefulWidget {
  const PublicProfilePage({super.key, required this.userId, required this.profileRepository});

  final String userId;
  final ProfileRepository profileRepository;

  @override
  State<PublicProfilePage> createState() => _PublicProfilePageState();
}

class _PublicProfilePageState extends State<PublicProfilePage> {
  Profile? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
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
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _profile == null
                  ? const SizedBox.shrink()
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [ProfileOverviewCard(profile: _profile!)],
                    ),
    );
  }
}
