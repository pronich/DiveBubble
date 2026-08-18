import 'dart:io';

import 'package:flutter/material.dart';

import '../../../data/services/attachment_cache_service.dart';

/// Resolves a cached (or freshly downloaded) attachment image with proper loading/error states
/// — shared by the chat bubble, Chat Info's Media grid, and the full-screen preview. A failed
/// download (bad URL, network drop) shows a tap-to-retry affordance instead of spinning
/// forever — `FutureBuilder.hasData` alone stays false on error too, so callers that only check
/// `!hasData` never notice the future actually completed (with an error) and get stuck.
class CachedAttachmentImage extends StatefulWidget {
  const CachedAttachmentImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;

  @override
  State<CachedAttachmentImage> createState() => _CachedAttachmentImageState();
}

class _CachedAttachmentImageState extends State<CachedAttachmentImage> {
  late Future<File> _future = AttachmentCacheService.getFile(widget.url);

  @override
  void didUpdateWidget(covariant CachedAttachmentImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // `late` only evaluates once at State creation — without this, a State object reused for a
    // different message (e.g. a ListView without per-item Keys reusing State by position) would
    // keep showing whichever image its *first* url resolved to, forever, regardless of what
    // widget.url becomes afterward.
    if (oldWidget.url != widget.url) {
      _future = AttachmentCacheService.getFile(widget.url);
    }
  }

  void _retry() {
    // Block body, not `=> _future = ...` — an arrow body here evaluates to the assignment's
    // value (the Future itself), which trips Flutter's "setState callback returned a Future"
    // assertion since it expects a plain VoidCallback.
    setState(() {
      _future = AttachmentCacheService.getFile(widget.url);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<File>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done && snapshot.hasError) {
          return GestureDetector(
            onTap: _retry,
            child: Container(
              width: widget.width,
              height: widget.height,
              color: theme.colorScheme.surfaceContainerHighest,
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.broken_image_outlined, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to retry',
                    style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return Container(
            width: widget.width,
            height: widget.height,
            color: theme.colorScheme.surfaceContainerHighest,
            alignment: Alignment.center,
            child: const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          );
        }
        return Image.file(snapshot.data!, width: widget.width, height: widget.height, fit: widget.fit);
      },
    );
  }
}
