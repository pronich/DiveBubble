import 'package:flutter/material.dart';

import '../../../../data/repositories/profile_repository.dart';
import '../../../../domain/entities/profile.dart';

class BlockedUsersPage extends StatefulWidget {
  const BlockedUsersPage({super.key, required this.profileRepository});

  final ProfileRepository profileRepository;

  @override
  State<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends State<BlockedUsersPage> {
  List<Profile>? _profiles;
  String? _error;
  final Set<String> _unblocking = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final ids = await widget.profileRepository.getBlockedUserIds();
      final profiles = await Future.wait(ids.map((id) => widget.profileRepository.getPublicProfile(id)));
      if (mounted) setState(() => _profiles = profiles);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  Future<void> _unblock(String userId) async {
    setState(() => _unblocking.add(userId));
    try {
      await widget.profileRepository.unblockUser(userId);
      if (!mounted) return;
      setState(() => _profiles = _profiles!.where((p) => p.id != userId).toList());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not unblock: $e')));
    } finally {
      if (mounted) setState(() => _unblocking.remove(userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Blocked users')),
      body: _error != null
          ? Center(child: Text('Error: $_error', style: TextStyle(color: theme.colorScheme.error)))
          : _profiles == null
              ? const Center(child: CircularProgressIndicator())
              : _profiles!.isEmpty
                  ? Center(
                      child: Text('No blocked users.', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
                    )
                  : ListView.separated(
                      itemCount: _profiles!.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final profile = _profiles![index];
                        final name = (profile.displayName?.isNotEmpty ?? false) ? profile.displayName! : 'Diver';
                        final isUnblocking = _unblocking.contains(profile.id);
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: theme.colorScheme.secondaryContainer,
                            backgroundImage: (profile.avatarUrl?.isNotEmpty ?? false) ? NetworkImage(profile.avatarUrl!) : null,
                            child: (profile.avatarUrl?.isNotEmpty ?? false)
                                ? null
                                : Icon(Icons.person, color: theme.colorScheme.onSecondaryContainer),
                          ),
                          title: Text(name),
                          trailing: OutlinedButton(
                            onPressed: isUnblocking ? null : () => _unblock(profile.id),
                            child: isUnblocking
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Unblock'),
                          ),
                        );
                      },
                    ),
    );
  }
}
