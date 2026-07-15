import 'package:flutter/material.dart';

import '../../../../domain/certification_agency.dart';
import '../../../../domain/certification_level.dart';
import '../view_models/profile_view_model.dart';

class UpdateLevelSheet extends StatefulWidget {
  const UpdateLevelSheet({
    super.key,
    required this.viewModel,
    this.initialLevel,
    this.initialAgency,
    this.initialNumber,
  });

  final ProfileViewModel viewModel;
  final String? initialLevel;
  final String? initialAgency;
  final String? initialNumber;

  @override
  State<UpdateLevelSheet> createState() => _UpdateLevelSheetState();
}

class _UpdateLevelSheetState extends State<UpdateLevelSheet> {
  late String? _level =
      kCertificationLevels.contains(widget.initialLevel) ? widget.initialLevel : null;
  late String? _agency =
      kCertificationAgencies.contains(widget.initialAgency) ? widget.initialAgency : null;
  late final _numberController = TextEditingController(text: widget.initialNumber);

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_level == null) return;
    final ok = await widget.viewModel.updateLevel(
      certificationLevel: _level!,
      certificationAgency: _agency,
      certificationNumber: _numberController.text.trim().isEmpty ? null : _numberController.text.trim(),
    );
    if (ok && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Update level', style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: _level,
              decoration: const InputDecoration(labelText: 'Level'),
              style: theme.textTheme.bodyLarge,
              hint: const Text('Select level'),
              items: kCertificationLevels
                  .map((level) => DropdownMenuItem<String?>(value: level, child: Text(level)))
                  .toList(),
              onChanged: (value) => setState(() => _level = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _agency,
              decoration: const InputDecoration(labelText: 'Agency (optional)'),
              style: theme.textTheme.bodyLarge,
              hint: const Text('Not set'),
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('Not set')),
                ...kCertificationAgencies.map((a) => DropdownMenuItem<String?>(value: a, child: Text(a))),
              ],
              onChanged: (value) => setState(() => _agency = value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _numberController,
              decoration: const InputDecoration(labelText: 'Certification number (optional)'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (widget.viewModel.isSubmitting || _level == null) ? null : _submit,
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
