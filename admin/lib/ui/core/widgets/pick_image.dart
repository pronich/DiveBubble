import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

class PickedImage {
  const PickedImage({required this.bytes, required this.filename});

  final Uint8List bytes;
  final String filename;
}

/// Web-only build — no "Library or Camera" chooser sheet like app/'s equivalent (no camera
/// to speak of on a desktop admin panel), just the browser's own file picker. Returns bytes
/// + filename (not a path — see multipart_upload.dart) or null if the diver backed out.
Future<PickedImage?> pickImage() async {
  final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
  if (picked == null) return null;
  final bytes = await picked.readAsBytes();
  return PickedImage(bytes: bytes, filename: picked.name);
}

/// Multi-select for the photo-grid manager (Create Trip, Trip Detail gallery) — same
/// bytes-based shape as [pickImage], just several at once.
Future<List<PickedImage>> pickMultipleImages() async {
  final picked = await ImagePicker().pickMultiImage(maxWidth: 1600, imageQuality: 85);
  final result = <PickedImage>[];
  for (final file in picked) {
    result.add(PickedImage(bytes: await file.readAsBytes(), filename: file.name));
  }
  return result;
}
