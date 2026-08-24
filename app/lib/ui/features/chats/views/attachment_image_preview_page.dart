import 'package:flutter/material.dart';
import 'package:gal/gal.dart';

import '../../../../data/services/attachment_cache_service.dart';
import '../../../core/widgets/cached_attachment_image.dart';

/// Full-screen, pinch-to-zoom view of a chat photo attachment — pushed from the bubble
/// thumbnail or the Media tab in Chat Info. Reuses the same cached local file everywhere else
/// (AttachmentCacheService), never re-downloads.
class AttachmentImagePreviewPage extends StatefulWidget {
  const AttachmentImagePreviewPage({super.key, required this.url});

  final String url;

  @override
  State<AttachmentImagePreviewPage> createState() => _AttachmentImagePreviewPageState();
}

class _AttachmentImagePreviewPageState extends State<AttachmentImagePreviewPage> {
  bool _saving = false;

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final file = await AttachmentCacheService.getFile(widget.url);
      await Gal.putImage(file.path, album: 'DiveBubble');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved to Photos')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save photo: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.download_outlined),
            tooltip: 'Save to Photos',
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: CachedAttachmentImage(url: widget.url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
