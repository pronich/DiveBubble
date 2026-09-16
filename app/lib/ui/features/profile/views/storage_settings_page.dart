import 'package:flutter/material.dart';

import '../../../../data/services/attachment_cache_service.dart';
import '../../../../data/services/error_codes.dart';
import '../../../../l10n/app_localizations.dart';

/// Wipes only the local chat-attachment cache — files stay on the server, so anything opened again is simply re-downloaded.
class StorageSettingsPage extends StatefulWidget {
  const StorageSettingsPage({super.key});

  @override
  State<StorageSettingsPage> createState() => _StorageSettingsPageState();
}

class _StorageSettingsPageState extends State<StorageSettingsPage> {
  bool _isClearing = false;

  Future<void> _confirmAndClear() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.clearCacheTitle),
        content: Text(l10n.clearCacheBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.clear)),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isClearing = true);
    try {
      await AttachmentCacheService.clearCache();
      // Covers anything an already-open preview loaded via Image.file, which the disk-cache clear alone wouldn't evict from Flutter's in-memory image cache.
      PaintingBinding.instance.imageCache.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.cacheCleared)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.couldNotClearCache(friendlyError(e)))));
    } finally {
      if (mounted) setState(() => _isClearing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.storageTitle)),
      body: ListTile(
        leading: _isClearing
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.delete_sweep_outlined),
        title: Text(l10n.clearCacheRow),
        subtitle: Text(l10n.clearCacheSubtitle),
        onTap: _isClearing ? null : _confirmAndClear,
      ),
    );
  }
}
