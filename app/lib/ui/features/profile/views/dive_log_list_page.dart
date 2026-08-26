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

class DiveLogListPage extends StatefulWidget {
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
  State<DiveLogListPage> createState() => _DiveLogListPageState();
}

class _DiveLogListPageState extends State<DiveLogListPage> {
  bool _multiSelect = false;
  final Set<String> _selectedIds = {};

  void _enterMultiSelect(String id) {
    setState(() {
      _multiSelect = true;
      _selectedIds.add(id);
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (!_selectedIds.remove(id)) _selectedIds.add(id);
      if (_selectedIds.isEmpty) _multiSelect = false;
    });
  }

  void _exitMultiSelect() {
    setState(() {
      _multiSelect = false;
      _selectedIds.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final entries = widget.viewModel.diveLog;
        return Scaffold(
          appBar: _multiSelect
              ? AppBar(
                  leading: IconButton(icon: const Icon(Icons.close), onPressed: _exitMultiSelect),
                  title: Text('${_selectedIds.length} selected'),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: _selectedIds.isEmpty ? null : _confirmDeleteSelected,
                    ),
                  ],
                )
              : AppBar(title: const Text('Dive Log')),
          body: entries.isEmpty
              ? EmptyStateView(
                  icon: Icons.scuba_diving_outlined,
                  title: 'No dives logged yet',
                  subtitle: 'Add a dive by hand, or import a dive log file.',
                  ctaLabel: 'Add a dive',
                  onCtaPressed: () => _openAdd(context),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: entries.length,
                  separatorBuilder: (_, _) => const Divider(height: 1, indent: 16),
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    return _DiveLogRow(
                      key: ValueKey(entry.id),
                      entry: entry,
                      multiSelect: _multiSelect,
                      selected: _selectedIds.contains(entry.id),
                      onTap: () {
                        if (_multiSelect) {
                          _toggleSelection(entry.id);
                        } else {
                          _openDetail(context, entry);
                        }
                      },
                      onLongPress: _multiSelect ? null : () => _enterMultiSelect(entry.id),
                      onIconTap: _multiSelect ? null : () => _enterMultiSelect(entry.id),
                      onSwipeDelete: _multiSelect ? null : () => _confirmDeleteOne(context, entry),
                    );
                  },
                ),
          floatingActionButton: _multiSelect
              ? null
              : FloatingActionButton(
                  onPressed: () => _openAddChoices(context),
                  child: const Icon(Icons.add),
                ),
        );
      },
    );
  }

  Future<void> _confirmDeleteSelected() async {
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete $count dive${count == 1 ? '' : 's'}?'),
        content: const Text("This can't be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ids = _selectedIds.toList();
    final deleted = await widget.viewModel.deleteDiveLogEntries(ids);
    if (!mounted) return;
    _exitMultiSelect();
    if (deleted.length < ids.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not delete ${ids.length - deleted.length} dive(s): ${widget.viewModel.error}',
          ),
        ),
      );
    }
  }

  /// Backs the swipe-left gesture — confirms before deleting since a swipe is easy to
  /// trigger by accident, same as the detail page's own delete confirmation.
  Future<bool> _confirmDeleteOne(BuildContext context, DiveLogEntry entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this dive?'),
        content: const Text("This can't be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete', style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    final ok = await widget.viewModel.deleteDiveLogEntry(entry.id);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not delete: ${widget.viewModel.error}')));
    }
    return ok;
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
              title: const Text('Import a dive log file'),
              subtitle: const Text('UDDF, CSV, or a Diving Log 6 export'),
              onTap: () => Navigator.of(context).pop(_AddChoice.import),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('CSV column format'),
              onTap: () {
                Navigator.of(context).pop();
                _showCSVFormatInfo(context);
              },
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
        _pickAndImportFile(context);
    }
  }

  void _showCSVFormatInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('CSV column format'),
        content: const Text(
          'First row must be a header with these column names (any order, only "date" is '
          'required):\n\n'
          'date (YYYY-MM-DD)\n'
          'time (HH:MM)\n'
          'country\n'
          'site\n'
          'max_depth_m\n'
          'avg_depth_m\n'
          'duration_min\n'
          'min_temp_c\n'
          'notes',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Got it')),
        ],
      ),
    );
  }

  Future<void> _openAdd(BuildContext context) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => AddEditDiveLogEntryPage(viewModel: widget.viewModel)));
    if (context.mounted && widget.viewModel.consumeJustLoggedFirstEntry()) {
      _showUpdateUnloggedCountPrompt(context);
    }
  }

  void _openDetail(BuildContext context, DiveLogEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DiveLogDetailPage(
          viewModel: widget.viewModel,
          entry: entry,
          tripRepository: widget.tripRepository,
          chatRepository: widget.chatRepository,
        ),
      ),
    );
  }

  Future<void> _pickAndImportFile(BuildContext context) async {
    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['uddf', 'xml', 'csv', 'sql', 'db', 'sqlite'],
    );
    if (picked?.path == null || !context.mounted) return;

    final result = await widget.viewModel.importDiveLog(picked!.path!);
    if (!context.mounted) return;

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not import: ${widget.viewModel.error ?? 'unknown error'}')),
      );
      return;
    }

    final message = result.skipped > 0
        ? '${result.imported} new dive${result.imported == 1 ? '' : 's'} imported, ${result.skipped} already logged'
        : '${result.imported} dive${result.imported == 1 ? '' : 's'} imported';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

    if (widget.viewModel.consumeJustLoggedFirstEntry()) {
      _showUpdateUnloggedCountPrompt(context);
    }
  }

  void _showUpdateUnloggedCountPrompt(BuildContext context) {
    final profile = widget.viewModel.profile;
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
                    builder: (_) => EditProfilePage(viewModel: widget.viewModel, profile: profile),
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
  const _DiveLogRow({
    super.key,
    required this.entry,
    required this.multiSelect,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    required this.onIconTap,
    required this.onSwipeDelete,
  });

  final DiveLogEntry entry;
  final bool multiSelect;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onIconTap;
  // Null while in multi-select mode — swipe-to-delete is disabled there, bulk delete via
  // the AppBar action is the equivalent action.
  final Future<bool> Function()? onSwipeDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitleParts = <String>[
      if (entry.locationText != null) entry.locationText!,
      if (entry.durationMinutes != null) '${entry.durationMinutes} min',
      if (entry.minTemperatureC != null) '${entry.minTemperatureC!.toStringAsFixed(0)}°C',
    ];

    final row = Container(
      color: selected ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3) : null,
      child: ListTile(
        onTap: onTap,
        onLongPress: onLongPress,
        leading: multiSelect
            ? Checkbox(value: selected, onChanged: (_) => onTap())
            : InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: onIconTap,
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.scuba_diving_outlined),
                ),
              ),
        title: Text(formatShortDateWithYear(entry.divedAt)),
        subtitle: subtitleParts.isEmpty ? null : Text(subtitleParts.join(' · ')),
        trailing: Text(
          entry.maxDepthM != null ? '${entry.maxDepthM!.toStringAsFixed(0)}m' : '—',
          style: theme.textTheme.titleMedium,
        ),
      ),
    );

    if (onSwipeDelete == null) return row;
    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => onSwipeDelete!(),
      background: Container(
        color: theme.colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Icon(Icons.delete_outline, color: theme.colorScheme.onErrorContainer),
      ),
      child: row,
    );
  }
}
