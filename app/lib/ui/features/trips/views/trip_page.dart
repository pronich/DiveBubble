import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/buddy_repository.dart';
import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/repositories/dive_center_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/push_repository.dart';
import '../../../../data/repositories/transport_repository.dart';
import '../../../../data/repositories/trip_repository.dart';
import '../../../../data/services/realtime_service.dart';
import '../../../../domain/certification_level.dart';
import '../../../../domain/entities/dive_center.dart';
import '../../../../domain/entities/profile.dart';
import '../../../../domain/entities/trip.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/auth/ensure_signed_in.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/external_url.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../core/widgets/photo_manager_grid.dart';
import '../../../core/widgets/pick_image.dart';
import '../../buddy/view_models/buddy_view_model.dart';
import '../../chats/view_models/chat_view_model.dart';
import '../../chats/views/trip_conversation_page.dart';
import '../../profile/views/diver_id_card.dart';
import '../../transport/view_models/transport_view_model.dart';
import '../view_models/trip_view_model.dart';
import 'dive_center_card.dart';
import 'join_by_code_dialog.dart';

class TripPage extends StatefulWidget {
  const TripPage({
    super.key,
    required this.viewModel,
    required this.tripRepository,
    required this.chatRepository,
    required this.transportRepository,
    required this.buddyRepository,
    required this.realtimeService,
    required this.diveCenterRepository,
    this.openedFromConversation = false,
  });

  final TripViewModel viewModel;
  final TripRepository tripRepository;
  final ChatRepository chatRepository;
  final TransportRepository transportRepository;
  final BuddyRepository buddyRepository;
  final RealtimeService realtimeService;
  final DiveCenterRepository diveCenterRepository;

  /// True when reached by tapping the header of an already-open Bubble (chat) —
  /// "Dive in to Bubble" would just navigate back into the conversation the diver is
  /// already in, which reads as a broken loop rather than a useful action.
  final bool openedFromConversation;

  @override
  State<TripPage> createState() => _TripPageState();
}

// Mirrors trip.MaxPhotosPerTrip server-side — hides/disables the "+" affordance once
// reached instead of letting the diver hit the 409 the hard way.
const _maxTripPhotos = 10;

class _TripPageState extends State<TripPage> {
  final _photoPageController = PageController();
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  @override
  void dispose() {
    _photoPageController.dispose();
    super.dispose();
  }

  void _openManagePhotos(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ManagePhotosPage(viewModel: widget.viewModel),
      ),
    );
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
          final isOrganizer = widget.viewModel.isOrganizer;

          // The photo carousel is a sibling of the scrollable body, not its first item —
          // nesting a horizontal PageView inside a vertical ListView put both gesture
          // recognizers in the same arena for any drag starting on the photo, and an
          // imprecise diagonal swipe could get won by the outer (vertical) one instead of
          // the carousel, sometimes swallowing taps too. Splitting them into a fixed header
          // + Expanded(ListView(...)) removes the vertical recognizer from that area entirely.
          return Column(
            children: [
              Builder(
                builder: (context) {
                  final photos = widget.viewModel.photos;
                  final hasPhotos = photos.isNotEmpty;
                  if (hasPhotos && _currentPhotoIndex >= photos.length) {
                    _currentPhotoIndex = photos.length - 1;
                  }

                  return AspectRatio(
                    aspectRatio: 4 / 3,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        hasPhotos
                            ? PageView.builder(
                                controller: _photoPageController,
                                itemCount: photos.length,
                                onPageChanged: (i) =>
                                    setState(() => _currentPhotoIndex = i),
                                // Tap-left/tap-right zones live *inside* each page (descendants
                                // of PageView), not stacked on top of it — a GestureDetector
                                // overlaying PageView from outside competes with its own drag
                                // recognizer for the same pointer and swallows real swipes;
                                // nested inside a page, Flutter's normal ancestor-scrollable/
                                // descendant-tap disambiguation lets a drag fall through to the
                                // PageView while a stationary tap still resolves here.
                                itemBuilder: (context, i) => Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.network(
                                      photos[i].url,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) =>
                                              Image.asset(
                                                AppAssets.tripPlaceholder,
                                                fit: BoxFit.cover,
                                              ),
                                    ),
                                    if (photos.length > 1) ...[
                                      Positioned(
                                        left: 0,
                                        top: 0,
                                        bottom: 0,
                                        width:
                                            MediaQuery.sizeOf(context).width /
                                            3,
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.translucent,
                                          onTap: _currentPhotoIndex > 0
                                              ? () => _photoPageController
                                                    .previousPage(
                                                      duration: const Duration(
                                                        milliseconds: 250,
                                                      ),
                                                      curve: Curves.easeOut,
                                                    )
                                              : null,
                                        ),
                                      ),
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        bottom: 0,
                                        width:
                                            MediaQuery.sizeOf(context).width /
                                            3,
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.translucent,
                                          onTap:
                                              _currentPhotoIndex <
                                                  photos.length - 1
                                              ? () => _photoPageController
                                                    .nextPage(
                                                      duration: const Duration(
                                                        milliseconds: 250,
                                                      ),
                                                      curve: Curves.easeOut,
                                                    )
                                              : null,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              )
                            : Image.asset(
                                AppAssets.tripPlaceholder,
                                fit: BoxFit.cover,
                              ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppGradients.imageScrim,
                          ),
                        ),
                        // Dot page indicator — only worth showing once there's more than one
                        // photo to swipe between.
                        if (photos.length > 1)
                          Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (var i = 0; i < photos.length; i++)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white.withValues(
                                        alpha: i == _currentPhotoIndex
                                            ? 1
                                            : 0.4,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        // A single "Manage photos" entry point, not inline add/remove
                        // controls on the slider itself — editing now happens in its own
                        // grid (see _ManagePhotosPage), so this hero is a pure viewer for
                        // every visitor, organizer included.
                        if (isOrganizer)
                          Positioned(
                            right: 16,
                            bottom: 16,
                            child: Material(
                              color: Colors.black.withValues(alpha: 0.45),
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () => _openManagePhotos(context),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.photo_library_outlined,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Manage photos',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
              Expanded(
                child: ListView(
                  // Bottom-only: the last item (Join/Book now button) needs room above the
                  // system nav bar — otherwise 3-button nav on Android overlaps it (no
                  // MediaQuery inset otherwise).
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.paddingOf(context).bottom,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  trip.title,
                                  style: theme.textTheme.headlineSmall,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _TripStatusPill(
                                trip: trip,
                                isOrganizer: isOrganizer,
                              ),
                            ],
                          ),
                          // Quick actions row, Telegram-Group-Info-style — only meaningful once
                          // already inside the Bubble (see openedFromConversation's own doc).
                          if (widget.openedFromConversation) ...[
                            const SizedBox(height: 16),
                            _ActionPillsRow(
                              viewModel: widget.viewModel,
                              trip: trip,
                              isOrganizer: isOrganizer,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                trip.location,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today_outlined,
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                formatDateRange(trip.startTime, trip.endDate),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'MEETING POINT',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${formatTime(trip.startTime)} · ${trip.meetingPoint ?? trip.location}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _InfoGrid(trip: trip),
                          if (trip.description != null) ...[
                            const SizedBox(height: 20),
                            Text(
                              'About this dive',
                              style: theme.textTheme.labelLarge,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              trip.description!,
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                          const SizedBox(height: 20),
                          _OrganizerCard(
                            isOrganizer: isOrganizer,
                            profile: widget.viewModel.organizerProfile,
                            creatorUserId: trip.creatorUserId,
                            currentUserId: widget.viewModel.currentUserId,
                            profileRepository:
                                widget.viewModel.profileRepository,
                            diveCenter: widget.viewModel.organizerDiveCenter,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Icon(
                                Icons.groups_outlined,
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _participantsText(trip),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          // Deliberately gated on *how this screen was reached*, not just
                          // trip.joined: Explore's "general" trip detail never shows who's in
                          // it, even for a trip the viewer has already joined — the member list
                          // only appears on the "specific" view reached from inside the Bubble
                          // itself. Two privacy postures for the same data, not two widgets.
                          if (widget.openedFromConversation) ...[
                            const SizedBox(height: 8),
                            _TripParticipantsList(
                              tripId: trip.id,
                              currentUserId: widget.viewModel.currentUserId,
                              tripRepository: widget.tripRepository,
                              profileRepository:
                                  widget.viewModel.profileRepository,
                            ),
                          ],
                          const SizedBox(height: 24),
                          if (trip.joined && !widget.openedFromConversation)
                            _DiveInButton(
                              trip: trip,
                              chatRepository: widget.chatRepository,
                              transportRepository: widget.transportRepository,
                              buddyRepository: widget.buddyRepository,
                              realtimeService: widget.realtimeService,
                              tripRepository: widget.tripRepository,
                              authRepository: widget.viewModel.authRepository,
                              profileRepository:
                                  widget.viewModel.profileRepository,
                              pushRepository: widget.viewModel.pushRepository,
                              diveCenterRepository: widget.diveCenterRepository,
                              currentUserId: widget.viewModel.currentUserId,
                            )
                          else if (!trip.joined &&
                              !isOrganizer &&
                              trip.bookingStatus == 'open')
                            trip.diveCenterId != null
                                ? _BookNowSection(
                                    trip: trip,
                                    diveCenter:
                                        widget.viewModel.organizerDiveCenter,
                                    viewModel: widget.viewModel,
                                    tripRepository: widget.tripRepository,
                                    chatRepository: widget.chatRepository,
                                    transportRepository:
                                        widget.transportRepository,
                                    buddyRepository: widget.buddyRepository,
                                    realtimeService: widget.realtimeService,
                                    diveCenterRepository:
                                        widget.diveCenterRepository,
                                  )
                                : _JoinButton(
                                    trip: trip,
                                    viewModel: widget.viewModel,
                                  ),
                          // Leave/Cancel now live in _ActionPillsRow up top, Telegram-Group-Info-style.
                        ],
                      ),
                    ),
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

/// Inline member list embedded right under "N people joined" — Telegram-style, no extra
/// screen to get to it. Same lazy-per-id profile fetch pattern as Transport's joined-divers.
class _TripParticipantsList extends StatefulWidget {
  const _TripParticipantsList({
    required this.tripId,
    required this.currentUserId,
    required this.tripRepository,
    required this.profileRepository,
  });

  final String tripId;
  final String currentUserId;
  final TripRepository tripRepository;
  final ProfileRepository profileRepository;

  @override
  State<_TripParticipantsList> createState() => _TripParticipantsListState();
}

class _TripParticipantsListState extends State<_TripParticipantsList> {
  List<String>? _userIds;
  final Map<String, Profile> _profiles = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final ids = await widget.tripRepository.getParticipantUserIds(
        widget.tripId,
      );
      if (mounted) setState(() => _userIds = ids);
      for (final id in ids) {
        widget.profileRepository
            .getPublicProfile(id)
            .then((p) {
              if (mounted) setState(() => _profiles[id] = p);
            })
            .catchError((_) {});
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_error != null) {
      return Text(
        'Error: $_error',
        style: TextStyle(color: theme.colorScheme.error),
      );
    }
    if (_userIds == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }

    return Column(
      children: [
        for (final userId in _userIds!)
          Builder(
            builder: (context) {
              final profile = _profiles[userId];
              final baseName = (profile?.displayName?.isNotEmpty ?? false)
                  ? profile!.displayName!
                  : 'Diver';
              final name = (profile?.isProductObserver ?? false)
                  ? '$baseName | Product Observer'
                  : baseName;
              return InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => showDiverIdCard(
                  context,
                  userId: userId,
                  currentUserId: widget.currentUserId,
                  profileRepository: widget.profileRepository,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        backgroundImage:
                            (profile?.avatarUrl?.isNotEmpty ?? false)
                            ? NetworkImage(profile!.avatarUrl!)
                            : null,
                        child: (profile?.avatarUrl?.isNotEmpty ?? false)
                            ? null
                            : Icon(
                                Icons.person,
                                size: 18,
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                      ),
                      const SizedBox(width: 10),
                      Text(name, style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[
      _InfoTile(
        icon: Icons.badge_outlined,
        label: 'LEVEL',
        value: certificationLevelAbbreviation(trip.minCertification),
      ),
      if (_depthText(trip) != null)
        _InfoTile(icon: Icons.waves, label: 'DEPTH', value: _depthText(trip)!),
      if (_diveCountText(trip) != null)
        _InfoTile(
          icon: Icons.scuba_diving_outlined,
          label: 'DIVES',
          value: _diveCountText(trip)!,
        ),
      _InfoTile(
        icon: Icons.schedule,
        label: 'DURATION',
        value: _durationText(trip),
      ),
    ];

    final rows = <Widget>[];
    for (var i = 0; i < tiles.length; i += 2) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 10));
      final second = i + 1 < tiles.length
          ? tiles[i + 1]
          : const SizedBox.shrink();
      rows.add(
        Row(
          children: [
            Expanded(child: tiles[i]),
            const SizedBox(width: 10),
            Expanded(child: second),
          ],
        ),
      );
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
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

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
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _OrganizerCard extends StatelessWidget {
  const _OrganizerCard({
    required this.isOrganizer,
    required this.profile,
    required this.creatorUserId,
    required this.currentUserId,
    required this.profileRepository,
    this.diveCenter,
  });

  final bool isOrganizer;
  final Profile? profile;
  final String? creatorUserId;
  final String currentUserId;
  final ProfileRepository profileRepository;

  /// Set for a business trip — the dive center's own identity is shown instead of the
  /// specific staff member who happened to create it (see CLAUDE.md's Business/dive
  /// centers section: the organization is the organizer, not one employee).
  final DiveCenter? diveCenter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dc = diveCenter;

    if (dc != null) {
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => showDiveCenterCard(context, dc),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.secondaryContainer,
                backgroundImage: (dc.logoUrl?.isNotEmpty ?? false)
                    ? NetworkImage(dc.logoUrl!)
                    : null,
                child: (dc.logoUrl?.isNotEmpty ?? false)
                    ? null
                    : Icon(
                        Icons.storefront_outlined,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dc.name,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Dive center',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    final name = (profile?.displayName?.isNotEmpty ?? false)
        ? profile!.displayName!
        : 'Organizer';

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: creatorUserId == null
          ? null
          : () => showDiverIdCard(
              context,
              userId: creatorUserId!,
              currentUserId: currentUserId,
              profileRepository: profileRepository,
            ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.secondaryContainer,
              backgroundImage: (profile?.avatarUrl?.isNotEmpty ?? false)
                  ? NetworkImage(profile!.avatarUrl!)
                  : null,
              child: (profile?.avatarUrl?.isNotEmpty ?? false)
                  ? null
                  : Icon(
                      Icons.person,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  isOrganizer ? 'Organizer · You' : 'Organizer',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            if (creatorUserId != null) ...[
              const Spacer(),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Only rendered for the actionable case (open, not yet joined) — Joined/Full/Cancelled are
// passive states shown as a pill next to the title instead (see _TripStatusPill).
class _JoinButton extends StatelessWidget {
  const _JoinButton({required this.trip, required this.viewModel});

  final Trip trip;
  final TripViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: viewModel.isJoining ? null : () => _handleJoin(context),
        child: viewModel.isJoining
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Text('Join'),
      ),
    );
  }

  Future<void> _handleJoin(BuildContext context) async {
    final userId = await ensureSignedIn(
      context,
      viewModel.authRepository,
      viewModel.profileRepository,
      viewModel.pushRepository,
    );
    if (userId == null) return;
    await viewModel.join();
  }
}

/// Replaces _JoinButton for business trips — we're a marketplace, not the ones taking the
/// diver's money, so there's no direct Join here (see trip.Service.Join's own server-side
/// rejection of this for business trips). "Book now" sends the diver to actually pay
/// (trip.bookingUrl, falling back to the dive center's general website); "I have a booking
/// code" is the way back in once they've got one — see CLAUDE.md's Booking Code flow section.
class _BookNowSection extends StatelessWidget {
  const _BookNowSection({
    required this.trip,
    required this.diveCenter,
    required this.viewModel,
    required this.tripRepository,
    required this.chatRepository,
    required this.transportRepository,
    required this.buddyRepository,
    required this.realtimeService,
    required this.diveCenterRepository,
  });

  final Trip trip;
  final DiveCenter? diveCenter;
  final TripViewModel viewModel;
  final TripRepository tripRepository;
  final ChatRepository chatRepository;
  final TransportRepository transportRepository;
  final BuddyRepository buddyRepository;
  final RealtimeService realtimeService;
  final DiveCenterRepository diveCenterRepository;

  @override
  Widget build(BuildContext context) {
    final url = trip.bookingUrl ?? diveCenter?.website;
    final priceMinor = trip.priceMinor;
    final label = priceMinor != null
        ? 'Book now — ${(priceMinor / 100).toStringAsFixed(2)} ${trip.currency}'
        : 'Book now';

    return Column(
      children: [
        if (url != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => launchUrl(
                externalUri(url),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(label),
            ),
          ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => _handleEnterCode(context),
            child: const Text('I have a booking code'),
          ),
        ),
      ],
    );
  }

  Future<void> _handleEnterCode(BuildContext context) async {
    final userId = await ensureSignedIn(
      context,
      viewModel.authRepository,
      viewModel.profileRepository,
      viewModel.pushRepository,
    );
    if (userId == null || !context.mounted) return;

    final resolved = await showJoinByCodeDialog(context, tripRepository);
    if (resolved == null) return;

    // Same trip this page is already showing — just refresh in place. A code for a
    // *different* trip (a mistaken paste, most likely) instead opens that trip directly,
    // since there's nothing more useful to do with it from here.
    if (resolved.id == trip.id) {
      await viewModel.load();
      return;
    }
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TripPage(
          viewModel: TripViewModel(
            repository: tripRepository,
            authRepository: viewModel.authRepository,
            profileRepository: viewModel.profileRepository,
            pushRepository: viewModel.pushRepository,
            diveCenterRepository: diveCenterRepository,
            tripId: resolved.id,
            currentUserId: userId,
          ),
          tripRepository: tripRepository,
          chatRepository: chatRepository,
          transportRepository: transportRepository,
          buddyRepository: buddyRepository,
          realtimeService: realtimeService,
          diveCenterRepository: diveCenterRepository,
        ),
      ),
    );
  }
}

/// Quick-actions row shown only on the Specific view (opened from inside a Bubble) —
/// Telegram Group-Info-style row of icon pills, replacing the old full-width Leave/Cancel
/// buttons. Mute is always shown; Leave (joined, non-organizer) and Cancel (organizer, not
/// already cancelled) are mutually exclusive, same gating the old buttons used.
class _ActionPillsRow extends StatelessWidget {
  const _ActionPillsRow({
    required this.viewModel,
    required this.trip,
    required this.isOrganizer,
  });

  final TripViewModel viewModel;
  final Trip trip;
  final bool isOrganizer;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _ActionPill(
            icon: viewModel.isMuted
                ? Icons.notifications_off_outlined
                : Icons.notifications_none,
            label: viewModel.isMuted ? 'Unmute' : 'Mute',
            onTap: viewModel.toggleMute,
          ),
        ),
        if (trip.joined && !isOrganizer) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _ActionPill(
              icon: Icons.logout,
              label: 'Leave',
              destructive: true,
              busy: viewModel.isLeaving,
              onTap: () => _handleLeave(context, viewModel),
            ),
          ),
        ] else if (isOrganizer && trip.bookingStatus != 'cancelled') ...[
          const SizedBox(width: 8),
          Expanded(
            child: _ActionPill(
              icon: Icons.cancel_outlined,
              label: 'Cancel',
              destructive: true,
              busy: viewModel.isCancelling,
              onTap: () => _handleCancel(context, viewModel),
            ),
          ),
        ],
      ],
    );
  }
}

/// On success, pops all the way back out of the Bubble; [MyTripsView]'s own
/// `await Navigator.push(...)` around [TripConversationPage] resolves the moment that
/// route is removed from the stack (popUntil pops it same as a direct pop), so its
/// existing post-return reload already picks up the trip disappearing — no extra
/// callback needed here.
Future<void> _handleLeave(BuildContext context, TripViewModel viewModel) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Leave this Bubble?'),
      content: const Text(
        "You'll lose your spot and can rejoin later if there's room.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          style: AppButtonStyles.ghost.copyWith(
            foregroundColor: WidgetStatePropertyAll(
              Theme.of(context).colorScheme.error,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Leave'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final error = await viewModel.leave();
  if (!context.mounted) return;
  if (error != null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    return;
  }
  Navigator.of(context).popUntil((route) => route.isFirst);
}

/// Organizer-only — cancelling doesn't remove the organizer from anything: it stays on
/// this page, the status pill flips to "Cancelled", and this pill itself disappears (see
/// _ActionPillsRow's own `bookingStatus != 'cancelled'` guard) since there's nothing left
/// to cancel. It's final: no reopen path exists.
Future<void> _handleCancel(
  BuildContext context,
  TripViewModel viewModel,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Cancel this trip?'),
      content: const Text(
        "Every participant keeps the Bubble to see the chat history, but no one — including you — "
        "can send messages, join, or arrange transport anymore. This can't be undone.",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Never mind'),
        ),
        TextButton(
          style: AppButtonStyles.ghost.copyWith(
            foregroundColor: WidgetStatePropertyAll(
              Theme.of(context).colorScheme.error,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Cancel trip'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final error = await viewModel.cancel();
  if (!context.mounted) return;
  if (error != null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    return;
  }
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(const SnackBar(content: Text('Trip cancelled')));
}

/// A single icon-over-label pill, Telegram Group-Info-style (video call / mute / search /
/// more, stacked icon+text in a rounded container) — [_ActionPillsRow] lays two of these
/// out evenly.
class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
    this.busy = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = destructive
        ? theme.colorScheme.error
        : theme.colorScheme.onSurfaceVariant;
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: busy ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              busy
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    )
                  : Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Passive status indicator next to the trip title — Organizer/Joined/Full/Cancelled.
/// Nothing shown for the common "open, not yet joined" case, matching the app's
/// quiet-by-default badges.
class _TripStatusPill extends StatelessWidget {
  const _TripStatusPill({required this.trip, required this.isOrganizer});

  final Trip trip;
  final bool isOrganizer;

  @override
  Widget build(BuildContext context) {
    final String? label;
    final Color background;
    final Color foreground;
    final theme = Theme.of(context);
    final semantic = Theme.of(context).extension<SemanticColors>()!;

    // Cancelled outranks Organizer/Joined — that's the one thing everyone in the Bubble
    // needs to see at a glance, organizer included, not just non-participants browsing in.
    if (trip.bookingStatus == 'cancelled') {
      label = 'Cancelled';
      background = theme.colorScheme.surfaceContainerHighest;
      foreground = theme.colorScheme.onSurfaceVariant;
    } else if (isOrganizer) {
      // Of course the organizer is "joined" — that label is more useful for everyone else.
      label = 'Organizer';
      background = theme.colorScheme.primaryContainer;
      foreground = theme.colorScheme.onPrimaryContainer;
    } else if (trip.joined) {
      label = 'Joined';
      background = semantic.successContainer;
      foreground = semantic.onSuccessContainer;
    } else if (trip.bookingStatus == 'full') {
      label = 'Full';
      background = semantic.infoContainer;
      foreground = semantic.onInfoContainer;
    } else {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

/// Shown instead of the Join button once the diver has joined — takes them straight into
/// the trip's chat rather than leaving them on a static "Joined" chip with nowhere to go.
class _DiveInButton extends StatelessWidget {
  const _DiveInButton({
    required this.trip,
    required this.chatRepository,
    required this.transportRepository,
    required this.buddyRepository,
    required this.realtimeService,
    required this.tripRepository,
    required this.authRepository,
    required this.profileRepository,
    required this.pushRepository,
    required this.diveCenterRepository,
    required this.currentUserId,
  });

  final Trip trip;
  final ChatRepository chatRepository;
  final TransportRepository transportRepository;
  final BuddyRepository buddyRepository;
  final RealtimeService realtimeService;
  final TripRepository tripRepository;
  final AuthRepository authRepository;
  final ProfileRepository profileRepository;
  final PushRepository pushRepository;
  final DiveCenterRepository diveCenterRepository;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () async {
          tripRepository.markRead(trip.id).catchError((_) {});
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TripConversationPage(
                chatViewModel: ChatViewModel(
                  repository: chatRepository,
                  realtimeService: realtimeService,
                  profileRepository: profileRepository,
                  tripId: trip.id,
                  currentUserId: currentUserId,
                ),
                transportViewModel: TransportViewModel(
                  repository: transportRepository,
                  authRepository: authRepository,
                  profileRepository: profileRepository,
                  pushRepository: pushRepository,
                  tripId: trip.id,
                  currentUserId: currentUserId,
                ),
                buddyViewModel: BuddyViewModel(
                  repository: buddyRepository,
                  authRepository: authRepository,
                  profileRepository: profileRepository,
                  pushRepository: pushRepository,
                  tripId: trip.id,
                  currentUserId: currentUserId,
                ),
                tripTitle: trip.title,
                tripPhotoUrl: trip.photoUrl,
                tripRepository: tripRepository,
                chatRepository: chatRepository,
                transportRepository: transportRepository,
                buddyRepository: buddyRepository,
                realtimeService: realtimeService,
                authRepository: authRepository,
                profileRepository: profileRepository,
                pushRepository: pushRepository,
                diveCenterRepository: diveCenterRepository,
                initialHasTransportAlert: trip.hasTransportAlert,
                initialHasBuddyAlert: trip.hasBuddyAlert,
              ),
            ),
          );
          // Catches any messages that arrived while actively in the chat — the Bubbles
          // list itself will pick up the corrected count next time it's opened.
          tripRepository.markRead(trip.id).catchError((_) {});
        },
        icon: const Icon(Icons.chat_bubble_outline, size: 18),
        label: const Text('Dive in to Bubble'),
      ),
    );
  }
}

/// The organizer's actual photo-editing surface — a grid instead of one-at-a-time controls
/// overlaid on the hero slider, with multi-select add (see pick_image.dart's
/// pickMultipleImages) instead of picking one file per tap.
class _ManagePhotosPage extends StatefulWidget {
  const _ManagePhotosPage({required this.viewModel});

  final TripViewModel viewModel;

  @override
  State<_ManagePhotosPage> createState() => _ManagePhotosPageState();
}

class _ManagePhotosPageState extends State<_ManagePhotosPage> {
  bool _isAdding = false;

  Future<void> _addPhotos() async {
    setState(() => _isAdding = true);
    try {
      final paths = await pickMultipleImages();
      if (paths.isEmpty) return;
      final room = _maxTripPhotos - widget.viewModel.photos.length;
      for (final path in paths.take(room)) {
        // Sequential, not parallel — same position-race reasoning as CreateTripPage's own
        // multi-upload loop.
        final error = await widget.viewModel.addPhoto(path);
        if (error != null && mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
          break;
        }
      }
      if (paths.length > room && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Only $_maxTripPhotos photos allowed per trip'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _removePhoto(String photoId) async {
    final error = await widget.viewModel.removePhoto(photoId);
    if (error != null && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage photos'),
        // Not functionally different from the back button — every add/remove already
        // commits immediately — but "Save" reads as a clearer "I'm done here" than relying
        // on an implicit back-arrow, same reasoning as admin/'s matching dialog.
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Save'),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          final photos = widget.viewModel.photos;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    'Upload up to $_maxTripPhotos photos.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                PhotoManagerGrid(
                  items: [
                    for (final p in photos)
                      PhotoManagerItem(
                        id: p.id,
                        imageProvider: NetworkImage(p.url),
                        isBusy: widget.viewModel.isRemovingPhoto(p.id),
                      ),
                  ],
                  maxItems: _maxTripPhotos,
                  isAdding: _isAdding,
                  onAdd: _addPhotos,
                  onRemove: _removePhoto,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
