import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:video_player/video_player.dart';

import '../../../../data/services/attachment_cache_service.dart';

/// Full-screen video playback for a chat attachment — pushed from the bubble thumbnail/grid or
/// the Media tab. Deliberately minimal (no chewie/scrubber-with-thumbnails): a single
/// tap-to-play/pause overlay plus a thin linear progress indicator, matching the plan's "keep it
/// minimal for v1" call. Mirrors AttachmentImagePreviewPage's AppBar/Share-button block exactly.
class AttachmentVideoPreviewPage extends StatefulWidget {
  const AttachmentVideoPreviewPage({super.key, required this.url});

  final String url;

  @override
  State<AttachmentVideoPreviewPage> createState() => _AttachmentVideoPreviewPageState();
}

class _AttachmentVideoPreviewPageState extends State<AttachmentVideoPreviewPage> {
  final _shareButtonKey = GlobalKey();
  bool _sharing = false;
  VideoPlayerController? _controller;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final file = await AttachmentCacheService.getFile(widget.url);
      final controller = VideoPlayerController.file(file);
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      // Keeps the play/pause overlay in sync with playback ending naturally, not just with
      // taps — VideoProgressIndicator listens to the controller itself, but this widget's own
      // play-icon overlay needs its own rebuild trigger.
      controller.addListener(_onControllerUpdate);
      setState(() => _controller = controller..play());
    } catch (e) {
      if (mounted) setState(() => _loadError = e);
    }
  }

  void _onControllerUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller?.removeListener(_onControllerUpdate);
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final file = await AttachmentCacheService.getFile(widget.url);
      final box = _shareButtonKey.currentContext?.findRenderObject() as RenderBox?;
      final origin = box == null ? null : (box.localToGlobal(Offset.zero) & box.size);
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], sharePositionOrigin: origin));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not share video: $e')));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  void _togglePlayback() {
    final controller = _controller;
    if (controller == null) return;
    setState(() => controller.value.isPlaying ? controller.pause() : controller.play());
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
      body: Center(child: _body()),
    );
  }

  Widget _body() {
    if (_loadError != null) {
      return const Text('Could not load video', style: TextStyle(color: Colors.white70));
    }
    final controller = _controller;
    if (controller == null) {
      return const CircularProgressIndicator(color: Colors.white70);
    }
    return GestureDetector(
      onTap: _togglePlayback,
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(controller),
            if (!controller.value.isPlaying)
              const Icon(Icons.play_circle_fill, color: Colors.white70, size: 64),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: VideoProgressIndicator(controller, allowScrubbing: true, padding: const EdgeInsets.all(0)),
            ),
          ],
        ),
      ),
    );
  }
}
