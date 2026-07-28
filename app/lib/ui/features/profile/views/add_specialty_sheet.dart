import 'package:flutter/material.dart';

import '../../../../domain/certification_agency.dart';
import '../../../../domain/specialty_type.dart';
import '../view_models/profile_view_model.dart';

class AddSpecialtySheet extends StatefulWidget {
  const AddSpecialtySheet({super.key, required this.viewModel});

  final ProfileViewModel viewModel;

  @override
  State<AddSpecialtySheet> createState() => _AddSpecialtySheetState();
}

class _AddSpecialtySheetState extends State<AddSpecialtySheet> {
  String _specialty = kSpecialtyTypes.first;
  final _customLabelController = TextEditingController();
  String? _agency;
  final _numberController = TextEditingController();

  bool get _isOther => _specialty == 'Other';

  @override
  void dispose() {
    _customLabelController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isOther && _customLabelController.text.trim().isEmpty) return;
    final ok = await widget.viewModel.addSpecialty(
      specialty: _specialty,
      customLabel: _isOther ? _customLabelController.text.trim() : null,
      agency: _agency,
      certNumber: _numberController.text.trim().isEmpty ? null : _numberController.text.trim(),
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
            Text('Add speciality', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: kSpecialtyTypes.map((type) {
                return ChoiceChip(
                  label: Text(type),
                  selected: _specialty == type,
                  onSelected: (_) => setState(() => _specialty = type),
                );
              }).toList(),
            ),
            if (_isOther) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _customLabelController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Speciality name'),
              ),
            ],
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
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Certification number (optional)'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.viewModel.isSubmitting ? null : _submit,
                child: const Text('Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
