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
  required String currentUserId,
  required ProfileRepository profileRepository,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _DiverIdCardSheet(userId: userId, currentUserId: currentUserId, profileRepository: profileRepository),
  );
}

class _DiverIdCardSheet extends StatefulWidget {
  const _DiverIdCardSheet({required this.userId, required this.currentUserId, required this.profileRepository});

  final String userId;
  final String currentUserId;
  final ProfileRepository profileRepository;

  @override
  State<_DiverIdCardSheet> createState() => _DiverIdCardSheetState();
}

class _DiverIdCardSheetState extends State<_DiverIdCardSheet> {
  Profile? _profile;
  bool _isLoading = true;
  bool _isBlocking = false;
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

  // Deliberately doesn't fetch "is this user already blocked" first — blocking an
  // already-blocked user is a harmless no-op server-side, so this stays a single always-visible
  // action rather than a toggle with its own extra round trip.
  Future<void> _confirmBlock() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Block this user?'),
        content: const Text("You won't see their messages in shared trip chats anymore. You can undo this from Profile → Blocked users."),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Block', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isBlocking = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await widget.profileRepository.blockUser(widget.userId);
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(const SnackBar(content: Text('Blocked. Manage in Profile → Blocked users.')));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBlocking = false);
      messenger.showSnackBar(SnackBar(content: Text('Could not block user: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.userId != widget.currentUserId)
              Row(
                children: [
                  const Spacer(),
                  _isBlocking
                      ? const Padding(
                          padding: EdgeInsets.all(8),
                          child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : IconButton(
                          icon: const Icon(Icons.block),
                          tooltip: 'Block user',
                          onPressed: _confirmBlock,
                        ),
                ],
              ),
            _isLoading
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
          ],
        ),
      ),
    );
  }
}
