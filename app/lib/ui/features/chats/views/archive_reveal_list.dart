import 'package:flutter/material.dart';

/// Telegram-style "pull down past the top of the list to reveal the Archive" — the folder
/// cell isn't a normal list item (it stays fully hidden otherwise, per the product ask), it's
/// drawn in the overscroll gap that opens up above the list's first row while you're dragging
/// past the top. BouncingScrollPhysics is what makes that gap exist at all (ScrollPosition.pixels
/// goes negative during the drag, which is exactly the rubber-band effect) — forced here on
/// every platform, not just iOS, since Android's default ClampingScrollPhysics never overscrolls
/// and this gesture wouldn't exist there otherwise.
///
/// Release below _openThreshold: the cell just springs back with the list (no separate
/// animation needed — the same physics-driven position updates that grew it also shrink it
/// back, via the ScrollUpdateNotifications the spring-back animation itself generates).
/// Release past _openThreshold: opens the Archive directly, Telegram's "pull all the way"
/// shortcut. There's no persistent "Archive" row — pulling again is the only way back in,
/// which is deliberately how the product spec wants it hidden.
///
/// Exact thresholds/feel are a best guess without on-device testing — expect a tuning pass.
class ArchiveRevealList extends StatefulWidget {
  const ArchiveRevealList({
    required this.itemCount,
    required this.itemBuilder,
    required this.separatorBuilder,
    required this.archivedCount,
    required this.archivedPreviewText,
    required this.onOpenArchive,
    this.padding,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final IndexedWidgetBuilder separatorBuilder;
  final int archivedCount;
  final String archivedPreviewText;
  final VoidCallback onOpenArchive;
  final EdgeInsetsGeometry? padding;

  @override
  State<ArchiveRevealList> createState() => _ArchiveRevealListState();
}

class _ArchiveRevealListState extends State<ArchiveRevealList> {
  static const _maxReveal = 72.0;
  static const _openThreshold = 116.0;

  double _pullDistance = 0;

  bool _handleNotification(ScrollNotification notification) {
    if (widget.archivedCount == 0) return false;
    if (notification is ScrollUpdateNotification || notification is OverscrollNotification) {
      final pixels = notification.metrics.pixels;
      final pull = pixels < 0 ? -pixels : 0.0;
      if (pull != _pullDistance) setState(() => _pullDistance = pull);
    } else if (notification is ScrollEndNotification) {
      if (_pullDistance >= _openThreshold) widget.onOpenArchive();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final revealHeight = _pullDistance.clamp(0.0, _maxReveal);
    final progress = (_pullDistance / _maxReveal).clamp(0.0, 1.0);
    final armed = _pullDistance >= _openThreshold;

    return NotificationListener<ScrollNotification>(
      onNotification: _handleNotification,
      child: Stack(
        children: [
          if (widget.archivedCount > 0 && revealHeight > 0)
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
                    count: widget.archivedCount,
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

class _ArchiveRevealCell extends StatelessWidget {
  const _ArchiveRevealCell({
    required this.count,
    required this.preview,
    required this.progress,
    required this.armed,
  });

  final int count;
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
                '$count',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
