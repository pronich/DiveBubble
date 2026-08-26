import 'package:flutter/material.dart';

import '../../../../domain/entities/dive_log_entry.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/widgets/calendar_picker_sheet.dart';
import '../view_models/profile_view_model.dart';

/// One page for add and edit, mirroring AddEditExpensePage's shape. For an imported entry
/// (widget.existing.isImported), the measured fields (date/time, depth, duration, min temp)
/// came from the diver's dive computer and are shown read-only — only site name and notes,
/// the two fields a UDDF export might genuinely be missing or wrong about, are editable.
class AddEditDiveLogEntryPage extends StatefulWidget {
  const AddEditDiveLogEntryPage({super.key, required this.viewModel, this.existing});

  final ProfileViewModel viewModel;
  final DiveLogEntry? existing;

  bool get isEdit => existing != null;
  bool get measuredFieldsLocked => existing?.isImported ?? false;

  @override
  State<AddEditDiveLogEntryPage> createState() => _AddEditDiveLogEntryPageState();
}

class _AddEditDiveLogEntryPageState extends State<AddEditDiveLogEntryPage> {
  late DateTime _date;
  late TimeOfDay _time;
  late final TextEditingController _depthController;
  late final TextEditingController _durationController;
  late final TextEditingController _tempController;
  late final TextEditingController _countryController;
  late final TextEditingController _siteController;
  late final TextEditingController _notesController;
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    final divedAt = e?.divedAt.toLocal() ?? DateTime.now();
    _date = DateTime(divedAt.year, divedAt.month, divedAt.day);
    _time = TimeOfDay.fromDateTime(divedAt);
    _depthController = TextEditingController(text: e?.maxDepthM?.toStringAsFixed(1) ?? '');
    _durationController = TextEditingController(text: e?.durationMinutes?.toString() ?? '');
    _tempController = TextEditingController(text: e?.minTemperatureC?.toStringAsFixed(1) ?? '');
    _countryController = TextEditingController(text: e?.country ?? '');
    _siteController = TextEditingController(text: e?.siteName ?? '');
    _notesController = TextEditingController(text: e?.notes ?? '');
  }

  @override
  void dispose() {
    _depthController.dispose();
    _durationController.dispose();
    _tempController.dispose();
    _countryController.dispose();
    _siteController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locked = widget.measuredFieldsLocked;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? 'Edit Dive' : 'Add Dive'),
        actions: [
          if (widget.isEdit)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: _confirmDelete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (locked)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'This dive was imported from your dive computer — only the country, dive site, and notes can be edited.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: locked ? null : _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Date'),
                    child: Text(formatShortDateWithYear(_date)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: locked ? null : _pickTime,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Time'),
                    child: Text(_time.format(context)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _depthController,
            enabled: !locked,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Max depth', suffixText: 'm'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _durationController,
            enabled: !locked,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Duration', suffixText: 'min'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _tempController,
            enabled: !locked,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            decoration: const InputDecoration(labelText: 'Min temperature', suffixText: '°C'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _countryController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Country'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _siteController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Dive site'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Notes'),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          if (_error != null) ...[
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
            const SizedBox(height: 12),
          ],
          ElevatedButton(
            onPressed: widget.viewModel.isSubmittingDiveLog ? null : _save,
            child: widget.viewModel.isSubmittingDiveLog
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.isEdit ? 'Save changes' : 'Add Dive'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showCalendarPicker(
      context,
      initialDate: _date,
      minimumDate: DateTime(_date.year - 20),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  double? _parseDouble(String text) => text.trim().isEmpty ? null : double.tryParse(text.trim());
  int? _parseInt(String text) => text.trim().isEmpty ? null : int.tryParse(text.trim());

  Future<void> _save() async {
    final divedAt = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);
    final country = _countryController.text.trim();
    final siteName = _siteController.text.trim();
    final notes = _notesController.text.trim();

    setState(() => _error = null);
    final errorMsg = widget.isEdit
        ? await widget.viewModel.updateDiveLogEntry(
            widget.existing!.id,
            divedAt: divedAt,
            maxDepthM: _parseDouble(_depthController.text),
            durationMinutes: _parseInt(_durationController.text),
            minTemperatureC: _parseDouble(_tempController.text),
            country: country,
            siteName: siteName,
            notes: notes,
          )
        : await widget.viewModel.addManualDiveLogEntry(
            divedAt: divedAt,
            maxDepthM: _parseDouble(_depthController.text),
            durationMinutes: _parseInt(_durationController.text),
            minTemperatureC: _parseDouble(_tempController.text),
            country: country,
            siteName: siteName,
            notes: notes,
          );
    if (errorMsg != null) {
      setState(() => _error = errorMsg);
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
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
    if (confirmed != true || !mounted) return;

    final ok = await widget.viewModel.deleteDiveLogEntry(widget.existing!.id);
    if (!mounted) return;
    if (!ok) {
      setState(() => _error = widget.viewModel.error);
      return;
    }
    Navigator.of(context).pop();
  }
}
