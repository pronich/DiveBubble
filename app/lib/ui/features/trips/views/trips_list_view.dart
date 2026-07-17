import 'package:flutter/material.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/repositories/dive_center_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/transport_repository.dart';
import '../../../../data/repositories/trip_repository.dart';
import '../../../../data/services/realtime_service.dart';
import '../../../../domain/certification_level.dart';
import '../../../../domain/entities/trip.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/auth/ensure_signed_in.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../view_models/create_trip_view_model.dart';
import '../view_models/trip_view_model.dart';
import '../view_models/trips_list_view_model.dart';
import 'create_trip_page.dart';
import 'join_by_code_dialog.dart';
import 'trip_page.dart';

class TripsListView extends StatefulWidget {
  const TripsListView({
    super.key,
    required this.viewModel,
    required this.tripRepository,
    required this.chatRepository,
    required this.transportRepository,
    required this.realtimeService,
    required this.authRepository,
    required this.profileRepository,
    required this.diveCenterRepository,
    required this.currentUserId,
  });

  final TripsListViewModel viewModel;
  final TripRepository tripRepository;
  final ChatRepository chatRepository;
  final TransportRepository transportRepository;
  final RealtimeService realtimeService;
  final AuthRepository authRepository;
  final ProfileRepository profileRepository;
  final DiveCenterRepository diveCenterRepository;
  final String currentUserId;

  @override
  State<TripsListView> createState() => _TripsListViewState();
}

class _TripsListViewState extends State<TripsListView> {
  bool _isScrolled = false;

  // Refetches on auth change (e.g. logging in via another screen's gate personalizes "joined")
  // and on app resume — data may be stale after the app sat backgrounded for a while.
  late final _lifecycleListener = AppLifecycleListener(onResume: widget.viewModel.loadTrips);

  @override
  void initState() {
    super.initState();
    widget.viewModel.loadTrips();
    widget.authRepository.addListener(_onAuthChanged);
  }

  @override
  void dispose() {
    widget.authRepository.removeListener(_onAuthChanged);
    _lifecycleListener.dispose();
    super.dispose();
  }

  void _onAuthChanged() => widget.viewModel.loadTrips();

  bool _handleScroll(ScrollNotification notification) {
    final isScrolled = notification.metrics.pixels > 0;
    if (isScrolled != _isScrolled) {
      setState(() => _isScrolled = isScrolled);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _ExploreHeader(
              viewModel: widget.viewModel,
              onCreateTrip: () => _openCreateTrip(context),
              onJoinByCode: () => _openJoinByCode(context),
              showShadow: _isScrolled,
            ),
            Expanded(
              child: NotificationListener<ScrollNotification>(
                onNotification: _handleScroll,
                child: ListenableBuilder(
                  listenable: widget.viewModel,
                  builder: (context, _) {
                    if (widget.viewModel.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final error = widget.viewModel.error;
                    if (error != null) {
                      return Center(child: Text('Error: $error'));
                    }

                    final trips = widget.viewModel.trips;
                    if (trips.isEmpty && widget.viewModel.hasActiveFilters) {
                      return EmptyStateView(
                        icon: Icons.search_off,
                        title: 'No trips match your search',
                        subtitle: 'Try a different search term or clear your filters.',
                        ctaLabel: 'Clear filters',
                        onCtaPressed: widget.viewModel.clearFilters,
                      );
                    }
                    if (trips.isEmpty) {
                      return EmptyStateView(
                        icon: Icons.scuba_diving_outlined,
                        title: 'Be the first to dive in',
                        subtitle: 'Start something new — create a trip and invite others to join.',
                        ctaLabel: 'Create trip',
                        onCtaPressed: () => _openCreateTrip(context),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: widget.viewModel.loadTrips,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          const spacing = 12.0;
                          const horizontalPadding = 16.0;
                          const textBlockHeight =
                              64.0; // title (1 line) + location + 2 fixed badge rows + paddings, kept fixed so the grid's childAspectRatio is predictable
                          final cardWidth =
                              (constraints.maxWidth -
                                  horizontalPadding * 2 -
                                  spacing) /
                              2;
                          final aspectRatio =
                              cardWidth / (cardWidth + textBlockHeight);

                          return GridView.builder(
                            padding: const EdgeInsets.fromLTRB(
                              horizontalPadding,
                              8,
                              horizontalPadding,
                              8,
                            ),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: spacing,
                                  mainAxisSpacing: spacing,
                                  childAspectRatio: aspectRatio,
                                ),
                            itemCount: trips.length,
                            itemBuilder: (context, index) => _TripCard(
                              trip: trips[index],
                              onTap: () => _openTrip(context, trips[index]),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openTrip(BuildContext context, Trip trip) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TripPage(
          viewModel: TripViewModel(
            repository: widget.tripRepository,
            authRepository: widget.authRepository,
            profileRepository: widget.profileRepository,
            diveCenterRepository: widget.diveCenterRepository,
            tripId: trip.id,
            currentUserId: widget.currentUserId,
          ),
          tripRepository: widget.tripRepository,
          chatRepository: widget.chatRepository,
          transportRepository: widget.transportRepository,
          realtimeService: widget.realtimeService,
          diveCenterRepository: widget.diveCenterRepository,
        ),
      ),
    );
  }

  Future<void> _openCreateTrip(BuildContext context) async {
    final userId = await ensureSignedIn(context, widget.authRepository, widget.profileRepository);
    if (userId == null || !context.mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateTripPage(
          viewModel: CreateTripViewModel(repository: widget.tripRepository),
          onCreated: (trip) {
            widget.viewModel.loadTrips();
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => TripPage(
                  viewModel: TripViewModel(
                    repository: widget.tripRepository,
                    authRepository: widget.authRepository,
                    profileRepository: widget.profileRepository,
                    diveCenterRepository: widget.diveCenterRepository,
                    tripId: trip.id,
                    currentUserId: userId,
                  ),
                  tripRepository: widget.tripRepository,
                  chatRepository: widget.chatRepository,
                  transportRepository: widget.transportRepository,
                  realtimeService: widget.realtimeService,
                  diveCenterRepository: widget.diveCenterRepository,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _openJoinByCode(BuildContext context) async {
    final userId = await ensureSignedIn(context, widget.authRepository, widget.profileRepository);
    if (userId == null || !context.mounted) return;

    final trip = await showJoinByCodeDialog(context, widget.tripRepository);
    if (trip == null || !context.mounted) return;

    widget.viewModel.loadTrips();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TripPage(
          viewModel: TripViewModel(
            repository: widget.tripRepository,
            authRepository: widget.authRepository,
            profileRepository: widget.profileRepository,
            diveCenterRepository: widget.diveCenterRepository,
            tripId: trip.id,
            currentUserId: userId,
          ),
          tripRepository: widget.tripRepository,
          chatRepository: widget.chatRepository,
          transportRepository: widget.transportRepository,
          realtimeService: widget.realtimeService,
          diveCenterRepository: widget.diveCenterRepository,
        ),
      ),
    );
  }
}

// The two quick actions below deliberately reuse the calm FilledButton (light-fill) theme
// rather than the bold primary ElevatedButton style, since Create/Join are secondary entry
// points most divers will ignore in favor of just browsing, the same way Airbnb's category
// chips stay quiet under its search bar. Search expands inline, directly below the search
// field, staying pinned at the top of the screen — Airbnb's "Where?" panel pattern — rather
// than sliding up as a bottom sheet; the trip grid below just gets shorter while it's open.
class _ExploreHeader extends StatefulWidget {
  const _ExploreHeader({
    required this.viewModel,
    required this.onCreateTrip,
    required this.onJoinByCode,
    required this.showShadow,
  });

  final TripsListViewModel viewModel;
  final VoidCallback onCreateTrip;
  final VoidCallback onJoinByCode;
  final bool showShadow;

  @override
  State<_ExploreHeader> createState() => _ExploreHeaderState();
}

class _ExploreHeaderState extends State<_ExploreHeader> {
  bool _filtersOpen = false;
  late final _queryController = TextEditingController(text: widget.viewModel.query);
  late SortMode _sortMode = widget.viewModel.sortMode;
  final _queryFocusNode = FocusNode();

  @override
  void dispose() {
    _queryController.dispose();
    _queryFocusNode.dispose();
    super.dispose();
  }

  void _openFilters() {
    setState(() => _filtersOpen = true);
    _queryFocusNode.requestFocus();
  }

  void _closeFilters() {
    setState(() => _filtersOpen = false);
    _queryFocusNode.unfocus();
  }

  Future<void> _selectNearest() async {
    setState(() => _sortMode = SortMode.nearest);
    final resolved = await widget.viewModel.resolvePosition();
    if (!resolved && mounted) {
      setState(() => _sortMode = SortMode.soonest);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not get your location — showing soonest trips instead')),
      );
    }
  }

  void _clear() {
    setState(() {
      _queryController.clear();
      _sortMode = SortMode.soonest;
    });
  }

  Future<void> _apply() async {
    _closeFilters();
    await widget.viewModel.applyFilters(query: _queryController.text.trim(), sortMode: _sortMode);
  }

  String _summaryLabel() {
    final parts = <String>[
      if (widget.viewModel.query.isNotEmpty) "'${widget.viewModel.query}'",
      if (widget.viewModel.sortMode == SortMode.nearest) 'Nearest',
    ];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasFilters = widget.viewModel.hasActiveFilters;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        boxShadow: widget.showShadow
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : [],
      ),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: _filtersOpen ? null : _openFilters,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.search, size: 20, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _filtersOpen
                          ? TextField(
                              controller: _queryController,
                              focusNode: _queryFocusNode,
                              textInputAction: TextInputAction.search,
                              onSubmitted: (_) => _apply(),
                              decoration: const InputDecoration(
                                isDense: true,
                                border: InputBorder.none,
                                hintText: 'Trips, dive centers, organizers, locations',
                              ),
                            )
                          : Padding(
                              padding: const EdgeInsets.symmetric(vertical: 7),
                              child: Text(
                                hasFilters ? _summaryLabel() : 'Search trips',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: hasFilters ? theme.colorScheme.onSurface : theme.colorScheme.onSurfaceVariant,
                                  fontWeight: hasFilters ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ),
                    ),
                    if (_filtersOpen)
                      InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: _closeFilters,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.close, size: 20, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      )
                    else if (hasFilters)
                      InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: widget.viewModel.clearFilters,
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(Icons.close, size: 18, color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (_filtersOpen) ...[
            const SizedBox(height: 16),
            Text('Sort by', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            ListenableBuilder(
              listenable: widget.viewModel,
              builder: (context, _) {
                return Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('Soonest'),
                      selected: _sortMode == SortMode.soonest,
                      onSelected: (_) => setState(() => _sortMode = SortMode.soonest),
                    ),
                    ChoiceChip(
                      label: widget.viewModel.isResolvingPosition
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Nearest'),
                      selected: _sortMode == SortMode.nearest,
                      onSelected: widget.viewModel.isResolvingPosition ? null : (_) => _selectNearest(),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(onPressed: _clear, child: const Text('Clear all')),
                const Spacer(),
                FilledButton(onPressed: _apply, child: const Text('Show trips')),
              ],
            ),
          ] else ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: widget.onCreateTrip,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Create trip'),
                    style: FilledButton.styleFrom(
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: widget.onJoinByCode,
                    icon: const Icon(Icons.confirmation_number_outlined, size: 18),
                    label: const Text('Join trip'),
                    style: FilledButton.styleFrom(
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TripCard extends StatelessWidget {
  const _TripCard({required this.trip, required this.onTap});

  final Trip trip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  (trip.photoUrl?.isNotEmpty ?? false)
                      ? Image.network(trip.photoUrl!, fit: BoxFit.cover)
                      : Image.asset(AppAssets.tripPlaceholder, fit: BoxFit.cover),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: AppGradients.imageScrim,
                    ),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: _DatePill(date: trip.startTime),
                  ),
                  Positioned(
                    left: 8,
                    top: 8,
                    child: _OrganizerTypePill(isDiveCenter: trip.diveCenterId != null),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontSize: 16,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          trip.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  _TripCardBadges(trip: trip),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripCardBadges extends StatelessWidget {
  const _TripCardBadges({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    final style = theme.textTheme.labelSmall?.copyWith(color: color);

    // Two fixed rows (not one flexible Wrap) so every card reserves exactly the same
    // badge-area height regardless of which optional fields a trip actually has.
    // Level is always populated (falls back to "Open to all"), so it anchors row 1.
    final secondRow = <Widget>[
      if (_depthText != null)
        _Badge(
          icon: Icons.waves,
          text: _depthText!,
          color: color,
          style: style,
        ),
      _Badge(
        icon: Icons.schedule,
        text: _durationText,
        color: color,
        style: style,
      ),
      if (_diveCountText != null)
        _Badge(
          icon: Icons.scuba_diving_outlined,
          text: _diveCountText!,
          color: color,
          style: style,
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Badge(
          icon: Icons.badge_outlined,
          text: certificationLevelAbbreviation(trip.minCertification),
          color: color,
          style: style,
        ),
        const SizedBox(height: 4),
        Wrap(spacing: 8, children: secondRow),
      ],
    );
  }

  String? get _depthText {
    final min = trip.depthMinM;
    final max = trip.depthMaxM;
    if (min == null && max == null) return null;
    if (min != null && max != null)
      return min == max ? '${min}m' : '$min–${max}m';
    return max != null ? '≤${max}m' : '${min}m+';
  }

  String? get _diveCountText {
    final min = trip.diveCountMin;
    final max = trip.diveCountMax;
    if (min == null && max == null) return null;
    if (min != null && max != null) return min == max ? '$min' : '$min–$max';
    return max != null ? '≤$max' : '$min+';
  }

  String get _durationText {
    final end = trip.endDate;
    if (end == null) return '1d';
    final start = trip.startTime.toLocal();
    final endLocal = end.toLocal();
    final startDate = DateTime(start.year, start.month, start.day);
    final endDateOnly = DateTime(endLocal.year, endLocal.month, endLocal.day);
    final days = endDateOnly.difference(startDate).inDays + 1;
    return '${days}d';
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.icon,
    required this.text,
    required this.color,
    required this.style,
  });

  final IconData icon;
  final String text;
  final Color color;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 2),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 68),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ),
      ],
    );
  }
}

// A quick "who's running this" signal — same top-left corner Airbnb-style listings use for
// a superhost/guest-favorite badge. Deliberately reuses _DatePill's exact pill styling
// (inverseSurface pill, labelSmall text) just mirrored to the opposite corner, so the two
// badges read as one visual family rather than two different treatments competing for
// attention on the same photo.
class _OrganizerTypePill extends StatelessWidget {
  const _OrganizerTypePill({required this.isDiveCenter});

  final bool isDiveCenter;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        isDiveCenter ? 'Dive Center' : 'Individual',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onInverseSurface,
        ),
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.inverseSurface,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        formatShortDate(date),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.onInverseSurface,
        ),
      ),
    );
  }
}
