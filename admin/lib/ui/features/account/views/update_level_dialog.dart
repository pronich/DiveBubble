import 'package:flutter/material.dart';

import '../../../../domain/certification_agency.dart';
import '../../../../domain/certification_level.dart';
import '../view_models/account_view_model.dart';

class UpdateLevelDialog extends StatefulWidget {
  const UpdateLevelDialog({super.key, required this.viewModel});

  final AccountViewModel viewModel;

  @override
  State<UpdateLevelDialog> createState() => _UpdateLevelDialogState();
}

class _UpdateLevelDialogState extends State<UpdateLevelDialog> {
  final _numberController = TextEditingController();
  String? _level;
  String? _agency;
  bool _isSubmitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = widget.viewModel.profile;
    _level = kCertificationLevels.contains(profile?.certificationLevel) ? profile!.certificationLevel : null;
    _agency = kCertificationAgencies.contains(profile?.certificationAgency) ? profile!.certificationAgency : null;
    _numberController.text = profile?.certificationNumber ?? '';
  }

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_level == null) {
      setState(() => _error = 'Select a level');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    final ok = await widget.viewModel.updateLevel(
      level: _level!,
      agency: _agency,
      number: _numberController.text.trim().isEmpty ? null : _numberController.text.trim(),
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
                  Expanded(child: Text('Certification level', style: theme.textTheme.titleLarge)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop(false)),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _level,
                decoration: const InputDecoration(labelText: 'Level'),
                items: kCertificationLevels.map((l) => DropdownMenuItem<String?>(value: l, child: Text(l))).toList(),
                onChanged: (v) => setState(() => _level = v),
              ),
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
                    : const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
