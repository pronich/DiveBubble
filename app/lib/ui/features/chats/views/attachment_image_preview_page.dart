import 'package:flutter/material.dart';

import '../../../core/widgets/cached_attachment_image.dart';

/// Full-screen, pinch-to-zoom view of a chat photo attachment — pushed from the bubble
/// thumbnail or the Media tab in Chat Info. Reuses the same cached local file everywhere else
/// (AttachmentCacheService), never re-downloads.
class AttachmentImagePreviewPage extends StatelessWidget {
  const AttachmentImagePreviewPage({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: CachedAttachmentImage(url: url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
