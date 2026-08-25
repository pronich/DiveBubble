import 'package:flutter/material.dart';

/// Telegram-style "pull down to reveal the Archive, pull again to refresh".
///
/// Two phases, controlled by [revealed] (owned by the parent so it can reset the state on
/// tab-switch-away/background-return — see MyTripsView's `_archiveRevealed`):
///
/// - Not revealed: the folder cell isn't a normal list item, it's drawn in the overscroll gap
///   that opens up above the list's first row while dragging past the top (BouncingScrollPhysics
///   is what makes that gap exist at all — forced here on every platform, not just iOS, since
///   Android's default ClampingScrollPhysics never overscrolls). Releasing past _openThreshold
///   calls [onRevealed] to pin the row; releasing short of it just springs back with the list,
///   no separate animation needed.
/// - Revealed: the folder becomes a real first list item (scrolls with the list, same as
///   Telegram), and the list switches to a normal RefreshIndicator — so a second pull now
///   triggers [onRefresh] instead of fighting the reveal gesture for the same drag.
///
/// Exact thresholds/feel are a best guess without on-device testing — expect a tuning pass.
class ArchiveRevealList extends StatefulWidget {
  const ArchiveRevealList({
    required this.itemCount,
    required this.itemBuilder,
    required this.separatorBuilder,
    required this.archivedCount,
    required this.archivedUnreadCount,
    required this.archivedPreviewText,
    required this.revealed,
    required this.onRevealed,
    required this.onOpenArchive,
    required this.onRefresh,
    this.padding,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final IndexedWidgetBuilder separatorBuilder;
  final int archivedCount;
  final int archivedUnreadCount;
  final String archivedPreviewText;
  final bool revealed;
  final VoidCallback onRevealed;
  final VoidCallback onOpenArchive;
  final Future<void> Function() onRefresh;
  final EdgeInsetsGeometry? padding;

  @override
  State<ArchiveRevealList> createState() => _ArchiveRevealListState();
}

class _ArchiveRevealListState extends State<ArchiveRevealList> {
  static const _maxReveal = 72.0;
  static const _openThreshold = 116.0;

  double _pullDistance = 0;
  // Guards against firing onRevealed more than once per gesture — BouncingScrollPhysics
  // still delivers a handful of ScrollUpdateNotifications after the finger lifts (the
  // spring-back), so this can't wait for ScrollEndNotification to check the threshold: by
  // then the ballistic animation has already carried pixels most of the way back to 0.
  // Triggering the moment the threshold is crossed mid-drag sidesteps that entirely.
  bool _triggeredReveal = false;

  bool get _canReveal => !widget.revealed && widget.archivedCount > 0;
  bool get _showPinnedRow => widget.revealed && widget.archivedCount > 0;

  bool _handleNotification(ScrollNotification notification) {
    if (!_canReveal) return false;
    if (notification is ScrollUpdateNotification || notification is OverscrollNotification) {
      final pixels = notification.metrics.pixels;
      final pull = pixels < 0 ? -pixels : 0.0;
      if (pull != _pullDistance) setState(() => _pullDistance = pull);
      if (!_triggeredReveal && pull >= _openThreshold) {
        _triggeredReveal = true;
        widget.onRevealed();
      }
    } else if (notification is ScrollEndNotification) {
      _triggeredReveal = false;
      if (_pullDistance != 0) setState(() => _pullDistance = 0);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (!_canReveal) {
      return RefreshIndicator(
        onRefresh: widget.onRefresh,
        child: ListView.separated(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: widget.padding,
          itemCount: widget.itemCount + (_showPinnedRow ? 1 : 0),
          itemBuilder: (context, index) {
            if (_showPinnedRow) {
              if (index == 0) {
                return _ArchivePinnedRow(
                  unreadCount: widget.archivedUnreadCount,
                  preview: widget.archivedPreviewText,
                  onTap: widget.onOpenArchive,
                );
              }
              return widget.itemBuilder(context, index - 1);
            }
            return widget.itemBuilder(context, index);
          },
          separatorBuilder: (context, index) {
            if (_showPinnedRow && index == 0) {
              return const Divider(height: 1, indent: 76);
            }
            return widget.separatorBuilder(context, _showPinnedRow ? index - 1 : index);
          },
        ),
      );
    }

    final revealHeight = _pullDistance.clamp(0.0, _maxReveal);
    final progress = (_pullDistance / _maxReveal).clamp(0.0, 1.0);
    final armed = _pullDistance >= _openThreshold;

    return NotificationListener<ScrollNotification>(
      onNotification: _handleNotification,
      child: Stack(
        children: [
          if (revealHeight > 0)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: revealHeight,
              child: ClipRect(
                child: OverflowBox(
                  maxHeight: _maxReveal,
                  minHeight: _maxReveal,
                  alignment: Alignment.bottomCenter,
                  child: _ArchiveRevealCell(
                    unreadCount: widget.archivedUnreadCount,
                    preview: widget.archivedPreviewText,
                    progress: progress,
                    armed: armed,
                  ),
                ),
              ),
            ),
          ListView.separated(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            padding: widget.padding,
            itemCount: widget.itemCount,
            itemBuilder: widget.itemBuilder,
            separatorBuilder: widget.separatorBuilder,
          ),
        ],
      ),
    );
  }
}

class _ArchivePinnedRow extends StatelessWidget {
  const _ArchivePinnedRow({required this.unreadCount, required this.preview, required this.onTap});

  final int unreadCount;
  final String preview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              child: Icon(Icons.archive, color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Archived Chats', style: theme.textTheme.titleMedium),
                  if (preview.isNotEmpty)
                    Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(minWidth: 22),
                height: 22,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$unreadCount',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
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

class _ArchiveRevealCell extends StatelessWidget {
  const _ArchiveRevealCell({
    required this.unreadCount,
    required this.preview,
    required this.progress,
    required this.armed,
  });

  final int unreadCount;
  final String preview;
  final double progress;
  final bool armed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Opacity(
      opacity: progress,
      child: Container(
        color: theme.colorScheme.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Transform.scale(
              scale: 0.6 + 0.4 * progress,
              child: CircleAvatar(
                radius: 26,
                backgroundColor: armed
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.archive,
                  color: armed ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Archived Chats', style: theme.textTheme.titleMedium),
                  if (preview.isNotEmpty)
                    Text(
                      preview,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                constraints: const BoxConstraints(minWidth: 22),
                height: 22,
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '$unreadCount',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
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
