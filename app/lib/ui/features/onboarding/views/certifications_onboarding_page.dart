import 'package:flutter/material.dart';

import '../../../../domain/certification_agency.dart';
import '../../../../domain/certification_level.dart';
import '../../../../l10n/app_localizations.dart';
import '../../profile/view_models/profile_view_model.dart';

/// Replaces the old bare 3-field bottom sheet with context on why certifications matter. Skippable — Certifications stays reachable from Profile after.
class CertificationsOnboardingPage extends StatefulWidget {
  const CertificationsOnboardingPage({super.key, required this.viewModel});

  final ProfileViewModel viewModel;

  @override
  State<CertificationsOnboardingPage> createState() => _CertificationsOnboardingPageState();
}

class _CertificationsOnboardingPageState extends State<CertificationsOnboardingPage> {
  String? _level;
  String? _agency;
  bool _showLevelError = false;
  final _numberController = TextEditingController();

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_level == null) {
      setState(() => _showLevelError = true);
      return;
    }
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
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(Icons.verified_outlined, size: 56, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Text(l10n.addYourCertifications, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                l10n.certificationsOnboardingBody,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              DropdownButtonFormField<String?>(
                initialValue: _level,
                decoration: InputDecoration(
                  labelText: l10n.level,
                  errorText: _showLevelError ? l10n.pleaseSelectALevel : null,
                ),
                hint: Text(l10n.selectLevel),
                items: kCertificationLevels
                    .map((level) => DropdownMenuItem<String?>(value: level, child: Text(level)))
                    .toList(),
                onChanged: (value) => setState(() {
                  _level = value;
                  _showLevelError = false;
                }),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String?>(
                initialValue: _agency,
                decoration: InputDecoration(labelText: l10n.agencyOptional),
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
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: widget.viewModel.isSubmitting ? null : _save,
                child: Text(l10n.saveAndContinue),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: widget.viewModel.isSubmitting ? null : () => Navigator.of(context).pop(),
                child: Text(l10n.skipForNow),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
