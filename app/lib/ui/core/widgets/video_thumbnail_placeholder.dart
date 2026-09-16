import 'package:flutter/material.dart';

/// Avoids spinning up a video decoder per thumbnail cell just to show a frame; only the full preview page actually decodes.
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
