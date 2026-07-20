import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/specialty_repository.dart';
import '../../../../domain/certification_level.dart';
import '../../../../domain/entities/my_profile.dart';
import '../../../../domain/entities/specialty_certification.dart';
import '../view_models/account_view_model.dart';
import 'add_specialty_dialog.dart';
import 'edit_account_dialog.dart';
import 'update_level_dialog.dart';

/// Personal account screen — reached from the sidebar's account footer (see AdminShell).
/// Mirrors app/'s ProfileView content (Overview, Certifications: Level + Specialties,
/// About/Legal, Sign out) minus the Gear Locker, which doesn't apply to a business
/// console the same way it does to a diver deciding what to pack for a trip. Deliberately
/// simpler than app/'s copy in two ways: no animated specialty "deck" (a plain list is
/// enough here — this screen won't realistically hold enough specialties to need it), and
/// no photo upload on Level/specialty cards (avatar upload is still there, on the profile
/// itself) — both scope cuts made to ship this round rather than left silently incomplete.
class AccountPage extends StatefulWidget {
  const AccountPage({
    super.key,
    required this.profileRepository,
    required this.specialtyRepository,
    required this.authRepository,
    required this.onSignedOut,
  });

  final ProfileRepository profileRepository;
  final SpecialtyRepository specialtyRepository;
  final AuthRepository authRepository;
  final VoidCallback onSignedOut;

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  late final _viewModel = AccountViewModel(
    profileRepository: widget.profileRepository,
    specialtyRepository: widget.specialtyRepository,
  );
  bool _isSigningOut = false;

  @override
  void initState() {
    super.initState();
    _viewModel.load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _openEditProfile() async {
    final changed = await showDialog<bool>(context: context, builder: (_) => EditAccountDialog(viewModel: _viewModel));
    if (changed == true) setState(() {});
  }

  Future<void> _openUpdateLevel() async {
    final changed = await showDialog<bool>(context: context, builder: (_) => UpdateLevelDialog(viewModel: _viewModel));
    if (changed == true) setState(() {});
  }

  Future<void> _openAddSpecialty() async {
    final added = await showDialog<bool>(context: context, builder: (_) => AddSpecialtyDialog(viewModel: _viewModel));
    if (added == true) setState(() {});
  }

  Future<void> _signOut() async {
    setState(() => _isSigningOut = true);
    await widget.authRepository.signOut();
    // Pop this pushed route *before* triggering RootGate's recheck — otherwise this screen
    // would still sit on top of the Navigator stack after RootGate swaps its base route to
    // LoginPage underneath, leaving the signed-out diver stranded looking at a stale Account
    // page instead of the login screen.
    if (mounted) Navigator.of(context).pop();
    widget.onSignedOut();
  }

  Future<void> _openLegal(String path) => launchUrl(Uri.parse('https://divebubble.io$path'), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Account')),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final profile = _viewModel.profile;
          if (profile == null) {
            return Center(child: Text(_viewModel.error ?? 'Could not load your profile'));
          }

          final name = (profile.displayName?.isNotEmpty ?? false) ? profile.displayName! : 'Account';
          final hasLevel = profile.certificationLevel?.isNotEmpty ?? false;

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Overview
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        backgroundImage: (profile.avatarUrl?.isNotEmpty ?? false) ? NetworkImage(profile.avatarUrl!) : null,
                        child: (profile.avatarUrl?.isNotEmpty ?? false)
                            ? null
                            : Icon(Icons.person, size: 40, color: theme.colorScheme.onSecondaryContainer),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(name, style: theme.textTheme.titleLarge),
                            if (profile.location?.isNotEmpty ?? false) ...[
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(Icons.location_on_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                                  const SizedBox(width: 4),
                                  Text(profile.location!, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      TextButton(onPressed: _openEditProfile, child: const Text('Edit')),
                    ],
                  ),
                  if (profile.bio?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 20),
                    InputDecorator(
                      decoration: const InputDecoration(labelText: 'About'),
                      child: Text(profile.bio!, style: theme.textTheme.bodyMedium),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _StatTile(value: '${profile.diveCount}', label: 'Dives')),
                      const SizedBox(width: 12),
                      Expanded(child: _StatTile(value: hasLevel ? certificationLevelAbbreviation(profile.certificationLevel) : '—', label: 'Level')),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        _InfoRow(label: 'Languages', value: profile.languages.isNotEmpty ? profile.languages : '—'),
                        const Divider(height: 1),
                        _InfoRow(label: 'Member since', value: profile.memberSince != null ? '${profile.memberSince!.year}' : '—'),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                  Text('Certifications', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (hasLevel)
                    _LevelCard(profile: profile, onTap: _openUpdateLevel)
                  else
                    OutlinedButton.icon(onPressed: _openUpdateLevel, icon: const Icon(Icons.add), label: const Text('Add certificate')),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('Specialties', style: theme.textTheme.labelLarge),
                      const Spacer(),
                      IconButton(onPressed: _openAddSpecialty, icon: const Icon(Icons.add)),
                    ],
                  ),
                  if (_viewModel.specialties.isEmpty)
                    Text('No specialties added yet.', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))
                  else
                    ..._viewModel.specialties.map((s) => _SpecialtyRow(specialty: s, onRemove: () => _viewModel.removeSpecialty(s.id))),

                  const SizedBox(height: 32),
                  Text('Settings', style: theme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Card(
                    margin: EdgeInsets.zero,
                    child: Column(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.info_outline),
                          title: const Text('About'),
                          subtitle: const Text('DiveBubble Business'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.description_outlined),
                          title: const Text('Privacy Policy'),
                          trailing: const Icon(Icons.open_in_new, size: 16),
                          onTap: () => _openLegal('/privacy'),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const Icon(Icons.gavel_outlined),
                          title: const Text('Terms of Service'),
                          trailing: const Icon(Icons.open_in_new, size: 16),
                          onTap: () => _openLegal('/terms'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  OutlinedButton.icon(
                    onPressed: _isSigningOut ? null : _signOut,
                    icon: const Icon(Icons.logout),
                    label: Text(_isSigningOut ? 'Signing out…' : 'Sign out'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: theme.textTheme.titleLarge),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  const _LevelCard({required this.profile, required this.onTap});

  final MyProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [theme.colorScheme.primary, theme.colorScheme.primaryContainer]),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (profile.certificationAgency != null)
                    Text(profile.certificationAgency!, style: TextStyle(color: theme.colorScheme.onPrimary.withValues(alpha: 0.8))),
                  Text(profile.certificationLevel ?? '', style: theme.textTheme.titleLarge?.copyWith(color: theme.colorScheme.onPrimary)),
                  if (profile.certificationNumber != null)
                    Text('#${profile.certificationNumber}', style: TextStyle(color: theme.colorScheme.onPrimary.withValues(alpha: 0.8))),
                ],
              ),
            ),
            Icon(Icons.edit, color: theme.colorScheme.onPrimary),
          ],
        ),
      ),
    );
  }
}

class _SpecialtyRow extends StatelessWidget {
  const _SpecialtyRow({required this.specialty, required this.onRemove});

  final SpecialtyCertification specialty;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = [specialty.agency, specialty.certNumber != null ? '#${specialty.certNumber}' : null].whereType<String>();
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.verified_outlined),
      title: Text(specialty.displayLabel),
      subtitle: subtitleParts.isEmpty ? null : Text(subtitleParts.join(' · ')),
      trailing: IconButton(icon: const Icon(Icons.close, size: 18), onPressed: onRemove),
    );
  }
}
