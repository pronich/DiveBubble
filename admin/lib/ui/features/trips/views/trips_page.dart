import 'package:flutter/material.dart';

import '../../../../data/repositories/trip_repository.dart';
import '../../../../domain/entities/trip.dart';
import '../../../core/formatting/date_format.dart';
import '../view_models/trips_view_model.dart';
import 'create_trip_page.dart';

enum _TripFilter { all, upcoming, past }

/// Body-only (no Scaffold/AppBar of its own) — embedded as one of AdminShell's sections.
/// Formerly DashboardPage/DashboardViewModel — renamed once this became specifically the
/// Trips section of a multi-section shell rather than the app's only screen.
class TripsPage extends StatefulWidget {
  const TripsPage({super.key, required this.tripRepository, required this.diveCenterId});

  final TripRepository tripRepository;
  final String diveCenterId;

  @override
  State<TripsPage> createState() => _TripsPageState();
}

class _TripsPageState extends State<TripsPage> {
  late final _viewModel = TripsViewModel(repository: widget.tripRepository, diveCenterId: widget.diveCenterId);
  _TripFilter _filter = _TripFilter.all;

  @override
  void initState() {
    super.initState();
    _viewModel.load();
  }

  Future<void> _openCreateTrip() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => CreateTripPage(tripRepository: widget.tripRepository, diveCenterId: widget.diveCenterId),
    );
    if (created == true) _viewModel.load();
  }

  Future<void> _openEditTrip(Trip trip) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => CreateTripPage(
        tripRepository: widget.tripRepository,
        diveCenterId: widget.diveCenterId,
        existingTrip: trip,
      ),
    );
    if (saved == true) _viewModel.load();
  }

  List<Trip> _filtered(List<Trip> trips) {
    final now = DateTime.now();
    switch (_filter) {
      case _TripFilter.all:
        return trips;
      case _TripFilter.upcoming:
        return trips.where((t) => t.bookingStatus != 'cancelled' && t.startTime.isAfter(now)).toList();
      case _TripFilter.past:
        return trips.where((t) => t.startTime.isBefore(now)).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final trips = _filtered(_viewModel.trips);
        return RefreshIndicator(
          onRefresh: _viewModel.load,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                            'ACTIVE TRIPS',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('Trips', style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            'Create, publish, and coordinate every dive your team runs.',
                            style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _openCreateTrip,
                      icon: const Icon(Icons.add),
                      label: const Text('New trip'),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Divider(color: theme.colorScheme.outlineVariant),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _FilterPill(label: 'All', selected: _filter == _TripFilter.all, onTap: () => setState(() => _filter = _TripFilter.all)),
                    const SizedBox(width: 8),
                    _FilterPill(
                      label: 'Upcoming',
                      selected: _filter == _TripFilter.upcoming,
                      onTap: () => setState(() => _filter = _TripFilter.upcoming),
                    ),
                    const SizedBox(width: 8),
                    _FilterPill(label: 'Past', selected: _filter == _TripFilter.past, onTap: () => setState(() => _filter = _TripFilter.past)),
                  ],
                ),
                const SizedBox(height: 24),
                if (_viewModel.isLoading)
                  const Padding(padding: EdgeInsets.only(top: 40), child: Center(child: CircularProgressIndicator()))
                else if (_viewModel.error != null)
                  Text('Error: ${_viewModel.error}', style: TextStyle(color: theme.colorScheme.error))
                else if (trips.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40),
                    child: Text(
                      _viewModel.trips.isEmpty ? 'No trips yet — create your first one.' : 'No trips in this filter.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const spacing = 24.0;
                      final twoColumns = constraints.maxWidth >= 900;
                      final cardWidth = twoColumns ? (constraints.maxWidth - spacing) / 2 : constraints.maxWidth;
                      return Wrap(
                        spacing: spacing,
                        runSpacing: spacing,
                        children: [
                          for (final trip in trips)
                            SizedBox(width: cardWidth, child: _TripCard(trip: trip, onManage: () => _openEditTrip(trip))),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: selected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip, required this.onManage});

  final Trip trip;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final priceMinor = trip.priceMinor;
    final photoUrl = trip.photoUrl;
    final cancelled = trip.bookingStatus == 'cancelled';

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: onManage,
        child: Container(
          decoration: BoxDecoration(border: Border.all(color: theme.colorScheme.outlineVariant)),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 140,
                  child: photoUrl != null
                      ? Image.network(photoUrl, fit: BoxFit.cover)
                      : Container(
                          color: theme.colorScheme.primaryContainer,
                          child: Icon(Icons.image_outlined, color: theme.colorScheme.onPrimaryContainer),
                        ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            _Badge(
                              text: cancelled ? 'Cancelled' : (trip.minCertification ?? 'Open to all'),
                              color: cancelled ? theme.colorScheme.errorContainer : theme.colorScheme.secondaryContainer,
                              onColor: cancelled ? theme.colorScheme.onErrorContainer : theme.colorScheme.onSecondaryContainer,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          trip.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(Icons.location_on_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(trip.location, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                            const SizedBox(width: 12),
                            Icon(Icons.calendar_today_outlined, size: 14, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              formatShortDate(trip.startTime),
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.people_outline, size: 14, color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 4),
                            Text(
                              trip.maxParticipants != null
                                  ? '${trip.participantCount}/${trip.maxParticipants} booked'
                                  : '${trip.participantCount} booked',
                              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            priceMinor != null
                                ? Text(
                                    '${formatPriceMinor(priceMinor)} ${trip.currency}',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  )
                                : Text(
                                    'No price',
                                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                  ),
                            TextButton.icon(
                              onPressed: onManage,
                              icon: const Icon(Icons.arrow_forward, size: 16),
                              label: const Text('Manage'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color, required this.onColor});

  final String text;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(color: onColor, fontWeight: FontWeight.bold),
      ),
    );
  }
}
