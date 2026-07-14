import 'package:flutter/material.dart';

import '../../../../domain/entities/trip.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/theme/app_gradients.dart';
import '../view_models/trip_view_model.dart';

class TripPage extends StatefulWidget {
  const TripPage({super.key, required this.viewModel});

  final TripViewModel viewModel;

  @override
  State<TripPage> createState() => _TripPageState();
}

class _TripPageState extends State<TripPage> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          if (widget.viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final error = widget.viewModel.error;
          if (error != null) {
            return Center(child: Text('Error: $error'));
          }

          final trip = widget.viewModel.trip;
          if (trip == null) {
            return const SizedBox.shrink();
          }

          final theme = Theme.of(context);
          final isOrganizer = trip.creatorUserId == widget.viewModel.currentUserId;

          return ListView(
            padding: EdgeInsets.zero,
            children: [
              AspectRatio(
                aspectRatio: 4 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(AppAssets.tripPlaceholder, fit: BoxFit.cover),
                    const DecoratedBox(
                      decoration: BoxDecoration(gradient: AppGradients.imageScrim),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.title, style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(trip.location, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          formatDateRange(trip.startTime, trip.endDate),
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text('MEETING POINT', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    const SizedBox(height: 2),
                    Text(
                      '${formatTime(trip.startTime)} · ${trip.meetingPoint ?? trip.location}',
                      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 16),
                    _InfoGrid(trip: trip),
                    if (trip.description != null) ...[
                      const SizedBox(height: 20),
                      Text('About this dive', style: theme.textTheme.labelLarge),
                      const SizedBox(height: 6),
                      Text(trip.description!, style: theme.textTheme.bodyMedium),
                    ],
                    const SizedBox(height: 20),
                    _OrganizerCard(isOrganizer: isOrganizer),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.groups_outlined, size: 16, color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          _participantsText(trip),
                          style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _JoinButton(trip: trip, viewModel: widget.viewModel),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _participantsText(Trip trip) {
    final count = trip.participantCount;
    final people = count == 1 ? 'person' : 'people';
    if (trip.maxParticipants != null) {
      return '$count $people out of ${trip.maxParticipants} joined';
    }
    return '$count $people joined';
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      _InfoTile(icon: Icons.badge_outlined, label: 'LEVEL', value: trip.minCertification ?? 'Open to all'),
      if (_depthText(trip) != null) _InfoTile(icon: Icons.south, label: 'DEPTH', value: _depthText(trip)!),
      if (_diveCountText(trip) != null) _InfoTile(icon: Icons.scuba_diving_outlined, label: 'DIVES', value: _diveCountText(trip)!),
      _InfoTile(icon: Icons.schedule, label: 'DURATION', value: _durationText(trip)),
    ];

    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 10));
      final second = i + 1 < tiles.length ? tiles[i + 1] : const SizedBox.shrink();
      rows.add(Row(
        children: [
          Expanded(child: tiles[i]),
          const SizedBox(width: 10),
          Expanded(child: second),
        ],
      ));
    }

    return Column(children: rows);
  }

  static String? _depthText(Trip trip) {
    final min = trip.depthMinM;
    final max = trip.depthMaxM;
    if (min == null && max == null) return null;
    if (min != null && max != null) {
      if (min == max) return '$min m';
      return '$min–$max m';
    }
    if (max != null) return 'Up to $max m';
    return '$min+ m';
  }

  static String? _diveCountText(Trip trip) {
    final min = trip.diveCountMin;
    final max = trip.diveCountMax;
    if (min == null && max == null) return null;
    if (min != null && max != null) {
      if (min == max) return min == 1 ? '1 dive' : '$min dives';
      return '$min–$max dives';
    }
    if (max != null) return 'Up to $max dives';
    return '$min+ dives';
  }

  static String _durationText(Trip trip) {
    final end = trip.endDate;
    if (end == null) return '1 day';
    final start = trip.startTime.toLocal();
    final endLocal = end.toLocal();
    final startDate = DateTime(start.year, start.month, start.day);
    final endDateOnly = DateTime(endLocal.year, endLocal.month, endLocal.day);
    final days = endDateOnly.difference(startDate).inDays + 1;
    return days == 1 ? '1 day' : '$days days';
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 4),
              Text(label, style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

class _OrganizerCard extends StatelessWidget {
  const _OrganizerCard({required this.isOrganizer});

  final bool isOrganizer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.secondaryContainer,
            child: Icon(Icons.person, color: theme.colorScheme.onSecondaryContainer),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Organizer', style: theme.textTheme.bodyMedium),
              // Display name isn't modeled yet — see Profile in the feature backlog.
              if (isOrganizer)
                Text('(You)', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

class _JoinButton extends StatelessWidget {
  const _JoinButton({required this.trip, required this.viewModel});

  final Trip trip;
  final TripViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    if (trip.joined) {
      return const Chip(label: Text('Joined'));
    }

    if (trip.bookingStatus == 'cancelled') {
      return const Chip(label: Text('Trip cancelled'));
    }
    if (trip.bookingStatus == 'full') {
      return const Chip(label: Text('Trip full'));
    }

    return ElevatedButton(
      onPressed: viewModel.isJoining ? null : viewModel.join,
      child: viewModel.isJoining
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Join'),
    );
  }
}
