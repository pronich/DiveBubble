import 'package:flutter/material.dart';

import '../../../core/widgets/pick_image.dart';
import '../view_models/account_view_model.dart';

class EditAccountDialog extends StatefulWidget {
  const EditAccountDialog({super.key, required this.viewModel});

  final AccountViewModel viewModel;

  @override
  State<EditAccountDialog> createState() => _EditAccountDialogState();
}

class _EditAccountDialogState extends State<EditAccountDialog> {
  late final _nameController = TextEditingController(text: widget.viewModel.profile?.displayName ?? '');
  late final _locationController = TextEditingController(text: widget.viewModel.profile?.location ?? '');
  late final _bioController = TextEditingController(text: widget.viewModel.profile?.bio ?? '');
  late final _diveCountController = TextEditingController(text: '${widget.viewModel.profile?.diveCount ?? 0}');
  late final _languagesController = TextEditingController(text: widget.viewModel.profile?.languages ?? '');

  PickedImage? _avatar;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _diveCountController.dispose();
    _languagesController.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final picked = await pickImage();
    if (picked != null && mounted) setState(() => _avatar = picked);
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Name is required');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    final ok = await widget.viewModel.updateProfile(
      displayName: name,
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
      bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
      diveCount: int.tryParse(_diveCountController.text.trim()),
      languages: _languagesController.text.trim(),
      avatar: _avatar,
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

  ImageProvider? _avatarImage() {
    if (_avatar != null) return MemoryImage(_avatar!.bytes);
    final url = widget.viewModel.profile?.avatarUrl;
    if (url != null && url.isNotEmpty) return NetworkImage(url);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final avatarImage = _avatarImage();

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(child: Text('Edit profile', style: theme.textTheme.titleLarge)),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop(false)),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: InkWell(
                    onTap: _pickAvatar,
                    customBorder: const CircleBorder(),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      backgroundImage: avatarImage,
                      child: avatarImage == null ? Icon(Icons.person, color: theme.colorScheme.onSurfaceVariant, size: 40) : null,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
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
                  decoration: const InputDecoration(labelText: 'Languages spoken', hintText: 'English, Danish'),
                ),
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
      ),
    );
  }
}
