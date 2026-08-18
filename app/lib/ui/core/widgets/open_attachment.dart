import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a plain web URL (e.g. a link shared in chat text) in the browser. Shows a SnackBar on
/// failure. PDF attachments open in-app instead (see AttachmentPdfPreviewPage) — this is only
/// for links.
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
