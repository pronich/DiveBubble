import 'package:flutter/material.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/buddy_repository.dart';
import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/repositories/dive_center_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/push_repository.dart';
import '../../../../data/repositories/transport_repository.dart';
import '../../../../data/repositories/trip_repository.dart';
import '../../../../data/services/realtime_service.dart';
import '../../buddy/view_models/buddy_view_model.dart';
import '../../buddy/views/buddy_view.dart';
import '../../transport/view_models/transport_view_model.dart';
import '../../transport/views/transport_view.dart';
import '../../trips/view_models/trip_view_model.dart';
import '../../trips/views/trip_page.dart';
import '../../../core/theme/app_colors.dart';
import '../view_models/chat_view_model.dart';
import 'chat_view.dart';

/// Shell for a joined trip: Chat and Transport are the two things worth reaching
/// immediately, so they're tabs here rather than buried inside Trip Page (which
/// stays reachable by tapping the title, for the fuller trip overview).
class TripConversationPage extends StatefulWidget {
  const TripConversationPage({
    super.key,
    required this.chatViewModel,
    required this.transportViewModel,
    required this.buddyViewModel,
    required this.tripTitle,
    this.tripPhotoUrl,
    required this.tripRepository,
    required this.chatRepository,
    required this.transportRepository,
    required this.buddyRepository,
    required this.realtimeService,
    required this.authRepository,
    required this.profileRepository,
    required this.pushRepository,
    required this.diveCenterRepository,
    required this.initialHasTransportAlert,
    this.onTransportAlertCleared,
    required this.initialHasBuddyAlert,
    this.onBuddyAlertCleared,
  });

  final ChatViewModel chatViewModel;
  final TransportViewModel transportViewModel;
  final BuddyViewModel buddyViewModel;
  final String tripTitle;
  // Rendered as a small tappable thumbnail on the right of the AppBar (see build) —
  // null shows a plain placeholder icon instead, same fallback every other trip photo spot
  // in the app uses.
  final String? tripPhotoUrl;
  final TripRepository tripRepository;
  final ChatRepository chatRepository;
  final TransportRepository transportRepository;
  final BuddyRepository buddyRepository;
  final RealtimeService realtimeService;
  final AuthRepository authRepository;
  final ProfileRepository profileRepository;
  final PushRepository pushRepository;
  final DiveCenterRepository diveCenterRepository;
  // Seeds TransportViewModel.hasAlert from the already-loaded Trip — the Bubble is only
  // ever reached by tapping a row from that loaded list, so this is always available and
  // skips a redundant GET /trips/{id}/transport/alert on every chat open.
  final bool initialHasTransportAlert;
  // Fired once the Transport tab is actually visited and the alert clears server-side —
  // lets MyTripsViewModel flip the same flag locally so the bottom-nav dot and Bubbles
  // row indicator update immediately, without MyTripsView refetching the whole list.
  final VoidCallback? onTransportAlertCleared;
  // Same two as above, for BuddyViewModel.hasAlert.
  final bool initialHasBuddyAlert;
  final VoidCallback? onBuddyAlertCleared;

  @override
  State<TripConversationPage> createState() => _TripConversationPageState();
}

class _TripConversationPageState extends State<TripConversationPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  bool _isCancelled = false;
  String? _businessName;
  // Gates the "@mention" composer chip off for the caller's own dive center — a staff
  // member mentioning their own business is meaningless (see ChatView.businessName's own
  // gate, which only checks "is this a business trip", not "am I the diver here").
  bool _isDiveCenterStaff = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_onTabChanged);
    // Seeded from the Trip already in hand (see the field's own comment) — the dot itself
    // lives in the AppBar, always visible regardless of which tab is active, so this is
    // what actually surfaces it before the diver ever switches to Transport/Buddy.
    widget.transportViewModel.seedAlert(widget.initialHasTransportAlert);
    widget.buddyViewModel.seedAlert(widget.initialHasBuddyAlert);
    _refreshTripDerivedState();
  }

  // Owned here, not by ChatViewModel/TransportViewModel — both tabs (plus the message
  // attribution below) just need plain read-only values derived from the trip, and a
  // single fetch avoids duplicating this (and its own realtime-subscription-shaped
  // footguns, see RealtimeService) into multiple ViewModels.
  Future<void> _refreshTripDerivedState() async {
    try {
      final trip = await widget.tripRepository.getTrip(
        widget.chatViewModel.tripId,
      );
      final diveCenterId = trip.diveCenterId;
      String? businessName;
      var isDiveCenterStaff = false;
      if (diveCenterId != null) {
        try {
          businessName = (await widget.diveCenterRepository.getById(
            diveCenterId,
          )).name;
        } catch (_) {
          // Best-effort — chat messages just fall back to the sender's plain name.
        }
        try {
          isDiveCenterStaff = await widget.diveCenterRepository.isMember(
            diveCenterId,
          );
        } catch (_) {
          // Best-effort — worst case the mention chip stays visible for a staff member.
        }
      }
      if (mounted) {
        setState(() {
          _isCancelled = trip.bookingStatus == 'cancelled';
          _businessName = businessName;
          _isDiveCenterStaff = isDiveCenterStaff;
        });
      }
    } catch (_) {
      // Best-effort — worst case the input stays enabled until the next successful check,
      // and the server-side guards (EnsureNotCancelled) still reject the action either way.
    }
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    if (_tabController.index == 1) {
      widget.transportViewModel.checkAlert().then(
        (_) => widget.onTransportAlertCleared?.call(),
      );
    } else if (_tabController.index == 2) {
      widget.buddyViewModel.checkAlert().then(
        (_) => widget.onBuddyAlertCleared?.call(),
      );
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: InkWell(
          onTap: () => _openTripPage(context),
          child: Text(
            widget.tripTitle,
            style: theme.textTheme.headlineSmall,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: () => _openTripPage(context),
              customBorder: const CircleBorder(),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.secondaryContainer,
                backgroundImage: (widget.tripPhotoUrl?.isNotEmpty ?? false)
                    ? NetworkImage(widget.tripPhotoUrl!)
                    : null,
                child: (widget.tripPhotoUrl?.isNotEmpty ?? false)
                    ? null
                    : Icon(
                        Icons.image_outlined,
                        size: 18,
                        color: theme.colorScheme.onSecondaryContainer,
                      ),
              ),
            ),
          ),
        ],
        bottom: _PillTabBar(
          tabController: _tabController,
          transportViewModel: widget.transportViewModel,
          buddyViewModel: widget.buddyViewModel,
          isCancelled: _isCancelled,
          businessName: _businessName,
        ),
      ),
      // Swipe-to-switch-tabs disabled: TabBarView's own horizontal drag recognizer competed
      // with each tab's vertical message scroll for any diagonal drag, sometimes hijacking a
      // scroll attempt into an accidental tab switch. The pill bar above already covers
      // switching tabs by tap, so nothing is lost by requiring that instead of a swipe.
      body: TabBarView(
        controller: _tabController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          ChatView(
            viewModel: widget.chatViewModel,
            isCancelled: _isCancelled,
            businessName: _businessName,
            canMentionDiveCenter: !_isDiveCenterStaff,
          ),
          TransportView(
            viewModel: widget.transportViewModel,
            chatRepository: widget.chatRepository,
            realtimeService: widget.realtimeService,
            isCancelled: _isCancelled,
            businessName: _businessName,
          ),
          BuddyView(
            viewModel: widget.buddyViewModel,
            chatRepository: widget.chatRepository,
            realtimeService: widget.realtimeService,
            isCancelled: _isCancelled,
          ),
        ],
      ),
    );
  }

  Future<void> _openTripPage(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TripPage(
          viewModel: TripViewModel(
            repository: widget.tripRepository,
            authRepository: widget.authRepository,
            profileRepository: widget.profileRepository,
            pushRepository: widget.pushRepository,
            diveCenterRepository: widget.diveCenterRepository,
            tripId: widget.chatViewModel.tripId,
            currentUserId: widget.chatViewModel.currentUserId,
          ),
          tripRepository: widget.tripRepository,
          chatRepository: widget.chatRepository,
          transportRepository: widget.transportRepository,
          buddyRepository: widget.buddyRepository,
          realtimeService: widget.realtimeService,
          diveCenterRepository: widget.diveCenterRepository,
          openedFromConversation: true,
        ),
      ),
    );
    // Trip Page is the only place bookingStatus can change (Cancel Trip) — refresh once
    // back, since ChatView/TransportView otherwise have no reason to know it changed.
    if (mounted) _refreshTripDerivedState();
  }
}

/// Airbnb/iOS-style segmented pill tab bar — the active segment expands to icon+label, the
/// other two collapse to icon-only circles. Pure restyle of a plain TabBar: same controller,
/// same 3 tabs, same tap-to-switch behavior, alert dot and ⓘ affordances carried over.
class _PillTabBar extends StatelessWidget implements PreferredSizeWidget {
  const _PillTabBar({
    required this.tabController,
    required this.transportViewModel,
    required this.buddyViewModel,
    required this.isCancelled,
    required this.businessName,
  });

  final TabController tabController;
  final TransportViewModel transportViewModel;
  final BuddyViewModel buddyViewModel;
  final bool isCancelled;
  final String? businessName;

  static const _compactWidth = 44.0;
  static const _pillHeight = 44.0;
  static const _gap = 8.0;
  // Both tab-tap page transitions and the pill's own width morph share this duration/curve —
  // kept in sync deliberately so the two motions read as one, not two competing animations.
  static const _switchDuration = Duration(milliseconds: 320);
  static const _switchCurve = Curves.easeOutCubic;

  static const _topGap = 10.0;

  @override
  Size get preferredSize => const Size.fromHeight(_pillHeight + _topGap + 12);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        tabController,
        transportViewModel,
        buddyViewModel,
      ]),
      builder: (context, _) {
        final activeIndex = tabController.index;
        final myOffer = transportViewModel.myOffer;
        final myRequest = buddyViewModel.myRequest;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, _topGap, 16, 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final activeWidth =
                  constraints.maxWidth - _gap * 2 - _compactWidth * 2;
              return SizedBox(
                height: _pillHeight,
                child: Row(
                  children: [
                    _PillSegment(
                      isActive: activeIndex == 0,
                      width: activeIndex == 0 ? activeWidth : _compactWidth,
                      outlinedIcon: Icons.chat_bubble_outline,
                      filledIcon: Icons.chat_bubble,
                      label: 'Chat',
                      hasAlert: false,
                      onTap: () => tabController.animateTo(
                        0,
                        duration: _switchDuration,
                        curve: _switchCurve,
                      ),
                    ),
                    const SizedBox(width: _gap),
                    _PillSegment(
                      isActive: activeIndex == 1,
                      width: activeIndex == 1 ? activeWidth : _compactWidth,
                      outlinedIcon: Icons.directions_car_outlined,
                      filledIcon: Icons.directions_car,
                      label: 'Transport',
                      hasAlert: transportViewModel.hasAlert,
                      onTap: () => tabController.animateTo(
                        1,
                        duration: _switchDuration,
                        curve: _switchCurve,
                      ),
                      // Only reachable once you're actually in a car — a plain offers list has
                      // nothing to show info about or leave/dissolve yet. Only surfaced on the
                      // active, expanded segment — no room for a second tap target once
                      // collapsed to an icon.
                      onInfoTap: myOffer == null
                          ? null
                          : () => showTransportOfferDetailSheet(
                              context,
                              offerId: myOffer.id,
                              viewModel: transportViewModel,
                              isCancelled: isCancelled,
                              businessName: businessName,
                            ),
                    ),
                    const SizedBox(width: _gap),
                    _PillSegment(
                      isActive: activeIndex == 2,
                      width: activeIndex == 2 ? activeWidth : _compactWidth,
                      outlinedIcon: Icons.emoji_people_outlined,
                      filledIcon: Icons.emoji_people,
                      label: 'Buddy',
                      hasAlert: buddyViewModel.hasAlert,
                      onTap: () => tabController.animateTo(
                        2,
                        duration: _switchDuration,
                        curve: _switchCurve,
                      ),
                      onInfoTap: myRequest == null
                          ? null
                          : () => showBuddyRequestDetailSheet(
                              context,
                              requestId: myRequest.id,
                              viewModel: buddyViewModel,
                              isCancelled: isCancelled,
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _PillSegment extends StatelessWidget {
  const _PillSegment({
    required this.isActive,
    required this.width,
    required this.outlinedIcon,
    required this.filledIcon,
    required this.label,
    required this.hasAlert,
    required this.onTap,
    this.onInfoTap,
  });

  final bool isActive;
  final double width;
  final IconData outlinedIcon;
  final IconData filledIcon;
  final String label;
  final bool hasAlert;
  final VoidCallback onTap;
  final VoidCallback? onInfoTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Both states sit on soft, near-identical light-blue backgrounds — content color stays
    // the same dark navy in both, only the background shade shifts (see AppColors.surfaceSelected
    // vs surfaceSecondary and the textOnLightBlue token, all straight from Figma).
    const contentColor = AppColors.textOnLightBlue;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: _PillTabBar._switchDuration,
        curve: _PillTabBar._switchCurve,
        width: width,
        height: double.infinity,
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.surfaceSelected
              : AppColors.surfaceSecondary,
          borderRadius: BorderRadius.circular(_PillTabBar._pillHeight / 2),
        ),
        clipBehavior: Clip.none,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isActive ? filledIcon : outlinedIcon,
                    size: 20,
                    color: contentColor,
                  ),
                  if (isActive) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: contentColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (isActive && onInfoTap != null)
              Positioned(
                right: 4,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onInfoTap,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.info_outline,
                          size: 16,
                          color: contentColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (hasAlert)
              Positioned(
                right: isActive ? -2 : -6,
                top: -2,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
