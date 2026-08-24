import 'package:flutter/material.dart';

/// Stands in for a video thumbnail everywhere one would normally show a decoded frame — chat
/// grid cells, the composer's pending strip, a solo-video bubble, the Media tab — since
/// generating a real frame per cell would mean spinning up a video decoder for every thumbnail
/// on screen. A dark tile plus a centered play glyph is enough to read as "video" next to photo
/// cells; the optional duration label makes it unambiguous. Full playback
/// (attachment_video_preview_page.dart) is the only place that actually decodes the file.
class VideoThumbnailPlaceholder extends StatelessWidget {
  const VideoThumbnailPlaceholder({super.key, required this.width, required this.height, this.durationSeconds});

  final double width;
  final double height;
  final int? durationSeconds;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.black87,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.play_circle_fill, color: Colors.white70, size: 28),
          if (durationSeconds != null)
            Positioned(
              right: 4,
              bottom: 4,
              child: Text(
                formatVideoDuration(durationSeconds!),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}

String formatVideoDuration(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}
