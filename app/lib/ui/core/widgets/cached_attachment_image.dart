import 'dart:io';

import 'package:flutter/material.dart';

import '../../../data/services/attachment_cache_service.dart';

/// Shows a tap-to-retry affordance on failure rather than spinning forever, since `FutureBuilder.hasData` alone stays false on error too and callers checking only `!hasData` never notice.
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
    // `late` only evaluates once at State creation, so without this a State object reused by position (e.g. a keyless ListView) would keep showing whichever image its *first* url resolved to.
    if (oldWidget.url != widget.url) {
      _future = AttachmentCacheService.getFile(widget.url);
    }
  }

  void _retry() {
    // Block body, not `=> _future = ...`, which would evaluate to the Future itself and trip Flutter's "setState callback returned a Future" assertion.
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
