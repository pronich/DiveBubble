import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_compress/video_compress.dart';

import '../../../domain/entities/picked_attachment.dart';

enum _AttachmentChoice { media, camera, document }

const _maxVideoDurationSeconds = 60;

const _videoExtensions = {'.mp4', '.mov', '.m4v', '.avi', '.3gp'};

/// Sibling to `pickImage`'s bottom sheet, but multi-capable: Photos & video (multi-select from
/// the library, mixed media in one pick, up to however many the caller still has room for — see
/// ChatView's cap) vs a single camera shot vs a single PDF document. Always returns a list —
/// empty if the diver backed out at any step, one item for camera/document, however many for a
/// library multi-select (fewer than picked if a video was rejected for being too long).
Future<List<PickedAttachment>> pickAttachment(BuildContext context) async {
  final choice = await showModalBottomSheet<_AttachmentChoice>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Photos & video'),
            onTap: () => Navigator.of(context).pop(_AttachmentChoice.media),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Take a photo'),
            onTap: () => Navigator.of(context).pop(_AttachmentChoice.camera),
          ),
          ListTile(
            leading: const Icon(Icons.picture_as_pdf_outlined),
            title: const Text('Document (PDF)'),
            onTap: () => Navigator.of(context).pop(_AttachmentChoice.document),
          ),
        ],
      ),
    ),
  );
  if (choice == null || !context.mounted) return const [];

  switch (choice) {
    case _AttachmentChoice.media:
      final picked = await ImagePicker().pickMultipleMedia(imageQuality: 85);
      final result = <PickedAttachment>[];
      for (final file in picked) {
        if (!context.mounted) break;
        if (_videoExtensions.contains(_extensionOf(file.path))) {
          final video = await _toVideoPickedAttachment(context, file.path);
          if (video != null) result.add(video);
        } else {
          result.add(await _toImagePickedAttachment(file.path));
        }
      }
      return result;

    case _AttachmentChoice.camera:
      final shot = await ImagePicker().pickImage(source: ImageSource.camera, maxWidth: 1600, imageQuality: 85);
      if (shot == null) return const [];
      return [await _toImagePickedAttachment(shot.path)];

    case _AttachmentChoice.document:
      final picked = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['pdf']);
      if (picked?.path == null) return const [];
      return [
        PickedAttachment(
          path: picked!.path!,
          type: 'pdf',
          filename: picked.name,
          sizeBytes: await picked.length(),
        ),
      ];
  }
}

String _extensionOf(String path) {
  final dot = path.lastIndexOf('.');
  return dot == -1 ? '' : path.substring(dot).toLowerCase();
}

Future<PickedAttachment> _toImagePickedAttachment(String path) async {
  final file = File(path);
  return PickedAttachment(
    path: path,
    type: 'image',
    filename: path.split(Platform.pathSeparator).last,
    sizeBytes: await file.length(),
  );
}

// Only a quick duration check here — a real read, not a guess, since getMediaInfo is fast
// (no encoding involved). Compression is deliberately deferred to Send time (see
// ChatViewModel._compressedVideoPathOrFallback) rather than run right here: doing it at pick
// time made the composer look frozen/unresponsive for however many seconds a clip took to
// compress, with no visible feedback that anything was happening at all.
Future<PickedAttachment?> _toVideoPickedAttachment(BuildContext context, String path) async {
  final messenger = ScaffoldMessenger.of(context);
  try {
    final info = await VideoCompress.getMediaInfo(path);
    final durationMs = info.duration ?? 0;
    if (durationMs > _maxVideoDurationSeconds * 1000) {
      messenger.showSnackBar(
        SnackBar(content: Text('Videos must be $_maxVideoDurationSeconds seconds or shorter')),
      );
      return null;
    }

    final file = File(path);
    return PickedAttachment(
      path: path,
      type: 'video',
      filename: path.split(Platform.pathSeparator).last,
      sizeBytes: await file.length(),
      durationSeconds: (durationMs / 1000).round(),
    );
  } catch (e) {
    messenger.showSnackBar(SnackBar(content: Text('Could not process video: $e')));
    return null;
  }
}
