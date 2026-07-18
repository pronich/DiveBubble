import 'package:flutter/material.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../profile/view_models/profile_view_model.dart';
import '../../profile/views/edit_profile_page.dart';

/// Google/Apple sign-in choice sheet, opened from anywhere a gated action needs a signed-in user.
class LoginSheet extends StatefulWidget {
  const LoginSheet({super.key, required this.authRepository, required this.profileRepository});

  final AuthRepository authRepository;
  final ProfileRepository profileRepository;

  /// Returns true if the user completed sign-in, false if they dismissed the sheet.
  static Future<bool> show(
    BuildContext context, {
    required AuthRepository authRepository,
    required ProfileRepository profileRepository,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => LoginSheet(authRepository: authRepository, profileRepository: profileRepository),
    );
    return result ?? false;
  }

  @override
  State<LoginSheet> createState() => _LoginSheetState();
}

class _LoginSheetState extends State<LoginSheet> {
  bool _loading = false;
  String? _error;

  Future<void> _signInWithGoogle() => _signIn(widget.authRepository.signInWithGoogle);

  Future<void> _signInWithApple() => _signIn(widget.authRepository.signInWithApple);

  Future<void> _signIn(Future<SignInResult> Function() signIn) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await signIn();
      if (!mounted) return;

      if (result.isNewUser) {
        // Quick onboarding: a brand-new account has nothing filled in yet, so go
        // straight to Edit Profile instead of leaving them on an empty screen.
        final profile = await widget.profileRepository.getProfile();
        if (mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => EditProfilePage(
                viewModel: ProfileViewModel(repository: widget.profileRepository),
                profile: profile,
                isOnboarding: true,
              ),
            ),
          );
        }
      }

      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Sign in', style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loading ? null : _signInWithGoogle,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.g_mobiledata, size: 26),
              label: const Text('Continue with Google'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _loading ? null : _signInWithApple,
              icon: const Icon(Icons.apple, size: 20),
              label: const Text('Continue with Apple'),
            ),
          ],
        ),
      ),
    );
  }
}
