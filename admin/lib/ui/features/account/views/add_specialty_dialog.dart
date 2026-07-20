import 'package:flutter/material.dart';

import '../../../../domain/certification_agency.dart';
import '../../../../domain/specialty_type.dart';
import '../view_models/account_view_model.dart';

class AddSpecialtyDialog extends StatefulWidget {
  const AddSpecialtyDialog({super.key, required this.viewModel});

  final AccountViewModel viewModel;

  @override
  State<AddSpecialtyDialog> createState() => _AddSpecialtyDialogState();
}

class _AddSpecialtyDialogState extends State<AddSpecialtyDialog> {
  final _customLabelController = TextEditingController();
  final _numberController = TextEditingController();
  String _specialty = kSpecialtyTypes.first;
  String? _agency;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _customLabelController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_specialty == 'Other' && _customLabelController.text.trim().isEmpty) {
      setState(() => _error = 'Enter a label for "Other"');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    final ok = await widget.viewModel.addSpecialty(
      specialty: _specialty,
      customLabel: _specialty == 'Other' ? _customLabelController.text.trim() : null,
      agency: _agency,
      certNumber: _numberController.text.trim().isEmpty ? null : _numberController.text.trim(),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isSubmitting = false;
        _error = widget.viewModel.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(child: Text('Add specialty', style: theme.textTheme.titleLarge)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop(false)),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _specialty,
                decoration: const InputDecoration(labelText: 'Type'),
                items: kSpecialtyTypes.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (v) => setState(() => _specialty = v ?? _specialty),
              ),
              if (_specialty == 'Other') ...[
                const SizedBox(height: 12),
                TextField(controller: _customLabelController, decoration: const InputDecoration(labelText: 'Label')),
              ],
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _agency,
                decoration: const InputDecoration(labelText: 'Agency (optional)'),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('None')),
                  ...kCertificationAgencies.map((a) => DropdownMenuItem<String?>(value: a, child: Text(a))),
                ],
                onChanged: (v) => setState(() => _agency = v),
              ),
              const SizedBox(height: 12),
              TextField(controller: _numberController, decoration: const InputDecoration(labelText: 'Certification number (optional)')),
              const SizedBox(height: 20),
              if (_error != null) ...[
                Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
                const SizedBox(height: 12),
              ],
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Add'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
