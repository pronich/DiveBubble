import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/services/attachment_cache_service.dart';

/// Downloads (if needed) and opens a chat attachment (PDF) via the OS's default viewer — the
/// requirement only asks for "a preview," and this reuses the exact same cached local file
/// used everywhere else instead of embedding a PDF renderer. Shows a SnackBar on failure.
/// Shared by the chat bubble and Chat Info's Files tab.
Future<void> openAttachmentExternally(BuildContext context, String url) async {
  try {
    final file = await AttachmentCacheService.getFile(url);
    final opened = await launchUrl(Uri.file(file.path), mode: LaunchMode.externalApplication);
    if (!opened) throw Exception('no app available to open this file');
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open file: $e')));
  }
}

/// Opens a plain web URL (e.g. a link shared in chat text) in the browser. Shows a SnackBar on
/// failure — distinct from [openAttachmentExternally], which resolves a cached local file first.
Future<void> launchUrlExternally(BuildContext context, String url) async {
  try {
    final opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!opened) throw Exception('no app available to open this link');
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open link: $e')));
  }
}

/// "123 KB" / "4.2 MB" style label — null input (unknown size) yields null, not a placeholder
/// string, so callers can decide whether to omit the row entirely.
String? formatAttachmentFileSize(int? bytes) {
  if (bytes == null) return null;
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
