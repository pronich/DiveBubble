import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/repositories/trip_repository.dart';
import '../../../../domain/entities/dive_log_entry.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../view_models/profile_view_model.dart';
import 'add_edit_dive_log_entry_page.dart';
import 'dive_log_detail_page.dart';
import 'edit_profile_page.dart';

class DiveLogListPage extends StatelessWidget {
  const DiveLogListPage({
    super.key,
    required this.viewModel,
    required this.tripRepository,
    required this.chatRepository,
  });

  final ProfileViewModel viewModel;
  final TripRepository tripRepository;
  final ChatRepository chatRepository;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        final entries = viewModel.diveLog;
        return Scaffold(
          appBar: AppBar(title: const Text('Dive Log')),
          body: entries.isEmpty
              ? EmptyStateView(
                  icon: Icons.scuba_diving_outlined,
                  title: 'No dives logged yet',
                  subtitle: 'Add a dive by hand, or import your dive computer\'s UDDF export.',
                  ctaLabel: 'Add a dive',
                  onCtaPressed: () => _openAdd(context),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, indent: 16),
                  itemBuilder: (context, index) => _DiveLogRow(
                    entry: entries[index],
                    onTap: () => _openDetail(context, entries[index]),
                  ),
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _openAddChoices(context),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Future<void> _openAddChoices(BuildContext context) async {
    final choice = await showModalBottomSheet<_AddChoice>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Add a dive manually'),
              onTap: () => Navigator.of(context).pop(_AddChoice.manual),
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: const Text('Import from a UDDF file'),
              subtitle: const Text(
                'Exported from Subsurface, Suunto app, Garmin Connect, Shearwater Cloud, etc.',
              ),
              onTap: () => Navigator.of(context).pop(_AddChoice.import),
            ),
          ],
        ),
      ),
    );
    if (choice == null || !context.mounted) return;

    switch (choice) {
      case _AddChoice.manual:
        _openAdd(context);
      case _AddChoice.import:
        _pickAndImportUDDF(context);
    }
  }

  Future<void> _openAdd(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => AddEditDiveLogEntryPage(viewModel: viewModel)));
    if (context.mounted && viewModel.consumeJustLoggedFirstEntry()) {
      _showUpdateUnloggedCountPrompt(context);
    }
  }

  void _openDetail(BuildContext context, DiveLogEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DiveLogDetailPage(
          viewModel: viewModel,
          entry: entry,
          tripRepository: tripRepository,
          chatRepository: chatRepository,
        ),
      ),
    );
  }

  Future<void> _pickAndImportUDDF(BuildContext context) async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['uddf', 'xml'],
    );
    if (picked?.path == null || !context.mounted) return;

    final result = await viewModel.importDiveLog(picked!.path!);
    if (!context.mounted) return;

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not import: ${viewModel.error ?? 'unknown error'}')),
      );
      return;
    }

    final message = result.skipped > 0
        ? '${result.imported} new dive${result.imported == 1 ? '' : 's'} imported, ${result.skipped} already logged'
        : '${result.imported} dive${result.imported == 1 ? '' : 's'} imported';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

    if (viewModel.consumeJustLoggedFirstEntry()) {
      _showUpdateUnloggedCountPrompt(context);
    }
  }

  void _showUpdateUnloggedCountPrompt(BuildContext context) {
    final profile = viewModel.profile;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'If some of these were already counted in your profile, update it in Edit Profile.',
        ),
        action: profile == null
            ? null
            : SnackBarAction(
                label: 'Edit Profile',
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => EditProfilePage(viewModel: viewModel, profile: profile),
                  ),
                ),
              ),
        duration: const Duration(seconds: 6),
      ),
    );
  }
}

enum _AddChoice { manual, import }

class _DiveLogRow extends StatelessWidget {
  const _DiveLogRow({required this.entry, required this.onTap});

  final DiveLogEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitleParts = <String>[
      if (entry.siteName?.isNotEmpty ?? false) entry.siteName!,
      if (entry.durationMinutes != null) '${entry.durationMinutes} min',
      if (entry.minTemperatureC != null) '${entry.minTemperatureC!.toStringAsFixed(0)}°C',
    ];
    return ListTile(
      onTap: onTap,
      leading: Icon(entry.isImported ? Icons.download_outlined : Icons.edit_outlined),
      title: Text(formatShortDate(entry.divedAt)),
      subtitle: subtitleParts.isEmpty ? null : Text(subtitleParts.join(' · ')),
      trailing: Text(
        entry.maxDepthM != null ? '${entry.maxDepthM!.toStringAsFixed(0)}m' : '—',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}
