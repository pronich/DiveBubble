import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../data/repositories/trip_repository.dart';
import '../../../../domain/certification_level.dart';
import '../../../../domain/entities/trip.dart';
import '../../../core/formatting/date_format.dart';
import 'create_trip_page.dart';

/// "Manage" now pushes here instead of opening the edit form directly — a real page (not a
/// popup), reachable from TripsPage's card, showing everything about the trip with an Edit
/// button that opens CreateTripPage's popup for actual field changes. Same icon set as
/// app/'s Trip Page info grid (badge_outlined/waves/scuba_diving_outlined/schedule) for
/// visual consistency between the two clients.
class TripDetailPage extends StatefulWidget {
  const TripDetailPage({
    super.key,
    required this.trip,
    required this.tripRepository,
    required this.diveCenterId,
    required this.onDiveIntoBubble,
  });

  final Trip trip;
  final TripRepository tripRepository;
  final String diveCenterId;

  // Threaded from AdminShell (via TripsPage) — pops this page and switches AdminShell to
  // the Bubbles tab with this trip's conversation already selected.
  final ValueChanged<String> onDiveIntoBubble;

  @override
  State<TripDetailPage> createState() => _TripDetailPageState();
}

class _TripDetailPageState extends State<TripDetailPage> {
  late Trip _trip = widget.trip;

  Future<void> _openEdit() async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => CreateTripPage(
        tripRepository: widget.tripRepository,
        diveCenterId: widget.diveCenterId,
        existingTrip: _trip,
      ),
    );
    if (saved != true) return;
    final refreshed = await widget.tripRepository.getMyTrips();
    Trip? updated;
    for (final t in refreshed) {
      if (t.id == _trip.id) {
        updated = t;
        break;
      }
    }
    final u = updated;
    if (u != null && mounted) setState(() => _trip = u);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trip = _trip;
    final cancelled = trip.bookingStatus == 'cancelled';

    return Scaffold(
      appBar: AppBar(
        title: Text(trip.title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                widget.onDiveIntoBubble(trip.id);
              },
              icon: const Icon(Icons.bubble_chart_outlined),
              label: const Text('Dive into Bubble'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: OutlinedButton.icon(onPressed: _openEdit, icon: const Icon(Icons.edit_outlined), label: const Text('Edit')),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: trip.photoUrl != null
                      ? Image.network(trip.photoUrl!, fit: BoxFit.cover)
                      : Container(
                          color: theme.colorScheme.primaryContainer,
                          child: Icon(Icons.image_outlined, size: 40, color: theme.colorScheme.onPrimaryContainer),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(trip.title, style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  if (cancelled)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: theme.colorScheme.errorContainer, borderRadius: BorderRadius.circular(12)),
                      child: Text('Cancelled', style: TextStyle(color: theme.colorScheme.onErrorContainer, fontWeight: FontWeight.bold)),
                    )
                  else if (trip.priceMinor != null)
                    Text(
                      '${formatPriceMinor(trip.priceMinor!)} ${trip.currency}',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(trip.location, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(width: 16),
                  Icon(Icons.calendar_today_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Text(formatShortDate(trip.startTime), style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
              const SizedBox(height: 20),
              _InfoGrid(trip: trip),
              if (trip.diveCenterId != null) ...[
                const SizedBox(height: 20),
                _BookingCodeCard(trip: trip),
              ],
              if (trip.meetingPoint?.isNotEmpty ?? false) ...[
                const SizedBox(height: 20),
                Text('Meeting point', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(trip.meetingPoint!),
              ],
              if (trip.description?.isNotEmpty ?? false) ...[
                const SizedBox(height: 20),
                Text('About this dive', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(trip.description!),
              ],
              const SizedBox(height: 20),
              Text(
                trip.maxParticipants != null
                    ? '${trip.participantCount} people out of ${trip.maxParticipants} joined'
                    : '${trip.participantCount} people joined',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      _InfoTile(icon: Icons.badge_outlined, label: 'LEVEL', value: certificationLevelAbbreviation(trip.minCertification)),
      if (trip.depthMinM != null || trip.depthMaxM != null)
        _InfoTile(icon: Icons.waves, label: 'DEPTH', value: _range(trip.depthMinM, trip.depthMaxM, 'm')),
      if (trip.diveCountMin != null || trip.diveCountMax != null)
        _InfoTile(icon: Icons.scuba_diving_outlined, label: 'DIVES', value: _range(trip.diveCountMin, trip.diveCountMax, '')),
      _InfoTile(icon: Icons.schedule, label: 'DURATION', value: _duration(trip)),
    ];
    return Wrap(spacing: 12, runSpacing: 12, children: tiles);
  }

  String _range(int? min, int? max, String unit) {
    if (min != null && max != null) return '$min–$max$unit';
    if (min != null) return '$min+$unit';
    return '${max!}$unit';
  }

  String _duration(Trip trip) {
    final end = trip.endDate;
    if (end == null) return '1d';
    final days = end.difference(trip.startTime).inDays + 1;
    return '${days}d';
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 6),
          Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, letterSpacing: 0.5)),
          Text(value, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

/// Only rendered for business trips (trip.diveCenterId != null) — individual trips never
/// get a booking code (see trip.Service.CreateTrip). This is the whole reason join-by-code
/// exists: a diver pays on bookingUrl, gets this code from the dive center some other way
/// (email, their own site's confirmation), and redeems it back in app/ — we never see the
/// actual transaction.
class _BookingCodeCard extends StatelessWidget {
  const _BookingCodeCard({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final code = trip.bookingCode;
    final url = trip.bookingUrl;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BOOKING CODE',
            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSecondaryContainer, letterSpacing: 0.5),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                code ?? '—',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  fontFamily: 'monospace',
                ),
              ),
              if (code != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Copy code',
                  icon: Icon(Icons.copy, size: 18, color: theme.colorScheme.onSecondaryContainer),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: code));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Booking code copied')));
                  },
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Give this code to divers after they book on your own site — they redeem it in the app to join this trip.',
            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSecondaryContainer.withValues(alpha: 0.85)),
          ),
          if (url != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
              icon: const Icon(Icons.open_in_new, size: 16),
              label: Text(url, overflow: TextOverflow.ellipsis),
            ),
          ],
        ],
      ),
    );
  }
}
