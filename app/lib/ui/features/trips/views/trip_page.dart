import 'package:flutter/material.dart';

import '../../../../data/services/error_codes.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/buddy_repository.dart';
import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/repositories/dive_center_repository.dart';
import '../../../../data/repositories/expense_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/push_repository.dart';
import '../../../../data/repositories/transport_repository.dart';
import '../../../../data/repositories/trip_repository.dart';
import '../../../../data/services/realtime_service.dart';
import '../../../../domain/certification_level.dart';
import '../../../../domain/entities/chat_link.dart';
import '../../../../domain/entities/media_item.dart';
import '../../../../domain/entities/dive_center.dart';
import '../../../../domain/entities/profile.dart';
import '../../../../domain/entities/trip.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/assets/app_assets.dart';
import '../../../core/auth/ensure_signed_in.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/external_url.dart';
import '../../../core/theme/semantic_colors.dart';
import '../../../core/widgets/photo_manager_grid.dart';
import '../../../core/widgets/pick_image.dart';
import '../../chats/view_models/chat_info_view_model.dart';
import '../../chats/views/chat_content_tabs.dart';
import '../../chats/views/trip_conversation_page.dart';
import '../../profile/views/diver_id_card.dart';
import '../view_models/create_trip_view_model.dart';
import '../view_models/trip_view_model.dart';
import 'create_trip_page.dart';
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
    required this.expenseRepository,
    this.openedFromConversation = false,
    this.entryCode,
  });

  final TripViewModel viewModel;
  final TripRepository tripRepository;
  final ChatRepository chatRepository;
  final TransportRepository transportRepository;
  final BuddyRepository buddyRepository;
  final RealtimeService realtimeService;
  final DiveCenterRepository diveCenterRepository;
  final ExpenseRepository expenseRepository;

  /// True when reached by tapping the header of an already-open Bubble, where "Dive in to Bubble" would just navigate back into the conversation, a broken loop.
  final bool openedFromConversation;

  /// Set when reached via an invite link — Join skips straight to JoinByCode with it instead of the per-trip-type button, since re-typing a code the diver already has would be redundant.
  final String? entryCode;

  @override
  State<TripPage> createState() => _TripPageState();
}

// Mirrors trip.MaxPhotosPerTrip server-side, hiding/disabling the "+" affordance instead of letting the diver hit the 409 the hard way.
const _maxTripPhotos = 10;

class _TripPageState extends State<TripPage>
    with SingleTickerProviderStateMixin {
  final _photoPageController = PageController();
  int _currentPhotoIndex = 0;

  // Only meaningful when widget.openedFromConversation, but created unconditionally since its lifecycle needs to exist across the whole State either way.
  late final TabController _tabController = TabController(
    length: 4,
    vsync: this,
  );

  // Lazily created once trip.id is known; guarded by the null check in _ensureBubbleContentLoaded so a rebuild never refires these.
  ChatInfoViewModel? _chatInfoViewModel;
  Future<List<MediaItem>>? _mediaFuture;
  Future<List<MediaItem>>? _filesFuture;
  Future<List<ChatLink>>? _linksFuture;

  void _ensureBubbleContentLoaded(String tripId) {
    if (_chatInfoViewModel != null) return;
    final vm = ChatInfoViewModel(
      repository: widget.chatRepository,
      tripId: tripId,
    );
    _chatInfoViewModel = vm;
    _mediaFuture = vm.loadMedia();
    _filesFuture = vm.loadFiles();
    _linksFuture = vm.loadLinks();
  }

  // Drives the collapsing SliverAppBar's toolbar title, off the in-flow title block's measured height rather than "the photo finished collapsing" — otherwise the toolbar title and in-flow title could briefly both be on screen, since the photo can fully collapse before the title block scrolls out of view.
  final _scrollController = ScrollController();
  final _titleBlockKey = GlobalKey();
  final ValueNotifier<bool> _showCollapsedTitle = ValueNotifier(false);

  void _handleScroll() {
    if (!_scrollController.hasClients) return;
    final width = MediaQuery.sizeOf(context).width;
    final photoHeight = width * 3 / 4; // matches photoHero's AspectRatio(4/3)
    final toolbarHeight = kToolbarHeight + MediaQuery.paddingOf(context).top;
    final titleBlockHeight =
        (_titleBlockKey.currentContext?.findRenderObject() as RenderBox?)
            ?.size
            .height ??
        0;
    final threshold = photoHeight - toolbarHeight + titleBlockHeight;
    final collapsed = _scrollController.offset >= threshold;
    if (collapsed != _showCollapsedTitle.value) {
      _showCollapsedTitle.value = collapsed;
    }
  }

  @override
  void initState() {
    super.initState();
    widget.viewModel.load();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _photoPageController.dispose();
    _tabController.dispose();
    _scrollController.dispose();
    _showCollapsedTitle.dispose();
    super.dispose();
  }

  void _openManagePhotos(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _ManagePhotosPage(viewModel: widget.viewModel),
      ),
    );
  }

  // Unlike _openManagePhotos, this pushes a separate CreateTripViewModel, so the trip needs an explicit reload once it pops back rather than relying on a shared, already-notifying instance.
  Future<void> _openEditTrip(BuildContext context, Trip trip) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CreateTripPage(
          viewModel: CreateTripViewModel(
            repository: widget.tripRepository,
            existingTripId: trip.id,
          ),
          existingTrip: trip,
          onCreated: (_) => Navigator.of(context).pop(),
        ),
      ),
    );
    if (mounted) widget.viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Captured here, above Scaffold: extendBodyBehindAppBar would otherwise make a descendant SafeArea pad for the whole transparent AppBar height rather than the real status-bar inset, so photoHero's Edit pill uses this true value directly to line up with the back button's row.
    final systemTopPadding = MediaQuery.paddingOf(context).top;
    return Scaffold(
      // Both modes build their own SliverAppBar inside a scroll view rather than Scaffold.appBar, letting the photo run full-bleed behind the status bar and Bubble Info's pinned tab bar park right below the collapsed header with no manual offset math.
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          if (widget.viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final error = widget.viewModel.error;
          if (error != null) {
            return Center(child: Text(AppLocalizations.of(context).errorWithMessage(error)));
          }

          final trip = widget.viewModel.trip;
          if (trip == null) {
            return const SizedBox.shrink();
          }

          final isOrganizer = widget.viewModel.isOrganizer;

          // Shared by both branches below — Bubble Info reuses the same photo carousel as the trip detail view, rather than a separate circle-avatar treatment.
          final photoHero = Builder(
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
                            // Tap zones live inside each page, not stacked on top of PageView, since an overlaying GestureDetector would compete with its drag recognizer and swallow real swipes.
                            itemBuilder: (context, i) => Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  photos[i].url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
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
                                    width: MediaQuery.sizeOf(context).width / 3,
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
                                    width: MediaQuery.sizeOf(context).width / 3,
                                    child: GestureDetector(
                                      behavior: HitTestBehavior.translucent,
                                      onTap:
                                          _currentPhotoIndex < photos.length - 1
                                          ? () => _photoPageController.nextPage(
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
                    // IgnorePointer is load-bearing: a bare DecoratedBox still claimed the hit test ahead of the PageView beneath it, silently swallowing every tap and swipe on the photo.
                    const IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppGradients.imageScrim,
                        ),
                      ),
                    ),
                    // Dot page indicator — only worth showing once there's more than one photo to swipe between.
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
                                    alpha: i == _currentPhotoIndex ? 1 : 0.4,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    // A single "Manage photos" entry point, not inline add/remove controls on the slider itself — editing happens in its own grid, so this hero is a pure viewer for everyone.
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
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.photo_library_outlined,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    AppLocalizations.of(context).managePhotos,
                                    style: const TextStyle(
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
                    // Edit trip — pinned under the status bar/back button row using the pre-captured systemTopPadding, not a SafeArea, which would overshoot in this Scaffold.
                    if (isOrganizer && trip.bookingStatus != 'cancelled')
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Padding(
                          padding: EdgeInsets.only(
                            top: systemTopPadding + 8,
                            right: 16,
                          ),
                          child: Material(
                            color: Colors.black.withValues(alpha: 0.45),
                            borderRadius: BorderRadius.circular(20),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: () => _openEditTrip(context, trip),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.edit_outlined,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      AppLocalizations.of(context).editButtonLabel,
                                      style: const TextStyle(
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
                      ),
                  ],
                ),
              );
            },
          );

          final photoHeight = MediaQuery.sizeOf(context).width * 3 / 4;

          // Collapsing header + in-flow title/badge — identical in both the general view and Bubble Info now.
          final headerSlivers = <Widget>[
            ValueListenableBuilder<bool>(
              valueListenable: _showCollapsedTitle,
              builder: (context, collapsed, child) => SliverAppBar(
                pinned: true,
                expandedHeight: photoHeight,
                backgroundColor: collapsed
                    ? theme.colorScheme.surface
                    : Colors.transparent,
                foregroundColor: collapsed
                    ? theme.colorScheme.onSurface
                    : Colors.white,
                elevation: 0,
                title: collapsed
                    ? Text(
                        trip.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : null,
                flexibleSpace: FlexibleSpaceBar(background: child),
              ),
              child: photoHero,
            ),
            SliverToBoxAdapter(
              child: Padding(
                key: _titleBlockKey,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        trip.title,
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                    const SizedBox(width: 8),
                    _TripStatusPill(trip: trip, isOrganizer: isOrganizer),
                  ],
                ),
              ),
            ),
            // Mute/Leave/Cancel — Bubble Info only; the general view has no equivalent affordance today.
            if (widget.openedFromConversation)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: _ActionPillsRow(
                    viewModel: widget.viewModel,
                    trip: trip,
                    isOrganizer: isOrganizer,
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: _TripInfoBlock(trip: trip, isOrganizer: isOrganizer),
            ),
          ];

          if (widget.openedFromConversation) {
            _ensureBubbleContentLoaded(trip.id);
            final l10n = AppLocalizations.of(context);
            final tabBar = TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: l10n.peopleTabLabel),
                Tab(text: l10n.mediaTabLabel),
                Tab(text: l10n.filesTabLabel),
                Tab(text: l10n.linksTabLabel),
              ],
            );
            return NestedScrollView(
              controller: _scrollController,
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                ...headerSlivers,
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _PinnedTabBarDelegate(
                    tabBar: tabBar,
                    backgroundColor: theme.colorScheme.surface,
                  ),
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  PeopleTab(
                    tripId: trip.id,
                    currentUserId: widget.viewModel.currentUserId,
                    tripRepository: widget.tripRepository,
                    profileRepository: widget.viewModel.profileRepository,
                    creatorUserId: trip.creatorUserId,
                    organizerDiveCenter: widget.viewModel.organizerDiveCenter,
                  ),
                  MediaTab(future: _mediaFuture!),
                  FilesTab(future: _filesFuture!),
                  LinksTab(future: _linksFuture!),
                ],
              ),
            );
          }

          // General view — no tabs, so a plain CustomScrollView; organizer card + participant count are deliberately gated on how this screen was reached, not just trip.joined, since the general preview never shows who's in the trip even to an already-joined viewer.
          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              ...headerSlivers,
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _OrganizerCard(
                        isOrganizer: isOrganizer,
                        profile: widget.viewModel.organizerProfile,
                        creatorUserId: trip.creatorUserId,
                        currentUserId: widget.viewModel.currentUserId,
                        profileRepository: widget.viewModel.profileRepository,
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
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  // Bottom-only: the Join/Book now button needs room above the system nav bar, or 3-button nav on Android overlaps it.
                  padding: EdgeInsets.fromLTRB(
                    16,
                    24,
                    16,
                    16 + MediaQuery.paddingOf(context).bottom,
                  ),
                  child: trip.joined
                      ? _DiveInButton(
                          trip: trip,
                          chatRepository: widget.chatRepository,
                          transportRepository: widget.transportRepository,
                          buddyRepository: widget.buddyRepository,
                          realtimeService: widget.realtimeService,
                          tripRepository: widget.tripRepository,
                          authRepository: widget.viewModel.authRepository,
                          profileRepository: widget.viewModel.profileRepository,
                          pushRepository: widget.viewModel.pushRepository,
                          diveCenterRepository: widget.diveCenterRepository,
                          expenseRepository: widget.expenseRepository,
                          currentUserId: widget.viewModel.currentUserId,
                        )
                      : !isOrganizer && trip.bookingStatus == 'open'
                      ? widget.entryCode != null
                            ? _InviteJoinButton(
                                code: widget.entryCode!,
                                viewModel: widget.viewModel,
                              )
                            : trip.diveCenterId != null
                            ? _BookNowSection(
                                trip: trip,
                                diveCenter:
                                    widget.viewModel.organizerDiveCenter,
                                viewModel: widget.viewModel,
                                tripRepository: widget.tripRepository,
                                chatRepository: widget.chatRepository,
                                transportRepository: widget.transportRepository,
                                buddyRepository: widget.buddyRepository,
                                realtimeService: widget.realtimeService,
                                diveCenterRepository:
                                    widget.diveCenterRepository,
                                expenseRepository: widget.expenseRepository,
                              )
                            : trip.isPrivate
                            ? _PrivateJoinSection(
                                trip: trip,
                                viewModel: widget.viewModel,
                                tripRepository: widget.tripRepository,
                                chatRepository: widget.chatRepository,
                                transportRepository: widget.transportRepository,
                                buddyRepository: widget.buddyRepository,
                                realtimeService: widget.realtimeService,
                                diveCenterRepository:
                                    widget.diveCenterRepository,
                                expenseRepository: widget.expenseRepository,
                              )
                            : _JoinButton(
                                trip: trip,
                                viewModel: widget.viewModel,
                              )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _participantsText(Trip trip) {
    final l10n = AppLocalizations.of(context);
    final count = trip.participantCount;
    if (trip.maxParticipants != null) {
      return l10n.participantsJoinedOfMaxPlural(count, trip.maxParticipants!);
    }
    return l10n.participantsJoinedPlural(count);
  }
}

/// Pinned once scrolled up to meet the toolbar; everything above it scrolls away normally.
class _PinnedTabBarDelegate extends SliverPersistentHeaderDelegate {
  _PinnedTabBarDelegate({required this.tabBar, required this.backgroundColor});

  final TabBar tabBar;
  final Color backgroundColor;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Material(
      color: backgroundColor,
      elevation: overlapsContent ? 2 : 0,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant _PinnedTabBarDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}

/// The organizer gets an "Organizer" pill next to their row instead of a separate card, so they never appear twice in the list.
class PeopleTab extends StatefulWidget {
  const PeopleTab({
    super.key,
    required this.tripId,
    required this.currentUserId,
    required this.tripRepository,
    required this.profileRepository,
    required this.creatorUserId,
    this.organizerDiveCenter,
  });

  final String tripId;
  final String currentUserId;
  final TripRepository tripRepository;
  final ProfileRepository profileRepository;
  final String? creatorUserId;

  /// Set for a business trip: the dive center gets its own pinned row; when null, the organizer pill lands on whichever participant row matches [creatorUserId].
  final DiveCenter? organizerDiveCenter;

  @override
  State<PeopleTab> createState() => _PeopleTabState();
}

class _PeopleTabState extends State<PeopleTab> {
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
      if (mounted) setState(() => _error = friendlyError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_error != null) {
      return Center(
        child: Text(
          AppLocalizations.of(context).errorWithMessage(_error!),
          style: TextStyle(color: theme.colorScheme.error),
        ),
      );
    }
    if (_userIds == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    final dc = widget.organizerDiveCenter;
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      children: [
        if (dc != null) ...[
          _PersonRow(
            avatar: CircleAvatar(
              radius: 16,
              backgroundColor: theme.colorScheme.secondaryContainer,
              backgroundImage: (dc.logoUrl?.isNotEmpty ?? false)
                  ? NetworkImage(dc.logoUrl!)
                  : null,
              child: (dc.logoUrl?.isNotEmpty ?? false)
                  ? null
                  : Icon(
                      Icons.storefront_outlined,
                      size: 18,
                      color: theme.colorScheme.onSecondaryContainer,
                    ),
            ),
            name: dc.name,
            isOrganizer: true,
            onTap: () => showDiveCenterCard(context, dc),
          ),
          const Divider(height: 20),
        ],
        for (final userId in _userIds!)
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              final profile = _profiles[userId];
              final baseName = (profile?.displayName?.isNotEmpty ?? false)
                  ? profile!.displayName!
                  : l10n.diver;
              final name = (profile?.isProductObserver ?? false)
                  ? '$baseName | ${l10n.productObserver}'
                  : baseName;
              return _PersonRow(
                avatar: CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  backgroundImage: (profile?.avatarUrl?.isNotEmpty ?? false)
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
                name: name,
                isOrganizer: dc == null && userId == widget.creatorUserId,
                onTap: () => showDiverIdCard(
                  context,
                  userId: userId,
                  currentUserId: widget.currentUserId,
                  profileRepository: widget.profileRepository,
                ),
              );
            },
          ),
      ],
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({
    required this.avatar,
    required this.name,
    required this.isOrganizer,
    required this.onTap,
  });

  final Widget avatar;
  final String name;
  final bool isOrganizer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          children: [
            avatar,
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name,
                style: theme.textTheme.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isOrganizer) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  AppLocalizations.of(context).organizerLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// The one block genuinely shared between the general view and Bubble Info, now a single widget instead of two independently-maintained copies.
class _TripInfoBlock extends StatelessWidget {
  const _TripInfoBlock({required this.trip, required this.isOrganizer});

  final Trip trip;
  final bool isOrganizer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
            l10n.meetingPointSectionLabel,
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
          if (isOrganizer && trip.bookingCode != null) ...[
            const SizedBox(height: 16),
            _BookingCodeRow(bookingCode: trip.bookingCode!),
          ],
          const SizedBox(height: 16),
          _InfoGrid(trip: trip),
          if (trip.description != null) ...[
            const SizedBox(height: 20),
            Text(l10n.aboutThisDive, style: theme.textTheme.labelLarge),
            const SizedBox(height: 6),
            Text(trip.description!, style: theme.textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final depthText = _depthText(trip, l10n);
    final diveCountText = _diveCountText(trip, l10n);
    final tiles = <Widget>[
      _InfoTile(
        icon: Icons.badge_outlined,
        label: l10n.levelSectionLabel,
        value: certificationLevelAbbreviation(trip.minCertification),
      ),
      if (depthText != null)
        _InfoTile(icon: Icons.waves, label: l10n.depthSectionLabel, value: depthText),
      if (diveCountText != null)
        _InfoTile(
          icon: Icons.scuba_diving_outlined,
          label: l10n.divesSectionLabel,
          value: diveCountText,
        ),
      _InfoTile(
        icon: Icons.schedule,
        label: l10n.durationSectionLabel,
        value: _durationText(trip, l10n),
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

  static String? _depthText(Trip trip, AppLocalizations l10n) {
    final min = trip.depthMinM;
    final max = trip.depthMaxM;
    if (min == null && max == null) return null;
    if (min != null && max != null) {
      if (min == max) return l10n.depthExactMeters(min);
      return l10n.depthRangeMeters(min, max);
    }
    if (max != null) return l10n.depthUpToMeters(max);
    return l10n.depthMinPlusMeters(min!);
  }

  static String? _diveCountText(Trip trip, AppLocalizations l10n) {
    final min = trip.diveCountMin;
    final max = trip.diveCountMax;
    if (min == null && max == null) return null;
    if (min != null && max != null) {
      if (min == max) return l10n.diveCountExactPlural(min);
      return l10n.diveCountRangeDives(min, max);
    }
    if (max != null) return l10n.diveCountUpToDives(max);
    return l10n.diveCountMinPlusDives(min!);
  }

  static String _durationText(Trip trip, AppLocalizations l10n) {
    final end = trip.endDate;
    if (end == null) return l10n.durationDaysPlural(1);
    final start = trip.startTime.toLocal();
    final endLocal = end.toLocal();
    final startDate = DateTime(start.year, start.month, start.day);
    final endDateOnly = DateTime(endLocal.year, endLocal.month, endLocal.day);
    final days = endDateOnly.difference(startDate).inDays + 1;
    return l10n.durationDaysPlural(days);
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
              // A longer translated label can outgrow this tile's half-row width — shrink to fit on one line instead of overflowing.
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
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

  /// Set for a business trip: the dive center's identity is shown instead of the specific staff member who happened to create it.
  final DiveCenter? diveCenter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
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
                      l10n.diveCenterLabel,
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
        : l10n.organizerLabel;

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
                  isOrganizer ? l10n.organizerYou : l10n.organizerLabel,
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

// Only rendered for the actionable open-not-joined case; takes priority over _BookNowSection/_PrivateJoinSection/_JoinButton since the code that resolved this preview already IS the credential.
class _InviteJoinButton extends StatelessWidget {
  const _InviteJoinButton({required this.code, required this.viewModel});

  final String code;
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
            : Text(AppLocalizations.of(context).join),
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
    await viewModel.joinByCode(code);
  }
}

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
            : Text(AppLocalizations.of(context).join),
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

/// Replaces _JoinButton for business trips — we're a marketplace, not the one taking the diver's money, so there's no direct Join here.
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
    required this.expenseRepository,
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
  final ExpenseRepository expenseRepository;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final url = trip.bookingUrl ?? diveCenter?.website;
    final priceMinor = trip.priceMinor;
    final label = priceMinor != null
        ? l10n.bookNowWithPrice((priceMinor / 100).toStringAsFixed(2), trip.currency)
        : l10n.bookNowLabel;

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
            onPressed: () => _enterBookingCode(
              context: context,
              trip: trip,
              viewModel: viewModel,
              tripRepository: tripRepository,
              chatRepository: chatRepository,
              transportRepository: transportRepository,
              buddyRepository: buddyRepository,
              realtimeService: realtimeService,
              diveCenterRepository: diveCenterRepository,
              expenseRepository: expenseRepository,
            ),
            child: Text(AppLocalizations.of(context).iHaveABookingCode),
          ),
        ),
      ],
    );
  }
}

/// Shared by _BookNowSection and _PrivateJoinSection — same "enter a code" recovery path either way.
Future<void> _enterBookingCode({
  required BuildContext context,
  required Trip trip,
  required TripViewModel viewModel,
  required TripRepository tripRepository,
  required ChatRepository chatRepository,
  required TransportRepository transportRepository,
  required BuddyRepository buddyRepository,
  required RealtimeService realtimeService,
  required DiveCenterRepository diveCenterRepository,
  required ExpenseRepository expenseRepository,
}) async {
  final userId = await ensureSignedIn(
    context,
    viewModel.authRepository,
    viewModel.profileRepository,
    viewModel.pushRepository,
  );
  if (userId == null || !context.mounted) return;

  final resolved = await showJoinByCodeDialog(context, tripRepository);
  if (resolved == null) return;

  // Same trip this page is already showing — just refresh in place. A code for a different trip opens that trip directly instead.
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
        expenseRepository: expenseRepository,
      ),
    ),
  );
}

/// Replaces _JoinButton for private trips — same server-side rejection of direct Join as a business trip, same code-recovery path, but shared by the organizer rather than handed out after an external payment.
class _PrivateJoinSection extends StatelessWidget {
  const _PrivateJoinSection({
    required this.trip,
    required this.viewModel,
    required this.tripRepository,
    required this.chatRepository,
    required this.transportRepository,
    required this.buddyRepository,
    required this.realtimeService,
    required this.diveCenterRepository,
    required this.expenseRepository,
  });

  final Trip trip;
  final TripViewModel viewModel;
  final TripRepository tripRepository;
  final ChatRepository chatRepository;
  final TransportRepository transportRepository;
  final BuddyRepository buddyRepository;
  final RealtimeService realtimeService;
  final DiveCenterRepository diveCenterRepository;
  final ExpenseRepository expenseRepository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          AppLocalizations.of(context).privateTripAskOrganizer,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () => _enterBookingCode(
            context: context,
            trip: trip,
            viewModel: viewModel,
            tripRepository: tripRepository,
            chatRepository: chatRepository,
            transportRepository: transportRepository,
            buddyRepository: buddyRepository,
            realtimeService: realtimeService,
            diveCenterRepository: diveCenterRepository,
            expenseRepository: expenseRepository,
          ),
          child: Text(AppLocalizations.of(context).iHaveAnInviteCode),
        ),
      ],
    );
  }
}

const _joinLinkBaseUrl = 'https://divebubble.io/join/';

/// The same code a private trip is gated on, or the code business dive-center staff would otherwise look up in admin/. Never shown to a non-organizer viewer.
class _BookingCodeRow extends StatelessWidget {
  _BookingCodeRow({required this.bookingCode});

  final String bookingCode;

  // Anchors the share popover to this button on iPad/Mac, required there or it throws, harmless elsewhere.
  final _actionButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context).inviteCodeSectionLabel,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                bookingCode,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          key: _actionButtonKey,
          icon: const Icon(Icons.ios_share),
          tooltip: AppLocalizations.of(context).shareInviteTooltip,
          onPressed: () => _showBookingCodeActionsSheet(
            context,
            bookingCode,
            _actionButtonKey,
          ),
        ),
      ],
    );
  }
}

enum _BookingCodeAction { copyCode, copyLink, shareLink }

Future<void> _showBookingCodeActionsSheet(
  BuildContext context,
  String bookingCode,
  GlobalKey shareButtonKey,
) async {
  final action = await showModalBottomSheet<_BookingCodeAction>(
    context: context,
    builder: (context) {
      final l10n = AppLocalizations.of(context);
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.ios_share),
              title: Text(l10n.shareInviteLink),
              onTap: () =>
                  Navigator.of(context).pop(_BookingCodeAction.shareLink),
            ),
            ListTile(
              leading: const Icon(Icons.link_outlined),
              title: Text(l10n.copyInviteLink),
              onTap: () => Navigator.of(context).pop(_BookingCodeAction.copyLink),
            ),
            ListTile(
              leading: const Icon(Icons.tag_outlined),
              title: Text(l10n.copyBookingCode),
              onTap: () => Navigator.of(context).pop(_BookingCodeAction.copyCode),
            ),
          ],
        ),
      );
    },
  );
  if (action == null || !context.mounted) return;

  final link = '$_joinLinkBaseUrl$bookingCode';
  switch (action) {
    case _BookingCodeAction.copyCode:
      await Clipboard.setData(ClipboardData(text: bookingCode));
    case _BookingCodeAction.copyLink:
      await Clipboard.setData(ClipboardData(text: link));
    case _BookingCodeAction.shareLink:
      // Anchors the share popover to the button on iPad/Mac — required there or it throws, harmless elsewhere.
      final box =
          shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
      final origin = box == null
          ? null
          : (box.localToGlobal(Offset.zero) & box.size);
      await SharePlus.instance.share(
        ShareParams(text: link, sharePositionOrigin: origin),
      );
      return;
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).copiedToClipboard)));
}

/// Mute is always shown; Leave (joined, non-organizer) and Cancel (organizer, not already cancelled) are mutually exclusive.
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
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        Expanded(
          child: _ActionPill(
            icon: viewModel.isMuted
                ? Icons.notifications_off_outlined
                : Icons.notifications_none,
            label: viewModel.isMuted ? l10n.unmute : l10n.mute,
            onTap: viewModel.toggleMute,
          ),
        ),
        if (trip.joined && !isOrganizer) ...[
          const SizedBox(width: 8),
          Expanded(
            child: _ActionPill(
              icon: Icons.logout,
              label: l10n.leave,
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
              label: l10n.cancel,
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

/// Pops all the way back out of the Bubble on success; MyTripsView's own post-return reload after its Navigator.push around TripConversationPage already picks up the trip disappearing.
Future<void> _handleLeave(BuildContext context, TripViewModel viewModel) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.leaveBubbleTitle),
      content: Text(l10n.leaveBubbleBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.cancel),
        ),
        TextButton(
          style: AppButtonStyles.ghost.copyWith(
            foregroundColor: WidgetStatePropertyAll(
              Theme.of(context).colorScheme.error,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.leave),
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

/// Organizer-only. Final: no reopen path exists once cancelled.
Future<void> _handleCancel(
  BuildContext context,
  TripViewModel viewModel,
) async {
  final l10n = AppLocalizations.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.cancelTripTitle),
      content: Text(l10n.cancelTripBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.neverMind),
        ),
        TextButton(
          style: AppButtonStyles.ghost.copyWith(
            foregroundColor: WidgetStatePropertyAll(
              Theme.of(context).colorScheme.error,
            ),
          ),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.cancelTrip),
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
  ).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).tripCancelledSnackbar)));
}

/// A single icon-over-label pill — [_ActionPillsRow] lays two of these out evenly.
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

/// Nothing shown for the common "open, not yet joined" case, matching the app's quiet-by-default badges.
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
    final l10n = AppLocalizations.of(context);

    // Cancelled outranks Organizer/Joined — that's the one thing everyone in the Bubble needs to see at a glance, organizer included.
    if (trip.bookingStatus == 'cancelled') {
      label = l10n.cancelledStatus;
      background = theme.colorScheme.surfaceContainerHighest;
      foreground = theme.colorScheme.onSurfaceVariant;
    } else if (isOrganizer) {
      // Of course the organizer is "joined" — that label is more useful for everyone else.
      label = l10n.organizerLabel;
      background = theme.colorScheme.primaryContainer;
      foreground = theme.colorScheme.onPrimaryContainer;
    } else if (trip.joined) {
      label = l10n.joinedStatus;
      background = semantic.successContainer;
      foreground = semantic.onSuccessContainer;
    } else if (trip.bookingStatus == 'full') {
      label = l10n.fullStatus;
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

/// Takes the diver straight into the trip's chat rather than leaving them on a static "Joined" chip with nowhere to go.
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
    required this.expenseRepository,
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
  final ExpenseRepository expenseRepository;
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
              builder: (_) => TripConversationPage.forTrip(
                trip: trip,
                currentUserId: currentUserId,
                tripRepository: tripRepository,
                chatRepository: chatRepository,
                transportRepository: transportRepository,
                buddyRepository: buddyRepository,
                realtimeService: realtimeService,
                authRepository: authRepository,
                profileRepository: profileRepository,
                pushRepository: pushRepository,
                diveCenterRepository: diveCenterRepository,
                expenseRepository: expenseRepository,
              ),
            ),
          );
          // Catches any messages that arrived while actively in the chat; the Bubbles list picks up the corrected count next time it's opened.
          tripRepository.markRead(trip.id).catchError((_) {});
        },
        icon: const Icon(Icons.chat_bubble_outline, size: 18),
        label: Text(AppLocalizations.of(context).diveInToBubble),
      ),
    );
  }
}

/// A grid instead of one-at-a-time controls overlaid on the hero slider, with multi-select add instead of picking one file per tap.
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
        // Sequential, not parallel — same position-race reasoning as CreateTripPage's multi-upload loop.
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
            content: Text(AppLocalizations.of(context).onlyNPhotosAllowed(_maxTripPhotos)),
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
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.managePhotos),
        // Not functionally different from the back button, since every add/remove already commits immediately — "Save" just reads as a clearer "I'm done here".
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.save),
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
                    l10n.uploadUpToNPhotos(_maxTripPhotos),
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
