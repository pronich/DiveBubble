import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/repositories/dive_center_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
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
import '../../../core/theme/semantic_colors.dart';
import '../../../core/widgets/pick_image.dart';
import '../../chats/view_models/chat_view_model.dart';
import '../../chats/views/trip_conversation_page.dart';
import '../../profile/views/diver_id_card.dart';
import '../../transport/view_models/transport_view_model.dart';
import '../view_models/trip_view_model.dart';
import 'join_by_code_dialog.dart';

class TripPage extends StatefulWidget {
  const TripPage({
    super.key,
    required this.viewModel,
    required this.tripRepository,
    required this.chatRepository,
    required this.transportRepository,
    required this.realtimeService,
    required this.diveCenterRepository,
    this.openedFromConversation = false,
  });

  final TripViewModel viewModel;
  final TripRepository tripRepository;
  final ChatRepository chatRepository;
  final TransportRepository transportRepository;
  final RealtimeService realtimeService;
  final DiveCenterRepository diveCenterRepository;

  /// True when reached by tapping the header of an already-open Bubble (chat) —
  /// "Dive in to Bubble" would just navigate back into the conversation the diver is
  /// already in, which reads as a broken loop rather than a useful action.
  final bool openedFromConversation;

  @override
  State<TripPage> createState() => _TripPageState();
}

class _TripPageState extends State<TripPage> {
  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
  }

  Future<void> _pickAndUploadPhoto(BuildContext context) async {
    final filePath = await pickImage(context);
    if (filePath == null || !context.mounted) return;

    final error = await widget.viewModel.uploadPhoto(filePath);
    if (!context.mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
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

          return ListView(
            padding: EdgeInsets.zero,
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
                      decoration: BoxDecoration(gradient: AppGradients.imageScrim),
                    ),
                    if (isOrganizer)
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: Material(
                          color: Colors.black.withValues(alpha: 0.45),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: widget.viewModel.isUploadingPhoto ? null : () => _pickAndUploadPhoto(context),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: widget.viewModel.isUploadingPhoto
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: Text(trip.title, style: theme.textTheme.headlineSmall)),
                        const SizedBox(width: 8),
                        _TripStatusPill(trip: trip, isOrganizer: isOrganizer),
                      ],
                    ),
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
                    _OrganizerCard(
                      isOrganizer: isOrganizer,
                      profile: widget.viewModel.organizerProfile,
                      creatorUserId: trip.creatorUserId,
                      profileRepository: widget.viewModel.profileRepository,
                      diveCenter: widget.viewModel.organizerDiveCenter,
                    ),
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
                    // Deliberately gated on *how this screen was reached*, not just
                    // trip.joined: Explore's "general" trip detail never shows who's in
                    // it, even for a trip the viewer has already joined — the member list
                    // only appears on the "specific" view reached from inside the Bubble
                    // itself. Two privacy postures for the same data, not two widgets.
                    if (widget.openedFromConversation) ...[
                      const SizedBox(height: 8),
                      _TripParticipantsList(
                        tripId: trip.id,
                        tripRepository: widget.tripRepository,
                        profileRepository: widget.viewModel.profileRepository,
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (trip.joined && !widget.openedFromConversation)
                      _DiveInButton(
                        trip: trip,
                        chatRepository: widget.chatRepository,
                        transportRepository: widget.transportRepository,
                        realtimeService: widget.realtimeService,
                        tripRepository: widget.tripRepository,
                        authRepository: widget.viewModel.authRepository,
                        profileRepository: widget.viewModel.profileRepository,
                        diveCenterRepository: widget.diveCenterRepository,
                        currentUserId: widget.viewModel.currentUserId,
                      )
                    else if (!trip.joined && !isOrganizer && trip.bookingStatus == 'open')
                      trip.diveCenterId != null
                          ? _BookNowSection(
                              trip: trip,
                              diveCenter: widget.viewModel.organizerDiveCenter,
                              viewModel: widget.viewModel,
                              tripRepository: widget.tripRepository,
                              chatRepository: widget.chatRepository,
                              transportRepository: widget.transportRepository,
                              realtimeService: widget.realtimeService,
                              diveCenterRepository: widget.diveCenterRepository,
                            )
                          : _JoinButton(trip: trip, viewModel: widget.viewModel)
                    else if (widget.openedFromConversation && trip.joined && !isOrganizer)
                      _LeaveButton(viewModel: widget.viewModel)
                    else if (widget.openedFromConversation && isOrganizer && trip.bookingStatus != 'cancelled')
                      _CancelButton(viewModel: widget.viewModel),
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
  const _TripParticipantsList({required this.tripId, required this.tripRepository, required this.profileRepository});

  final String tripId;
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
      final ids = await widget.tripRepository.getParticipantUserIds(widget.tripId);
      if (mounted) setState(() => _userIds = ids);
      for (final id in ids) {
        widget.profileRepository.getPublicProfile(id).then((p) {
          if (mounted) setState(() => _profiles[id] = p);
        }).catchError((_) {});
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_error != null) {
      return Text('Error: $_error', style: TextStyle(color: theme.colorScheme.error));
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
          Builder(builder: (context) {
            final profile = _profiles[userId];
            final name = (profile?.displayName?.isNotEmpty ?? false) ? profile!.displayName! : 'Diver';
            return InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => showDiverIdCard(context, userId: userId, profileRepository: widget.profileRepository),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      backgroundImage: (profile?.avatarUrl?.isNotEmpty ?? false) ? NetworkImage(profile!.avatarUrl!) : null,
                      child: (profile?.avatarUrl?.isNotEmpty ?? false)
                          ? null
                          : Icon(Icons.person, size: 18, color: theme.colorScheme.onSecondaryContainer),
                    ),
                    const SizedBox(width: 10),
                    Text(name, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
            );
          }),
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
      _InfoTile(icon: Icons.badge_outlined, label: 'LEVEL', value: certificationLevelAbbreviation(trip.minCertification)),
      if (_depthText(trip) != null) _InfoTile(icon: Icons.waves, label: 'DEPTH', value: _depthText(trip)!),
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
  const _OrganizerCard({
    required this.isOrganizer,
    required this.profile,
    required this.creatorUserId,
    required this.profileRepository,
    this.diveCenter,
  });

  final bool isOrganizer;
  final Profile? profile;
  final String? creatorUserId;
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
              backgroundImage: (dc.logoUrl?.isNotEmpty ?? false) ? NetworkImage(dc.logoUrl!) : null,
              child: (dc.logoUrl?.isNotEmpty ?? false)
                  ? null
                  : Icon(Icons.storefront_outlined, color: theme.colorScheme.onSecondaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(dc.name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                  Text(
                    'Dive center',
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final name = (profile?.displayName?.isNotEmpty ?? false) ? profile!.displayName! : 'Organizer';

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: creatorUserId == null
          ? null
          : () => showDiverIdCard(context, userId: creatorUserId!, profileRepository: profileRepository),
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
              backgroundImage: (profile?.avatarUrl?.isNotEmpty ?? false) ? NetworkImage(profile!.avatarUrl!) : null,
              child: (profile?.avatarUrl?.isNotEmpty ?? false)
                  ? null
                  : Icon(Icons.person, color: theme.colorScheme.onSecondaryContainer),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                Text(
                  isOrganizer ? 'Organizer · You' : 'Organizer',
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
            if (creatorUserId != null) ...[
              const Spacer(),
              Icon(Icons.chevron_right, color: theme.colorScheme.onSurfaceVariant),
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
    final userId = await ensureSignedIn(context, viewModel.authRepository, viewModel.profileRepository);
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
    required this.realtimeService,
    required this.diveCenterRepository,
  });

  final Trip trip;
  final DiveCenter? diveCenter;
  final TripViewModel viewModel;
  final TripRepository tripRepository;
  final ChatRepository chatRepository;
  final TransportRepository transportRepository;
  final RealtimeService realtimeService;
  final DiveCenterRepository diveCenterRepository;

  @override
  Widget build(BuildContext context) {
    final url = trip.bookingUrl ?? diveCenter?.website;
    final priceMinor = trip.priceMinor;
    final label = priceMinor != null ? 'Book now — ${(priceMinor / 100).toStringAsFixed(2)} ${trip.currency}' : 'Book now';

    return Column(
      children: [
        if (url != null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
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
    final userId = await ensureSignedIn(context, viewModel.authRepository, viewModel.profileRepository);
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
            diveCenterRepository: diveCenterRepository,
            tripId: resolved.id,
            currentUserId: userId,
          ),
          tripRepository: tripRepository,
          chatRepository: chatRepository,
          transportRepository: transportRepository,
          realtimeService: realtimeService,
          diveCenterRepository: diveCenterRepository,
        ),
      ),
    );
  }
}

/// Only shown on the Specific view (opened from inside a Bubble) to a joined,
/// non-organizer diver — the organizer's way out is cancelling the trip, not this.
/// On success, pops all the way back out of the Bubble; [MyTripsView]'s own
/// `await Navigator.push(...)` around [TripConversationPage] resolves the moment that
/// route is removed from the stack (popUntil pops it same as a direct pop), so its
/// existing post-return reload already picks up the trip disappearing — no extra
/// callback needed here.
class _LeaveButton extends StatelessWidget {
  const _LeaveButton({required this.viewModel});

  final TripViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: Theme.of(context).colorScheme.error,
          side: BorderSide(color: Theme.of(context).colorScheme.error),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        onPressed: viewModel.isLeaving ? null : () => _handleLeave(context),
        child: viewModel.isLeaving
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Leave Bubble'),
      ),
    );
  }

  Future<void> _handleLeave(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave this Bubble?'),
        content: const Text("You'll lose your spot and can rejoin later if there's room."),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            style: AppButtonStyles.ghost.copyWith(foregroundColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.error)),
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
}

/// Organizer-only, Specific view — the structural counterpart to [_LeaveButton], but
/// cancelling doesn't remove the organizer from anything: it stays on this page, the
/// status pill flips to "Cancelled", and this button itself disappears (see the caller's
/// `bookingStatus != 'cancelled'` guard) since there's nothing left to cancel. Bolder
/// (solid destructive) styling than Leave's outlined one — this affects every participant,
/// not just the person tapping it, and it's final: no reopen path exists.
class _CancelButton extends StatelessWidget {
  const _CancelButton({required this.viewModel});

  final TripViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: AppButtonStyles.destructive,
        onPressed: viewModel.isCancelling ? null : () => _handleCancel(context),
        child: viewModel.isCancelling
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Cancel Trip'),
      ),
    );
  }

  Future<void> _handleCancel(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel this trip?'),
        content: const Text(
          "Every participant keeps the Bubble to see the chat history, but no one — including you — "
          "can send messages, join, or arrange transport anymore. This can't be undone.",
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Never mind')),
          TextButton(
            style: AppButtonStyles.ghost.copyWith(foregroundColor: WidgetStatePropertyAll(Theme.of(context).colorScheme.error)),
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Trip cancelled')));
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
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(color: foreground, fontWeight: FontWeight.w600),
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
    required this.realtimeService,
    required this.tripRepository,
    required this.authRepository,
    required this.profileRepository,
    required this.diveCenterRepository,
    required this.currentUserId,
  });

  final Trip trip;
  final ChatRepository chatRepository;
  final TransportRepository transportRepository;
  final RealtimeService realtimeService;
  final TripRepository tripRepository;
  final AuthRepository authRepository;
  final ProfileRepository profileRepository;
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
                  tripId: trip.id,
                  currentUserId: currentUserId,
                ),
                tripTitle: trip.title,
                tripRepository: tripRepository,
                chatRepository: chatRepository,
                transportRepository: transportRepository,
                realtimeService: realtimeService,
                authRepository: authRepository,
                profileRepository: profileRepository,
                diveCenterRepository: diveCenterRepository,
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
