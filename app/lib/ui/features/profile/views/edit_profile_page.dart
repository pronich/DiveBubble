import 'package:flutter/material.dart';

import '../../../../data/services/location_service.dart';
import '../../../../domain/entities/profile.dart';
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

  /// True only for the brand-new-account flow pushed from LoginSheet (after Location and
  /// Push permission) — chains straight into CertificationsOnboardingPage after saving, so
  /// a new diver sets their certification level as part of the same onboarding pass
  /// instead of having to find Certifications later.
  final bool isOnboarding;

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late final _nameController = TextEditingController(text: widget.profile.displayName);
  late final _locationController = TextEditingController(text: widget.profile.location);
  late final _bioController = TextEditingController(text: widget.profile.bio);
  late final _diveCountController = TextEditingController(text: widget.profile.diveCount.toString());
  late List<String> _languages = widget.profile.languages.isEmpty
      ? []
      : widget.profile.languages.split(',').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

  final _locationService = LocationService();
  bool _locating = false;
  bool _showNameError = false;

  @override
  void initState() {
    super.initState();
    // Best-effort auto-fill on first open, for anyone who never set a location — never
    // overwrites a value the diver already typed. Skipped when isOnboarding: the new-account
    // flow already ran this exact request (with its own explanation) a screen earlier via
    // LocationPermissionPage; re-running it here would silently re-prompt even after the
    // diver explicitly tapped "Not now" there, undoing the point of asking first.
    if (_locationController.text.isEmpty && !widget.isOnboarding) {
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

    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile')),
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
                  labelText: 'Display name',
                  helperText: 'Shown to other divers instead of your real name',
                  errorText: _showNameError ? 'Please enter a display name' : null,
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
                  labelText: 'Location',
                  suffixIcon: _locating
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                        )
                      : IconButton(
                          icon: const Icon(Icons.my_location, size: 20),
                          tooltip: 'Use current location',
                          onPressed: _detectLocation,
                        ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bioController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Bio'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _diveCountController,
                decoration: const InputDecoration(labelText: 'Dives'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: _pickLanguages,
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: 'Languages'),
                  child: Text(
                    _languages.isEmpty ? 'Select languages' : _languages.join(', '),
                    style: _languages.isEmpty
                        ? theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)
                        : theme.textTheme.bodyMedium,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (widget.viewModel.error != null) ...[
                Text('Error: ${widget.viewModel.error}', style: TextStyle(color: theme.colorScheme.error)),
                const SizedBox(height: 12),
              ],
              ElevatedButton(
                onPressed: widget.viewModel.isSubmitting ? null : _save,
                child: widget.viewModel.isSubmitting
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(widget.isOnboarding ? 'Continue' : 'Save'),
              ),
            ],
          );
        },
      ),
    );
  }
}
