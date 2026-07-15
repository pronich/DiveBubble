import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../domain/certification_level.dart';
import '../../../../domain/entities/trip.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/widgets/pick_image.dart';
import '../view_models/create_trip_view_model.dart';

class CreateTripPage extends StatefulWidget {
  const CreateTripPage({super.key, required this.viewModel, required this.onCreated});

  final CreateTripViewModel viewModel;
  final ValueChanged<Trip> onCreated;

  @override
  State<CreateTripPage> createState() => _CreateTripPageState();
}

class _CreateTripPageState extends State<CreateTripPage> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _meetingPointController = TextEditingController();
  final _depthMinController = TextEditingController();
  final _depthMaxController = TextEditingController();
  final _diveCountMinController = TextEditingController();
  final _diveCountMaxController = TextEditingController();
  final _maxParticipantsController = TextEditingController();

  DateTime? _startDate;
  TimeOfDay? _startTimeOfDay;
  DateTime? _endDate;
  String? _minCertification;
  String? _photoPath;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _meetingPointController.dispose();
    _depthMinController.dispose();
    _depthMaxController.dispose();
    _diveCountMinController.dispose();
    _diveCountMaxController.dispose();
    _maxParticipantsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create trip')),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _CoverPhotoPicker(
                photoPath: _photoPath,
                onPick: _pickPhoto,
                onRemove: () => setState(() => _photoPath = null),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _locationController,
                decoration: const InputDecoration(labelText: 'Location'),
              ),
              const SizedBox(height: 12),
              _DatePickerField(
                label: 'Date',
                value: _startDate,
                onPick: (date) => setState(() => _startDate = date),
              ),
              const SizedBox(height: 12),
              _TimePickerField(
                label: 'Meeting time',
                value: _startTimeOfDay,
                onPick: (time) => setState(() => _startTimeOfDay = time),
              ),
              const SizedBox(height: 12),
              _DatePickerField(
                label: 'End date (optional, multi-day trips)',
                value: _endDate,
                minimumDate: _startDate,
                onPick: (date) => setState(() => _endDate = date),
                onClear: () => setState(() => _endDate = null),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _meetingPointController,
                decoration: const InputDecoration(labelText: 'Meeting point (optional)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description (optional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _minCertification,
                decoration: const InputDecoration(labelText: 'Required level'),
                style: Theme.of(context).textTheme.bodyLarge,
                hint: const Text('Open to all'),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('Open to all')),
                  ...kCertificationLevels.map((level) => DropdownMenuItem<String?>(value: level, child: Text(level))),
                ],
                onChanged: (value) => setState(() => _minCertification = value),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _depthMinController,
                      decoration: const InputDecoration(labelText: 'Min depth (m)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _depthMaxController,
                      decoration: const InputDecoration(labelText: 'Max depth (m)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _diveCountMinController,
                      decoration: const InputDecoration(labelText: 'Min dives'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _diveCountMaxController,
                      decoration: const InputDecoration(labelText: 'Max dives'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _maxParticipantsController,
                decoration: const InputDecoration(labelText: 'Seats (optional)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              if (widget.viewModel.error != null) ...[
                Text('Error: ${widget.viewModel.error}', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                const SizedBox(height: 12),
              ],
              ElevatedButton(
                onPressed: widget.viewModel.isSubmitting ? null : _submit,
                child: widget.viewModel.isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Create trip'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickPhoto() async {
    final path = await pickImage(context);
    if (path != null && mounted) setState(() => _photoPath = path);
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final location = _locationController.text.trim();
    if (title.isEmpty || location.isEmpty || _startDate == null || _startTimeOfDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title, location, date and meeting time are required')),
      );
      return;
    }

    final startTime = DateTime(
      _startDate!.year,
      _startDate!.month,
      _startDate!.day,
      _startTimeOfDay!.hour,
      _startTimeOfDay!.minute,
    );

    final trip = await widget.viewModel.submit(
      title: title,
      location: location,
      startTime: startTime,
      endDate: _endDate,
      description: _textOrNull(_descriptionController),
      meetingPoint: _textOrNull(_meetingPointController),
      minCertification: _minCertification,
      depthMinM: _intOrNull(_depthMinController),
      depthMaxM: _intOrNull(_depthMaxController),
      diveCountMin: _intOrNull(_diveCountMinController),
      diveCountMax: _intOrNull(_diveCountMaxController),
      maxParticipants: _intOrNull(_maxParticipantsController),
    );

    if (trip != null) {
      // Awaited before navigating away — Trip Page's own TripViewModel.load() fetches
      // fresh data on mount, so the photo needs to already be persisted by then, not
      // still racing in the background.
      final photoPath = _photoPath;
      if (photoPath != null) {
        await widget.viewModel.uploadPhoto(trip.id, photoPath);
      }
      widget.onCreated(trip);
    }
  }

  String? _textOrNull(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  int? _intOrNull(TextEditingController controller) => int.tryParse(controller.text.trim());
}

/// Local-file preview, not a network one — the trip doesn't exist yet, so there's nothing
/// to upload to until after submit() succeeds (see _submit's photoPath handling). Same 4:3
/// aspect ratio as Trip Page's own hero image, so the preview matches what it'll look like once live.
class _CoverPhotoPicker extends StatelessWidget {
  const _CoverPhotoPicker({required this.photoPath, required this.onPick, required this.onRemove});

  final String? photoPath;
  final VoidCallback onPick;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: photoPath == null
            ? InkWell(
                onTap: onPick,
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(height: 8),
                      Text(
                        'Add cover photo (optional)',
                        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(File(photoPath!), fit: BoxFit.cover),
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onRemove,
                        child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.close, color: Colors.white, size: 18)),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    bottom: 8,
                    child: Material(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onPick,
                        child: const Padding(padding: EdgeInsets.all(6), child: Icon(Icons.camera_alt, color: Colors.white, size: 18)),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// iOS-style wheel picker in a bottom sheet — Material's `showDatePicker`/`showTimePicker`
/// dialogs read as a jarring overlay on top of the field; this matches native iOS pickers instead.
Future<DateTime?> _showWheelPicker(
  BuildContext context, {
  required CupertinoDatePickerMode mode,
  required DateTime initialDateTime,
  DateTime? minimumDate,
}) {
  var selected = initialDateTime;
  return showModalBottomSheet<DateTime>(
    context: context,
    builder: (context) {
      return SafeArea(
        child: SizedBox(
          height: 260,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                  CupertinoButton(onPressed: () => Navigator.of(context).pop(selected), child: const Text('Done')),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: mode,
                  initialDateTime: initialDateTime,
                  minimumDate: minimumDate,
                  use24hFormat: true,
                  onDateTimeChanged: (dt) => selected = dt,
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _DatePickerField extends StatelessWidget {
  const _DatePickerField({required this.label, required this.value, required this.onPick, this.onClear, this.minimumDate});

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPick;
  final VoidCallback? onClear;
  final DateTime? minimumDate;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await _showWheelPicker(
          context,
          mode: CupertinoDatePickerMode.date,
          initialDateTime: value ?? minimumDate ?? now,
          minimumDate: minimumDate ?? now,
        );
        if (picked != null) onPick(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: value != null && onClear != null
              ? IconButton(icon: const Icon(Icons.clear), onPressed: onClear)
              : const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(value != null ? formatShortDate(value!) : 'Select a date'),
      ),
    );
  }
}

class _TimePickerField extends StatelessWidget {
  const _TimePickerField({required this.label, required this.value, required this.onPick});

  final String label;
  final TimeOfDay? value;
  final ValueChanged<TimeOfDay> onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final initial = value != null ? DateTime(now.year, now.month, now.day, value!.hour, value!.minute) : now;
        final picked = await _showWheelPicker(context, mode: CupertinoDatePickerMode.time, initialDateTime: initial);
        if (picked != null) onPick(TimeOfDay.fromDateTime(picked));
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.access_time_outlined),
        ),
        child: Text(value != null ? value!.format(context) : 'Select a time'),
      ),
    );
  }
}
