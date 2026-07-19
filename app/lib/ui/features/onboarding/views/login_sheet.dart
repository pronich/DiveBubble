import 'package:flutter/material.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/push_repository.dart';
import 'location_permission_page.dart';

/// Google/Apple sign-in choice sheet, opened from anywhere a gated action needs a signed-in user.
class LoginSheet extends StatefulWidget {
  const LoginSheet({
    super.key,
    required this.authRepository,
    required this.profileRepository,
    required this.pushRepository,
  });

  final AuthRepository authRepository;
  final ProfileRepository profileRepository;
  final PushRepository pushRepository;

  /// Returns true if the user completed sign-in, false if they dismissed the sheet.
  static Future<bool> show(
    BuildContext context, {
    required AuthRepository authRepository,
    required ProfileRepository profileRepository,
    required PushRepository pushRepository,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => LoginSheet(
        authRepository: authRepository,
        profileRepository: profileRepository,
        pushRepository: pushRepository,
      ),
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
        // A brand-new account gets a short guided setup instead of landing on an empty
        // screen: location -> push permission (each with its own "why", one screen per
        // decision rather than surprise system prompts) -> profile basics -> certificates
        // (skippable). Each screen pushes the next and awaits it, then pops itself once its
        // child returns — the same chaining EditProfilePage already used for its own
        // certificates step, just extended two steps earlier.
        if (mounted) {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => LocationPermissionPage(
                profileRepository: widget.profileRepository,
                pushRepository: widget.pushRepository,
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
