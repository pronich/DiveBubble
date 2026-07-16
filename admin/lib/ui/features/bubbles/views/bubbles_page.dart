import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../data/repositories/message_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/trip_repository.dart';
import '../../../../data/services/realtime_service.dart';
import '../../../../domain/entities/chat_message.dart';
import '../../../../domain/entities/my_profile.dart';
import '../../../../domain/entities/trip.dart';
import '../../../core/formatting/date_format.dart';
import '../view_models/bubbles_view_model.dart';

// Same grouping window as app/'s ChatView — consecutive messages from the same sender on
// the same day collapse into one visual cluster as long as the gap stays under this.
const _groupingWindow = Duration(minutes: 5);

/// Body-only (embedded in AdminShell). Named "Bubbles" (not "Messages") to match the app's
/// own branding — a joined trip *is* its chat there too (see CLAUDE.md's Navigation / IA
/// section), so this screen is literally the same concept from the organization's side.
class BubblesPage extends StatefulWidget {
  const BubblesPage({
    super.key,
    required this.tripRepository,
    required this.messageRepository,
    required this.profileRepository,
    required this.realtimeService,
    required this.diveCenterId,
    required this.diveCenterName,
    required this.getCurrentUserId,
    required this.selectedTabIndex,
    required this.openTripId,
  });

  final TripRepository tripRepository;
  final MessageRepository messageRepository;
  final ProfileRepository profileRepository;
  final RealtimeService realtimeService;
  final String diveCenterId;

  // Suffixed onto a colleague's name ("Name | DiveCenterName") so a staff member reading a
  // teammate's reply can tell at a glance it's a colleague, not a diver — same "| Dive
  // Center" attribution app/ already shows divers. Static for this page's lifetime, same as
  // diveCenterId — a Company-name edit while Bubbles is already built won't retroactively
  // update it (same precedent as AdminShell's own _companyName vs. `late final _pages` split).
  final String diveCenterName;

  final Future<String?> Function() getCurrentUserId;

  // Set by TripDetailPage's "Dive into Bubble" button (via AdminShell._diveIntoBubble) — a
  // non-null value here means "select this trip's conversation", consumed once and reset
  // back to null by this page (see _onOpenTripIdChanged). A ValueNotifier, not just
  // ValueListenable, since this page also writes the reset back.
  final ValueNotifier<String?> openTripId;

  // AdminShell keeps every section alive in an IndexedStack built exactly once (`late final
  // _pages`, see its own comment on why) — so this widget's own constructor args, and
  // therefore a plain `isActive: selectedIndex == 1` bool, would only ever be evaluated at
  // that first build and never again. A ValueListenable sidesteps that: AdminShell mutates
  // the same notifier on every tab switch, and this page listens to it directly instead of
  // relying on widget rebuilds — reloading trips whenever the tab flips from inactive to
  // active, so a trip created while on the Trips tab shows up here without a manual refresh.
  final ValueListenable<int> selectedTabIndex;

  static const _tabIndex = 1;

  @override
  State<BubblesPage> createState() => _BubblesPageState();
}

class _BubblesPageState extends State<BubblesPage> {
  BubblesViewModel? _viewModel;
  final _messageController = TextEditingController();
  late int _lastTabIndex = widget.selectedTabIndex.value;

  @override
  void initState() {
    super.initState();
    _init();
    widget.selectedTabIndex.addListener(_onTabIndexChanged);
    widget.openTripId.addListener(_onOpenTripIdChanged);
  }

  void _onTabIndexChanged() {
    final current = widget.selectedTabIndex.value;
    if (current == BubblesPage._tabIndex && _lastTabIndex != BubblesPage._tabIndex) {
      _viewModel?.loadTrips();
    }
    _lastTabIndex = current;
  }

  void _onOpenTripIdChanged() {
    final tripId = widget.openTripId.value;
    if (tripId == null) return;
    _viewModel?.selectTrip(tripId);
    // Consumed — reset so navigating away and back to this tab doesn't reselect it.
    widget.openTripId.value = null;
  }

  Future<void> _init() async {
    final userId = await widget.getCurrentUserId();
    final vm = BubblesViewModel(
      tripRepository: widget.tripRepository,
      messageRepository: widget.messageRepository,
      profileRepository: widget.profileRepository,
      realtimeService: widget.realtimeService,
      diveCenterId: widget.diveCenterId,
      diveCenterName: widget.diveCenterName,
      currentUserId: userId ?? '',
    );
    await vm.loadTrips();
    if (!mounted) return;
    setState(() => _viewModel = vm);
  }

  @override
  void dispose() {
    widget.selectedTabIndex.removeListener(_onTabIndexChanged);
    widget.openTripId.removeListener(_onOpenTripIdChanged);
    _messageController.dispose();
    _viewModel?.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final body = _messageController.text;
    if (body.trim().isEmpty) return;
    _messageController.clear();
    final error = await _viewModel!.send(body);
    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = _viewModel;
    if (vm == null) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListenableBuilder(
      listenable: vm,
      builder: (context, _) {
        return Row(
          children: [
            SizedBox(width: 320, child: _Inbox(viewModel: vm, onSelect: vm.selectTrip)),
            VerticalDivider(width: 1, color: Theme.of(context).colorScheme.outlineVariant),
            Expanded(child: _Conversation(viewModel: vm, controller: _messageController, onSend: _send)),
          ],
        );
      },
    );
  }
}

class _Inbox extends StatefulWidget {
  const _Inbox({required this.viewModel, required this.onSelect});

  final BubblesViewModel viewModel;
  final ValueChanged<String> onSelect;

  @override
  State<_Inbox> createState() => _InboxState();
}

class _InboxState extends State<_Inbox> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = widget.viewModel;
    final query = _search.trim().toLowerCase();
    final trips = query.isEmpty ? viewModel.trips : viewModel.trips.where((t) => t.title.toLowerCase().contains(query)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'INBOX',
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Text('Bubbles', style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        if (viewModel.trips.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              decoration: const InputDecoration(hintText: 'Search trips', prefixIcon: Icon(Icons.search), isDense: true),
              onChanged: (value) => setState(() => _search = value),
            ),
          ),
        Expanded(
          child: viewModel.isLoadingTrips
              ? const Center(child: CircularProgressIndicator())
              : viewModel.trips.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        'No trips yet — create one to start a conversation with your divers.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    )
                  : trips.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text('No matches.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        )
                      : ListView(
                          children: [
                            for (final trip in trips)
                              _InboxRow(trip: trip, selected: trip.id == viewModel.selectedTripId, onTap: () => widget.onSelect(trip.id)),
                          ],
                        ),
        ),
      ],
    );
  }
}

class _InboxRow extends StatelessWidget {
  const _InboxRow({required this.trip, required this.selected, required this.onTap});

  final Trip trip;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = trip.title.trim().isEmpty ? '?' : trip.title.trim().substring(0, 1).toUpperCase();
    return Material(
      color: selected ? theme.colorScheme.primaryContainer : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primary,
                child: Text(initials, style: const TextStyle(color: Colors.white)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      '${formatShortDate(trip.startTime)} · ${trip.location}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              if (trip.unreadCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(color: theme.colorScheme.error, borderRadius: BorderRadius.circular(10)),
                  child: Text(
                    trip.unreadCount > 9 ? '9+' : '${trip.unreadCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Conversation extends StatefulWidget {
  const _Conversation({required this.viewModel, required this.controller, required this.onSend});

  final BubblesViewModel viewModel;
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  State<_Conversation> createState() => _ConversationState();
}

class _ConversationState extends State<_Conversation> {
  final _scrollController = ScrollController();
  String? _lastTripId;
  int _lastMessageCount = 0;
  bool _isNearBottom = true;
  bool _showNewMessagesPill = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  // Reversed list (see build) means pixels near 0 is "near the bottom" — same convention
  // as app/'s ChatView, and for the same reason: offset 0 in a reversed list is exactly
  // the newest message, not an estimate.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final nearBottom = _scrollController.position.pixels <= 80;
    if (nearBottom == _isNearBottom && !(nearBottom && _showNewMessagesPill)) return;
    setState(() {
      _isNearBottom = nearBottom;
      if (nearBottom) _showNewMessagesPill = false;
    });
  }

  void _scrollToBottom({required bool animate}) {
    if (!_scrollController.hasClients) return;
    if (animate) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    } else {
      _scrollController.jumpTo(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = widget.viewModel;
    final trip = viewModel.selectedTrip;
    if (trip == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.bubble_chart_outlined, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(
              'Select a Bubble to view its conversation.',
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    final cancelled = trip.bookingStatus == 'cancelled';

    // Switching to a different Bubble entirely — reset local scroll/pill state and snap to
    // its bottom without animating (there's nothing to animate from, it's a fresh list).
    if (trip.id != _lastTripId) {
      _lastTripId = trip.id;
      _lastMessageCount = 0;
      _isNearBottom = true;
      _showNewMessagesPill = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(animate: false));
    }

    final messages = viewModel.messages;
    final items = _buildDisplayItems(messages);
    final reversedItems = items.reversed.toList();

    if (messages.length != _lastMessageCount) {
      final wasEmpty = _lastMessageCount == 0;
      final isOwnMessage = messages.isNotEmpty && messages.last.userId == viewModel.currentUserId;
      _lastMessageCount = messages.length;
      if (!wasEmpty && (isOwnMessage || _isNearBottom)) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(animate: true));
      } else if (!wasEmpty && !isOwnMessage) {
        _showNewMessagesPill = true;
      }
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant))),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primary,
                child: Text(
                  trip.title.trim().isEmpty ? '?' : trip.title.trim().substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trip.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text(
                      '${formatShortDate(trip.startTime)} · ${trip.location}',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: viewModel.isLoadingMessages
              ? const Center(child: CircularProgressIndicator())
              : messages.isEmpty
                  ? Center(
                      child: Text(
                        'No messages yet.',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    )
                  : Stack(
                      children: [
                        ListView.builder(
                          controller: _scrollController,
                          reverse: true,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          itemCount: reversedItems.length,
                          itemBuilder: (context, index) {
                            final item = reversedItems[index];
                            if (item.date != null) {
                              return _DateSeparator(date: item.date!);
                            }
                            final message = item.message!;
                            return _MessageRow(
                              message: message,
                              isOwn: message.userId == viewModel.currentUserId,
                              isFirstInCluster: item.isFirstInCluster,
                              isLastInCluster: item.isLastInCluster,
                              profile: viewModel.senderProfiles[message.userId],
                              diveCenterName: viewModel.diveCenterName,
                            );
                          },
                        ),
                        if (_showNewMessagesPill)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 8,
                            child: Center(
                              child: _NewMessagesPill(
                                onTap: () {
                                  setState(() => _showNewMessagesPill = false);
                                  _scrollToBottom(animate: true);
                                },
                              ),
                            ),
                          ),
                      ],
                    ),
        ),
        if (cancelled)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: theme.colorScheme.surfaceContainerHighest,
            child: Text(
              'This trip has been cancelled — the conversation is read-only.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: theme.colorScheme.outlineVariant))),
            child: Row(
              children: [
                Expanded(
                  // Enter alone sends (and is swallowed here so it never lands as a
                  // newline first); Shift+Enter falls through to the TextField and
                  // inserts a newline normally — needs keyboardType: multiline, since a
                  // single-line field never lets Enter produce a newline to begin with.
                  child: Focus(
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.enter &&
                          !HardwareKeyboard.instance.isShiftPressed) {
                        widget.onSend();
                        return KeyEventResult.handled;
                      }
                      return KeyEventResult.ignored;
                    },
                    child: TextField(
                      controller: widget.controller,
                      decoration: InputDecoration(hintText: 'Message ${trip.title} as organization'),
                      keyboardType: TextInputType.multiline,
                      minLines: 1,
                      maxLines: 5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: viewModel.isSending ? null : widget.onSend,
                  icon: const Icon(Icons.send),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _NewMessagesPill extends StatelessWidget {
  const _NewMessagesPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.primary,
      borderRadius: BorderRadius.circular(999),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_downward, size: 16, color: theme.colorScheme.onPrimary),
              const SizedBox(width: 6),
              Text(
                'New messages',
                style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onPrimary, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One cluster boundary is forced by a sender change, a gap over [_groupingWindow], or a
/// calendar-day change (which also emits a date separator ahead of it) — same rules as
/// app/'s ChatView.
class _MessageCluster {
  _MessageCluster(this.day, ChatMessage first) : messages = [first];
  final DateTime day;
  final List<ChatMessage> messages;
}

List<_MessageCluster> _buildClusters(List<ChatMessage> messages) {
  final clusters = <_MessageCluster>[];
  for (final m in messages) {
    final local = m.createdAt.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    final last = clusters.isEmpty ? null : clusters.last;
    final continuesCluster = last != null &&
        last.day == day &&
        last.messages.last.userId == m.userId &&
        m.createdAt.difference(last.messages.last.createdAt) <= _groupingWindow;
    if (continuesCluster) {
      last.messages.add(m);
    } else {
      clusters.add(_MessageCluster(day, m));
    }
  }
  return clusters;
}

class _ChatDisplayItem {
  const _ChatDisplayItem.separator(this.date)
      : message = null,
        isFirstInCluster = false,
        isLastInCluster = false;

  const _ChatDisplayItem.message(this.message, {required this.isFirstInCluster, required this.isLastInCluster}) : date = null;

  final DateTime? date;
  final ChatMessage? message;
  final bool isFirstInCluster;
  final bool isLastInCluster;
}

List<_ChatDisplayItem> _buildDisplayItems(List<ChatMessage> messages) {
  final clusters = _buildClusters(messages);
  final items = <_ChatDisplayItem>[];
  DateTime? lastDay;
  for (final cluster in clusters) {
    if (lastDay == null || cluster.day != lastDay) {
      items.add(_ChatDisplayItem.separator(cluster.day));
      lastDay = cluster.day;
    }
    for (var i = 0; i < cluster.messages.length; i++) {
      items.add(_ChatDisplayItem.message(
        cluster.messages[i],
        isFirstInCluster: i == 0,
        isLastInCluster: i == cluster.messages.length - 1,
      ));
    }
  }
  return items;
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            formatChatDateSeparator(date),
            style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

/// Own messages never carry a name/avatar; everyone else's reserve a fixed-width avatar
/// gutter so bubbles line up whether or not this particular row shows the avatar — same
/// layout convention as app/'s ChatView._MessageRow.
class _MessageRow extends StatelessWidget {
  const _MessageRow({
    required this.message,
    required this.isOwn,
    required this.isFirstInCluster,
    required this.isLastInCluster,
    required this.profile,
    required this.diveCenterName,
  });

  final ChatMessage message;
  final bool isOwn;
  final bool isFirstInCluster;
  final bool isLastInCluster;
  final MyProfile? profile;

  // Suffixed onto a colleague's name below ("Name | DiveCenterName") — same attribution
  // app/ already shows divers, reused here so a staff member reading a teammate's reply
  // knows at a glance it's a colleague, not a diver, without needing a separate bubble color.
  final String diveCenterName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isColleague = !isOwn && message.isDiveCenterStaff;
    final bubbleColor = isOwn ? colorScheme.primary : colorScheme.secondaryContainer;
    final onBubbleColor = isOwn ? colorScheme.onPrimary : colorScheme.onSecondaryContainer;

    final baseName = (profile?.displayName?.isNotEmpty ?? false) ? profile!.displayName! : 'Diver';
    final name = (isColleague && diveCenterName.isNotEmpty) ? '$baseName | $diveCenterName' : baseName;
    // A colleague's name always shows, even mid-cluster — unlike a diver's, where only the
    // first message in a cluster needs it (see _buildClusters).
    final showName = !isOwn && (isFirstInCluster || isColleague);

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: bubbleColor, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showName)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                name,
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, color: onBubbleColor),
              ),
            ),
          _MessageBody(body: message.body, time: formatTime(message.createdAt), color: onBubbleColor),
        ],
      ),
    );

    if (isOwn) {
      return Padding(
        padding: EdgeInsets.only(top: isFirstInCluster ? 10 : 2, bottom: 2),
        child: Align(alignment: Alignment.centerRight, child: bubble),
      );
    }

    return Padding(
      padding: EdgeInsets.only(top: isFirstInCluster ? 14 : 2, bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          SizedBox(
            width: 32,
            child: isLastInCluster
                ? CircleAvatar(
                    radius: 16,
                    backgroundColor: bubbleColor,
                    backgroundImage: (profile?.avatarUrl?.isNotEmpty ?? false) ? NetworkImage(profile!.avatarUrl!) : null,
                    child: (profile?.avatarUrl?.isNotEmpty ?? false) ? null : Icon(Icons.person, size: 18, color: onBubbleColor),
                  )
                : null,
          ),
          const SizedBox(width: 8),
          Flexible(child: bubble),
        ],
      ),
    );
  }
}

/// Message text with its timestamp trailing inline on the same line — like WhatsApp/Telegram,
/// not stacked on its own row below. A zero-opacity copy of the timestamp is appended as a
/// [WidgetSpan] so the paragraph's line-wrapping reserves room for it (falling to a new line
/// if the last line is already full); the real, visible timestamp is then drawn on top at the
/// bottom-right corner via [Stack]+[Positioned], landing in that reserved space.
class _MessageBody extends StatelessWidget {
  const _MessageBody({required this.body, required this.time, required this.color});

  final String body;
  final String time;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bodyStyle = TextStyle(color: color);
    final timeStyle = theme.textTheme.labelSmall?.copyWith(color: color.withValues(alpha: 0.7), fontSize: 11);
    return Stack(
      children: [
        Text.rich(
          TextSpan(
            style: bodyStyle,
            children: [
              TextSpan(text: body),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: Opacity(
                  opacity: 0,
                  child: Padding(padding: const EdgeInsets.only(left: 8), child: Text(time, style: timeStyle)),
                ),
              ),
            ],
          ),
        ),
        Positioned(right: 0, bottom: 0, child: Text(time, style: timeStyle)),
      ],
    );
  }
}
