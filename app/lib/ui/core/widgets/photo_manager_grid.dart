import 'package:flutter/material.dart';

class PhotoManagerItem {
  const PhotoManagerItem({required this.id, required this.imageProvider, this.isBusy = false});

  final String id;
  final ImageProvider imageProvider;

  /// True while this specific photo is uploading (Create Trip) or being removed (Trip
  /// Page's gallery) — shows a spinner over the tile instead of the delete button.
  final bool isBusy;
}

/// Shared "manage this trip's photos" grid — square, cropped thumbnails (BoxFit.cover) so a
/// gallery of any size stays compact, an "add" tile at the end (hidden once [maxItems] is
/// reached), and a small delete overlay per photo. Used both for Create Trip's not-yet-
/// uploaded local picks and for an existing trip's already-uploaded gallery — the caller
/// decides what "add"/"remove" actually do (stage locally vs. call the API).
class PhotoManagerGrid extends StatelessWidget {
  const PhotoManagerGrid({
    super.key,
    required this.items,
    required this.maxItems,
    required this.onAdd,
    required this.onRemove,
    this.isAdding = false,
  });

  final List<PhotoManagerItem> items;
  final int maxItems;
  final VoidCallback onAdd;
  final ValueChanged<String> onRemove;
  final bool isAdding;

  @override
  Widget build(BuildContext context) {
    final showAddTile = items.length < maxItems;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length + (showAddTile ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return _AddTile(onTap: isAdding ? null : onAdd, isLoading: isAdding);
        }
        final item = items[index];
        return _PhotoTile(item: item, onRemove: () => onRemove(item.id));
      },
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap, required this.isLoading});

  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Icon(Icons.add_a_photo_outlined, color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.item, required this.onRemove});

  final PhotoManagerItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image(image: item.imageProvider, fit: BoxFit.cover),
          if (item.isBusy)
            Container(
              color: Colors.black.withValues(alpha: 0.4),
              child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            )
          else
            Positioned(
              right: 4,
              top: 4,
              child: Material(
                color: Colors.black.withValues(alpha: 0.5),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onRemove,
                  child: const Padding(padding: EdgeInsets.all(4), child: Icon(Icons.close, color: Colors.white, size: 16)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
