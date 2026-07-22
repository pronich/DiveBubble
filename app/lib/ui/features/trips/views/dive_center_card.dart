import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../domain/entities/dive_center.dart';
import '../../../core/utils/external_url.dart';
import '../../profile/views/profile_overview_card.dart';

/// Same "tap an identity, get a sheet" pattern as showDiverIdCard, but for a business — a
/// dive center's card shows what it collected at onboarding for exactly this purpose (see
/// CLAUDE.md's Business/dive centers section) rather than a diver's Overview. No network
/// fetch needed here (unlike showDiverIdCard) since the caller already has the DiveCenter
/// loaded — TripPage's own organizerDiveCenter.
Future<void> showDiveCenterCard(BuildContext context, DiveCenter diveCenter) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => _DiveCenterCardSheet(diveCenter: diveCenter),
  );
}

class _DiveCenterCardSheet extends StatelessWidget {
  const _DiveCenterCardSheet({required this.diveCenter});

  final DiveCenter diveCenter;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(child: DiveCenterOverviewCard(diveCenter: diveCenter)),
      ),
    );
  }
}

/// Extracted from the sheet above so it could, in principle, be reused elsewhere the way
/// ProfileOverviewCard is (nothing does yet — a dive center has no other detail screen).
class DiveCenterOverviewCard extends StatelessWidget {
  const DiveCenterOverviewCard({super.key, required this.diveCenter});

  final DiveCenter diveCenter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dc = diveCenter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Rounded square, not a circle — the same visual distinction _OrganizerCard's
            // avatar already makes between a business and a person.
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                width: 80,
                height: 80,
                color: theme.colorScheme.secondaryContainer,
                child: (dc.logoUrl?.isNotEmpty ?? false)
                    ? Image.network(
                        dc.logoUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.storefront_outlined, size: 36, color: theme.colorScheme.onSecondaryContainer),
                      )
                    : Icon(Icons.storefront_outlined, size: 36, color: theme.colorScheme.onSecondaryContainer),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dc.name, style: theme.textTheme.titleLarge),
                  Text('Dive center', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  if (dc.location?.isNotEmpty ?? false) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            dc.location!,
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
        if (dc.description?.isNotEmpty ?? false) ...[
          const SizedBox(height: 24),
          InputDecorator(
            decoration: const InputDecoration(labelText: 'About'),
            child: SizedBox(
              height: 60,
              child: SingleChildScrollView(child: Text(dc.description!, style: theme.textTheme.bodyMedium)),
            ),
          ),
        ],
        const SizedBox(height: 20),
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              if (dc.agency?.isNotEmpty ?? false) ...[
                ProfileInfoRow(
                  label: 'Agency',
                  value: (dc.agencyDetail?.isNotEmpty ?? false) ? '${dc.agency} · ${dc.agencyDetail}' : dc.agency!,
                ),
                const Divider(height: 1),
              ],
              ProfileInfoRow(label: 'Languages', value: dc.languages.isNotEmpty ? dc.languages : '—'),
              if (dc.website?.isNotEmpty ?? false) ...[
                const Divider(height: 1),
                _LinkRow(label: 'Website', value: dc.website!, onTap: () => launchUrl(externalUri(dc.website!), mode: LaunchMode.externalApplication)),
              ],
              if (dc.phone?.isNotEmpty ?? false) ...[
                const Divider(height: 1),
                _LinkRow(label: 'Phone', value: dc.phone!, onTap: () => launchUrl(Uri(scheme: 'tel', path: dc.phone!))),
              ],
              if (dc.email?.isNotEmpty ?? false) ...[
                const Divider(height: 1),
                _LinkRow(label: 'Email', value: dc.email!, onTap: () => launchUrl(Uri(scheme: 'mailto', path: dc.email!))),
              ],
              // No "Member since" here — that's when this dive center joined the platform,
              // not how long it's actually operated, and showing it reads as "brand new
              // business" even for an established one. Profile's ProfileInfoRow equivalent
              // is legitimate there (it really is the diver's own membership date), but
              // isn't the same fact for a business — deliberately omitted, not forgotten.
            ],
          ),
        ),
      ],
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.label, required this.value, required this.onTap});

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            Flexible(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600, color: theme.colorScheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
