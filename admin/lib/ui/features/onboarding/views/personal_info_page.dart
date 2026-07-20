import 'package:flutter/material.dart';

import '../../../../data/repositories/profile_repository.dart';
import '../../../../domain/certification_agency.dart';
import '../../../../domain/certification_level.dart';
import '../../../core/widgets/pick_image.dart';
import '../view_models/personal_info_view_model.dart';

/// First step of the new-account onboarding chain (isNewUser only — see RootGate) —
/// pushed before OnboardingPage's dive-center step. displayName/avatarUrl are usually
/// already seeded from the Google identity by the time this renders (see backend's
/// LoginOrRegister), so this is mostly a confirm-and-add-detail step rather than a blank
/// form: it prefills from GET /me and lets the new owner set up their own personal diver
/// profile (name/photo/location/bio/dive count/certification/languages) — full parity
/// with what AccountPage's Edit-profile + Level dialogs collect later, not just a name/
/// location/bio subset, so a new dive-center owner who's also a diver doesn't have to
/// revisit this same information twice right after finishing onboarding.
class PersonalInfoPage extends StatefulWidget {
  const PersonalInfoPage({super.key, required this.profileRepository, required this.onDone});

  final ProfileRepository profileRepository;
  final VoidCallback onDone;

  @override
  State<PersonalInfoPage> createState() => _PersonalInfoPageState();
}

class _PersonalInfoPageState extends State<PersonalInfoPage> {
  late final _viewModel = PersonalInfoViewModel(repository: widget.profileRepository);

  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();
  final _diveCountController = TextEditingController(text: '0');
  final _certNumberController = TextEditingController();
  final _languagesController = TextEditingController();

  String? _certLevel;
  String? _certAgency;

  PickedImage? _avatar;
  bool _prefilled = false;

  @override
  void initState() {
    super.initState();
    _viewModel.addListener(_onViewModelChanged);
    _viewModel.load();
  }

  void _onViewModelChanged() {
    if (!_prefilled && !_viewModel.isLoading && _viewModel.initial != null) {
      _prefilled = true;
      final profile = _viewModel.initial!;
      _nameController.text = profile.displayName ?? '';
      _locationController.text = profile.location ?? '';
      _bioController.text = profile.bio ?? '';
      _diveCountController.text = '${profile.diveCount}';
      _certNumberController.text = profile.certificationNumber ?? '';
      _languagesController.text = profile.languages;
      _certLevel = kCertificationLevels.contains(profile.certificationLevel) ? profile.certificationLevel : null;
      _certAgency = kCertificationAgencies.contains(profile.certificationAgency) ? profile.certificationAgency : null;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _viewModel.removeListener(_onViewModelChanged);
    _nameController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _diveCountController.dispose();
    _certNumberController.dispose();
    _languagesController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picked = await pickImage();
    if (picked != null && mounted) setState(() => _avatar = picked);
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }

    final ok = await _viewModel.submit(
      displayName: name,
      location: _textOrNull(_locationController),
      bio: _textOrNull(_bioController),
      diveCount: int.tryParse(_diveCountController.text.trim()),
      certificationLevel: _certLevel,
      certificationAgency: _certAgency,
      certificationNumber: _textOrNull(_certNumberController),
      languages: _languagesController.text.trim(),
      avatar: _avatar,
    );
    if (ok) widget.onDone();
  }

  String? _textOrNull(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  ImageProvider? _avatarImage(String? existingUrl) {
    if (_avatar != null) return MemoryImage(_avatar!.bytes);
    if (existingUrl != null && existingUrl.isNotEmpty) return NetworkImage(existingUrl);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_viewModel.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final avatarImage = _avatarImage(_viewModel.initial?.avatarUrl);

    return Scaffold(
      appBar: AppBar(title: const Text('Tell us about you')),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Text(
                    'This is your own diver profile — separate from your dive center\'s. You can change it any time.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: InkWell(
                      onTap: _pickAvatar,
                      customBorder: const CircleBorder(),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: theme.colorScheme.surfaceContainerHighest,
                        backgroundImage: avatarImage,
                        child: avatarImage == null
                            ? Icon(Icons.add_a_photo_outlined, color: theme.colorScheme.onSurfaceVariant)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text('Photo (optional)', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ),
                  const SizedBox(height: 24),
                  TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Display name')),
                  const SizedBox(height: 12),
                  TextField(controller: _locationController, decoration: const InputDecoration(labelText: 'Location (optional)')),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _bioController,
                    decoration: const InputDecoration(labelText: 'About you (optional)'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _diveCountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Dive count'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _languagesController,
                    decoration: const InputDecoration(labelText: 'Languages spoken (optional)', hintText: 'English, Danish'),
                  ),
                  const SizedBox(height: 20),
                  Text('Certification', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: _certLevel,
                    decoration: const InputDecoration(labelText: 'Level (optional)'),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('None')),
                      ...kCertificationLevels.map((l) => DropdownMenuItem<String?>(value: l, child: Text(l))),
                    ],
                    onChanged: (v) => setState(() => _certLevel = v),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: _certAgency,
                    decoration: const InputDecoration(labelText: 'Agency (optional)'),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('None')),
                      ...kCertificationAgencies.map((a) => DropdownMenuItem<String?>(value: a, child: Text(a))),
                    ],
                    onChanged: (v) => setState(() => _certAgency = v),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _certNumberController,
                    decoration: const InputDecoration(labelText: 'Certification number (optional)'),
                  ),
                  const SizedBox(height: 24),
                  if (_viewModel.error != null) ...[
                    Text(_viewModel.error!, style: TextStyle(color: theme.colorScheme.error)),
                    const SizedBox(height: 12),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _viewModel.isSubmitting ? null : _submit,
                      child: _viewModel.isSubmitting
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Continue'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
