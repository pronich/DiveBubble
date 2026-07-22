import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

import '../../../../domain/certification_level.dart';
import '../../../../domain/entities/trip.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/widgets/calendar_picker_sheet.dart';
import '../../../core/widgets/photo_manager_grid.dart';
import '../../../core/widgets/pick_image.dart';
import '../view_models/create_trip_view_model.dart';

// Mirrors trip.MaxPhotosPerTrip server-side — same precedent as TripPage's own copy.
const _maxTripPhotos = 10;

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
  List<String> _photoPaths = [];
  bool _isPickingPhotos = false;

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
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  'Upload up to $_maxTripPhotos photos.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
              PhotoManagerGrid(
                items: [
                  for (final path in _photoPaths) PhotoManagerItem(id: path, imageProvider: FileImage(File(path))),
                ],
                maxItems: _maxTripPhotos,
                isAdding: _isPickingPhotos,
                onAdd: _addPhotos,
                onRemove: (path) => setState(() => _photoPaths = _photoPaths.where((p) => p != path).toList()),
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

  Future<void> _addPhotos() async {
    setState(() => _isPickingPhotos = true);
    try {
      final picked = await pickMultipleImages();
      if (!mounted || picked.isEmpty) return;
      final room = _maxTripPhotos - _photoPaths.length;
      setState(() => _photoPaths = [..._photoPaths, ...picked.take(room)]);
      if (picked.length > room) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Only $_maxTripPhotos photos allowed per trip')));
      }
    } finally {
      if (mounted) setState(() => _isPickingPhotos = false);
    }
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

    // Best-effort forward-geocode — prefer the meeting point (more precise) over the
    // general location. Any failure (no results, no network) just leaves lat/lng null;
    // never blocks trip creation.
    double? latitude;
    double? longitude;
    try {
      final geocodeQuery = _textOrNull(_meetingPointController) ?? location;
      final results = await Geocoding().locationFromAddress(geocodeQuery);
      if (results.isNotEmpty) {
        latitude = results.first.latitude;
        longitude = results.first.longitude;
      }
    } catch (_) {
      // ignore — see above
    }

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
      latitude: latitude,
      longitude: longitude,
    );

    if (trip != null) {
      // Sequential, not parallel — the backend assigns each photo's position as "current
      // row count" at insert time, so concurrent uploads could race for the same position.
      // Also awaited in full before navigating away — Trip Page's own TripViewModel.load()
      // fetches fresh data on mount, so every photo needs to already be persisted by then.
      for (final path in _photoPaths) {
        await widget.viewModel.uploadPhoto(trip.id, path);
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

DateTime _roundUpToNextHour(DateTime time) {
  if (time.minute == 0 && time.second == 0) return time;
  return DateTime(time.year, time.month, time.day, time.hour + 1);
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
        final picked = await showCalendarPicker(context, initialDate: value, minimumDate: minimumDate);
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
        // No time picked yet -> start the wheel at the next clean hour, not the exact
        // current minute (matches admin/'s own create-trip default) — a diver opening this
        // at 14:37 almost certainly means "around 3pm", not literally :37.
        final initial = value != null ? DateTime(now.year, now.month, now.day, value!.hour, value!.minute) : _roundUpToNextHour(now);
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
