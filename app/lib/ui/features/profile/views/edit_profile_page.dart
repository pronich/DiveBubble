import 'package:flutter/material.dart';

import '../../../../data/services/location_service.dart';
import '../../../../domain/entities/profile.dart';
import '../../../../l10n/app_localizations.dart';
import '../../onboarding/views/certifications_onboarding_page.dart';
import '../view_models/profile_view_model.dart';
import 'language_picker_page.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({
    super.key,
    required this.viewModel,
    required this.profile,
    this.isOnboarding = false,
  });

  final ProfileViewModel viewModel;
  final Profile profile;

  /// True only for the brand-new-account flow — chains straight into CertificationsOnboardingPage after saving instead of leaving a new diver to find it later.
  final bool isOnboarding;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final _nameController = TextEditingController(text: widget.profile.displayName);
  late final _locationController = TextEditingController(text: widget.profile.location);
  late final _bioController = TextEditingController(text: widget.profile.bio);
  late final _diveCountController = TextEditingController(text: widget.profile.diveCount.toString());
  // No separate stored field: derived from the count being 0 *and* the diver having logged something, so the toggle doesn't reset on reopen, but a brand-new diver with 0 dives and no log isn't shown as pre-disabled.
  late bool _allDivesLogged = widget.profile.diveCount == 0 && widget.viewModel.diveLog.isNotEmpty;
  late List<String> _languages = widget.profile.languages.isEmpty
      ? []
      : widget.profile.languages.split(',').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

  final _locationService = LocationService();
  bool _locating = false;
  bool _showNameError = false;

  @override
  void initState() {
    super.initState();
    // Best-effort auto-fill on first open, never overwriting a value the diver already typed — this is the only place location is ever requested now (LocationPermissionPage is unwired).
    if (_locationController.text.isEmpty) {
      _detectLocation();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _diveCountController.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    setState(() => _locating = true);
    final result = await _locationService.currentCityCountry();
    if (mounted && result != null) {
      setState(() => _locationController.text = result);
    }
    if (mounted) setState(() => _locating = false);
  }

  Future<void> _onToggleAllDivesLogged(bool value) async {
    if (value && int.tryParse(_diveCountController.text.trim()) != 0) {
      final l10n = AppLocalizations.of(context);
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.zeroOutUnloggedDivesTitle),
          content: Text(l10n.zeroOutUnloggedDivesBody),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)),
            TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.zeroOut)),
          ],
        ),
      );
      if (confirmed != true) return;
      _diveCountController.text = '0';
    }
    setState(() => _allDivesLogged = value);
  }

  Future<void> _pickLanguages() async {
    final result = await Navigator.of(context).push<List<String>>(
      MaterialPageRoute(builder: (_) => LanguagePickerPage(initialSelection: _languages)),
    );
    if (result != null) setState(() => _languages = result);
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      setState(() => _showNameError = true);
      return;
    }
    final success = await widget.viewModel.submit(
      displayName: _nameController.text.trim(),
      location: _locationController.text.trim(),
      bio: _bioController.text.trim(),
      diveCount: int.tryParse(_diveCountController.text.trim()) ?? 0,
      languages: _languages.join(', '),
    );
    if (!success || !mounted) return;

    if (widget.isOnboarding) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => CertificationsOnboardingPage(viewModel: widget.viewModel)),
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.editProfileTitle)),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _nameController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.displayNameLabel,
                  helperText: l10n.displayNameHelper,
                  errorText: _showNameError ? l10n.pleaseEnterDisplayName : null,
                ),
                onChanged: (value) {
                  if (_showNameError && value.trim().isNotEmpty) setState(() => _showNameError = false);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _locationController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  labelText: l10n.locationLabel,
                  suffixIcon: _locating
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : IconButton(
                          icon: const Icon(Icons.my_location, size: 20),
                          tooltip: l10n.useCurrentLocationTooltip,
                          onPressed: _detectLocation,
                        ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bioController,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: l10n.bioLabel),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _diveCountController,
                enabled: !_allDivesLogged,
                decoration: InputDecoration(
                  labelText: l10n.unloggedDivesLabel,
                  helperText: l10n.unloggedDivesHelper,
                ),
                keyboardType: TextInputType.number,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.allDivesAreLogged),
                value: _allDivesLogged,
                onChanged: _onToggleAllDivesLogged,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickLanguages,
                child: InputDecorator(
                  decoration: InputDecoration(labelText: l10n.languagesLabel),
                  child: Text(
                    _languages.isEmpty ? l10n.selectLanguages : _languages.join(', '),
                    style: _languages.isEmpty
                        ? theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)
                        : theme.textTheme.bodyMedium,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (widget.viewModel.error != null) ...[
                Text(l10n.errorWithMessage(widget.viewModel.error!), style: TextStyle(color: theme.colorScheme.error)),
                const SizedBox(height: 12),
              ],
              ElevatedButton(
                onPressed: widget.viewModel.isSubmitting ? null : _save,
                child: widget.viewModel.isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(widget.isOnboarding ? l10n.continueLabel : l10n.save),
              ),
            ],
          );
        },
      ),
    );
  }
}
