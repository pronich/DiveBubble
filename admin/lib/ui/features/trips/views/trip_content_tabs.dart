import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/trip_repository.dart';
import '../../../../domain/entities/chat_link.dart';
import '../../../../domain/entities/media_item.dart';
import '../../../../domain/entities/my_profile.dart';
import '../../../core/formatting/date_format.dart';

/// People/Media/Files/Links tab bodies for TripDetailPage — mirrors app/'s Bubble Info tabs
/// (chat_content_tabs.dart, trip_page.dart's PeopleTab), ported rather than shared since
/// admin/ has no shared code with app/ yet (see CLAUDE.md). No tap-to-profile-card here —
/// admin has no diver-id-card viewer, this is a read-only roster for staff.
class PeopleTab extends StatefulWidget {
  const PeopleTab({super.key, required this.tripId, required this.tripRepository, required this.profileRepository, required this.diveCenterName});

  final String tripId;
  final TripRepository tripRepository;
  final ProfileRepository profileRepository;
  final String diveCenterName;

  @override
  State<PeopleTab> createState() => _PeopleTabState();
}

class _PeopleTabState extends State<PeopleTab> {
  List<String>? _userIds;
  final Map<String, MyProfile> _profiles = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final ids = await widget.tripRepository.getParticipantUserIds(widget.tripId);
      if (mounted) setState(() => _userIds = ids);
      for (final id in ids) {
        widget.profileRepository.getById(id).then((p) {
          if (mounted) setState(() => _profiles[id] = p);
        }).catchError((_) {});
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (_error != null) {
      return Center(child: Text('Error: $_error', style: TextStyle(color: theme.colorScheme.error)));
    }
    final userIds = _userIds;
    if (userIds == null) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      children: [
        _PersonRow(
          icon: Icons.storefront_outlined,
          name: widget.diveCenterName,
          isOrganizer: true,
        ),
        const Divider(height: 20),
        if (userIds.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('No divers joined yet.', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ),
        for (final userId in userIds)
          _PersonRow(
            icon: Icons.person,
            name: _profiles[userId]?.displayName ?? 'Diver',
            isOrganizer: false,
          ),
      ],
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.icon, required this.name, required this.isOrganizer});

  final IconData icon;
  final String name;
  final bool isOrganizer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: theme.colorScheme.secondaryContainer,
            child: Icon(icon, size: 18, color: theme.colorScheme.onSecondaryContainer),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name, style: theme.textTheme.bodyMedium)),
          if (isOrganizer)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, borderRadius: BorderRadius.circular(999)),
              child: Text(
                'Organizer',
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}

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
          return const Center(child: Text('No photos or videos shared yet'));
        }
        return GridView.builder(
          padding: const EdgeInsets.all(4),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 4, mainAxisSpacing: 4),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final isVideo = item.type == 'video';
            return GestureDetector(
              key: ValueKey('${item.messageId}-$index'),
              onTap: () => launchUrl(Uri.parse(item.url), mode: LaunchMode.externalApplication),
              child: isVideo
                  ? Container(
                      color: Colors.black87,
                      child: const Center(child: Icon(Icons.play_circle_outline, color: Colors.white, size: 32)),
                    )
                  : Image.network(item.url, fit: BoxFit.cover),
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
          padding: EdgeInsets.zero,
          itemCount: items.length,
          separatorBuilder: (context, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final item = items[index];
            final sizeLabel = _formatFileSize(item.sizeBytes);
            return ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: Text(item.filename ?? 'Document.pdf', maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text([?sizeLabel, formatChatDateSeparator(item.createdAt)].join(' · ')),
              onTap: () => launchUrl(Uri.parse(item.url), mode: LaunchMode.externalApplication),
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
          padding: EdgeInsets.zero,
          itemCount: items.length,
          separatorBuilder: (context, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final link = items[index];
            return ListTile(
              leading: const Icon(Icons.link),
              title: Text(link.url, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(formatChatDateSeparator(link.createdAt)),
              onTap: () => launchUrl(Uri.parse(link.url), mode: LaunchMode.externalApplication),
            );
          },
        );
      },
    );
  }
}

// "123 KB" / "4.2 MB" style label — null input (unknown size) yields null.
String? _formatFileSize(int? bytes) {
  if (bytes == null) return null;
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
