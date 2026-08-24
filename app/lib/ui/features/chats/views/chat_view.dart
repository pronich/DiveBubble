import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import '../../../../data/services/attachment_cache_service.dart';
import '../../../../domain/entities/chat_attachment.dart';
import '../../../../domain/entities/chat_message.dart';
import '../../../../domain/entities/chat_reaction.dart';
import '../../../../domain/entities/profile.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/widgets/cached_attachment_image.dart';
import '../../../core/widgets/open_attachment.dart';
import '../../../../domain/entities/picked_attachment.dart';
import '../../../core/widgets/pick_attachment.dart';
import '../../../core/widgets/video_thumbnail_placeholder.dart';
import '../../profile/views/diver_id_card.dart';
import '../view_models/chat_view_model.dart';
import 'attachment_image_preview_page.dart';
import 'attachment_video_preview_page.dart';

// Consecutive messages from the same sender on the same day collapse into one visual
// cluster (name shown once, avatar anchored to the last bubble) as long as the gap
// between them stays under this window — a longer gap reads as a separate "turn", so it
// gets its own name + avatar again, Telegram-style.
const _groupingWindow = Duration(minutes: 5);

// Mirrors the backend's upload.MaxAttachmentSize/MaxVideoAttachmentSize — checked client-side
// before ever hitting the network as a cheap UX win; the backend still enforces these
// authoritatively. Video gets the larger cap since it's compressed but still much bigger than a
// photo or PDF.
const _maxAttachmentSizeBytes = 10 * 1024 * 1024;
const _maxVideoAttachmentSizeBytes = 50 * 1024 * 1024;

// Mirrors message.maxAttachmentsPerMessage backend-side — same "cheap client-side check, real
// enforcement is server-side" split as the size cap above.
const _maxAttachmentsPerMessage = 9;

// Fixed set, Messenger-style — mirrors message.AllowedReactionEmojis / migration 000055's CHECK
// constraint. No custom-emoji picker in v1.
const _reactionEmojis = ['❤️', '😅', '😁', '🙃', '😢', '😮', '😡', '👌'];

// One row in the @-mention autocomplete list — either the dive center (synthetic, not a real
// participant) or a trip participant, both rendered/selected identically (see
// _ChatViewState._mentionEntries and the mention list's ListTile builder).
class _MentionEntry {
  const _MentionEntry({required this.displayName, this.isDiveCenter = false});

  final String displayName;
  final bool isDiveCenter;
}

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

class _ChatViewState extends State<ChatView>
    with AutomaticKeepAliveClientMixin {
  final _textController = TextEditingController();
  final _composerFocusNode = FocusNode();
  final _itemScrollController = ItemScrollController();
  final _itemPositionsListener = ItemPositionsListener.create();
  final Map<String, Profile> _profiles = {};
  final Set<String> _fetchingProfileIds = {};
  int _lastMessageCount = 0;
  bool _isNearBottom = true;
  bool _showNewMessagesPill = false;

  // Index of the '@' that opened the currently-active mention token in _textController.text,
  // or -1 when no mention is being typed right now (see _onComposerTextChanged).
  int _mentionTokenStart = -1;
  List<_MentionEntry> _mentionMatches = [];

  List<PickedAttachment> _pendingAttachments = [];

  // Set by the long-press actions sheet's Reply action or a bubble's swipe-to-reply gesture;
  // cleared on send or explicit dismiss (_ReplyPreviewChip's X).
  ChatMessage? _replyingTo;

  // Briefly flashed on the bubble _scrollToMessage lands on, then cleared — see
  // _scrollToMessage's own comment.
  String? _highlightedMessageId;
  Timer? _highlightTimer;

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
    _itemPositionsListener.itemPositions.addListener(_onScroll);
    _textController.addListener(_onComposerTextChanged);
  }

  @override
  void dispose() {
    _textController.removeListener(_onComposerTextChanged);
    _textController.dispose();
    _composerFocusNode.dispose();
    _itemPositionsListener.itemPositions.removeListener(_onScroll);
    _highlightTimer?.cancel();
    widget.viewModel.dispose();
    super.dispose();
  }

  // Tracks whether the diver is close enough to the bottom that a new message should
  // just land in front of them — also what dismisses the "new messages" pill once they
  // scroll back down manually, without waiting for a tap on it. The list renders reverse:
  // true (see build) so "bottom"/newest is item index 0 — near-bottom means that item is
  // currently among the visible ones, not a precise pixel threshold (scrollable_positioned_list
  // doesn't expose raw scroll-offset pixels the way a plain ScrollController did).
  void _onScroll() {
    final nearBottom = _itemPositionsListener.itemPositions.value.any((p) => p.index == 0);
    if (nearBottom == _isNearBottom && !(nearBottom && _showNewMessagesPill)) return;
    setState(() {
      _isNearBottom = nearBottom;
      if (nearBottom) _showNewMessagesPill = false;
    });
  }

  // Reversed list means the bottom/newest message is item index 0 — jumpTo/scrollTo(index: 0)
  // always lands exactly there, same guarantee the old pixel-offset-0 approach relied on.
  void _scrollToBottom({required bool animate}) {
    if (!_itemScrollController.isAttached) return;
    if (animate) {
      _itemScrollController.scrollTo(
        index: 0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    } else {
      _itemScrollController.jumpTo(index: 0);
    }
  }

  // Jumps to and briefly highlights an arbitrary earlier message — tapping a reply's quoted
  // strip (see _MessageRow). Recomputes reversedItems fresh rather than caching it, since the
  // display-item list only otherwise exists inside build()'s scope.
  void _scrollToMessage(String messageId) {
    final reversedItems = _buildDisplayItems(widget.viewModel.messages).reversed.toList();
    final index = reversedItems.indexWhere((item) => item.message?.id == messageId);
    if (index == -1 || !_itemScrollController.isAttached) return;
    _itemScrollController.scrollTo(
      index: index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      alignment: 0.4,
    );
    _highlightTimer?.cancel();
    setState(() => _highlightedMessageId = messageId);
    _highlightTimer = Timer(const Duration(milliseconds: 1200), () {
      if (mounted) setState(() => _highlightedMessageId = null);
    });
  }

  // Best-effort, one-at-a-time per sender — a profile fetch failing just leaves that
  // cluster's name/avatar on the generic "Diver" fallback rather than blocking the chat.
  void _loadProfile(String userId) {
    if (_profiles.containsKey(userId) || _fetchingProfileIds.contains(userId))
      return;
    _fetchingProfileIds.add(userId);
    widget.viewModel.profileRepository
        .getPublicProfile(userId)
        .then((p) {
          if (mounted) setState(() => _profiles[userId] = p);
        })
        .catchError((_) {
          // ignore — stays on the fallback
        })
        .whenComplete(() => _fetchingProfileIds.remove(userId));
  }

  // Telegram-style: typing '@' always opens the people list (dive center included, per
  // Nikolai's review comment — no more separate fixed chip) right above the composer, live-
  // filtered as more characters follow. Fires on every keystroke via _textController's
  // listener; cheap enough (participants list tops out at a trip's roster) not to debounce.
  void _onComposerTextChanged() {
    final text = _textController.text;
    final cursor = _textController.selection.baseOffset;
    if (cursor < 0) {
      if (_mentionTokenStart != -1) setState(() => _mentionTokenStart = -1);
      return;
    }
    final atIndex = _activeMentionStart(text, cursor);
    if (atIndex == -1) {
      if (_mentionTokenStart != -1) setState(() => _mentionTokenStart = -1);
      return;
    }
    final query = text.substring(atIndex + 1, cursor).toLowerCase();
    final all = _mentionEntries();
    final matches = query.isEmpty
        ? all
        : all.where((e) => e.displayName.toLowerCase().contains(query)).toList();
    setState(() {
      _mentionTokenStart = atIndex;
      _mentionMatches = matches;
    });
  }

  // Scans backward from the cursor for an '@' that starts the current word (at the very
  // start of the text, or preceded by whitespace) — hitting whitespace first, or no '@' at
  // all, means no mention is currently being typed.
  int _activeMentionStart(String text, int cursor) {
    for (var i = cursor - 1; i >= 0; i--) {
      final char = text[i];
      if (char == '@') {
        final prev = i == 0 ? null : text[i - 1];
        return (prev == null || prev == ' ' || prev == '\n') ? i : -1;
      }
      if (char == ' ' || char == '\n') return -1;
    }
    return -1;
  }

  // Dive center first (when this is a business trip and the current user isn't its own
  // staff — same gate the old chip used), then every trip participant.
  List<_MentionEntry> _mentionEntries() {
    final businessName = widget.businessName;
    return [
      if (businessName != null && widget.canMentionDiveCenter)
        _MentionEntry(displayName: businessName, isDiveCenter: true),
      for (final p in widget.viewModel.participants)
        if ((p.displayName ?? '').isNotEmpty) _MentionEntry(displayName: p.displayName!),
    ];
  }

  void _selectMention(_MentionEntry entry) {
    final text = _textController.text;
    final cursor = _textController.selection.baseOffset;
    final start = _mentionTokenStart;
    if (start == -1 || cursor < 0 || cursor > text.length) return;
    final replacement = '@${entry.displayName} ';
    _textController.value = TextEditingValue(
      text: text.replaceRange(start, cursor, replacement),
      selection: TextSelection.collapsed(offset: start + replacement.length),
    );
    setState(() => _mentionTokenStart = -1);
  }

  void _openProfile(String userId) {
    showDiverIdCard(
      context,
      userId: userId,
      currentUserId: widget.viewModel.currentUserId,
      profileRepository: widget.viewModel.profileRepository,
    );
  }

  void _showReportSheet(ChatMessage message) {
    _settleFocus(focusComposer: false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ReportMessageSheet(
        viewModel: widget.viewModel,
        messageId: message.id,
      ),
    );
  }

  // Deferred a frame past whatever triggered it (menu-item tap, backdrop dismiss, swipe) —
  // popping the context-menu route has its own focus-restoration behavior that runs on the
  // same frame, so calling requestFocus/unfocus synchronously right after Navigator.pop()
  // routinely got clobbered by it (or vice versa). Scheduling via addPostFrameCallback lets
  // ours run last and win, regardless of exactly what the route pop itself does.
  void _settleFocus({required bool focusComposer}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (focusComposer) {
        _composerFocusNode.requestFocus();
      } else {
        FocusScope.of(context).unfocus();
      }
    });
  }

  // Entry point for both the long-press menu and swipe-to-reply — same effect either way.
  void _startReply(ChatMessage message) {
    setState(() => _replyingTo = message);
    _settleFocus(focusComposer: true);
  }

  void _cancelReply() => setState(() => _replyingTo = null);

  void _copyMessageText(ChatMessage message) {
    Clipboard.setData(ClipboardData(text: message.body));
    _settleFocus(focusComposer: false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied')));
  }

  Future<void> _confirmDeleteMessage(ChatMessage message) async {
    _settleFocus(focusComposer: false);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this message?'),
        content: const Text('This cannot be undone — it will be removed for everyone in this Bubble.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final error = await widget.viewModel.deleteMessage(message.id);
    if (!mounted || error == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not delete message: $error')));
  }

  Future<void> _reactToMessage(String messageId, String emoji) async {
    _settleFocus(focusComposer: false);
    final error = await widget.viewModel.reactToMessage(messageId, emoji);
    if (!mounted || error == null) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not react: $error')));
  }

  // Long-press menu — iOS/Telegram-style: background dims+blurs, the pressed bubble stays put
  // (rendered from a snapshot taken at press time — see _MessageRow's onLongPress, which hands
  // over the bubble's on-screen Rect + a captured image), and the action list sits right below
  // it. Reply/Copy are universal, Report (not-mine) vs Delete (mine) is the only branch.
  // Deleted messages never reach here (see build's onLongPress gate). The dimmed backdrop is
  // deliberately its own overlay (not showModalBottomSheet) so it can leave room for a future
  // emoji-reaction row above the bubble without restructuring this again.
  void _showMessageActionsSheet(ChatMessage message, Rect bubbleRect, ui.Image bubbleImage) {
    final isMine = message.userId == widget.viewModel.currentUserId;
    Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierColor: Colors.transparent,
        transitionDuration: const Duration(milliseconds: 180),
        reverseTransitionDuration: const Duration(milliseconds: 120),
        pageBuilder: (_, animation, _) => FadeTransition(
          opacity: animation,
          child: _MessageContextMenu(
            bubbleRect: bubbleRect,
            bubbleImage: bubbleImage,
            onDismiss: () => _settleFocus(focusComposer: false),
            reactions: message.reactions,
            onReact: (emoji) {
              Navigator.of(context).pop();
              _reactToMessage(message.id, emoji);
            },
            actions: [
              _ContextMenuAction(icon: Icons.reply_outlined, label: 'Reply', onTap: () => _startReply(message)),
              _ContextMenuAction(icon: Icons.copy_outlined, label: 'Copy text', onTap: () => _copyMessageText(message)),
              if (isMine)
                _ContextMenuAction(
                  icon: Icons.delete_outline,
                  label: 'Delete',
                  isDestructive: true,
                  onTap: () => _confirmDeleteMessage(message),
                )
              else
                _ContextMenuAction(icon: Icons.flag_outlined, label: 'Report', onTap: () => _showReportSheet(message)),
            ],
          ),
        ),
      ),
    );
  }

  // A document stays a message on its own — the grid below is built for photo/video cells,
  // and a PDF mixed into it would just render broken. Mutually exclusive in both directions.
  Future<void> _pickAttachment() async {
    if (_pendingAttachments.any((a) => a.type == 'pdf')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Remove the document first to add photos.')),
      );
      return;
    }
    final room = _maxAttachmentsPerMessage - _pendingAttachments.length;
    if (room <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Only $_maxAttachmentsPerMessage attachments allowed per message')),
      );
      return;
    }
    final picked = await pickAttachment(context);
    if (picked.isEmpty) return;
    if (!mounted) return;
    if (picked.any((p) => p.type == 'pdf') && _pendingAttachments.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A document can only be sent on its own.')),
      );
      return;
    }
    bool fitsSizeCap(PickedAttachment p) =>
        p.sizeBytes <= (p.type == 'video' ? _maxVideoAttachmentSizeBytes : _maxAttachmentSizeBytes);
    final tooLarge = picked.where((p) => !fitsSizeCap(p)).isNotEmpty;
    final accepted = picked.where(fitsSizeCap).take(room).toList();
    if (accepted.isNotEmpty) setState(() => _pendingAttachments = [..._pendingAttachments, ...accepted]);
    if (tooLarge || picked.length > room) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tooLarge
                ? 'Some files are too large.'
                : 'Only $_maxAttachmentsPerMessage attachments allowed per message.',
          ),
        ),
      );
    }
  }

  void _removePendingAttachment(PickedAttachment attachment) =>
      setState(() => _pendingAttachments = _pendingAttachments.where((a) => a != attachment).toList());

  Future<void> _handleSend() async {
    final text = _textController.text;
    // No structured mention storage (see the chat-richness plan's Stage 4) — the composer
    // just checks whether the literal "@BusinessName" text made it into the message, same as
    // the old chip's boolean but driven by what was actually typed instead of a manual toggle.
    final businessName = widget.businessName;
    final mentionsDiveCenter = businessName != null && text.contains('@$businessName');
    final attachments = _pendingAttachments;
    final replyToId = _replyingTo?.id;

    if (attachments.isEmpty) {
      if (text.trim().isEmpty) return;
      _textController.clear();
      setState(() {
        _mentionTokenStart = -1;
        _replyingTo = null;
      });
      widget.viewModel.send(text, mentionsDiveCenter: mentionsDiveCenter, replyToId: replyToId);
      return;
    }

    // Clear the composer immediately — a pending bubble (with its own per-item loaders, see
    // _AttachmentGrid) takes over from here, see ChatViewModel.uploadMultipleAndSend, so
    // there's no window where both the composer chips and the sent bubble are visible at once.
    _textController.clear();
    setState(() {
      _mentionTokenStart = -1;
      _pendingAttachments = [];
      _replyingTo = null;
    });
    try {
      await widget.viewModel.uploadMultipleAndSend(
        attachments,
        caption: text,
        mentionsDiveCenter: mentionsDiveCenter,
        replyToId: replyToId,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send attachment: $e')),
      );
    }
  }

  void _showFeedbackSheet(ChatMessage message) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          _FeedbackSheet(viewModel: widget.viewModel, messageId: message.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Column(
      children: [
        Expanded(
          // Telegram-style: tapping anywhere in the message list dismisses the keyboard —
          // translucent so it never steals the scroll drag or a message bubble's own onTap,
          // both of which keep working exactly as before.
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => FocusScope.of(context).unfocus(),
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
                  final message = item.message;
                  if (message != null &&
                      message.kind == 'user' &&
                      message.userId != widget.viewModel.currentUserId) {
                    _loadProfile(message.userId);
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
                  final isOwnMessage =
                      messages.isNotEmpty &&
                      messages.last.userId == widget.viewModel.currentUserId;
                  _lastMessageCount = messages.length;
                  if (!wasEmpty && (isOwnMessage || _isNearBottom)) {
                    WidgetsBinding.instance.addPostFrameCallback(
                      (_) => _scrollToBottom(animate: true),
                    );
                  } else if (!wasEmpty && !isOwnMessage) {
                    _showNewMessagesPill = true;
                  }
                }

                return Stack(
                  children: [
                    ScrollablePositionedList.builder(
                      itemScrollController: _itemScrollController,
                      itemPositionsListener: _itemPositionsListener,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      itemCount: reversedItems.length,
                      itemBuilder: (context, index) {
                        final item = reversedItems[index];
                        if (item.date != null) {
                          return _DateSeparator(
                            key: ValueKey(item.date),
                            date: item.date!,
                          );
                        }
                        final message = item.message!;
                        if (message.kind != 'user') {
                          return _SystemMessageRow(
                            key: ValueKey(message.id),
                            message: message,
                            onGiveFeedback: () => _showFeedbackSheet(message),
                          );
                        }
                        final isMine =
                            message.userId == widget.viewModel.currentUserId;
                        final isDeleted = message.deletedAt != null;
                        final repliedTo = message.replyToId == null
                            ? null
                            : _findMessageById(messages, message.replyToId!);
                        final repliedToSenderName = repliedTo == null
                            ? null
                            : repliedTo.userId == widget.viewModel.currentUserId
                                ? 'You'
                                : (_profiles[repliedTo.userId]?.displayName?.isNotEmpty ?? false)
                                    ? _profiles[repliedTo.userId]!.displayName!
                                    : 'Diver';
                        return _MessageRow(
                          key: ValueKey(message.id),
                          message: message,
                          isMine: isMine,
                          isFirstInCluster: item.isFirstInCluster,
                          isLastInCluster: item.isLastInCluster,
                          profile: _profiles[message.userId],
                          businessName: widget.businessName,
                          isHighlighted: _highlightedMessageId == message.id,
                          repliedToMessage: repliedTo,
                          repliedToSenderName: repliedToSenderName,
                          onTapSender: () => _openProfile(message.userId),
                          onTapReplyPreview: repliedTo == null ? null : () => _scrollToMessage(repliedTo.id),
                          onLongPress: isDeleted
                              ? null
                              : (rect, image) => _showMessageActionsSheet(message, rect, image),
                          onReply: isDeleted ? null : () => _startReply(message),
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
        ),
        SafeArea(
          top: false,
          child: widget.isCancelled
              ? Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'This trip has been cancelled — the chat is read-only.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Typing '@' opens this list (dive center included as a normal entry when
                    // it's a business trip — see _mentionEntries); tapping a row inserts
                    // "@Display Name " and closes it. Mentioning the dive center is how a
                    // diver flags a message as actually needing staff attention (push only
                    // notifies staff on a mention, not every message).
                    if (_mentionTokenStart != -1 && _mentionMatches.isNotEmpty)
                      Container(
                        key: const ValueKey('mentionList'),
                        margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                        constraints: const BoxConstraints(maxHeight: 180),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: _mentionMatches.length,
                          itemBuilder: (context, index) {
                            final entry = _mentionMatches[index];
                            return ListTile(
                              dense: true,
                              leading: Icon(
                                entry.isDiveCenter ? Icons.campaign_outlined : Icons.person_outline,
                                size: 20,
                              ),
                              title: Text(entry.displayName),
                              onTap: () => _selectMention(entry),
                            );
                          },
                        ),
                      ),
                    if (_replyingTo != null)
                      Padding(
                        key: const ValueKey('replyPreviewChip'),
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                        child: _ReplyPreviewChip(
                          senderName: _replyingTo!.userId == widget.viewModel.currentUserId
                              ? 'You'
                              : ((_profiles[_replyingTo!.userId]?.displayName?.isNotEmpty ?? false)
                                  ? _profiles[_replyingTo!.userId]!.displayName!
                                  : 'Diver'),
                          previewText: _replyPreviewText(_replyingTo!),
                          onCancel: _cancelReply,
                        ),
                      ),
                    if (_pendingAttachments.isNotEmpty)
                      Padding(
                        key: const ValueKey('pendingAttachmentsRow'),
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                        // A lone PDF keeps the named chip; photos get a compact thumbnail
                        // strip instead (a filename-per-item row doesn't fit several across).
                        child: _pendingAttachments.length == 1 && _pendingAttachments.first.type == 'pdf'
                            ? _PendingAttachmentChip(
                                attachment: _pendingAttachments.first,
                                onRemove: () => _removePendingAttachment(_pendingAttachments.first),
                              )
                            : SizedBox(
                                height: 72,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: _pendingAttachments.length,
                                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                                  itemBuilder: (context, index) {
                                    final attachment = _pendingAttachments[index];
                                    return _PendingPhotoThumb(
                                      attachment: attachment,
                                      onRemove: () => _removePendingAttachment(attachment),
                                    );
                                  },
                                ),
                              ),
                      ),
                    Padding(
                      key: const ValueKey('composerRow'),
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.attach_file),
                            onPressed: _pickAttachment,
                          ),
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              focusNode: _composerFocusNode,
                              minLines: 1,
                              maxLines: 5,
                              keyboardType: TextInputType.multiline,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: _pendingAttachments.isNotEmpty ? 'Caption (optional)' : 'Message',
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.send),
                            onPressed: _handleSend,
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

/// Shown above the composer while replying to an earlier message — same shape/slot as
/// _PendingAttachmentChip below (a left accent bar instead of a thumbnail, same dismiss-X).
class _ReplyPreviewChip extends StatelessWidget {
  const _ReplyPreviewChip({required this.senderName, required this.previewText, required this.onCancel});

  final String senderName;
  final String previewText;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(width: 3, height: 34, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to $senderName',
                  style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  previewText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          IconButton(icon: const Icon(Icons.close, size: 18), onPressed: onCancel),
        ],
      ),
    );
  }
}

/// Shown above the composer between picking a file and tapping send — a small preview chip
/// with a remove (X) affordance. Once send is tapped this is cleared immediately; the upload
/// itself is tracked by a pending bubble in the message list instead (see ChatViewModel).
class _PendingAttachmentChip extends StatelessWidget {
  const _PendingAttachmentChip({
    required this.attachment,
    required this.onRemove,
  });

  final PickedAttachment attachment;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: attachment.type == 'image'
                ? Image.file(File(attachment.path), width: 44, height: 44, fit: BoxFit.cover)
                : Container(
                    width: 44,
                    height: 44,
                    color: theme.colorScheme.surface,
                    alignment: Alignment.center,
                    child: Icon(Icons.picture_as_pdf_outlined, color: theme.colorScheme.onSurfaceVariant),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              attachment.filename,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          IconButton(icon: const Icon(Icons.close, size: 18), onPressed: onRemove),
        ],
      ),
    );
  }
}

/// One square thumbnail in the multi-photo composer strip — a small remove-X badge overlaid
/// top-right, same idea as _PendingAttachmentChip's dismiss but compact enough to sit several
/// across in a horizontal scroll.
class _PendingPhotoThumb extends StatelessWidget {
  const _PendingPhotoThumb({required this.attachment, required this.onRemove});

  final PickedAttachment attachment;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: attachment.type == 'video'
                ? const VideoThumbnailPlaceholder(width: 64, height: 64)
                : Image.file(File(attachment.path), width: 64, height: 64, fit: BoxFit.cover),
          ),
          Positioned(
            top: -6,
            right: -6,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 22,
                height: 22,
                decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders a message's attachment(s) above its caption (`_MessageBody`) — the caption still
/// renders unconditionally below, even when empty, since it's what shows the timestamp. A
/// single non-PDF attachment gets the plain thumbnail treatment; several get the grid.
class _AttachmentPreview extends StatelessWidget {
  const _AttachmentPreview({required this.attachments, required this.color});

  final List<ChatAttachment> attachments;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (attachments.length > 1) {
      return _AttachmentGrid(attachments: attachments, color: color);
    }
    final attachment = attachments.first;
    switch (attachment.type) {
      case 'pdf':
        return _PdfAttachmentRow(attachment: attachment, color: color);
      case 'video':
        return _VideoAttachmentThumbnail(attachment: attachment, color: color);
      default:
        return _ImageAttachmentThumbnail(attachment: attachment, color: color);
    }
  }
}

// 1 -> full-width single image (handled by _ImageAttachmentThumbnail instead, never calls
// this); 2-3 -> that many columns, 1 row; 4 -> 2x2; 5-6 -> 3 columns, 2 rows; 7-9 -> 3x3. A
// trailing incomplete row's empty cells just stay empty, same as Telegram/WhatsApp.
int _gridColumns(int count) {
  if (count <= 3) return count;
  if (count == 4) return 2;
  return 3;
}

/// The 2+ attachment case — mixed photo/video. Tapping a photo cell opens the full-screen photo
/// preview, swipeable across every *photo* on this message (see AttachmentImagePreviewPage's
/// siblingUrls — video items are excluded from that swipe set, each video opens its own single
/// player instead). Each cell shows its own upload spinner independently (Nikolai's ask) rather
/// than one shared spinner for the whole grid.
class _AttachmentGrid extends StatelessWidget {
  const _AttachmentGrid({required this.attachments, required this.color});

  final List<ChatAttachment> attachments;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final imageUrls = [for (final a in attachments) if (a.type != 'video' && a.url != null) a.url!];
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: _gridColumns(attachments.length),
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
            childAspectRatio: 1,
          ),
          itemCount: attachments.length,
          itemBuilder: (context, index) {
            final attachment = attachments[index];
            final url = attachment.url;
            final isVideo = attachment.type == 'video';
            return GestureDetector(
              onTap: url == null
                  ? null
                  : () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => isVideo
                            ? AttachmentVideoPreviewPage(url: url)
                            : AttachmentImagePreviewPage(
                                url: url,
                                siblingUrls: imageUrls,
                                initialIndex: imageUrls.indexOf(url),
                              ),
                      ),
                    ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (isVideo)
                    VideoThumbnailPlaceholder(
                      width: double.infinity,
                      height: double.infinity,
                      durationSeconds: attachment.durationSeconds,
                    )
                  else if (url != null)
                    CachedAttachmentImage(url: url, fit: BoxFit.cover)
                  else if (attachment.localPath != null)
                    Image.file(File(attachment.localPath!), fit: BoxFit.cover),
                  if (!attachment.isUploaded)
                    Container(
                      color: Colors.black.withValues(alpha: 0.35),
                      child: const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ImageAttachmentThumbnail extends StatelessWidget {
  const _ImageAttachmentThumbnail({required this.attachment, required this.color});

  final ChatAttachment attachment;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final url = attachment.url;
    final localPath = attachment.localPath;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: GestureDetector(
        // Not tappable yet while it's still just a local pending echo — nothing to preview
        // remotely until the upload actually resolves.
        onTap: url == null
            ? null
            : () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AttachmentImagePreviewPage(url: url)),
              ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // No separate "downloaded" badge here (unlike the PDF row below) — the image
              // itself is the badge: a spinner while it's fetching, the photo once it's on
              // disk. A sibling badge fed by its own independent
              // AttachmentCacheService.getCachedFileInfo call raced this widget's own download
              // and settled first, so it showed "not downloaded" even after the photo had
              // fully loaded and was visibly on-screen.
              if (url != null)
                CachedAttachmentImage(url: url, width: 220, height: 160)
              else if (localPath != null)
                Image.file(File(localPath), width: 220, height: 160, fit: BoxFit.cover),
              if (!attachment.isUploaded)
                Container(
                  width: 220,
                  height: 160,
                  color: Colors.black.withValues(alpha: 0.35),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single-video bubble, sized to match _ImageAttachmentThumbnail so a solo video and a solo
/// photo bubble read the same width/height — the difference is the play-icon placeholder body
/// (see VideoThumbnailPlaceholder) instead of a decoded frame.
class _VideoAttachmentThumbnail extends StatelessWidget {
  const _VideoAttachmentThumbnail({required this.attachment, required this.color});

  final ChatAttachment attachment;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final url = attachment.url;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: GestureDetector(
        onTap: url == null
            ? null
            : () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AttachmentVideoPreviewPage(url: url)),
              ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            alignment: Alignment.center,
            children: [
              VideoThumbnailPlaceholder(width: 220, height: 160, durationSeconds: attachment.durationSeconds),
              if (!attachment.isUploaded)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PdfAttachmentRow extends StatelessWidget {
  const _PdfAttachmentRow({required this.attachment, required this.color});

  final ChatAttachment attachment;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final url = attachment.url;
    final filename = attachment.filename ?? 'Document.pdf';
    final sizeLabel = formatAttachmentFileSize(attachment.sizeBytes);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: GestureDetector(
        onTap: url == null ? null : () => openAttachmentInApp(context, url),
        child: Container(
          constraints: const BoxConstraints(minWidth: 200),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.picture_as_pdf_outlined, color: color),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      filename,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: color, fontWeight: FontWeight.w600),
                    ),
                    if (sizeLabel != null)
                      Text(sizeLabel, style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 12)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (!attachment.isUploaded || url == null)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: color.withValues(alpha: 0.7)),
                )
              else
                FutureBuilder<FileInfo?>(
                  future: AttachmentCacheService.getCachedFileInfo(url),
                  builder: (context, snapshot) => Icon(
                    snapshot.data != null ? Icons.check_circle_outline : Icons.cloud_download_outlined,
                    size: 18,
                    color: color.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
        ),
      ),
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
              Icon(
                Icons.arrow_downward,
                size: 16,
                color: theme.colorScheme.onPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                'New messages',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
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
    // A system message (kind != 'user') always starts its own cluster — it renders as a
    // centered row, never grouped with a neighboring real message.
    final continuesCluster =
        last != null &&
        last.day == day &&
        last.messages.last.userId == m.userId &&
        m.kind == 'user' &&
        last.messages.last.kind == 'user' &&
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

  const _ChatDisplayItem.message(
    this.message, {
    required this.isFirstInCluster,
    required this.isLastInCluster,
  }) : date = null;

  final DateTime? date;
  final ChatMessage? message;
  final bool isFirstInCluster;
  final bool isLastInCluster;
}

ChatMessage? _findMessageById(List<ChatMessage> messages, String id) {
  for (final m in messages) {
    if (m.id == id) return m;
  }
  return null;
}

// Shown in both the reply-quote strip inside a bubble and the composer's _ReplyPreviewChip —
// same fallback a deleted push notification body needs, mirrored from the backend's own
// pushBodyFor (routes_message.go), since text-vs-attachment-only is the same ambiguity here.
String _replyPreviewText(ChatMessage m) {
  if (m.deletedAt != null) return 'Message deleted';
  if (m.body.isNotEmpty) return m.body;
  if (m.attachments.length > 1) return '📎 ${m.attachments.length} attachments';
  return switch (m.attachments.isEmpty ? null : m.attachments.first.type) {
    'image' => '📷 Photo',
    'video' => '🎬 Video',
    'pdf' => '📄 PDF',
    _ => '',
  };
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
      items.add(
        _ChatDisplayItem.message(
          cluster.messages[i],
          isFirstInCluster: i == 0,
          isLastInCluster: i == cluster.messages.length - 1,
        ),
      );
    }
  }
  return items;
}

class _DateSeparator extends StatelessWidget {
  const _DateSeparator({super.key, required this.date});

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
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

/// A system-generated row (kind != 'user') — centered, no bubble/avatar, same pill look as
/// _DateSeparator. The switch on message.kind is the deliberate extension point for future
/// system kinds (Car/Buddy chat join messages); each just adds another case here.
class _SystemMessageRow extends StatelessWidget {
  const _SystemMessageRow({
    super.key,
    required this.message,
    required this.onGiveFeedback,
  });

  final ChatMessage message;
  final VoidCallback onGiveFeedback;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.8,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              switch (message.kind) {
                'feedback_prompt' => _FeedbackButton(
                  provided: message.feedbackProvided,
                  onPressed: onGiveFeedback,
                ),
                // car_joined/buddy_joined (and any future system kind) are just announcements — no action.
                _ => const SizedBox.shrink(),
              },
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackButton extends StatelessWidget {
  const _FeedbackButton({required this.provided, required this.onPressed});

  final bool provided;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (provided) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Chip(
          label: const Text('Thank you!'),
          avatar: const Icon(Icons.check, size: 16),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: FilledButton(
        onPressed: onPressed,
        child: const Text('Give feedback'),
      ),
    );
  }
}

/// Own messages never carry a name/avatar (isMine short-circuits straight to a
/// right-aligned bubble); everyone else's messages reserve a fixed-width avatar gutter
/// so bubbles line up whether or not this particular row is the one showing the avatar.
class _MessageRow extends StatefulWidget {
  const _MessageRow({
    super.key,
    required this.message,
    required this.isMine,
    required this.isFirstInCluster,
    required this.isLastInCluster,
    required this.profile,
    required this.onTapSender,
    this.onLongPress,
    this.onReply,
    this.businessName,
    this.repliedToMessage,
    this.repliedToSenderName,
    this.onTapReplyPreview,
    this.isHighlighted = false,
  });

  final ChatMessage message;
  final bool isMine;
  final bool isFirstInCluster;
  final bool isLastInCluster;
  final Profile? profile;
  final VoidCallback onTapSender;

  /// Fired once the bubble's on-screen Rect + a snapshot image are captured (see
  /// _MessageRowState._handleLongPress) — the caller uses both to render the iOS-style
  /// dimmed-background context menu in place. Null only for an already-deleted message.
  final void Function(Rect bubbleRect, ui.Image bubbleImage)? onLongPress;

  /// Fired by the swipe-to-reply gesture — same effect as the long-press menu's own Reply
  /// action. Null only for an already-deleted message.
  final VoidCallback? onReply;

  /// Never applied to the diver's own messages (see isMine below), and only ever combined
  /// with message.isDiveCenterStaff — a regular diver's message in a business trip's chat
  /// must never look like it came from the organization.
  final String? businessName;

  /// Resolved by ChatView (looked up in the already-loaded message list) when
  /// message.replyToId is set — null means either not a reply, or the original has since
  /// scrolled out of the loaded history (rare, v1 loads full history — see ChatViewModel).
  final ChatMessage? repliedToMessage;
  final String? repliedToSenderName;
  final VoidCallback? onTapReplyPreview;

  /// Briefly true right after onTapReplyPreview's own scroll-to lands here — see
  /// ChatView._scrollToMessage.
  final bool isHighlighted;

  @override
  State<_MessageRow> createState() => _MessageRowState();
}

class _MessageRowState extends State<_MessageRow> {
  double _dragDx = 0;
  static const _maxDrag = 60.0;
  static const _triggerThreshold = 40.0;

  // Wraps the bubble so onLongPress can snapshot exactly what's on screen (see
  // _handleLongPress) — the context menu renders this snapshot in place rather than
  // rebuilding the bubble's widget tree a second time in a completely different part of it.
  final _repaintKey = GlobalKey();

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    final next = (_dragDx + details.delta.dx).clamp(0.0, _maxDrag);
    if (next != _dragDx) setState(() => _dragDx = next);
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    final triggered = _dragDx > _triggerThreshold;
    setState(() => _dragDx = 0);
    if (triggered) widget.onReply?.call();
  }

  Future<void> _handleLongPress() async {
    final onLongPress = widget.onLongPress;
    if (onLongPress == null) return;
    final renderObject = _repaintKey.currentContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) return;
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;
    final image = await renderObject.toImage(pixelRatio: devicePixelRatio);
    if (!mounted) return;
    final rect = renderObject.localToGlobal(Offset.zero) & renderObject.size;
    onLongPress(rect, image);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final message = widget.message;
    final isMine = widget.isMine;
    final isFirstInCluster = widget.isFirstInCluster;
    final isLastInCluster = widget.isLastInCluster;
    final profile = widget.profile;
    final businessName = widget.businessName;
    final isDeleted = message.deletedAt != null;
    final bubbleColor = isMine
        ? colorScheme.primary
        : colorScheme.secondaryContainer;
    final onBubbleColor = isMine
        ? colorScheme.onPrimary
        : colorScheme.onSecondaryContainer;

    final baseName = (profile?.displayName?.isNotEmpty ?? false)
        ? profile!.displayName!
        : 'Diver';
    // Staff display always wins over the Observer label — in his own dive center's Bubbles
    // the founder shows up as staff, not as an observer (see users.is_product_observer).
    final isObserver =
        !message.isDiveCenterStaff && (profile?.isProductObserver ?? false);
    final name =
        (message.isDiveCenterStaff && (businessName?.isNotEmpty ?? false))
        ? '$baseName | $businessName'
        : isObserver
        ? '$baseName | Product Observer'
        : baseName;
    // Staff/Observer messages always carry a name, even mid-cluster — a trip's chat is
    // effectively a group conversation (organizer + every diver) even though it's framed as
    // one thread, so it should always be clear which staff member/observer is replying, not
    // just the first message in a burst. Regular divers keep the usual "only the first
    // message in a cluster" rule.
    final showName =
        !isMine &&
        (isFirstInCluster || message.isDiveCenterStaff || isObserver);

    final bubbleContent = Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.72,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: isDeleted
          ? Text(
              'Message deleted',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: onBubbleColor.withValues(alpha: 0.7),
                fontStyle: FontStyle.italic,
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (message.mentionsDiveCenter &&
                    (businessName?.isNotEmpty ?? false))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      '@$businessName',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: onBubbleColor,
                      ),
                    ),
                  ),
                if (showName)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: GestureDetector(
                      onTap: widget.onTapSender,
                      child: Text(
                        name,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: onBubbleColor,
                        ),
                      ),
                    ),
                  ),
                if (widget.repliedToMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: _ReplyQuoteStrip(
                      senderName: widget.repliedToSenderName ?? 'Diver',
                      previewText: _replyPreviewText(widget.repliedToMessage!),
                      color: onBubbleColor,
                      onTap: widget.onTapReplyPreview,
                    ),
                  ),
                if (message.attachments.isNotEmpty)
                  _AttachmentPreview(attachments: message.attachments, color: onBubbleColor),
                _MessageBody(
                  body: message.body,
                  time: formatTime(message.createdAt),
                  color: onBubbleColor,
                ),
                if (message.reactions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: _ReactionSummary(reactions: message.reactions, color: onBubbleColor),
                  ),
              ],
            ),
    );

    // AnimatedContainer color-flash for _scrollToMessage's landing highlight — transparent
    // to isHighlighted's own bubbleColor-tinted overlay otherwise.
    final highlighted = AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: widget.isHighlighted ? theme.colorScheme.tertiaryContainer.withValues(alpha: 0.6) : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: widget.isHighlighted ? const EdgeInsets.all(2) : EdgeInsets.zero,
      child: bubbleContent,
    );

    final bubble = isDeleted
        ? highlighted
        : Stack(
            alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
            children: [
              if (_dragDx > 0)
                Opacity(
                  opacity: (_dragDx / _maxDrag).clamp(0.0, 1.0),
                  child: Icon(Icons.reply, color: theme.colorScheme.onSurfaceVariant),
                ),
              GestureDetector(
                onLongPress: widget.onLongPress == null ? null : _handleLongPress,
                onHorizontalDragUpdate: widget.onReply == null ? null : _onHorizontalDragUpdate,
                onHorizontalDragEnd: widget.onReply == null ? null : _onHorizontalDragEnd,
                child: Transform.translate(
                  offset: Offset(_dragDx, 0),
                  child: RepaintBoundary(key: _repaintKey, child: highlighted),
                ),
              ),
            ],
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
                    onTap: widget.onTapSender,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: colorScheme.secondaryContainer,
                      backgroundImage: (profile?.avatarUrl?.isNotEmpty ?? false)
                          ? NetworkImage(profile!.avatarUrl!)
                          : null,
                      child: (profile?.avatarUrl?.isNotEmpty ?? false)
                          ? null
                          : Icon(
                              Icons.person,
                              size: 18,
                              color: colorScheme.onSecondaryContainer,
                            ),
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

/// The quoted strip inside a bubble that's replying to another message — tap scrolls to and
/// highlights the original (see ChatView._scrollToMessage).
/// "❤️ 3 😂 1" under a bubble that has any reactions — informational only for v1, no "who
/// reacted" detail, no tap-shortcut beyond the long-press menu itself (see plan). Sorted by
/// _reactionEmojis' own fixed order so the row doesn't visually reshuffle as counts change.
class _ReactionSummary extends StatelessWidget {
  const _ReactionSummary({required this.reactions, required this.color});

  final Map<String, ChatReaction> reactions;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = [
      for (final emoji in _reactionEmojis)
        if (reactions[emoji] != null) MapEntry(emoji, reactions[emoji]!),
    ];
    if (entries.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 6,
      children: [
        for (final entry in entries)
          Text(
            '${entry.key} ${entry.value.count}',
            style: theme.textTheme.labelSmall?.copyWith(color: color.withValues(alpha: 0.85)),
          ),
      ],
    );
  }
}

class _ReplyQuoteStrip extends StatelessWidget {
  const _ReplyQuoteStrip({
    required this.senderName,
    required this.previewText,
    required this.color,
    this.onTap,
  });

  final String senderName;
  final String previewText;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color.withValues(alpha: 0.6), width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              senderName,
              style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700, color: color),
            ),
            Text(
              previewText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(color: color.withValues(alpha: 0.85)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContextMenuAction {
  const _ContextMenuAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
}

/// iOS/Telegram-style long-press menu: dims+blurs everything, keeps the pressed bubble visible
/// in place (rendered from the snapshot _MessageRow captured, not rebuilt), and anchors the
/// action list directly below it — flipping above when there isn't room underneath. Tapping
/// the backdrop dismisses with no action; tapping an item pops first, then runs it, so each
/// [_ContextMenuAction.onTap] can stay a plain "do the thing" callback.
class _MessageContextMenu extends StatelessWidget {
  const _MessageContextMenu({
    required this.bubbleRect,
    required this.bubbleImage,
    required this.actions,
    required this.onDismiss,
    required this.reactions,
    required this.onReact,
  });

  final Rect bubbleRect;
  final ui.Image bubbleImage;
  final List<_ContextMenuAction> actions;

  /// Fired on backdrop-tap-to-cancel only — action taps handle their own focus outcome (see
  /// ChatView._settleFocus), so this must not also fire there or it'd fight Reply's intent.
  final VoidCallback onDismiss;

  /// This viewer's current reactions on the message — used only to highlight whichever of the
  /// fixed 8 emojis (if any) they've already picked; ChatViewModel.reactToMessage decides
  /// set-vs-remove from this same data.
  final Map<String, ChatReaction> reactions;
  final void Function(String emoji) onReact;

  static const _menuWidth = 230.0;
  static const _gap = 8.0;
  static const _rowHeight = 48.0;
  static const _screenMargin = 16.0;
  static const _reactionRowHeight = 52.0;
  static const _reactionCellWidth = 36.0;
  // 8 == _reactionEmojis.length — can't reference that in a const expression here, so kept in
  // sync by hand; both live right next to each other at the top of this file.
  static const _reactionRowWidth = _reactionCellWidth * 8 + 12;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenSize = MediaQuery.sizeOf(context);
    final safePadding = MediaQuery.paddingOf(context);
    final menuHeight = actions.length * _rowHeight + 16;

    // Menu always renders below the bubble, the reaction row always above it — a fixed,
    // consistent arrangement. When there isn't room below for the menu, or above for the
    // reaction row, the whole group shifts up together instead (Telegram/Messenger do the same
    // for a bubble near the bottom of the screen); minTop reserves space above the bubble for
    // the reaction row specifically, since that's a second thing (not just the menu) now
    // competing for vertical space near the top of the screen.
    final spaceBelow = screenSize.height - safePadding.bottom - bubbleRect.bottom;
    final shortfall = (menuHeight + _gap + _screenMargin) - spaceBelow;
    final verticalShift = shortfall > 0 ? shortfall : 0.0;
    // max/min rather than .clamp() — a bubble already hard against the top of the screen can
    // make the "don't go above the safe area" floor exceed bubbleRect.top itself, which
    // .clamp(lower, upper) would throw on (lower > upper); this degrades to "no shift" instead.
    final minTop = safePadding.top + _screenMargin + _reactionRowHeight + _gap;
    final shiftedBubbleTop = math.max(minTop, math.min(bubbleRect.top, bubbleRect.top - verticalShift));
    final menuTop = shiftedBubbleTop + bubbleRect.height + _gap;
    final reactionRowTop = shiftedBubbleTop - _gap - _reactionRowHeight;

    var menuLeft = bubbleRect.left;
    if (menuLeft + _menuWidth > screenSize.width - _screenMargin) {
      menuLeft = screenSize.width - _screenMargin - _menuWidth;
    }
    if (menuLeft < _screenMargin) menuLeft = _screenMargin;

    var reactionRowLeft = bubbleRect.left;
    if (reactionRowLeft + _reactionRowWidth > screenSize.width - _screenMargin) {
      reactionRowLeft = screenSize.width - _screenMargin - _reactionRowWidth;
    }
    if (reactionRowLeft < _screenMargin) reactionRowLeft = _screenMargin;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: () {
                onDismiss();
                Navigator.of(context).pop();
              },
              // Solid, near-opaque scrim — not a real-time blur (BackdropFilter's first-frame
              // cost was visibly lagging a beat behind the menu appearing, see the bug this
              // fixed) — and matches Telegram/Messenger's own look: other messages aren't just
              // dimmed, they're not really visible at all.
              child: Container(color: Colors.black.withValues(alpha: 0.92)),
            ),
          ),
          Positioned(
            left: bubbleRect.left,
            top: shiftedBubbleTop,
            width: bubbleRect.width,
            height: bubbleRect.height,
            child: IgnorePointer(
              child: RawImage(image: bubbleImage, width: bubbleRect.width, height: bubbleRect.height),
            ),
          ),
          Positioned(
            left: reactionRowLeft,
            top: reactionRowTop,
            width: _reactionRowWidth,
            height: _reactionRowHeight,
            child: Material(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(_reactionRowHeight / 2),
              elevation: 8,
              clipBehavior: Clip.antiAlias,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (final emoji in _reactionEmojis)
                    InkWell(
                      onTap: () => onReact(emoji),
                      customBorder: const CircleBorder(),
                      child: SizedBox(
                        width: _reactionCellWidth,
                        height: _reactionRowHeight,
                        child: Center(
                          child: Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: (reactions[emoji]?.reactedByMe ?? false)
                                ? BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                    shape: BoxShape.circle,
                                  )
                                : null,
                            child: Text(emoji, style: const TextStyle(fontSize: 20)),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Positioned(
            left: menuLeft,
            top: menuTop,
            width: _menuWidth,
            child: Material(
              color: theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
              elevation: 8,
              clipBehavior: Clip.antiAlias,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) Divider(height: 1, color: theme.colorScheme.outlineVariant),
                    InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        actions[i].onTap();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                actions[i].label,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: actions[i].isDestructive ? theme.colorScheme.error : theme.colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Icon(
                              actions[i].icon,
                              size: 18,
                              color: actions[i].isDestructive ? theme.colorScheme.error : theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _reportReasons = ['Spam', 'Harassment', 'Inappropriate content', 'Other'];

class _ReportMessageSheet extends StatefulWidget {
  const _ReportMessageSheet({required this.viewModel, required this.messageId});

  final ChatViewModel viewModel;
  final String messageId;

  @override
  State<_ReportMessageSheet> createState() => _ReportMessageSheetState();
}

class _ReportMessageSheetState extends State<_ReportMessageSheet> {
  String _reason = _reportReasons.first;
  final _detailsController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final error = await widget.viewModel.reportMessage(
      widget.messageId,
      _reason,
      details: _detailsController.text.trim().isEmpty
          ? null
          : _detailsController.text.trim(),
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Report sent — thank you.')));
    } else {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not send report: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report message',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _reportReasons
                  .map(
                    (reason) => ChoiceChip(
                      label: Text(reason),
                      selected: _reason == reason,
                      onSelected: (_) => setState(() => _reason = reason),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _detailsController,
              decoration: const InputDecoration(
                labelText: 'Details (optional)',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Fixed checklist for "what did DiveBubble help you with" — 'Nothing yet' is exclusive with
// the rest (see _FeedbackSheetState._toggleHelpedWith), so it's never combined with a real
// answer in the stored comma-joined string.
const _helpedWithOptions = [
  'Trip information',
  'Chatting with participants',
  'Finding transport',
  'Finding Buddy',
  'Nothing yet',
];

class _FeedbackSheet extends StatefulWidget {
  const _FeedbackSheet({required this.viewModel, required this.messageId});

  final ChatViewModel viewModel;
  final String messageId;

  @override
  State<_FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<_FeedbackSheet> {
  int _rating = 0;
  final Set<String> _helpedWith = {};
  final _commentController = TextEditingController();
  bool _contactOk = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _toggleHelpedWith(String option, bool selected) {
    setState(() {
      if (option == 'Nothing yet') {
        _helpedWith
          ..clear()
          ..addAll(selected ? {option} : {});
        return;
      }
      if (selected) {
        _helpedWith
          ..remove('Nothing yet')
          ..add(option);
      } else {
        _helpedWith.remove(option);
      }
    });
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final error = await widget.viewModel.submitFeedback(
      widget.messageId,
      _rating,
      _helpedWith.toList(),
      _commentController.text.trim().isEmpty
          ? null
          : _commentController.text.trim(),
      _contactOk,
    );
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Thank you!')));
    } else {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not send feedback: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'How useful was DiveBubble for this trip?',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var star = 1; star <= 5; star++)
                  IconButton(
                    onPressed: () => setState(() => _rating = star),
                    icon: Icon(
                      star <= _rating ? Icons.star : Icons.star_border,
                      color: theme.colorScheme.primary,
                      size: 32,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'What did DiveBubble help you with?',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _helpedWithOptions.map((option) {
                final selected = _helpedWith.contains(option);
                return FilterChip(
                  // The built-in checkmark animates its own width in/out of the avatar slot,
                  // which visibly resizes/reflows every chip in the Wrap on toggle. Reserving
                  // a fixed-size icon slot ourselves (check when selected, invisible otherwise)
                  // keeps every chip's width constant regardless of selection state.
                  showCheckmark: false,
                  avatar: SizedBox(
                    width: 18,
                    height: 18,
                    child: selected
                        ? Icon(
                            Icons.check,
                            size: 18,
                            color: theme.colorScheme.onSecondaryContainer,
                          )
                        : null,
                  ),
                  label: Text(option),
                  selected: selected,
                  onSelected: (value) => _toggleHelpedWith(option, value),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            Text('What should we improve?', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              decoration: const InputDecoration(hintText: 'Optional'),
              maxLines: 3,
            ),
            CheckboxListTile(
              value: _contactOk,
              onChanged: (value) => setState(() => _contactOk = value ?? false),
              title: const Text('Can we contact you about your feedback?'),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_isSubmitting || _rating == 0) ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit feedback'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Message text with its timestamp trailing inline on the same line — like WhatsApp/Telegram,
/// not stacked on its own row below. A zero-opacity copy of the timestamp is appended as a
/// [WidgetSpan] so the paragraph's line-wrapping reserves room for it (falling to a new line
/// if the last line is already full); the real, visible timestamp is then drawn on top at the
/// bottom-right corner via [Stack]+[Positioned], landing in that reserved space.
final _urlPattern = RegExp(r'(https?:\/\/\S+|www\.\S+)', caseSensitive: false);

class _MessageBody extends StatefulWidget {
  const _MessageBody({
    required this.body,
    required this.time,
    required this.color,
  });

  final String body;
  final String time;
  final Color color;

  @override
  State<_MessageBody> createState() => _MessageBodyState();
}

class _MessageBodyState extends State<_MessageBody> {
  final _linkRecognizers = <TapGestureRecognizer>[];

  @override
  void dispose() {
    for (final recognizer in _linkRecognizers) {
      recognizer.dispose();
    }
    super.dispose();
  }

  List<TextSpan> _buildSpans(TextStyle? bodyStyle) {
    for (final recognizer in _linkRecognizers) {
      recognizer.dispose();
    }
    _linkRecognizers.clear();

    final spans = <TextSpan>[];
    var start = 0;
    for (final match in _urlPattern.allMatches(widget.body)) {
      if (match.start > start) {
        spans.add(TextSpan(text: widget.body.substring(start, match.start)));
      }
      // Trailing punctuation (e.g. a sentence-ending period) usually isn't part of the URL.
      var end = match.end;
      while (end > match.start && '.,;:!?)'.contains(widget.body[end - 1])) {
        end--;
      }
      final url = widget.body.substring(match.start, end);
      final recognizer = TapGestureRecognizer()
        ..onTap = () => launchUrlExternally(context, url.startsWith('http') ? url : 'https://$url');
      _linkRecognizers.add(recognizer);
      spans.add(
        TextSpan(
          text: url,
          style: bodyStyle?.copyWith(decoration: TextDecoration.underline),
          recognizer: recognizer,
        ),
      );
      if (end < match.end) {
        spans.add(TextSpan(text: widget.body.substring(end, match.end)));
      }
      start = match.end;
    }
    if (start < widget.body.length) {
      spans.add(TextSpan(text: widget.body.substring(start)));
    }
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bodyStyle = TextStyle(color: widget.color);
    final timeStyle = theme.textTheme.labelSmall?.copyWith(
      color: widget.color.withValues(alpha: 0.7),
      fontSize: 11,
    );
    return Stack(
      children: [
        Text.rich(
          TextSpan(
            style: bodyStyle,
            children: [
              ..._buildSpans(bodyStyle),
              WidgetSpan(
                alignment: PlaceholderAlignment.baseline,
                baseline: TextBaseline.alphabetic,
                child: Opacity(
                  opacity: 0,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Text(widget.time, style: timeStyle),
                  ),
                ),
              ),
            ],
          ),
        ),
        Positioned(right: 0, bottom: 0, child: Text(widget.time, style: timeStyle)),
      ],
    );
  }
}
