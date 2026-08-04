import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/push_repository.dart';
import '../../../../data/services/location_service.dart';
import '../../profile/view_models/profile_view_model.dart';
import '../../profile/views/edit_profile_page.dart';
import 'location_permission_page.dart';
import 'push_permission_page.dart';

// What LoginSheet's own modal route resolves with — decided once, up front, so the
// permission-chain screens (pushed after the sheet is already gone, see `show()`) never
// need to re-check anything or fall back on a standalone/isNewUser split of their own.
typedef _SignInOutcome = ({bool isNewUser, bool needsLocation, bool needsPush});

/// Google/Apple/email sign-in choice sheet, opened from anywhere a gated action needs a
/// signed-in user.
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
    // Captured before the sheet (and its own BuildContext) closes — the permission chain
    // below pushes onto this only once the sheet is already gone. Pushing a full-screen
    // route while a showModalBottomSheet route is still on the stack made iOS's push
    // transition apply its outgoing-route parallax/scrim to the sheet itself, producing a
    // broken half-sheet/half-page slide (the "slider" glitch seen on reinstall + log back in).
    final navigator = Navigator.of(context, rootNavigator: true);
    final outcome = await showModalBottomSheet<_SignInOutcome>(
      context: context,
      isScrollControlled: true,
      builder: (_) => LoginSheet(
        authRepository: authRepository,
        profileRepository: profileRepository,
        pushRepository: pushRepository,
      ),
    );
    if (outcome == null) return false;

    if (outcome.needsLocation) {
      await navigator.push(
        MaterialPageRoute(
          builder: (_) => LocationPermissionPage(
            profileRepository: profileRepository,
            pushRepository: pushRepository,
            needsPush: outcome.needsPush,
            isNewUser: outcome.isNewUser,
          ),
        ),
      );
    } else if (outcome.needsPush) {
      await navigator.push(
        MaterialPageRoute(
          builder: (_) => PushPermissionPage(
            profileRepository: profileRepository,
            pushRepository: pushRepository,
            isNewUser: outcome.isNewUser,
          ),
        ),
      );
    } else if (outcome.isNewUser) {
      final profile = await profileRepository.getProfile();
      await navigator.push(
        MaterialPageRoute(
          builder: (_) => EditProfilePage(
            viewModel: ProfileViewModel(repository: profileRepository),
            profile: profile,
            isOnboarding: true,
          ),
        ),
      );
    }

    return true;
  }

  @override
  State<LoginSheet> createState() => _LoginSheetState();
}

enum _AuthProvider { google, apple }

class _LoginSheetState extends State<LoginSheet> {
  bool _loading = false;
  // Which provider button triggered the current _loading — Google/Apple share the one
  // _loading flag (both get disabled together), but only the button actually pressed should
  // show its own spinner instead of its static icon.
  _AuthProvider? _pendingProvider;
  String? _error;

  // Email/OTP is a small state machine inline in the same sheet rather than its own route —
  // "enter email" then "enter the code we sent", both skippable back to the two provider
  // buttons above via "Use a different sign-in method".
  bool _showEmailForm = false;
  bool _emailCodeSent = false;
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _signInWithGoogle() => _signIn(widget.authRepository.signInWithGoogle, _AuthProvider.google);

  Future<void> _signInWithApple() => _signIn(widget.authRepository.signInWithApple, _AuthProvider.apple);

  Future<void> _signIn(Future<SignInResult> Function() signIn, _AuthProvider provider) async {
    setState(() {
      _loading = true;
      _pendingProvider = provider;
      _error = null;
    });
    try {
      final result = await signIn();
      await _onSignedIn(result);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
        _pendingProvider = null;
      });
    }
  }

  Future<void> _onSignedIn(SignInResult result) async {
    // Checked for every sign-in, new account or returning — a returning diver's device can
    // still have undecided permissions (new phone, reinstall), and a brand-new account isn't
    // guaranteed to be undecided either (e.g. this device previously ran the app under a
    // different account). The sign-in button's own spinner (_loading) stays up through this
    // — it's a plain status read, no OS dialog involved, so there's nothing to show yet.
    final needsLocation = await LocationService().permissionUndecided();
    final pushSettings = await FirebaseMessaging.instance.getNotificationSettings();
    final needsPush = pushSettings.authorizationStatus == AuthorizationStatus.notDetermined;
    if (!mounted) return;
    Navigator.of(context).pop((isNewUser: result.isNewUser, needsLocation: needsLocation, needsPush: needsPush));
  }

  Future<void> _sendEmailCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Enter your email');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.authRepository.startEmailLogin(email);
      if (mounted) setState(() => _emailCodeSent = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyEmailCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Enter the code we sent you');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.authRepository.verifyEmailLogin(_emailController.text.trim(), code);
      if (mounted) await _onSignedIn(result);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        // showModalBottomSheet doesn't push its content above the keyboard on its own —
        // without viewInsets.bottom here, the email field (revealed after tapping
        // "Continue with email") stayed anchored in place and ended up hidden underneath
        // the keyboard instead of the sheet growing to make room for it.
        padding: EdgeInsets.fromLTRB(24, 20, 24, 32 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Sign in', style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            if (_showEmailForm) ..._buildEmailForm(theme) else ..._buildProviderButtons(theme),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildProviderButtons(ThemeData theme) {
    return [
      ElevatedButton.icon(
        onPressed: _loading ? null : _signInWithGoogle,
        icon: _pendingProvider == _AuthProvider.google
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.g_mobiledata, size: 26),
        label: const Text('Continue with Google'),
      ),
      // Apple's native credential requires webAuthenticationOptions (Services ID + redirect
      // URI) on Android, which we don't configure — Google Play has no equivalent-to-Apple's
      // 5.1.1(v) requirement to offer it, so it's simplest to just hide the button there.
      if (defaultTargetPlatform == TargetPlatform.iOS) ...[
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _loading ? null : _signInWithApple,
          icon: _pendingProvider == _AuthProvider.apple
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.apple, size: 20),
          label: const Text('Continue with Apple'),
        ),
      ],
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: _loading ? null : () => setState(() => _showEmailForm = true),
        icon: const Icon(Icons.email_outlined, size: 20),
        label: const Text('Continue with email'),
      ),
    ];
  }

  List<Widget> _buildEmailForm(ThemeData theme) {
    if (_emailCodeSent) {
      return [
        Text(
          'Enter the code we sent to ${_emailController.text.trim()}',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        // AutofillHints.oneTimeCode is what lets iOS/Android offer the code straight from
        // Mail (or an SMS, if this were that) as a keyboard suggestion — same native
        // mechanism as a text-message OTP field, just sourced from an email here.
        AutofillGroup(
          child: TextField(
            controller: _codeController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: theme.textTheme.headlineSmall,
            decoration: const InputDecoration(counterText: '', hintText: '000000'),
            maxLength: 6,
            onSubmitted: (_) => _verifyEmailCode(),
          ),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: _loading ? null : _verifyEmailCode,
          child: _loading
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Verify'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _loading ? null : () => setState(() => _emailCodeSent = false),
          child: const Text('Use a different email'),
        ),
      ];
    }

    return [
      TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        decoration: const InputDecoration(labelText: 'Email'),
        onSubmitted: (_) => _sendEmailCode(),
      ),
      const SizedBox(height: 12),
      ElevatedButton(
        onPressed: _loading ? null : _sendEmailCode,
        child: _loading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Text('Send code'),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: _loading ? null : () => setState(() => _showEmailForm = false),
        child: const Text('Use a different sign-in method'),
      ),
    ];
  }
}
