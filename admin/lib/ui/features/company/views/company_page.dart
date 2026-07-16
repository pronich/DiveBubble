import 'package:flutter/material.dart';

import '../../../../data/repositories/dive_center_repository.dart';
import '../../../../domain/dive_center_agency.dart';
import '../../../../domain/entities/dive_center.dart';
import '../../../core/widgets/pick_image.dart';
import '../view_models/company_view_model.dart';

/// Body-only (embedded in AdminShell). No "founded year" / "divers reached" stats and no
/// Danger Zone/Archive here — those were on the reference mockup but aren't real yet:
/// founded/team-size were explicitly deferred at onboarding time (see CLAUDE.md), and
/// archiving a dive center is a genuine feature (revoke access, hide trips) that deserves
/// its own round rather than a decorative button with no backend behind it.
class CompanyPage extends StatefulWidget {
  const CompanyPage({super.key, required this.diveCenter, required this.diveCenterRepository, this.onUpdated});

  final DiveCenter diveCenter;
  final DiveCenterRepository diveCenterRepository;

  // Lets AdminShell keep its own sidebar copy (account-footer company name) in sync after a
  // save — the ViewModel's own copy already reflects it, but nothing else in the shell
  // watches this page's ViewModel.
  final ValueChanged<DiveCenter>? onUpdated;

  @override
  State<CompanyPage> createState() => _CompanyPageState();
}

class _CompanyPageState extends State<CompanyPage> {
  late final _viewModel = CompanyViewModel(repository: widget.diveCenterRepository, diveCenter: widget.diveCenter);

  late final _nameController = TextEditingController(text: widget.diveCenter.name);
  late final _locationController = TextEditingController(text: widget.diveCenter.location ?? '');
  late final _descriptionController = TextEditingController(text: widget.diveCenter.description ?? '');
  late final _agencyDetailController = TextEditingController(text: widget.diveCenter.agencyDetail ?? '');
  late final _languagesController = TextEditingController(text: widget.diveCenter.languages);
  late final _websiteController = TextEditingController(text: widget.diveCenter.website ?? '');
  late final _phoneController = TextEditingController(text: widget.diveCenter.phone ?? '');
  late final _emailController = TextEditingController(text: widget.diveCenter.email ?? '');
  late String? _agency = widget.diveCenter.agency;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descriptionController.dispose();
    _agencyDetailController.dispose();
    _languagesController.dispose();
    _websiteController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  void _discard() {
    setState(() {
      final dc = _viewModel.diveCenter;
      _nameController.text = dc.name;
      _locationController.text = dc.location ?? '';
      _descriptionController.text = dc.description ?? '';
      _agencyDetailController.text = dc.agencyDetail ?? '';
      _languagesController.text = dc.languages;
      _websiteController.text = dc.website ?? '';
      _phoneController.text = dc.phone ?? '';
      _emailController.text = dc.email ?? '';
      _agency = dc.agency;
    });
  }

  Future<void> _pickAndUploadLogo() async {
    final picked = await pickImage();
    if (picked == null) return;
    final ok = await _viewModel.uploadLogo(picked.bytes, picked.filename);
    if (ok) widget.onUpdated?.call(_viewModel.diveCenter);
  }

  String? _textOrNull(TextEditingController controller) {
    final text = controller.text.trim();
    return text.isEmpty ? null : text;
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Company name is required')));
      return;
    }
    final ok = await _viewModel.save(
      name: name,
      location: _textOrNull(_locationController),
      description: _textOrNull(_descriptionController),
      agency: _agency,
      agencyDetail: _textOrNull(_agencyDetailController),
      languages: _languagesController.text.trim(),
      website: _textOrNull(_websiteController),
      phone: _textOrNull(_phoneController),
      email: _textOrNull(_emailController),
    );
    if (!mounted) return;
    if (ok) {
      widget.onUpdated?.call(_viewModel.diveCenter);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        final logoUrl = _viewModel.diveCenter.logoUrl;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SETTINGS',
                style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant, letterSpacing: 0.5),
              ),
              const SizedBox(height: 4),
              Text('Company', style: theme.textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                'Public info shown to divers browsing your trips.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              Divider(color: theme.colorScheme.outlineVariant),
              const SizedBox(height: 24),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              borderRadius: BorderRadius.circular(14),
                              image: logoUrl != null ? DecorationImage(image: NetworkImage(logoUrl), fit: BoxFit.cover) : null,
                            ),
                            child: logoUrl == null
                                ? Center(
                                    child: Text(
                                      _viewModel.diveCenter.name.trim().isEmpty ? '?' : _viewModel.diveCenter.name.trim().substring(0, 1).toUpperCase(),
                                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_viewModel.diveCenter.name, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                                if (_viewModel.diveCenter.description?.isNotEmpty ?? false)
                                  Text(
                                    _viewModel.diveCenter.description!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                  ),
                              ],
                            ),
                          ),
                          OutlinedButton(onPressed: _viewModel.isSaving ? null : _pickAndUploadLogo, child: const Text('Replace logo')),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Company name'))),
                          const SizedBox(width: 16),
                          Expanded(child: TextField(controller: _websiteController, decoration: const InputDecoration(labelText: 'Website'))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _emailController,
                              decoration: const InputDecoration(labelText: 'Email'),
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone'))),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(controller: _locationController, decoration: const InputDecoration(labelText: 'Location')),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String?>(
                              initialValue: kDiveCenterAgencies.contains(_agency) ? _agency : null,
                              decoration: const InputDecoration(labelText: 'Agency affiliation'),
                              items: [
                                const DropdownMenuItem<String?>(value: null, child: Text('None')),
                                ...kDiveCenterAgencies.map((a) => DropdownMenuItem<String?>(value: a, child: Text(a))),
                              ],
                              onChanged: (value) => setState(() => _agency = value),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: _agencyDetailController,
                              decoration: const InputDecoration(labelText: 'Affiliation detail', hintText: 'e.g. 5 Star Dive Center'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _languagesController,
                        decoration: const InputDecoration(labelText: 'Languages spoken', hintText: 'English, Danish'),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(labelText: 'Tagline / about'),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 8),
                      Divider(color: theme.colorScheme.outlineVariant),
                      const SizedBox(height: 16),
                      if (_viewModel.error != null) ...[
                        Text(_viewModel.error!, style: TextStyle(color: theme.colorScheme.error)),
                        const SizedBox(height: 12),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          OutlinedButton(onPressed: _viewModel.isSaving ? null : _discard, child: const Text('Discard')),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: _viewModel.isSaving ? null : _save,
                            child: _viewModel.isSaving
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Text('Save changes'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
