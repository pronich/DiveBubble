import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/dive_center_repository.dart';
import '../../../data/repositories/message_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../data/repositories/specialty_repository.dart';
import '../../../data/repositories/transport_repository.dart';
import '../../../data/repositories/trip_repository.dart';
import '../../../data/services/realtime_service.dart';
import '../../../domain/entities/dive_center.dart';
import '../../../domain/entities/my_profile.dart';
import '../../features/account/views/account_page.dart';
import '../../features/bubbles/views/bubbles_page.dart';
import '../../features/company/views/company_page.dart';
import '../../features/trips/views/trips_page.dart';
import '../../features/users/views/users_page.dart';

/// The whole app's persistent frame once signed in: a fixed left sidebar (nav + account
/// footer) with a swappable content area on the right — replaces the old
/// one-screen-per-Scaffold navigation (see CLAUDE.md's admin/ scaffolding notes). Every
/// section is body-only (no own Scaffold/AppBar), same "embedded, not pushed" pattern
/// app/'s ChatView/TransportView use inside TripConversationPage.
class AdminShell extends StatefulWidget {
  const AdminShell({
    super.key,
    required this.diveCenter,
    required this.diveCenterRepository,
    required this.tripRepository,
    required this.messageRepository,
    required this.profileRepository,
    required this.specialtyRepository,
    required this.transportRepository,
    required this.realtimeService,
    required this.authRepository,
    required this.onSignedOut,
  });

  final DiveCenter diveCenter;
  final DiveCenterRepository diveCenterRepository;
  final TripRepository tripRepository;
  final MessageRepository messageRepository;
  final ProfileRepository profileRepository;
  final SpecialtyRepository specialtyRepository;
  final TransportRepository transportRepository;
  final RealtimeService realtimeService;
  final AuthRepository authRepository;
  final VoidCallback onSignedOut;

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selectedIndex = 0;
  MyProfile? _profile;

  // Mirrors _selectedIndex for pages built once via `late final _pages` below (a plain
  // constructor arg on those pages would only ever see the index's value at that first
  // build) — BubblesPage listens to this directly to know when it becomes the active tab.
  final _selectedIndexNotifier = ValueNotifier<int>(0);

  // Set by "Dive into Bubble" (Trip Page → Bubbles) — BubblesPage listens and, once it's
  // consumed the request (selected that trip), resets this back to null so switching tabs
  // away and back doesn't reselect it.
  final _pendingBubbleTripId = ValueNotifier<String?>(null);

  // Mirrors BubblesViewModel.hasUnreadMention (see BubblesPage.onMentionStateChanged) —
  // the sidebar listens to this directly since it needs to show a dot even while Bubbles
  // itself isn't the active section.
  final _hasUnreadMention = ValueNotifier<bool>(false);

  void _diveIntoBubble(String tripId) {
    setState(() {
      _selectedIndex = 1;
      _selectedIndexNotifier.value = 1;
    });
    _pendingBubbleTripId.value = tripId;
  }

  // Sidebar-only display state — kept separate from _pages below so a Company edit can
  // refresh the account-footer company name without rebuilding (and losing the state of)
  // every other section.
  late String _companyName = widget.diveCenter.name;

  // Built once each, not inline in build() — an IndexedStack still rebuilds its children on
  // every parent rebuild if they're constructed inline, which would wipe each section's own
  // state on every sidebar tap (same gotcha app/'s RootShell already hit once — see CLAUDE.md).
  late final _pages = [
    TripsPage(
      tripRepository: widget.tripRepository,
      diveCenterId: widget.diveCenter.id,
      onDiveIntoBubble: _diveIntoBubble,
    ),
    BubblesPage(
      tripRepository: widget.tripRepository,
      messageRepository: widget.messageRepository,
      profileRepository: widget.profileRepository,
      transportRepository: widget.transportRepository,
      realtimeService: widget.realtimeService,
      diveCenterId: widget.diveCenter.id,
      diveCenterName: widget.diveCenter.name,
      getCurrentUserId: widget.authRepository.currentUserId,
      selectedTabIndex: _selectedIndexNotifier,
      openTripId: _pendingBubbleTripId,
      onDiveIntoBubble: _diveIntoBubble,
      onMentionStateChanged: (v) => _hasUnreadMention.value = v,
    ),
    UsersPage(diveCenterRepository: widget.diveCenterRepository, diveCenterId: widget.diveCenter.id),
    CompanyPage(
      diveCenter: widget.diveCenter,
      diveCenterRepository: widget.diveCenterRepository,
      onUpdated: (dc) => setState(() => _companyName = dc.name),
    ),
  ];

  @override
  void initState() {
    super.initState();
    widget.profileRepository.getMe().then((p) {
      if (mounted) setState(() => _profile = p);
    }).catchError((_) {
      // Best-effort — the account footer just falls back to email-less initials if this fails.
    });
  }

  @override
  void dispose() {
    _selectedIndexNotifier.dispose();
    _pendingBubbleTripId.dispose();
    _hasUnreadMention.dispose();
    super.dispose();
  }

  // Below this, a permanent 260px sidebar leaves too little room for actual content — a
  // browser window this narrow is either a phone or a very cramped desktop window either way.
  static const _mobileBreakpoint = 760.0;

  void _onAccountTap(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AccountPage(
          profileRepository: widget.profileRepository,
          specialtyRepository: widget.specialtyRepository,
          authRepository: widget.authRepository,
          onSignedOut: widget.onSignedOut,
        ),
      ),
    );
  }

  Future<void> _onSignOut() async {
    await widget.authRepository.signOut();
    widget.onSignedOut();
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < _mobileBreakpoint;

    final sidebar = _Sidebar(
      selectedIndex: _selectedIndex,
      onSelect: (i) {
        setState(() {
          _selectedIndex = i;
          _selectedIndexNotifier.value = i;
        });
        // The Drawer (mobile only — see build's isMobile branch) needs closing after a tap;
        // a no-op on desktop, where this widget isn't wrapped in a Drawer at all.
        if (isMobile) Navigator.of(context).maybePop();
      },
      hasUnreadMention: _hasUnreadMention,
      companyName: _companyName,
      profile: _profile,
      onAccountTap: () => _onAccountTap(context),
      onSignOut: _onSignOut,
    );

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(title: Text(_Sidebar._items[_selectedIndex].label)),
        drawer: Drawer(child: sidebar),
        body: IndexedStack(index: _selectedIndex, children: _pages),
      );
    }

    return Scaffold(
      body: Row(
        children: [
          SizedBox(width: 260, child: sidebar),
          Expanded(child: IndexedStack(index: _selectedIndex, children: _pages)),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.selectedIndex,
    required this.onSelect,
    required this.hasUnreadMention,
    required this.companyName,
    required this.profile,
    required this.onAccountTap,
    required this.onSignOut,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  // Only the Bubbles item (index _bubblesIndex) ever shows a dot — a diver @mentioning
  // the dive center, surfaced here so a mention isn't just one row among many in an inbox
  // staff might not have open.
  final ValueListenable<bool> hasUnreadMention;
  static const _bubblesIndex = 1;

  final String companyName;
  final MyProfile? profile;
  final VoidCallback onAccountTap;
  final VoidCallback onSignOut;

  // Bubbles' icon pair (bubble_chart_outlined/bubble_chart) matches app/'s own bottom-nav
  // Bubbles tab exactly (root_shell.dart) — same brand concept, same glyph, on purpose.
  static const _items = [
    (icon: Icons.calendar_today_outlined, selectedIcon: Icons.calendar_today, label: 'Trips'),
    (icon: Icons.bubble_chart_outlined, selectedIcon: Icons.bubble_chart, label: 'Bubbles'),
    (icon: Icons.people_outline, selectedIcon: Icons.people, label: 'Team'),
    (icon: Icons.apartment_outlined, selectedIcon: Icons.apartment, label: 'Company'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = profile?.displayName?.trim();
    final displayName = (name == null || name.isEmpty) ? 'Account' : name;
    final initials = displayName.trim().isEmpty
        ? '?'
        : displayName.trim().split(RegExp(r'\s+')).map((w) => w[0]).take(2).join().toUpperCase();

    // No fixed width here — the desktop call site wraps this in its own SizedBox(width:
    // 260), while the mobile Drawer wrapping it (see AdminShell.build's isMobile branch)
    // sizes itself. Only the border is unconditional; a thin line reads fine either way.
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(right: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    'assets/images/logo_1024.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                    // A failed load's default error widget doesn't respect the 36x36 box the
                    // way a normal image does, which blew out this Row's width entirely (see
                    // the "RIGHT OVERFLOWED" report) — bound to the same size explicitly.
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 36,
                      height: 36,
                      color: Theme.of(context).colorScheme.primary,
                      child: const Icon(Icons.anchor, color: Colors.white, size: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('DiveBubble', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    Text(
                      'FOR ORGANIZATIONS',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          for (final (i, item) in _items.indexed)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Material(
                color: i == selectedIndex ? theme.colorScheme.primaryContainer : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => onSelect(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          i == selectedIndex ? item.selectedIcon : item.icon,
                          size: 20,
                          color: i == selectedIndex ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          item.label,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: i == selectedIndex ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface,
                            fontWeight: i == selectedIndex ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                        if (i == _bubblesIndex)
                          ValueListenableBuilder<bool>(
                            valueListenable: hasUnreadMention,
                            builder: (context, hasMention, _) {
                              if (!hasMention) return const SizedBox.shrink();
                              return Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(color: theme.colorScheme.error, shape: BoxShape.circle),
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          const Spacer(),
          Divider(height: 1, color: theme.colorScheme.outlineVariant),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onAccountTap,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: theme.colorScheme.primary,
                      backgroundImage: profile?.avatarUrl != null ? NetworkImage(profile!.avatarUrl!) : null,
                      child: profile?.avatarUrl == null
                          ? Text(initials, style: const TextStyle(color: Colors.white, fontSize: 13))
                          : null,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(displayName, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                          Text(
                            companyName,
                            style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Sign out',
                      icon: const Icon(Icons.logout, size: 18),
                      onPressed: onSignOut,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
