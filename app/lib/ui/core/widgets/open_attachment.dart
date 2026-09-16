import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/services/attachment_cache_service.dart';

/// QuickLook on iOS (no "open in Safari" escape hatch), the OS's registered viewer on Android. Reuses the same cached local file used everywhere else.
Future<void> openAttachmentInApp(BuildContext context, String url) async {
  try {
    final file = await AttachmentCacheService.getFile(url);
    final result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done) throw Exception(result.message);
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open file: $e')));
  }
}

/// Distinct from [openAttachmentInApp], which stays in-app.
Future<void> launchUrlExternally(BuildContext context, String url) async {
  try {
    final opened = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!opened) throw Exception('no app available to open this link');
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open link: $e')));
  }
}

/// Null input yields null, not a placeholder string, so callers can decide whether to omit the row entirely.
String? formatAttachmentFileSize(int? bytes) {
  if (bytes == null) return null;
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
