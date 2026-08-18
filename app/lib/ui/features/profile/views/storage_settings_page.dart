import 'package:flutter/material.dart';

import '../../../../data/services/attachment_cache_service.dart';

/// Lets a diver free up disk space by wiping the local chat-attachment cache — the files
/// themselves are still on the server, so anything opened again is simply re-downloaded.
class StorageSettingsPage extends StatefulWidget {
  const StorageSettingsPage({super.key});

  @override
  State<StorageSettingsPage> createState() => _StorageSettingsPageState();
}

class _StorageSettingsPageState extends State<StorageSettingsPage> {
  bool _isClearing = false;

  Future<void> _confirmAndClear() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear cache?'),
        content: const Text(
          'This removes downloaded photos and files from this device. Nothing is deleted from '
          'the trip chats themselves — files are simply re-downloaded next time you open them.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Clear')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isClearing = true);
    try {
      await AttachmentCacheService.clearCache();
      // Covers anything an already-open preview loaded via Image.file — disk cache alone
      // wouldn't evict that from Flutter's own in-memory image cache.
      PaintingBinding.instance.imageCache.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cache cleared.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not clear cache: $e')));
    } finally {
      if (mounted) setState(() => _isClearing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Storage')),
      body: ListTile(
        leading: _isClearing
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.delete_sweep_outlined),
        title: const Text('Clear cache'),
        subtitle: const Text('Removes downloaded chat photos and files from this device'),
        onTap: _isClearing ? null : _confirmAndClear,
      ),
    );
  }
}
