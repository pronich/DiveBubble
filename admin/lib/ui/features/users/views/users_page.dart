import 'package:flutter/material.dart';

import '../../../../data/repositories/dive_center_repository.dart';
import '../../../../domain/entities/dive_center_member.dart';
import '../view_models/users_view_model.dart';
import 'add_member_dialog.dart';

/// Body-only (embedded in AdminShell). No "Invited/pending" status exists yet — adding a
/// member is search-then-add against an existing account (see AddMemberDialog's own
/// comment), so every row here is, truthfully, already active.
class UsersPage extends StatefulWidget {
  const UsersPage({super.key, required this.diveCenterRepository, required this.diveCenterId});

  final DiveCenterRepository diveCenterRepository;
  final String diveCenterId;

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  late final _viewModel = UsersViewModel(repository: widget.diveCenterRepository, diveCenterId: widget.diveCenterId);
  String _search = '';

  @override
  void initState() {
    super.initState();
    _viewModel.load();
  }

  Future<void> _openInvite() async {
    final added = await showDialog<bool>(
      context: context,
      builder: (_) => AddMemberDialog(diveCenterRepository: widget.diveCenterRepository, diveCenterId: widget.diveCenterId),
    );
    if (added == true) _viewModel.load();
  }

  Future<void> _remove(DiveCenterMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove from team?'),
        content: Text('${member.displayName ?? 'This user'} will lose access to this organization\'s trips.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Remove')),
        ],
      ),
    );
    if (confirmed != true) return;
    final error = await _viewModel.removeMember(member.userId);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  List<DiveCenterMember> _filtered(List<DiveCenterMember> members) {
    final query = _search.trim().toLowerCase();
    if (query.isEmpty) return members;
    return members
        .where((m) => (m.displayName ?? '').toLowerCase().contains(query) || m.role.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final members = _filtered(_viewModel.members);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TEAM',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text('Users', style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          'Manage who has access to your organization.',
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(onPressed: _openInvite, icon: const Icon(Icons.add), label: const Text('Invite user')),
                ],
              ),
              const SizedBox(height: 20),
              Divider(color: theme.colorScheme.outlineVariant),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  hintText: 'Search by name or role...',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (value) => setState(() => _search = value),
              ),
              const SizedBox(height: 24),
              if (_viewModel.isLoading)
                const Padding(padding: EdgeInsets.only(top: 40), child: Center(child: CircularProgressIndicator()))
              else if (_viewModel.error != null)
                Text('Error: ${_viewModel.error}', style: TextStyle(color: theme.colorScheme.error))
              else if (members.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Text(
                    _viewModel.members.isEmpty ? 'No team members yet.' : 'No matches.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                )
              else
                _MembersTable(members: members, onRemove: _remove),
            ],
          ),
        );
      },
    );
  }
}

class _MembersTable extends StatelessWidget {
  const _MembersTable({required this.members, required this.onRemove});

  final List<DiveCenterMember> members;
  final void Function(DiveCenterMember) onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(border: Border.all(color: theme.colorScheme.outlineVariant), borderRadius: BorderRadius.circular(12)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            color: theme.colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(flex: 3, child: _HeaderCell('NAME')),
                Expanded(flex: 2, child: _HeaderCell('ROLE')),
                Expanded(flex: 3, child: _HeaderCell('EMAIL')),
                Expanded(flex: 2, child: _HeaderCell('CERTIFICATION')),
                Expanded(flex: 2, child: _HeaderCell('STATUS')),
                const SizedBox(width: 40),
              ],
            ),
          ),
          for (final member in members)
            Container(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant))),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
                          child: member.avatarUrl == null ? const Icon(Icons.person, size: 16) : null,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            member.displayName?.isNotEmpty == true ? member.displayName! : 'Diver',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(member.role == 'owner' ? 'Owner' : 'Staff'),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      member.email ?? '—',
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      member.certificationLevel ?? '—',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Active',
                        style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSecondaryContainer),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_horiz),
                      onSelected: (value) {
                        if (value == 'remove') onRemove(member);
                      },
                      itemBuilder: (_) => const [PopupMenuItem(value: 'remove', child: Text('Remove'))],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 0.5,
          ),
    );
  }
}
