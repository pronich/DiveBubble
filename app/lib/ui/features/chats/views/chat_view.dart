import 'dart:io';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

import '../../../../data/services/attachment_cache_service.dart';
import '../../../../domain/entities/chat_message.dart';
import '../../../../domain/entities/profile.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/widgets/cached_attachment_image.dart';
import '../../../core/widgets/open_attachment.dart';
import '../../../core/widgets/pick_attachment.dart';
import '../../profile/views/diver_id_card.dart';
import '../view_models/chat_view_model.dart';
import 'attachment_image_preview_page.dart';

// Consecutive messages from the same sender on the same day collapse into one visual
// cluster (name shown once, avatar anchored to the last bubble) as long as the gap
// between them stays under this window — a longer gap reads as a separate "turn", so it
// gets its own name + avatar again, Telegram-style.
const _groupingWindow = Duration(minutes: 5);

// Mirrors the backend's upload.MaxAttachmentSize — checked client-side before ever hitting the
// network as a cheap UX win; the backend still enforces this authoritatively.
const _maxAttachmentSizeBytes = 10 * 1024 * 1024;

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
  final _scrollController = ScrollController();
  final Map<String, Profile> _profiles = {};
  final Set<String> _fetchingProfileIds = {};
  int _lastMessageCount = 0;
  bool _isNearBottom = true;
  bool _showNewMessagesPill = false;
  // Armed via the "@DiveCenter" chip (business trips only — see the chip's own comment
  // below), reset once the armed message is actually sent.
  bool _mentionArmed = false;

  PickedAttachment? _pendingAttachment;

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
    if (nearBottom == _isNearBottom && !(nearBottom && _showNewMessagesPill))
      return;
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
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    } else {
      _scrollController.jumpTo(0);
    }
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

  void _openProfile(String userId) {
    showDiverIdCard(
      context,
      userId: userId,
      currentUserId: widget.viewModel.currentUserId,
      profileRepository: widget.viewModel.profileRepository,
    );
  }

  void _showReportSheet(ChatMessage message) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _ReportMessageSheet(
        viewModel: widget.viewModel,
        messageId: message.id,
      ),
    );
  }

  Future<void> _pickAttachment() async {
    final picked = await pickAttachment(context);
    if (picked == null) return;
    if (picked.sizeBytes > _maxAttachmentSizeBytes) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File is too large — max 10MB.')),
      );
      return;
    }
    setState(() => _pendingAttachment = picked);
  }

  void _removePendingAttachment() => setState(() => _pendingAttachment = null);

  Future<void> _handleSend() async {
    final text = _textController.text;
    final mentionsDiveCenter = _mentionArmed;
    final attachment = _pendingAttachment;

    if (attachment == null) {
      if (text.trim().isEmpty) return;
      _textController.clear();
      setState(() => _mentionArmed = false);
      widget.viewModel.send(text, mentionsDiveCenter: mentionsDiveCenter);
      return;
    }

    // Clear the composer immediately — a pending bubble (with its own loader over the
    // attachment) takes over from here, see ChatViewModel.uploadAndSend, so there's no window
    // where both the composer chip's spinner and the sent bubble are visible at once.
    _textController.clear();
    setState(() {
      _mentionArmed = false;
      _pendingAttachment = null;
    });
    try {
      await widget.viewModel.uploadAndSend(
        attachment.path,
        attachmentType: attachment.type,
        attachmentFilename: attachment.filename,
        caption: text,
        mentionsDiveCenter: mentionsDiveCenter,
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
                    ListView.builder(
                      controller: _scrollController,
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
                        return _MessageRow(
                          key: ValueKey(message.id),
                          message: message,
                          isMine: isMine,
                          isFirstInCluster: item.isFirstInCluster,
                          isLastInCluster: item.isLastInCluster,
                          profile: _profiles[message.userId],
                          businessName: widget.businessName,
                          onTapSender: () => _openProfile(message.userId),
                          onLongPress: isMine
                              ? null
                              : () => _showReportSheet(message),
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
                    // Business trips only — mentioning the dive center is how a diver flags
                    // a message as actually needing staff attention (Stage 2 push will only
                    // notify staff on a mention, not every message, to avoid spamming
                    // several staff members over one trip's chat).
                    if (widget.businessName != null &&
                        widget.canMentionDiveCenter)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FilterChip(
                            avatar: const Icon(
                              Icons.campaign_outlined,
                              size: 16,
                            ),
                            label: Text('@${widget.businessName}'),
                            selected: _mentionArmed,
                            onSelected: (value) =>
                                setState(() => _mentionArmed = value),
                          ),
                        ),
                      ),
                    if (_pendingAttachment != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                        child: _PendingAttachmentChip(
                          attachment: _pendingAttachment!,
                          onRemove: _removePendingAttachment,
                        ),
                      ),
                    Padding(
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
                              minLines: 1,
                              maxLines: 5,
                              keyboardType: TextInputType.multiline,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                hintText: _pendingAttachment != null ? 'Caption (optional)' : 'Message',
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

/// Renders a message's photo or PDF attachment above its caption (`_MessageBody`) — the caption
/// still renders unconditionally below, even when empty, since it's what shows the timestamp.
class _AttachmentPreview extends StatelessWidget {
  const _AttachmentPreview({required this.message, required this.color});

  final ChatMessage message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (message.attachmentType == 'pdf') {
      return _PdfAttachmentRow(message: message, color: color);
    }
    return _ImageAttachmentThumbnail(message: message, color: color);
  }
}

class _ImageAttachmentThumbnail extends StatelessWidget {
  const _ImageAttachmentThumbnail({required this.message, required this.color});

  final ChatMessage message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final url = message.attachmentUrl;
    final localPath = message.localAttachmentPath;
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
              if (message.isPending)
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

class _PdfAttachmentRow extends StatelessWidget {
  const _PdfAttachmentRow({required this.message, required this.color});

  final ChatMessage message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final url = message.attachmentUrl;
    final filename = message.attachmentFilename ?? 'Document.pdf';
    final sizeLabel = formatAttachmentFileSize(message.attachmentSizeBytes);
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
              if (message.isPending || url == null)
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
class _MessageRow extends StatelessWidget {
  const _MessageRow({
    super.key,
    required this.message,
    required this.isMine,
    required this.isFirstInCluster,
    required this.isLastInCluster,
    required this.profile,
    required this.onTapSender,
    this.onLongPress,
    this.businessName,
  });

  final ChatMessage message;
  final bool isMine;
  final bool isFirstInCluster;
  final bool isLastInCluster;
  final Profile? profile;
  final VoidCallback onTapSender;

  /// Null for the diver's own messages — reporting your own message isn't a thing.
  final VoidCallback? onLongPress;

  /// Never applied to the diver's own messages (see isMine below), and only ever combined
  /// with message.isDiveCenterStaff — a regular diver's message in a business trip's chat
  /// must never look like it came from the organization.
  final String? businessName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
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

    final bubble = GestureDetector(
      onLongPress: onLongPress,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
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
                  onTap: onTapSender,
                  child: Text(
                    name,
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: onBubbleColor,
                    ),
                  ),
                ),
              ),
            if (message.attachmentUrl != null || message.localAttachmentPath != null)
              _AttachmentPreview(message: message, color: onBubbleColor),
            _MessageBody(
              body: message.body,
              time: formatTime(message.createdAt),
              color: onBubbleColor,
            ),
          ],
        ),
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
