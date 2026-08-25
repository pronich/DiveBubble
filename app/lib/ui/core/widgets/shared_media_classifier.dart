import 'dart:io';

import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import '../../../domain/entities/picked_attachment.dart';

// Mirrors pick_attachment.dart's own cap — a video longer than this can't be sent from the
// composer either way, so there's nothing useful to stage.
const _maxVideoDurationSeconds = 60;

/// Converts what the OS handed us via Share-to-DiveBubble into the same PickedAttachment
/// shape the in-app picker produces, so ChatView's composer (initialAttachments) can't tell
/// the difference. Unlike pick_attachment.dart's own picker, this has no BuildContext to
/// show a SnackBar from — items that don't fit (unsupported type, video too long) are just
/// silently dropped; ChatView's own room/size-cap enforcement covers the rest.
Future<List<PickedAttachment>> classifySharedMedia(
  List<SharedMediaFile> files,
) async {
  final result = <PickedAttachment>[];
  for (final file in files) {
    switch (file.type) {
      case SharedMediaType.image:
        result.add(await _toAttachment(file, type: 'image'));
      case SharedMediaType.video:
        final durationMs = file.duration ?? 0;
        if (durationMs > _maxVideoDurationSeconds * 1000) continue;
        result.add(
          await _toAttachment(
            file,
            type: 'video',
            durationSeconds: (durationMs / 1000).round(),
          ),
        );
      case SharedMediaType.file:
        // Only PDF maps to anything the chat composer can actually send — see
        // pick_attachment.dart's own 'document (PDF)' option.
        if (file.mimeType == 'application/pdf' ||
            file.path.toLowerCase().endsWith('.pdf')) {
          result.add(await _toAttachment(file, type: 'pdf'));
        }
      case SharedMediaType.text:
      case SharedMediaType.url:
        // Not attachable — the composer has nowhere to put plain text/a URL as a "file".
        break;
    }
  }
  return result;
}

Future<PickedAttachment> _toAttachment(
  SharedMediaFile file, {
  required String type,
  int? durationSeconds,
}) async {
  return PickedAttachment(
    path: file.path,
    type: type,
    filename: file.path.split(Platform.pathSeparator).last,
    sizeBytes: await File(file.path).length(),
    durationSeconds: durationSeconds,
  );
}
