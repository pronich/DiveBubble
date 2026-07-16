import 'package:flutter/material.dart';

import '../../../../data/repositories/trip_repository.dart';
import '../../../../domain/certification_level.dart';
import '../../../../domain/entities/trip.dart';
import '../../../core/formatting/date_format.dart';
import '../view_models/trips_view_model.dart';
import 'create_trip_page.dart';
import 'trip_detail_page.dart';

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
  String _search = '';
  bool _searchExpanded = false;
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

  Future<void> _openManageTrip(Trip trip) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TripDetailPage(trip: trip, tripRepository: widget.tripRepository, diveCenterId: widget.diveCenterId),
      ),
    );
    // The detail page may have edited the trip (price, dates, ...) — reload so the grid
    // reflects it without the diver having to manually refresh.
    _viewModel.load();
  }

  List<Trip> _filtered(List<Trip> trips) {
    final now = DateTime.now();
    var result = switch (_filter) {
      _TripFilter.all => trips,
      _TripFilter.upcoming => trips.where((t) => t.bookingStatus != 'cancelled' && t.startTime.isAfter(now)).toList(),
      _TripFilter.past => trips.where((t) => t.startTime.isBefore(now)).toList(),
    };
    final query = _search.trim().toLowerCase();
    if (query.isNotEmpty) {
      result = result.where((t) => t.title.toLowerCase().contains(query) || t.location.toLowerCase().contains(query)).toList();
    }
    return result;
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
                    const Spacer(),
                    // Collapsed to an icon by default — not worth a permanent input box
                    // for something used rarely (per explicit feedback; Bubbles' own
                    // search stays always-visible since that list grows unbounded faster).
                    if (_searchExpanded)
                      SizedBox(
                        width: 260,
                        height: 40,
                        child: TextField(
                          controller: _searchController,
                          autofocus: true,
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Search trips...',
                            prefixIcon: const Icon(Icons.search, size: 18),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.close, size: 18),
                              onPressed: () => setState(() {
                                _searchExpanded = false;
                                _search = '';
                                _searchController.clear();
                              }),
                            ),
                          ),
                          onChanged: (value) => setState(() => _search = value),
                        ),
                      )
                    else
                      IconButton(
                        tooltip: 'Search trips',
                        icon: const Icon(Icons.search),
                        onPressed: () => setState(() => _searchExpanded = true),
                      ),
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
                  // Single column, thin rows — tried a 2-column card grid first (matching
                  // app/'s Explore) but admin/'s trip fields vary a lot more per trip than a
                  // fixed-aspect-ratio grid can absorb gracefully, so rows ended up uneven
                  // heights. A thin single-line row sidesteps that: every trip's tags share
                  // one scrollable row regardless of how many are present, so every row is
                  // the same height no matter what.
                  Column(
                    children: [
                      for (final trip in trips)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _TripRow(trip: trip, onManage: () => _openManageTrip(trip)),
                        ),
                    ],
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

String _rangeText(int? min, int? max, String unit) {
  if (min != null && max != null) return '$min–$max$unit';
  if (min != null) return '$min+$unit';
  return '${max!}$unit';
}

class _TripRow extends StatelessWidget {
  const _TripRow({required this.trip, required this.onManage});

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
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: onManage,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(border: Border.all(color: theme.colorScheme.outlineVariant)),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: photoUrl != null
                      ? Image.network(photoUrl, fit: BoxFit.cover)
                      : Container(
                          color: theme.colorScheme.primaryContainer,
                          child: Icon(Icons.image_outlined, size: 20, color: theme.colorScheme.onPrimaryContainer),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      trip.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    // One scrollable row rather than a Wrap — keeps every row exactly one
                    // line tall regardless of how many optional fields a given trip has
                    // (see the Column above's own comment on why this replaced the grid).
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      child: Row(
                        children: [
                          _Badge(
                            icon: cancelled ? null : Icons.badge_outlined,
                            text: cancelled ? 'Cancelled' : certificationLevelAbbreviation(trip.minCertification),
                            color: cancelled ? theme.colorScheme.errorContainer : theme.colorScheme.secondaryContainer,
                            onColor: cancelled ? theme.colorScheme.onErrorContainer : theme.colorScheme.onSecondaryContainer,
                          ),
                          const SizedBox(width: 10),
                          _Tag(icon: Icons.location_on_outlined, text: trip.location),
                          const SizedBox(width: 10),
                          _Tag(icon: Icons.calendar_today_outlined, text: formatShortDate(trip.startTime)),
                          const SizedBox(width: 10),
                          _Tag(
                            icon: Icons.people_outline,
                            text: trip.maxParticipants != null
                                ? '${trip.participantCount}/${trip.maxParticipants} booked'
                                : '${trip.participantCount} booked',
                          ),
                          if (trip.depthMinM != null || trip.depthMaxM != null) ...[
                            const SizedBox(width: 10),
                            _Tag(icon: Icons.waves, text: _rangeText(trip.depthMinM, trip.depthMaxM, 'm')),
                          ],
                          if (trip.diveCountMin != null || trip.diveCountMax != null) ...[
                            const SizedBox(width: 10),
                            _Tag(icon: Icons.scuba_diving_outlined, text: _rangeText(trip.diveCountMin, trip.diveCountMax, '')),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  priceMinor != null
                      ? Text(
                          '${formatPriceMinor(priceMinor)} ${trip.currency}',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary),
                        )
                      : Text('No price', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  TextButton.icon(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32)),
                    onPressed: onManage,
                    icon: const Icon(Icons.arrow_forward, size: 14),
                    label: const Text('Manage'),
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

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(text, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({this.icon, required this.text, required this.color, required this.onColor});

  final IconData? icon;
  final String text;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: onColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: onColor, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
