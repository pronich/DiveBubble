import 'package:flutter/material.dart';

import '../../../../domain/certification_agency.dart';
import '../../../../domain/certification_level.dart';
import '../../../../l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);

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
            Text(l10n.updateLevelTitle, style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            DropdownButtonFormField<String?>(
              initialValue: _level,
              decoration: InputDecoration(labelText: l10n.level),
              style: theme.textTheme.bodyLarge,
              hint: Text(l10n.selectLevel),
              items: kCertificationLevels
                  .map((level) => DropdownMenuItem<String?>(value: level, child: Text(level)))
                  .toList(),
              onChanged: (value) => setState(() => _level = value),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: _agency,
              decoration: InputDecoration(labelText: l10n.agencyOptional),
              style: theme.textTheme.bodyLarge,
              hint: Text(l10n.notSet),
              items: [
                DropdownMenuItem<String?>(value: null, child: Text(l10n.notSet)),
                ...kCertificationAgencies.map((a) => DropdownMenuItem<String?>(value: a, child: Text(a))),
              ],
              onChanged: (value) => setState(() => _agency = value),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _numberController,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(labelText: l10n.certificationNumberOptional),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (widget.viewModel.isSubmitting || _level == null) ? null : _submit,
                child: Text(l10n.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
