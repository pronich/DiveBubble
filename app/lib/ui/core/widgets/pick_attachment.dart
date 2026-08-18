import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'pick_image.dart';

/// A file picked for a chat attachment — local path plus enough metadata (type, filename, size)
/// to show a pending-attachment chip and pre-check the size before uploading.
class PickedAttachment {
  const PickedAttachment({
    required this.path,
    required this.type,
    required this.filename,
    required this.sizeBytes,
  });

  final String path;
  final String type; // 'image' | 'pdf'
  final String filename;
  final int sizeBytes;
}

enum _AttachmentChoice { photo, document }

/// Sibling to [pickImage]'s bottom sheet — offers Photo (reuses pickImage's own
/// library/camera chooser) vs PDF document. Returns null if the diver backed out at any step.
Future<PickedAttachment?> pickAttachment(BuildContext context) async {
  final choice = await showModalBottomSheet<_AttachmentChoice>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_outlined),
            title: const Text('Photo'),
            onTap: () => Navigator.of(context).pop(_AttachmentChoice.photo),
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
  if (choice == null) return null;
  if (!context.mounted) return null;

  switch (choice) {
    case _AttachmentChoice.photo:
      final path = await pickImage(context);
      if (path == null) return null;
      final file = File(path);
      return PickedAttachment(
        path: path,
        type: 'image',
        filename: path.split(Platform.pathSeparator).last,
        sizeBytes: await file.length(),
      );

    case _AttachmentChoice.document:
      final picked = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: ['pdf']);
      if (picked?.path == null) return null;
      return PickedAttachment(
        path: picked!.path!,
        type: 'pdf',
        filename: picked.name,
        sizeBytes: await picked.length(),
      );
  }
}
