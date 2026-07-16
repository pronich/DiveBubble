import 'package:flutter/material.dart';

import '../../../../data/repositories/dive_center_repository.dart';
import '../../../../data/services/dive_center_api_service.dart';
import '../../../../domain/entities/dive_center_member.dart';

/// Search-then-add, not a free-form invite — MVP staff-add is exact-email lookup only (see
/// CLAUDE.md's Membership API note), since there's no invite-by-email flow for people who
/// don't have a DiveBubble account yet.
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
  String _role = 'staff';
  bool _isSearching = false;
  bool _isAdding = false;
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
    });
    try {
      final preview = await widget.diveCenterRepository.searchMemberByEmail(widget.diveCenterId, email);
      setState(() => _found = preview);
    } on MemberNotFoundException {
      setState(() => _error = 'No DiveBubble account found for that email — they need to sign up first.');
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      setState(() => _isSearching = false);
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
                      onPressed: (found == null || _isAdding) ? null : _add,
                      child: _isAdding
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Add to team'),
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
