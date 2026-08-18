import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Disk cache for chat attachments (photos and PDFs) so a participant doesn't re-download the
/// same file every time a Bubble is reopened. Keyed by URL — sufficient because attachment
/// filenames are UUID-based (see backend's upload.Service.SaveAttachment), so a URL never
/// changes in place; a re-sent file always gets a brand-new one.
class AttachmentCacheService {
  AttachmentCacheService._();

  static final CacheManager instance = CacheManager(
    Config(
      'divebubble_attachments',
      stalePeriod: const Duration(days: 30),
      maxNrOfCacheObjects: 500,
    ),
  );

  /// Downloads once, then always serves the local file on subsequent calls.
  static Future<File> getFile(String url) => instance.getSingleFile(url);

  /// Cheap local metadata lookup (no network call) — null means "not cached yet", used for the
  /// downloaded/not-downloaded badge on an attachment.
  static Future<FileInfo?> getCachedFileInfo(String url) => instance.getFileFromCache(url);

  /// Wipes every cached attachment from disk. Callers should also clear
  /// `PaintingBinding.instance.imageCache` since an already-opened preview may have populated
  /// Flutter's own in-memory image cache via `Image.file`.
  static Future<void> clearCache() => instance.emptyCache();
}
