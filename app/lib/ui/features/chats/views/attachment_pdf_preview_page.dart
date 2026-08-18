import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

import '../../../../data/services/attachment_cache_service.dart';

/// Full-screen in-app PDF viewer — pushed from the bubble's file row or Chat Info's Files tab,
/// instead of handing the file off to the OS's own viewer. Reuses the same cached local file
/// used everywhere else (AttachmentCacheService), never re-downloads. pdfx shows its own
/// loading/error UI while the document Future resolves.
class AttachmentPdfPreviewPage extends StatefulWidget {
  const AttachmentPdfPreviewPage({super.key, required this.url, this.filename});

  final String url;
  final String? filename;

  @override
  State<AttachmentPdfPreviewPage> createState() => _AttachmentPdfPreviewPageState();
}

class _AttachmentPdfPreviewPageState extends State<AttachmentPdfPreviewPage> {
  late final _controller = PdfControllerPinch(
    document: AttachmentCacheService.getFile(
      widget.url,
    ).then((file) => PdfDocument.openFile(file.path)),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.filename ?? 'Document',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: PdfViewPinch(controller: _controller),
    );
  }
}
