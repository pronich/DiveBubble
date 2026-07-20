import 'package:flutter/material.dart';

import '../../../../data/repositories/dive_center_repository.dart';
import '../../../../domain/dive_center_agency.dart';
import '../../../../domain/entities/dive_center.dart';
import '../../../core/widgets/pick_image.dart';
import '../view_models/onboarding_view_model.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.diveCenterRepository, required this.onCreated});

  final DiveCenterRepository diveCenterRepository;
  final ValueChanged<DiveCenter> onCreated;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  late final _viewModel = OnboardingViewModel(repository: widget.diveCenterRepository);

  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _agencyDetailController = TextEditingController();
  final _languagesController = TextEditingController();
  final _websiteController = TextEditingController();
  final _phoneController = TextEditingController();

  String? _agency;
  PickedImage? _logo;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _agencyDetailController.dispose();
    _languagesController.dispose();
    _websiteController.dispose();
    _phoneController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picked = await pickImage();
    if (picked != null && mounted) setState(() => _logo = picked);
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
      return;
    }

    final dc = await _viewModel.submit(
      name: name,
      location: _textOrNull(_locationController),
      description: _textOrNull(_descriptionController),
      agency: _agency,
      agencyDetail: _textOrNull(_agencyDetailController),
      languages: _textOrNull(_languagesController),
      website: _textOrNull(_websiteController),
      phone: _textOrNull(_phoneController),
      logo: _logo,
    );
    if (dc != null) widget.onCreated(dc);
  }

  String? _textOrNull(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Set up your dive center')),
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
                    'This is what divers will see about your dive center. You can change it any time.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                  Center(
                    child: InkWell(
                      onTap: _pickLogo,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                          image: _logo != null ? DecorationImage(image: MemoryImage(_logo!.bytes), fit: BoxFit.cover) : null,
                        ),
                        child: _logo == null
                            ? Icon(Icons.add_a_photo_outlined, color: theme.colorScheme.onSurfaceVariant)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: Text('Logo (optional)', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  ),
                  const SizedBox(height: 24),
                  TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Dive center name')),
                  const SizedBox(height: 12),
                  TextField(controller: _locationController, decoration: const InputDecoration(labelText: 'Location (optional)')),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(labelText: 'About (optional)'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    initialValue: _agency,
                    decoration: const InputDecoration(labelText: 'Agency affiliation (optional)'),
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('None')),
                      ...kDiveCenterAgencies.map((a) => DropdownMenuItem<String?>(value: a, child: Text(a))),
                    ],
                    onChanged: (value) => setState(() => _agency = value),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _agencyDetailController,
                    decoration: const InputDecoration(labelText: 'Affiliation detail (optional)', hintText: 'e.g. 5 Star Dive Center'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _languagesController,
                    decoration: const InputDecoration(labelText: 'Languages spoken (optional)', hintText: 'English, Danish'),
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: _websiteController, decoration: const InputDecoration(labelText: 'Website (optional)')),
                  const SizedBox(height: 12),
                  TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone (optional)')),
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
                          : const Text('Create dive center'),
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
