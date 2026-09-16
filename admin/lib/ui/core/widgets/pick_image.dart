import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class PickedImage {
  const PickedImage({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;
}

/// Web-only — no "Library or Camera" chooser like app/'s equivalent since desktop has no camera; just the browser's file picker.
Future<PickedImage?> pickImage() async {
  final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
  if (picked == null) return null;
  final bytes = await picked.readAsBytes();
  return PickedImage(bytes: bytes, filename: picked.name);
}

Future<List<PickedImage>> pickMultipleImages() async {
  final picked = await ImagePicker().pickMultiImage(maxWidth: 1600, imageQuality: 85);
  final result = <PickedImage>[];
  for (final file in picked) {
    result.add(PickedImage(bytes: await file.readAsBytes(), filename: file.name));
  }
  return result;
}
