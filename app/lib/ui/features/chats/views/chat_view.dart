import 'package:flutter/material.dart';

import '../../../../domain/entities/chat_message.dart';
import '../../../../domain/entities/profile.dart';
import '../../../core/formatting/date_format.dart';
import '../../profile/views/diver_id_card.dart';
import '../view_models/chat_view_model.dart';

// Consecutive messages from the same sender on the same day collapse into one visual
// cluster (name shown once, avatar anchored to the last bubble) as long as the gap
// between them stays under this window — a longer gap reads as a separate "turn", so it
// gets its own name + avatar again, Telegram-style.
const _groupingWindow = Duration(minutes: 5);

class ChatView extends StatefulWidget {
  const ChatView({
    super.key,
    required this.viewModel,
    this.isCancelled = false,
    this.businessName,
    this.canMentionDiveCenter = true,
  });

  final ChatViewModel viewModel;

  /// Trip Page (see TripConversationPage._refreshTripDerivedState) is the source of truth —
  /// cancelling freezes the input, but history stays fully visible either way.
  final bool isCancelled;

  /// Set when this Bubble's trip is organized by a dive center — a non-own message from an
  /// actual staff member of that center (message.isDiveCenterStaff) gets "Name | Dive
  /// Center" instead of just "Name" (see _MessageRow); other divers in the same Bubble
  /// keep their plain name, since they aren't posting on the organization's behalf.
  final String? businessName;

  /// False when the current user is themselves staff of this trip's dive center — mentioning
  /// your own business is meaningless, so the chip is hidden for staff even though they're
  /// on a "business trip" (businessName != null) the same way a diver is.
  final bool canMentionDiveCenter;

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> with AutomaticKeepAliveClientMixin {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final Map<String, Profile> _profiles = {};
  final Set<String> _fetchingProfileIds = {};
  int _lastMessageCount = 0;
  bool _isNearBottom = true;
  bool _showNewMessagesPill = false;
  // Armed via the "@DiveCenter" chip (business trips only — see the chip's own comment
  // below), reset once the armed message is actually sent.
  bool _mentionArmed = false;

  // TabBarView disposes offscreen tabs by default — without this, switching to Transport
  // and back tore down ChatView (and, since dispose() below tears down the ChatViewModel
  // with it) then rebuilt a fresh ChatView still holding the now-disposed ViewModel,
  // throwing "used after being disposed" on the next call.
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Same deferral as TransportView's initState — TabBarView builds both tabs eagerly,
    // and load()'s synchronous first-line notifyListeners() can otherwise fire mid-build.
    Future.microtask(widget.viewModel.load);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    widget.viewModel.dispose();
    super.dispose();
  }

  // Tracks whether the diver is close enough to the bottom that a new message should
  // just land in front of them — also what dismisses the "new messages" pill once they
  // scroll back down manually, without waiting for a tap on it.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    // The list renders reverse: true (see build) so "bottom"/newest is offset 0, not
    // maxScrollExtent — pixels near 0 is what "near the bottom" means here.
    final nearBottom = _scrollController.position.pixels <= 80;
    if (nearBottom == _isNearBottom && !(nearBottom && _showNewMessagesPill)) return;
    setState(() {
      _isNearBottom = nearBottom;
      if (nearBottom) _showNewMessagesPill = false;
    });
  }

  // Reversed list means the bottom/newest message sits at offset 0 exactly, not an
  // estimated maxScrollExtent — jumpTo(0)/animateTo(0) always lands precisely, unlike a
  // forward list where ListView.builder only has estimated extents for offscreen items
  // until they're actually realized.
  void _scrollToBottom({required bool animate}) {
    if (!_scrollController.hasClients) return;
    if (animate) {
      _scrollController.animateTo(0, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
    } else {
      _scrollController.jumpTo(0);
    }
  }

  // Best-effort, one-at-a-time per sender — a profile fetch failing just leaves that
  // cluster's name/avatar on the generic "Diver" fallback rather than blocking the chat.
  void _loadProfile(String userId) {
    if (_profiles.containsKey(userId) || _fetchingProfileIds.contains(userId)) return;
    _fetchingProfileIds.add(userId);
    widget.viewModel.profileRepository.getPublicProfile(userId).then((p) {
      if (mounted) setState(() => _profiles[userId] = p);
    }).catchError((_) {
      // ignore — stays on the fallback
    }).whenComplete(() => _fetchingProfileIds.remove(userId));
  }

  void _openProfile(String userId) {
    showDiverIdCard(context, userId: userId, profileRepository: widget.viewModel.profileRepository);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Expanded(
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

              final messages = widget.viewModel.messages;
              if (messages.isEmpty) {
                return const Center(child: Text('No messages yet'));
              }

              final items = _buildDisplayItems(messages);
              for (final item in items) {
                final senderId = item.message?.userId;
                if (senderId != null && senderId != widget.viewModel.currentUserId) {
                  _loadProfile(senderId);
                }
              }
              // Rendered with reverse: true (see below), so item 0 is the newest — reverse
              // the ascending list built above rather than reworking the clustering logic
              // (isFirstInCluster/isLastInCluster/date separators) to run backwards.
              final reversedItems = items.reversed.toList();

              if (messages.length != _lastMessageCount) {
                final wasEmpty = _lastMessageCount == 0;
                // Sending a message always snaps you to it, regardless of scroll position —
                // an incoming message from someone else only does that if you were already
                // near the bottom; otherwise it'd yank you away mid-read, so it just raises
                // the "new messages" pill instead. wasEmpty (initial load) needs no explicit
                // scroll at all: offset 0 in a reversed list is already the newest message.
                final isOwnMessage = messages.isNotEmpty && messages.last.userId == widget.viewModel.currentUserId;
                _lastMessageCount = messages.length;
                if (!wasEmpty && (isOwnMessage || _isNearBottom)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(animate: true));
                } else if (!wasEmpty && !isOwnMessage) {
                  _showNewMessagesPill = true;
                }
              }

              return Stack(
                children: [
                  ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: reversedItems.length,
                    itemBuilder: (context, index) {
                      final item = reversedItems[index];
                      if (item.date != null) {
                        return _DateSeparator(date: item.date!);
                      }
                      final message = item.message!;
                      final isMine = message.userId == widget.viewModel.currentUserId;
                      return _MessageRow(
                        message: message,
                        isMine: isMine,
                        isFirstInCluster: item.isFirstInCluster,
                        isLastInCluster: item.isLastInCluster,
                        profile: _profiles[message.userId],
                        businessName: widget.businessName,
                        onTapSender: () => _openProfile(message.userId),
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
              );
            },
          ),
        ),
        SafeArea(
          top: false,
          child: widget.isCancelled
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'This trip has been cancelled — the chat is read-only.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Business trips only — mentioning the dive center is how a diver flags
                    // a message as actually needing staff attention (Stage 2 push will only
                    // notify staff on a mention, not every message, to avoid spamming
                    // several staff members over one trip's chat).
                    if (widget.businessName != null && widget.canMentionDiveCenter)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FilterChip(
                            avatar: const Icon(Icons.campaign_outlined, size: 16),
                            label: Text('@${widget.businessName}'),
                            selected: _mentionArmed,
                            onSelected: (value) => setState(() => _mentionArmed = value),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              minLines: 1,
                              maxLines: 5,
                              keyboardType: TextInputType.multiline,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: const InputDecoration(hintText: 'Message'),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: () {
                              final text = _textController.text;
                              final mentionsDiveCenter = _mentionArmed;
                              _textController.clear();
                              setState(() => _mentionArmed = false);
                              widget.viewModel.send(text, mentionsDiveCenter: mentionsDiveCenter);
                            },
                          ),
                        ],
                      ),
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

/// One cluster boundary can be forced by a sender change, a gap over [_groupingWindow],
/// or a calendar-day change (which also emits a [_ChatDisplayItem.separator] ahead of it).
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

/// Own messages never carry a name/avatar (isMine short-circuits straight to a
/// right-aligned bubble); everyone else's messages reserve a fixed-width avatar gutter
/// so bubbles line up whether or not this particular row is the one showing the avatar.
class _MessageRow extends StatelessWidget {
  const _MessageRow({
    required this.message,
    required this.isMine,
    required this.isFirstInCluster,
    required this.isLastInCluster,
    required this.profile,
    required this.onTapSender,
    this.businessName,
  });

  final ChatMessage message;
  final bool isMine;
  final bool isFirstInCluster;
  final bool isLastInCluster;
  final Profile? profile;
  final VoidCallback onTapSender;

  /// Never applied to the diver's own messages (see isMine below), and only ever combined
  /// with message.isDiveCenterStaff — a regular diver's message in a business trip's chat
  /// must never look like it came from the organization.
  final String? businessName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bubbleColor = isMine ? colorScheme.primary : colorScheme.secondaryContainer;
    final onBubbleColor = isMine ? colorScheme.onPrimary : colorScheme.onSecondaryContainer;

    final baseName = (profile?.displayName?.isNotEmpty ?? false) ? profile!.displayName! : 'Diver';
    final name = (message.isDiveCenterStaff && (businessName?.isNotEmpty ?? false)) ? '$baseName | $businessName' : baseName;
    // Staff messages always carry a name, even mid-cluster — a trip's chat is effectively a
    // group conversation (organizer + every diver) even though it's framed as one thread, so
    // it should always be clear which staff member is replying, not just the first message
    // in a burst. Regular divers keep the usual "only the first message in a cluster" rule.
    final showName = !isMine && (isFirstInCluster || message.isDiveCenterStaff);

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: bubbleColor, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (message.mentionsDiveCenter && (businessName?.isNotEmpty ?? false))
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '@$businessName',
                style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: onBubbleColor),
              ),
            ),
          if (showName)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: GestureDetector(
                onTap: onTapSender,
                child: Text(
                  name,
                  style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600, color: onBubbleColor),
                ),
              ),
            ),
          _MessageBody(body: message.body, time: formatTime(message.createdAt), color: onBubbleColor),
        ],
      ),
    );

    if (isMine) {
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
                ? GestureDetector(
                    onTap: onTapSender,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: colorScheme.secondaryContainer,
                      backgroundImage: (profile?.avatarUrl?.isNotEmpty ?? false) ? NetworkImage(profile!.avatarUrl!) : null,
                      child: (profile?.avatarUrl?.isNotEmpty ?? false)
                          ? null
                          : Icon(Icons.person, size: 18, color: colorScheme.onSecondaryContainer),
                    ),
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
