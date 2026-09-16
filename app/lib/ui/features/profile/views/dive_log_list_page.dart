import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../../../data/repositories/chat_repository.dart';
import '../../../../data/repositories/trip_repository.dart';
import '../../../../domain/entities/dive_log_entry.dart';
import '../../../../l10n/app_localizations.dart';
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
        final l10n = AppLocalizations.of(context);
        final entries = widget.viewModel.diveLog;
        return Scaffold(
          appBar: _multiSelect
              ? AppBar(
                  leading: IconButton(icon: const Icon(Icons.close), onPressed: _exitMultiSelect),
                  title: Text(l10n.selectedCountLabel(_selectedIds.length)),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: _selectedIds.isEmpty ? null : _confirmDeleteSelected,
                    ),
                  ],
                )
              : AppBar(title: Text(l10n.diveLogTabTitle)),
          body: entries.isEmpty
              ? EmptyStateView(
                  icon: Icons.scuba_diving_outlined,
                  title: l10n.noDivesLoggedYet,
                  subtitle: l10n.addDiveOrImportBody,
                  ctaLabel: l10n.addADive,
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
                      // entries is sorted newest-first (see ProfileViewModel._diveLog), so the
                      // top row is the diver's most recent — and therefore highest-numbered —
                      // dive, counting back down to 1 for the oldest at the bottom.
                      diveNumber: entries.length - index,
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
    final l10n = AppLocalizations.of(context);
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteDivesConfirmTitle(count)),
        content: Text(l10n.cantBeUndone),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete, style: TextStyle(color: Theme.of(context).colorScheme.error)),
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
            l10n.couldNotDeleteDivesError(ids.length - deleted.length, widget.viewModel.error ?? l10n.unknownError),
          ),
        ),
      );
    }
  }

  /// Backs the swipe-left gesture — confirms before deleting since a swipe is easy to
  /// trigger by accident, same as the detail page's own delete confirmation.
  Future<bool> _confirmDeleteOne(BuildContext context, DiveLogEntry entry) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteThisDiveTitle),
        content: Text(l10n.cantBeUndone),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    final ok = await widget.viewModel.deleteDiveLogEntry(entry.id);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.couldNotDeleteWithError(widget.viewModel.error ?? l10n.unknownError))),
      );
    }
    return ok;
  }

  Future<void> _openAddChoices(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final choice = await showModalBottomSheet<_AddChoice>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(l10n.addADiveManually),
              onTap: () => Navigator.of(context).pop(_AddChoice.manual),
            ),
            ListTile(
              leading: const Icon(Icons.upload_file_outlined),
              title: Text(l10n.importADiveLogFile),
              subtitle: Text(l10n.importFormatsSubtitle),
              onTap: () => Navigator.of(context).pop(_AddChoice.import),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: Text(l10n.csvColumnFormatTitle),
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
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.csvColumnFormatTitle),
        content: Text(l10n.csvColumnFormatBody),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: Text(l10n.gotIt)),
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
    final l10n = AppLocalizations.of(context);

    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.couldNotImport(widget.viewModel.error ?? l10n.unknownError))),
      );
      return;
    }

    final message = result.skipped > 0
        ? l10n.diveImportedWithSkipped(result.imported, result.skipped)
        : l10n.diveImportedSimple(result.imported);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));

    if (widget.viewModel.consumeJustLoggedFirstEntry()) {
      _showUpdateUnloggedCountPrompt(context);
    }
  }

  void _showUpdateUnloggedCountPrompt(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = widget.viewModel.profile;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.updateUnloggedCountPromptBody),
        action: profile == null
            ? null
            : SnackBarAction(
                label: l10n.editProfileAction,
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
    required this.diveNumber,
    required this.multiSelect,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
    required this.onIconTap,
    required this.onSwipeDelete,
  });

  final DiveLogEntry entry;
  final int diveNumber;
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
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Text(
                    '$diveNumber',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
