import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../domain/entities/trip.dart';
import '../../../core/formatting/date_format.dart';
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
  final _minCertificationController = TextEditingController();
  final _depthMinController = TextEditingController();
  final _depthMaxController = TextEditingController();
  final _diveCountMinController = TextEditingController();
  final _diveCountMaxController = TextEditingController();
  final _maxParticipantsController = TextEditingController();

  DateTime? _startDate;
  TimeOfDay? _startTimeOfDay;
  DateTime? _endDate;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _meetingPointController.dispose();
    _minCertificationController.dispose();
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
              TextField(
                controller: _minCertificationController,
                decoration: const InputDecoration(labelText: 'Required level (optional)'),
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
      minCertification: _textOrNull(_minCertificationController),
      depthMinM: _intOrNull(_depthMinController),
      depthMaxM: _intOrNull(_depthMaxController),
      diveCountMin: _intOrNull(_diveCountMinController),
      diveCountMax: _intOrNull(_diveCountMaxController),
      maxParticipants: _intOrNull(_maxParticipantsController),
    );

    if (trip != null) {
      widget.onCreated(trip);
    }
  }

  String? _textOrNull(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  int? _intOrNull(TextEditingController controller) => int.tryParse(controller.text.trim());
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
