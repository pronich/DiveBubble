import 'package:flutter/material.dart';

/// Shared by LevelCard and SpecialtyCard: no photo yet -> a small bordered placeholder
/// that opens the picker on tap; photo present -> a thumbnail that opens a full-screen
/// Preview instead, with its own Edit action to replace it. White-on-color styling since
/// both host cards are solid-color (brand gradient / specialty accent) with white text.
class CardPhotoPicker extends StatelessWidget {
  const CardPhotoPicker({
    super.key,
    required this.photoUrl,
    required this.onPick,
    this.isUploading = false,
    this.size = 36,
  });

  final String? photoUrl;
  final VoidCallback onPick;
  final bool isUploading;
  final double size;

  bool get _hasPhoto => photoUrl?.isNotEmpty ?? false;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: isUploading ? null : () => _hasPhoto ? _openPreview(context) : onPick(),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: Colors.white.withValues(alpha: 0.16),
          image: _hasPhoto ? DecorationImage(image: NetworkImage(photoUrl!), fit: BoxFit.cover) : null,
          border: _hasPhoto ? null : Border.all(color: Colors.white.withValues(alpha: 0.6)),
        ),
        child: isUploading
            ? const Center(
                child: SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
              )
            : (_hasPhoto ? null : const Icon(Icons.add_a_photo_outlined, color: Colors.white, size: 16)),
      ),
    );
  }

  void _openPreview(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _PhotoPreviewPage(photoUrl: photoUrl!, onEdit: onPick),
      ),
    );
  }
}

class _PhotoPreviewPage extends StatelessWidget {
  const _PhotoPreviewPage({required this.photoUrl, required this.onEdit});

  final String photoUrl;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onEdit();
            },
            child: const Text('Edit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Center(child: InteractiveViewer(child: Image.network(photoUrl))),
    );
  }
}
