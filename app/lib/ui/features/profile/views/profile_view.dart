import 'package:flutter/material.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/gear_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/specialty_repository.dart';
import '../../../../data/services/location_service.dart';
import '../../../../domain/entities/profile.dart';
import '../../../core/widgets/dashed_divider.dart';
import '../../onboarding/views/login_sheet.dart';
import '../view_models/profile_view_model.dart';
import 'about_page.dart';
import 'add_specialty_sheet.dart';
import 'edit_profile_page.dart';
import 'gear_locker_page.dart';
import 'gear_summary_card.dart';
import 'legal_page.dart';
import 'level_card.dart';
import 'notifications_settings_page.dart';
import 'specialties_section.dart';
import 'update_level_sheet.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({
    super.key,
    required this.authRepository,
    required this.profileRepository,
    required this.specialtyRepository,
    required this.gearRepository,
    required this.isActive,
  });

  final AuthRepository authRepository;
  final ProfileRepository profileRepository;
  final SpecialtyRepository specialtyRepository;
  final GearRepository gearRepository;

  /// Whether this is the currently-selected bottom-nav tab. RootShell's IndexedStack keeps
  /// ProfileView alive when another tab is selected, so this is how it notices tab switches.
  final bool isActive;

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late final _viewModel = ProfileViewModel(
    repository: widget.profileRepository,
    specialtyRepository: widget.specialtyRepository,
    gearRepository: widget.gearRepository,
  );
  final _locationService = LocationService();
  bool _signedIn = false;
  String? _guestLocation;
  final _certificationsKey = GlobalKey();
  bool _specialtiesExpanded = false;

  // Re-checks on app resume too — the session may have expired/been revoked while backgrounded.
  late final _lifecycleListener = AppLifecycleListener(onResume: _refresh);

  @override
  void initState() {
    super.initState();
    widget.authRepository.addListener(_refresh);
    _refresh();
  }

  @override
  void didUpdateWidget(ProfileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Leaving the tab collapses the specialties stack back down, so it doesn't stay
    // expanded (widget state survives IndexedStack) when the user returns later.
    if (oldWidget.isActive && !widget.isActive && _specialtiesExpanded) {
      setState(() => _specialtiesExpanded = false);
    }
  }

  @override
  void dispose() {
    widget.authRepository.removeListener(_refresh);
    _lifecycleListener.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final userId = await widget.authRepository.currentUserId();
    if (!mounted) return;
    setState(() => _signedIn = userId != null);
    if (userId != null) {
      _viewModel.load();
    } else if (_guestLocation == null) {
      _locationService.currentCityCountry().then((loc) {
        if (mounted) setState(() => _guestLocation = loc);
      });
    }
  }

  void _openEditProfile(BuildContext context, Profile profile) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EditProfilePage(viewModel: _viewModel, profile: profile)),
    );
  }

  void _scrollToCertifications() {
    final ctx = _certificationsKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile', style: Theme.of(context).textTheme.headlineSmall)),
      body: !_signedIn
          ? _GuestBody(
              location: _guestLocation,
              onDiveIn: () => LoginSheet.show(
                context,
                authRepository: widget.authRepository,
                profileRepository: widget.profileRepository,
              ),
            )
          : ListenableBuilder(
              listenable: _viewModel,
              builder: (context, _) {
                if (_viewModel.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                final error = _viewModel.error;
                if (error != null) {
                  return Center(child: Text('Error: $error'));
                }

                final profile = _viewModel.profile;
                if (profile == null) {
                  return const SizedBox.shrink();
                }

                return _SignedInBody(
                  profile: profile,
                  viewModel: _viewModel,
                  certificationsKey: _certificationsKey,
                  onEdit: () => _openEditProfile(context, profile),
                  onLevelStatTap: _scrollToCertifications,
                  onDiveOut: widget.authRepository.signOut,
                  specialtiesExpanded: _specialtiesExpanded,
                  onToggleSpecialtiesExpanded: (v) => setState(() => _specialtiesExpanded = v),
                );
              },
            ),
    );
  }
}

class _GuestBody extends StatelessWidget {
  const _GuestBody({required this.location, required this.onDiveIn});

  final String? location;
  final VoidCallback onDiveIn;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    child: Icon(Icons.person, size: 40, color: theme.colorScheme.onSecondaryContainer),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Guest', style: theme.textTheme.titleLarge),
                        if (location != null) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(Icons.location_on_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  location!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(onPressed: onDiveIn, child: const Text('Dive in')),
              ),
            ],
          ),
        ),
        const _SettingsDivider(),
        const _SettingsRow(icon: Icons.info_outline, label: 'About', page: AboutPage()),
        const _SettingsRow(icon: Icons.description_outlined, label: 'Legal', page: LegalPage()),
      ],
    );
  }
}

class _SignedInBody extends StatelessWidget {
  const _SignedInBody({
    required this.profile,
    required this.viewModel,
    required this.certificationsKey,
    required this.onEdit,
    required this.onLevelStatTap,
    required this.onDiveOut,
    required this.specialtiesExpanded,
    required this.onToggleSpecialtiesExpanded,
  });

  final Profile profile;
  final ProfileViewModel viewModel;
  final GlobalKey certificationsKey;
  final VoidCallback onEdit;
  final VoidCallback onLevelStatTap;
  final Future<void> Function() onDiveOut;
  final bool specialtiesExpanded;
  final ValueChanged<bool> onToggleSpecialtiesExpanded;

  bool get _hasLevel => profile.certificationLevel?.isNotEmpty ?? false;

  void _openUpdateLevelSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => UpdateLevelSheet(
        viewModel: viewModel,
        initialLevel: profile.certificationLevel,
        initialAgency: profile.certificationAgency,
        initialNumber: profile.certificationNumber,
      ),
    );
  }

  void _openAddSpecialtySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => AddSpecialtySheet(viewModel: viewModel),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = (profile.displayName?.isNotEmpty ?? false) ? profile.displayName! : 'Diver';

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    backgroundImage: (profile.avatarUrl?.isNotEmpty ?? false)
                        ? NetworkImage(profile.avatarUrl!)
                        : null,
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
                              Expanded(
                                child: Text(
                                  profile.location!,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              if (profile.bio?.isNotEmpty ?? false) ...[
                const SizedBox(height: 24),
                InputDecorator(
                  decoration: const InputDecoration(labelText: 'Bio'),
                  child: SizedBox(
                    height: 60,
                    child: SingleChildScrollView(
                      child: Text(profile.bio!, style: theme.textTheme.bodyMedium),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _StatCard(value: '${profile.diveCount}', label: 'Dives')),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      value: _hasLevel ? profile.certificationLevel! : 'Add certificate',
                      label: 'Level',
                      onTap: _hasLevel ? null : onLevelStatTap,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _InfoRow(label: 'Languages', value: profile.languages.isNotEmpty ? profile.languages : '—'),
                    const Divider(height: 1),
                    _InfoRow(label: 'Member since', value: '${profile.memberSince.year}'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: const Text('Edit profile'),
              ),
              const SizedBox(height: 24),
              DashedDivider(key: certificationsKey),
              const SizedBox(height: 16),
              Text('Certifications', style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              _SubHeader(
                title: 'Level',
                trailing: _hasLevel
                    ? TextButton(onPressed: () => _openUpdateLevelSheet(context), child: const Text('Update'))
                    : null,
              ),
              _hasLevel
                  ? LevelCard(
                      level: profile.certificationLevel!,
                      agency: profile.certificationAgency,
                      number: profile.certificationNumber,
                      verified: profile.certificationVerified,
                    )
                  : AddLevelCard(onTap: () => _openUpdateLevelSheet(context)),
              const SizedBox(height: 20),
              _SubHeader(
                title: 'Specialties',
                trailing: viewModel.specialties.isNotEmpty
                    ? IconButton(
                        onPressed: () => _openAddSpecialtySheet(context),
                        icon: const Icon(Icons.add_circle_outline),
                        visualDensity: VisualDensity.compact,
                      )
                    : null,
              ),
              SpecialtiesSection(
                specialties: viewModel.specialties,
                expanded: specialtiesExpanded,
                onToggle: onToggleSpecialtiesExpanded,
                onAdd: () => _openAddSpecialtySheet(context),
                onRemove: viewModel.removeSpecialty,
              ),
              const SizedBox(height: 24),
              const DashedDivider(),
              const SizedBox(height: 16),
              Text('Gear', style: theme.textTheme.titleMedium),
              const SizedBox(height: 16),
              GearSummaryCard(
                gear: viewModel.gear,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => GearLockerPage(viewModel: viewModel)),
                ),
              ),
            ],
          ),
        ),
        const _SettingsDivider(),
        const _SettingsRow(
          icon: Icons.notifications_outlined,
          label: 'Notifications',
          page: NotificationsSettingsPage(),
        ),
        const _SettingsRow(icon: Icons.info_outline, label: 'About', page: AboutPage()),
        const _SettingsRow(icon: Icons.description_outlined, label: 'Legal', page: LegalPage()),
        const Divider(height: 32),
        _DiveOutRow(onDiveOut: onDiveOut),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Visual break between the profile card and the settings-style rows below it —
/// wider gap plus a full-width divider, rather than just another spaced-out card.
class _SettingsDivider extends StatelessWidget {
  const _SettingsDivider();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(height: 16),
        DashedDivider(),
        SizedBox(height: 8),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.icon, required this.label, required this.page});

  final IconData icon;
  final String label;
  final Widget page;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.onSurfaceVariant),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => page)),
    );
  }
}

/// Deliberately plain/unobtrusive — a diver signing out isn't a destructive action, so it
/// doesn't get the alarm treatment a real "delete" action would.
class _DiveOutRow extends StatelessWidget {
  const _DiveOutRow({required this.onDiveOut});

  final Future<void> Function() onDiveOut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(Icons.logout, color: theme.colorScheme.onSurfaceVariant),
      title: Text('Dive out', style: TextStyle(color: theme.colorScheme.onSurfaceVariant)),
      onTap: onDiveOut,
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.value, required this.label, this.onTap});

  final String value;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: onTap != null
                  ? theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600)
                  : theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            Text(label, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

/// Sub-section label inside Certifications (Level/Specialties) — an optional trailing
/// action ("Update" text button or "+" icon), same idea as the compact quick-action
/// pattern used in Explore's header.
class _SubHeader extends StatelessWidget {
  const _SubHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: theme.textTheme.labelLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          if (trailing != null) trailing!,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
