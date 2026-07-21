import 'package:flutter/material.dart';

import '../../../../data/repositories/dive_center_repository.dart';
import '../../../../data/services/dive_center_api_service.dart';
import '../../../../domain/entities/dive_center_member.dart';

/// Search-then-add for an existing account; falls back to sending an invitation email when
/// the search comes up empty (see CLAUDE.md's Implemented — dive centers section) — an
/// invitee is auto-joined the moment they sign in with the invited email, no separate accept
/// step, so there's nothing more for this dialog to do once the invite is sent.
class AddMemberDialog extends StatefulWidget {
  const AddMemberDialog({super.key, required this.diveCenterRepository, required this.diveCenterId});

  final DiveCenterRepository diveCenterRepository;
  final String diveCenterId;

  @override
  State<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<AddMemberDialog> {
  final _emailController = TextEditingController();
  MemberPreview? _found;
  // Set on a MemberNotFoundException — the email that came up empty, offered as an invite
  // target instead. Cleared on every new search so a stale offer never lingers.
  String? _notFoundEmail;
  String _role = 'staff';
  bool _isSearching = false;
  bool _isAdding = false;
  bool _isInviting = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    setState(() {
      _isSearching = true;
      _error = null;
      _found = null;
      _notFoundEmail = null;
    });
    try {
      final preview = await widget.diveCenterRepository.searchMemberByEmail(widget.diveCenterId, email);
      setState(() => _found = preview);
    } on MemberNotFoundException {
      setState(() => _notFoundEmail = email);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _isSearching = false);
    }
  }

  Future<void> _invite() async {
    final email = _notFoundEmail;
    if (email == null) return;
    setState(() {
      _isInviting = true;
      _error = null;
    });
    try {
      await widget.diveCenterRepository.inviteMember(widget.diveCenterId, email, _role);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isInviting = false);
    }
  }

  Future<void> _add() async {
    final found = _found;
    if (found == null) return;
    setState(() {
      _isAdding = true;
      _error = null;
    });
    try {
      await widget.diveCenterRepository.addMember(widget.diveCenterId, found.userId, _role);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final found = _found;
    final notFoundEmail = _notFoundEmail;
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Invite a user', style: theme.textTheme.headlineSmall)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop(false)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Find an existing DiveBubble account by email, then add them to your team.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      onSubmitted: (_) => _search(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _isSearching ? null : _search,
                    child: _isSearching
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Search'),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ],
              if (found != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundImage: found.avatarUrl != null ? NetworkImage(found.avatarUrl!) : null,
                        child: found.avatarUrl == null ? const Icon(Icons.person) : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          found.displayName?.isNotEmpty == true ? found.displayName! : 'Diver',
                          style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'staff', child: Text('Staff')),
                    DropdownMenuItem(value: 'owner', child: Text('Owner')),
                  ],
                  onChanged: (value) => setState(() => _role = value ?? 'staff'),
                ),
              ],
              if (notFoundEmail != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'No DiveBubble account found for $notFoundEmail — send an invitation instead. '
                    "They'll be added to your team automatically the first time they sign in with this address.",
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'staff', child: Text('Staff')),
                    DropdownMenuItem(value: 'owner', child: Text('Owner')),
                  ],
                  onChanged: (value) => setState(() => _role = value ?? 'staff'),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isAdding || _isInviting
                          ? null
                          : found != null
                              ? _add
                              : notFoundEmail != null
                                  ? _invite
                                  : null,
                      child: (_isAdding || _isInviting)
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(notFoundEmail != null ? 'Send invite' : 'Add to team'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
