import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

class PickedChatAttachment {
  const PickedChatAttachment({required this.bytes, required this.filename, required this.type});

  final Uint8List bytes;
  final String filename;
  final String type; // 'image' | 'pdf'
}

/// Web-only, bytes-based like pick_image.dart — no camera or video, since admin/'s attach flow only needs sharing photos and documents on desktop.
Future<List<PickedChatAttachment>> pickChatPhotos() async {
  final picked = await ImagePicker().pickMultiImage(maxWidth: 1600, imageQuality: 85);
  final result = <PickedChatAttachment>[];
  for (final file in picked) {
    result.add(PickedChatAttachment(bytes: await file.readAsBytes(), filename: file.name, type: 'image'));
  }
  return result;
}

Future<List<PickedChatAttachment>> pickChatDocuments() async {
  final files = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
  final result = <PickedChatAttachment>[];
  for (final file in files) {
    result.add(PickedChatAttachment(bytes: await file.readAsBytes(), filename: file.name, type: 'pdf'));
  }
  return result;
}
