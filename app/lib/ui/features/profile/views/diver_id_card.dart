import 'package:flutter/material.dart';

import '../../../../data/services/error_codes.dart';

import '../../../../data/repositories/profile_repository.dart';
import '../../../../domain/entities/profile.dart';
import '../../../../l10n/app_localizations.dart';
import 'profile_overview_card.dart';

/// Same ProfileOverviewCard look as the diver's own Profile screen, reached via a sheet instead of a full page push, with no Edit/Certifications/Gear/settings.
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
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Deliberately doesn't check "is this user already blocked" first — a no-op re-block is harmless server-side, avoiding a toggle with its own extra round trip.
  Future<void> _confirmBlock() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.blockThisUserTitle),
        content: Text(l10n.blockUserBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.block, style: TextStyle(color: Theme.of(context).colorScheme.error)),
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
      messenger.showSnackBar(SnackBar(content: Text(l10n.blockedManageBody)));
    } catch (e) {
      if (!mounted) return;
      setState(() => _isBlocking = false);
      messenger.showSnackBar(SnackBar(content: Text(l10n.couldNotBlockUser(friendlyError(e)))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
                          tooltip: l10n.blockUserTooltip,
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
                        child: Text(l10n.errorWithMessage(_error!), style: TextStyle(color: Theme.of(context).colorScheme.error)),
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
