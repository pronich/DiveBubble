import 'package:flutter/material.dart';

import '../../../../domain/entities/chat_link.dart';
import '../../../../domain/entities/media_item.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/widgets/cached_attachment_image.dart';
import '../../../core/widgets/open_attachment.dart';
import 'attachment_image_preview_page.dart';

/// Media/Files/Links tab bodies for Bubble Info — shared by TripPage's People/Media/Files/Links
/// tab bar (reached from either the Bubble title or avatar; see trip_conversation_page.dart).
/// Media/Files are keyed per-attachment now (MediaItem), not per-message — a message can carry
/// several attachments (see ChatMessage.attachments).

class MediaTab extends StatelessWidget {
  const MediaTab({super.key, required this.future});

  final Future<List<MediaItem>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MediaItem>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Could not load media: ${snapshot.error}'));
        }
        final items = snapshot.data ?? const [];
        if (items.isEmpty) {
          return const Center(child: Text('No photos shared yet'));
        }
        return GridView.builder(
          padding: const EdgeInsets.all(4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            // .attachment.url is always non-null here — every server-sent attachment has one,
            // only a not-yet-uploaded pending item (never true for anything from this tab) doesn't.
            final url = items[index].attachment.url!;
            return GestureDetector(
              key: ValueKey('${items[index].messageId}-$index'),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => AttachmentImagePreviewPage(url: url)),
              ),
              child: CachedAttachmentImage(url: url),
            );
          },
        );
      },
    );
  }
}

class FilesTab extends StatelessWidget {
  const FilesTab({super.key, required this.future});

  final Future<List<MediaItem>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MediaItem>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Could not load files: ${snapshot.error}'));
        }
        final items = snapshot.data ?? const [];
        if (items.isEmpty) {
          return const Center(child: Text('No files shared yet'));
        }
        return ListView.separated(
          // Explicit, even though zero — ListView auto-inserts MediaQuery.padding (status bar
          // + home indicator insets) as top/bottom padding whenever padding is left null (see
          // ScrollView.buildSlivers in the Flutter SDK). MediaTab/PeopleTab already pass their
          // own explicit padding and never hit this; this list didn't, which is what showed up
          // as a large gap above the first row.
          padding: EdgeInsets.zero,
          itemCount: items.length,
          separatorBuilder: (context, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = items[index];
            final sizeLabel = formatAttachmentFileSize(item.attachment.sizeBytes);
            return ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: Text(item.attachment.filename ?? 'Document.pdf', maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text([?sizeLabel, formatChatDateSeparator(item.createdAt.toLocal())].join(' · ')),
              onTap: () => openAttachmentInApp(context, item.attachment.url!),
            );
          },
        );
      },
    );
  }
}

class LinksTab extends StatelessWidget {
  const LinksTab({super.key, required this.future});

  final Future<List<ChatLink>> future;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ChatLink>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Could not load links: ${snapshot.error}'));
        }
        final items = snapshot.data ?? const [];
        if (items.isEmpty) {
          return const Center(child: Text('No links shared yet'));
        }
        return ListView.separated(
          // See FilesTab's own comment — same fix, same reason (ListView auto-inserts
          // MediaQuery.padding as top/bottom padding when padding is left null).
          padding: EdgeInsets.zero,
          itemCount: items.length,
          separatorBuilder: (context, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final link = items[index];
            return ListTile(
              leading: const Icon(Icons.link),
              title: Text(link.url, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(formatChatDateSeparator(link.createdAt.toLocal())),
              onTap: () => launchUrlExternally(context, link.url),
            );
          },
        );
      },
    );
  }
}
