import 'package:flutter/material.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/gear_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/push_repository.dart';
import '../../../../data/repositories/specialty_repository.dart';
import '../../../../data/services/location_service.dart';
import '../../../../domain/certification_level.dart';
import '../../../../domain/entities/profile.dart';
import '../../../core/widgets/dashed_divider.dart';
import '../../../core/widgets/pick_image.dart';
import '../../onboarding/views/login_sheet.dart';
import '../view_models/profile_view_model.dart';
import 'about_page.dart';
import 'add_specialty_sheet.dart';
import 'blocked_users_page.dart';
import 'edit_profile_page.dart';
import 'gear_locker_page.dart';
import 'gear_summary_card.dart';
import 'legal_page.dart';
import 'level_card.dart';
import 'notifications_settings_page.dart';
import 'profile_overview_card.dart';
import 'specialties_section.dart';
import 'update_level_sheet.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({
    super.key,
    required this.authRepository,
    required this.profileRepository,
    required this.specialtyRepository,
    required this.gearRepository,
    required this.pushRepository,
    required this.isActive,
  });

  final AuthRepository authRepository;
  final ProfileRepository profileRepository;
  final SpecialtyRepository specialtyRepository;
  final GearRepository gearRepository;
  final PushRepository pushRepository;

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
              onDiveIn: () async {
                // notifyListeners() (and thus _refresh, via the authRepository listener
                // above) fires the moment sign-in itself completes — before LoginSheet's
                // own onboarding chain (location/push/certificates) has written anything.
                // Awaiting here and reloading once the whole sheet closes is what actually
                // picks up the fully-onboarded profile, instead of the early, still-mostly-
                // empty snapshot from right after sign-in.
                final signedIn = await LoginSheet.show(
                  context,
                  authRepository: widget.authRepository,
                  profileRepository: widget.profileRepository,
                  pushRepository: widget.pushRepository,
                );
                if (signedIn) _refresh();
              },
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
                  onDeleteAccount: widget.authRepository.deleteAccount,
                  specialtiesExpanded: _specialtiesExpanded,
                  onToggleSpecialtiesExpanded: (v) => setState(() => _specialtiesExpanded = v),
                  pushRepository: widget.pushRepository,
                  profileRepository: widget.profileRepository,
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
    required this.onDeleteAccount,
    required this.specialtiesExpanded,
    required this.onToggleSpecialtiesExpanded,
    required this.pushRepository,
    required this.profileRepository,
  });

  final Profile profile;
  final ProfileViewModel viewModel;
  final GlobalKey certificationsKey;
  final VoidCallback onEdit;
  final VoidCallback onLevelStatTap;
  final Future<void> Function() onDiveOut;
  final Future<void> Function() onDeleteAccount;
  final bool specialtiesExpanded;
  final ValueChanged<bool> onToggleSpecialtiesExpanded;
  final PushRepository pushRepository;
  final ProfileRepository profileRepository;

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

  Future<void> _pickAndUploadAvatar(BuildContext context) async {
    final filePath = await pickImage(context);
    if (filePath == null || !context.mounted) return;

    final ok = await viewModel.uploadAvatar(filePath);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(viewModel.error ?? 'Could not upload photo')));
    }
  }

  Future<void> _removeAvatar(BuildContext context) async {
    final ok = await viewModel.removeAvatar();
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(viewModel.error ?? 'Could not remove photo')));
    }
  }

  // "Look at it vs change it" separation — same precedent CardPhotoPicker uses for
  // cert/specialty photos — rather than jumping straight into the image picker on tap.
  Future<void> _showAvatarOptions(BuildContext context) async {
    final hasAvatar = profile.avatarUrl?.isNotEmpty ?? false;
    await showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Change photo'),
              onTap: () {
                Navigator.of(sheetContext).pop();
                _pickAndUploadAvatar(context);
              },
            ),
            if (hasAvatar)
              ListTile(
                leading: Icon(Icons.delete_outline, color: Theme.of(sheetContext).colorScheme.error),
                title: Text('Remove photo', style: TextStyle(color: Theme.of(sheetContext).colorScheme.error)),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _removeAvatar(context);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadCertificationPhoto(BuildContext context) async {
    final filePath = await pickImage(context);
    if (filePath == null || !context.mounted) return;

    final ok = await viewModel.uploadCertificationPhoto(filePath);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(viewModel.error ?? 'Could not upload photo')));
    }
  }

  Future<void> _pickAndUploadSpecialtyPhoto(BuildContext context, String id) async {
    final filePath = await pickImage(context);
    if (filePath == null || !context.mounted) return;

    final ok = await viewModel.uploadSpecialtyPhoto(id, filePath);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(viewModel.error ?? 'Could not upload photo')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ProfileOverviewCard(
                profile: profile,
                onEditProfile: onEdit,
                onLevelStatTap: onLevelStatTap,
                onAvatarTap: () => _showAvatarOptions(context),
                isUploadingAvatar: viewModel.isUploadingPhoto,
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
                      level: certificationLevelAbbreviation(profile.certificationLevel),
                      agency: profile.certificationAgency,
                      number: profile.certificationNumber,
                      verified: profile.certificationVerified,
                      photoUrl: profile.certificationPhotoUrl,
                      onPhotoTap: () => _pickAndUploadCertificationPhoto(context),
                      isUploadingPhoto: viewModel.isUploadingPhoto,
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
                onPhotoTap: (id) => _pickAndUploadSpecialtyPhoto(context, id),
                uploadingPhotoId: viewModel.uploadingSpecialtyId,
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
        _SettingsRow(
          icon: Icons.notifications_outlined,
          label: 'Notifications',
          page: NotificationsSettingsPage(pushRepository: pushRepository),
        ),
        _SettingsRow(icon: Icons.block, label: 'Blocked users', page: BlockedUsersPage(profileRepository: profileRepository)),
        const _SettingsRow(icon: Icons.info_outline, label: 'About', page: AboutPage()),
        const _SettingsRow(icon: Icons.description_outlined, label: 'Legal', page: LegalPage()),
        const Divider(height: 32),
        _DiveOutRow(onDiveOut: onDiveOut),
        _DeleteAccountRow(onDeleteAccount: onDeleteAccount),
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

/// Destructive styling (theme.colorScheme.error), unlike _DiveOutRow's deliberately muted
/// treatment — this is permanent and affects trips the diver organized, so it earns the
/// alarm treatment sign-out doesn't get.
class _DeleteAccountRow extends StatefulWidget {
  const _DeleteAccountRow({required this.onDeleteAccount});

  final Future<void> Function() onDeleteAccount;

  @override
  State<_DeleteAccountRow> createState() => _DeleteAccountRowState();
}

class _DeleteAccountRowState extends State<_DeleteAccountRow> {
  bool _isDeleting = false;

  Future<void> _confirmAndDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This permanently anonymizes your account and cancels any trips you organize. '
          "This can't be undone.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await widget.onDeleteAccount();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not delete account: $e')));
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: _isDeleting
          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
          : Icon(Icons.delete_outline, color: theme.colorScheme.error),
      title: Text('Delete account', style: TextStyle(color: theme.colorScheme.error)),
      onTap: _isDeleting ? null : _confirmAndDelete,
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

