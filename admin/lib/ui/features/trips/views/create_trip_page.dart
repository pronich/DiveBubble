import 'package:flutter/material.dart';

import '../../../../data/repositories/trip_repository.dart';
import '../../../../domain/certification_level.dart';
import '../../../../domain/entities/trip.dart';
import '../view_models/create_trip_view_model.dart';

/// Opened via `showDialog` (not pushed as a route) — the full Create/Edit form fits
/// comfortably in a popup since there aren't many fields, and the user explicitly asked
/// for the full form here rather than a stripped-down quick-create modal.
class CreateTripPage extends StatefulWidget {
  const CreateTripPage({super.key, required this.tripRepository, required this.diveCenterId, this.existingTrip});

  final TripRepository tripRepository;
  final String diveCenterId;

  // Non-null reuses this same form to edit an already-created trip instead of creating a
  // new one — prefilled from its current values (see initState below).
  final Trip? existingTrip;

  @override
  State<CreateTripPage> createState() => _CreateTripPageState();
}

class _CreateTripPageState extends State<CreateTripPage> {
  late final _viewModel = CreateTripViewModel(
    repository: widget.tripRepository,
    diveCenterId: widget.diveCenterId,
    existingTripId: widget.existingTrip?.id,
  );

  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _meetingPointController = TextEditingController();
  final _depthMinController = TextEditingController();
  final _depthMaxController = TextEditingController();
  final _diveCountMinController = TextEditingController();
  final _diveCountMaxController = TextEditingController();
  final _maxParticipantsController = TextEditingController();
  final _priceController = TextEditingController();

  DateTime? _startDate;
  TimeOfDay? _startTimeOfDay;
  DateTime? _endDate;
  String? _minCertification;

  @override
  void initState() {
    super.initState();
    final trip = widget.existingTrip;
    if (trip == null) return;
    _titleController.text = trip.title;
    _locationController.text = trip.location;
    _descriptionController.text = trip.description ?? '';
    _meetingPointController.text = trip.meetingPoint ?? '';
    _depthMinController.text = trip.depthMinM?.toString() ?? '';
    _depthMaxController.text = trip.depthMaxM?.toString() ?? '';
    _diveCountMinController.text = trip.diveCountMin?.toString() ?? '';
    _diveCountMaxController.text = trip.diveCountMax?.toString() ?? '';
    _maxParticipantsController.text = trip.maxParticipants?.toString() ?? '';
    final priceMinor = trip.priceMinor;
    _priceController.text = priceMinor == null ? '' : (priceMinor / 100).toStringAsFixed(2);
    _startDate = DateTime(trip.startTime.year, trip.startTime.month, trip.startTime.day);
    _startTimeOfDay = TimeOfDay(hour: trip.startTime.hour, minute: trip.startTime.minute);
    _endDate = trip.endDate;
    _minCertification = kCertificationLevels.contains(trip.minCertification) ? trip.minCertification : null;
  }

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
    _priceController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(context: context, initialTime: _startTimeOfDay ?? TimeOfDay.now());
    if (picked != null) setState(() => _startTimeOfDay = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate ?? DateTime.now(),
      firstDate: _startDate ?? DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked != null) setState(() => _endDate = picked);
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final location = _locationController.text.trim();
    if (title.isEmpty || location.isEmpty || _startDate == null || _startTimeOfDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title, location, date and start time are required')),
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

    final trip = await _viewModel.submit(
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
      priceMinor: _priceMinorOrNull(_priceController),
    );

    if (trip != null && mounted) Navigator.of(context).pop(true);
  }

  String? _textOrNull(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  int? _intOrNull(TextEditingController controller) => int.tryParse(controller.text.trim());

  // "125.50" -> 12550 øre. Whole-currency-unit input is what an owner actually types;
  // storage stays in minor units (see migration 000023's own comment on price_minor).
  int? _priceMinorOrNull(TextEditingController controller) {
    final text = controller.text.trim();
    if (text.isEmpty) return null;
    final value = double.tryParse(text);
    if (value == null) return null;
    return (value * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 560, maxHeight: MediaQuery.sizeOf(context).height * 0.85),
        child: ListenableBuilder(
          listenable: _viewModel,
          builder: (context, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 12, 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _viewModel.isEditing ? 'Edit trip' : 'Create a trip',
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop(false)),
                    ],
                  ),
                ),
                if (!_viewModel.isEditing)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                    child: Text(
                      'Publish a new dive to your team and members.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                    child: Column(
                      children: [
                        TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title')),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _locationController,
                          decoration: const InputDecoration(labelText: 'Location'),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _PickerField(
                                label: 'Date',
                                value: _startDate == null
                                    ? null
                                    : '${_startDate!.year}-${_startDate!.month}-${_startDate!.day}',
                                onTap: _pickStartDate,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _PickerField(
                                label: 'Start time',
                                value: _startTimeOfDay?.format(context),
                                onTap: _pickStartTime,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _PickerField(
                          label: 'End date (optional, multi-day trips)',
                          value: _endDate == null ? null : '${_endDate!.year}-${_endDate!.month}-${_endDate!.day}',
                          onTap: _pickEndDate,
                          onClear: _endDate == null ? null : () => setState(() => _endDate = null),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _priceController,
                          decoration: const InputDecoration(labelText: 'Price (optional)', prefixText: 'DKK '),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
                          decoration: const InputDecoration(labelText: 'Required level (optional)'),
                          hint: const Text('Open to all'),
                          items: [
                            const DropdownMenuItem<String?>(value: null, child: Text('Open to all')),
                            ...kCertificationLevels.map(
                              (level) => DropdownMenuItem<String?>(value: level, child: Text(level)),
                            ),
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
                        if (_viewModel.error != null) ...[
                          const SizedBox(height: 16),
                          Text('Error: ${_viewModel.error}', style: TextStyle(color: theme.colorScheme.error)),
                        ],
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: _viewModel.isSubmitting ? null : _submit,
                          child: _viewModel.isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(_viewModel.isEditing ? 'Save changes' : 'Publish'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PickerField extends StatelessWidget {
  const _PickerField({required this.label, required this.value, required this.onTap, this.onClear});

  final String label;
  final String? value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: onClear != null ? IconButton(icon: const Icon(Icons.clear), onPressed: onClear) : null,
        ),
        child: Text(value ?? 'Select'),
      ),
    );
  }
}
