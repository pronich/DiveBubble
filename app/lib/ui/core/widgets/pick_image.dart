import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Shared by every image-upload affordance (avatar, trip photo, certification/specialty
/// photos) — a small "Library or Camera" chooser, then a resized pick. Returns the local
/// file path to hand to whichever repository upload method, or null if the diver backed out.
Future<String?> pickImage(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (context) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Choose from library'),
            onTap: () => Navigator.of(context).pop(ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt_outlined),
            title: const Text('Take a photo'),
            onTap: () => Navigator.of(context).pop(ImageSource.camera),
          ),
        ],
      ),
    ),
  );
  if (source == null) return null;

  final picked = await ImagePicker().pickImage(source: source, maxWidth: 1600, imageQuality: 85);
  return picked?.path;
}
