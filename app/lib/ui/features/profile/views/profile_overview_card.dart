import 'package:flutter/material.dart';

import '../../../../domain/entities/profile.dart';

/// Shared Overview block (avatar/name/location, bio, dive count + level stats,
/// languages/member-since) — used both for the diver's own Profile screen and for
/// viewing another diver's public profile (organizer/participant taps).
///
/// [onEditProfile] null hides the Edit button (public view). [onLevelStatTap] null makes
/// the Level tile non-interactive — an empty level then just shows "—" instead of the
/// owner-only "Add certificate" prompt, since that CTA makes no sense on someone else's profile.
class ProfileOverviewCard extends StatelessWidget {
  const ProfileOverviewCard({
    super.key,
    required this.profile,
    this.onEditProfile,
    this.onLevelStatTap,
  });

  final Profile profile;
  final VoidCallback? onEditProfile;
  final VoidCallback? onLevelStatTap;

  bool get _hasLevel => profile.certificationLevel?.isNotEmpty ?? false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = (profile.displayName?.isNotEmpty ?? false) ? profile.displayName! : 'Diver';

    return Column(
      children: [
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
                        Expanded(
                          child: Text(
                            profile.location!,
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
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
              child: SingleChildScrollView(child: Text(profile.bio!, style: theme.textTheme.bodyMedium)),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: ProfileStatCard(value: '${profile.diveCount}', label: 'Dives')),
            const SizedBox(width: 12),
            Expanded(
              child: ProfileStatCard(
                value: _hasLevel ? profile.certificationLevel! : (onLevelStatTap != null ? 'Add certificate' : '—'),
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
              ProfileInfoRow(label: 'Languages', value: profile.languages.isNotEmpty ? profile.languages : '—'),
              const Divider(height: 1),
              ProfileInfoRow(label: 'Member since', value: '${profile.memberSince.year}'),
            ],
          ),
        ),
        if (onEditProfile != null) ...[
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: onEditProfile,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit profile'),
          ),
        ],
      ],
    );
  }
}

class ProfileStatCard extends StatelessWidget {
  const ProfileStatCard({super.key, required this.value, required this.label, this.onTap});

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

class ProfileInfoRow extends StatelessWidget {
  const ProfileInfoRow({super.key, required this.label, required this.value});

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
