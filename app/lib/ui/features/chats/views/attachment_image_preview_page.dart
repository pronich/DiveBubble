import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../data/services/attachment_cache_service.dart';
import '../../../core/widgets/cached_attachment_image.dart';

/// Full-screen, pinch-to-zoom view of a chat photo attachment — pushed from the bubble
/// thumbnail/grid or the Media tab in Chat Info. Reuses the same cached local file everywhere
/// else (AttachmentCacheService), never re-downloads.
class AttachmentImagePreviewPage extends StatefulWidget {
  const AttachmentImagePreviewPage({
    super.key,
    required this.url,
    this.siblingUrls,
    this.initialIndex = 0,
  });

  final String url;

  /// When set to more than one URL, swipe between every photo attachment on the same message
  /// (see _AttachmentGrid in chat_view.dart) — the page opens on initialIndex. Left null (or a
  /// single item) by the Media tab and every other single-photo entry point, which fall back
  /// to the plain single-photo view this page always had.
  final List<String>? siblingUrls;
  final int initialIndex;

  @override
  State<AttachmentImagePreviewPage> createState() => _AttachmentImagePreviewPageState();
}

class _AttachmentImagePreviewPageState extends State<AttachmentImagePreviewPage> {
  final _shareButtonKey = GlobalKey();
  bool _sharing = false;
  late final PageController _pageController;
  late String _currentUrl;

  @override
  void initState() {
    super.initState();
    final urls = _urls;
    _currentUrl = urls[widget.initialIndex.clamp(0, urls.length - 1)];
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> get _urls =>
      (widget.siblingUrls != null && widget.siblingUrls!.length > 1) ? widget.siblingUrls! : [widget.url];

  // The OS share sheet, not a dedicated "save to library" action — lets the user pick Save
  // Image, AirDrop, another app, etc., same as tapping Share on any photo elsewhere on the
  // phone, rather than DiveBubble reimplementing one specific destination itself.
  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final file = await AttachmentCacheService.getFile(_currentUrl);
      // Anchors the share popover to the button on iPad/Mac — required there or it throws;
      // harmless elsewhere (see ShareParams.sharePositionOrigin's own doc comment).
      final box = _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
      final origin = box == null ? null : (box.localToGlobal(Offset.zero) & box.size);
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], sharePositionOrigin: origin));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not share photo: $e')));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final urls = _urls;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            key: _shareButtonKey,
            icon: _sharing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.ios_share),
            tooltip: 'Share',
            onPressed: _sharing ? null : _share,
          ),
        ],
      ),
      body: urls.length == 1
          ? Center(
              child: InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: CachedAttachmentImage(url: urls.first, fit: BoxFit.contain),
              ),
            )
          : PageView.builder(
              controller: _pageController,
              itemCount: urls.length,
              onPageChanged: (i) => setState(() => _currentUrl = urls[i]),
              itemBuilder: (context, i) => Center(
                child: InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: CachedAttachmentImage(url: urls[i], fit: BoxFit.contain),
                ),
              ),
            ),
    );
  }
}
