import 'package:firebase_messaging/firebase_messaging.dart';

import '../../../../data/services/error_codes.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/push_repository.dart';
import '../../../../l10n/app_localizations.dart';
import '../../profile/view_models/profile_view_model.dart';
import '../../profile/views/edit_profile_page.dart';
import 'push_permission_page.dart';

// Decided once, up front, so the permission-chain screens pushed after the sheet is gone never need to re-check anything themselves.
typedef _SignInOutcome = ({bool isNewUser, bool needsPush});

/// Opened from anywhere a gated action needs a signed-in user.
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
    // Captured before the sheet closes: pushing a full-screen route while the bottom sheet route is still on the stack made iOS apply its parallax/scrim to the sheet, producing a broken half-sheet slide.
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

    if (outcome.needsPush) {
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
  // Google/Apple share the one _loading flag (both disabled together), but only the button actually pressed should show its spinner.
  _AuthProvider? _pendingProvider;
  String? _error;

  // Email/OTP is a small state machine inline in the same sheet rather than its own route: "enter email" then "enter the code we sent".
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
        _error = friendlyError(e);
        _loading = false;
        _pendingProvider = null;
      });
    }
  }

  Future<void> _onSignedIn(SignInResult result) async {
    // Checked for every sign-in, new or returning — a returning diver's device can still have push undecided (new phone, reinstall).
    final pushSettings = await FirebaseMessaging.instance.getNotificationSettings();
    final needsPush = pushSettings.authorizationStatus == AuthorizationStatus.notDetermined;
    if (!mounted) return;
    Navigator.of(context).pop((isNewUser: result.isNewUser, needsPush: needsPush));
  }

  Future<void> _sendEmailCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = AppLocalizations.of(context).enterYourEmail);
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
      if (mounted) setState(() => _error = friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyEmailCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() => _error = AppLocalizations.of(context).enterCodeSentToYou);
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
          _error = friendlyError(e);
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
        // Without viewInsets.bottom here, the email field stayed hidden underneath the keyboard instead of the sheet growing to make room for it.
        padding: EdgeInsets.fromLTRB(24, 20, 24, 32 + MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(AppLocalizations.of(context).signIn, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            if (_showEmailForm) ..._buildEmailForm(context, theme) else ..._buildProviderButtons(context, theme),
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

  List<Widget> _buildProviderButtons(BuildContext context, ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return [
      ElevatedButton.icon(
        onPressed: _loading ? null : _signInWithGoogle,
        icon: _pendingProvider == _AuthProvider.google
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.g_mobiledata, size: 26),
        label: Text(l10n.continueWithGoogle),
      ),
      // Apple's native credential requires Android webAuthenticationOptions we don't configure, and Google Play has no equivalent 5.1.1(v) requirement, so it's simplest to hide the button there.
      if (defaultTargetPlatform == TargetPlatform.iOS) ...[
        const SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _loading ? null : _signInWithApple,
          icon: _pendingProvider == _AuthProvider.apple
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.apple, size: 20),
          label: Text(l10n.continueWithApple),
        ),
      ],
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: _loading ? null : () => setState(() => _showEmailForm = true),
        icon: const Icon(Icons.email_outlined, size: 20),
        label: Text(l10n.continueWithEmail),
      ),
    ];
  }

  List<Widget> _buildEmailForm(BuildContext context, ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    if (_emailCodeSent) {
      return [
        Text(
          l10n.enterCodeSentTo(_emailController.text.trim()),
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        // AutofillHints.oneTimeCode lets iOS/Android offer the code straight from Mail as a keyboard suggestion, same as a text-message OTP field.
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
              : Text(l10n.verify),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: _loading ? null : () => setState(() => _emailCodeSent = false),
          child: Text(l10n.useADifferentEmail),
        ),
      ];
    }

    return [
      TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        decoration: InputDecoration(labelText: l10n.email),
        onSubmitted: (_) => _sendEmailCode(),
      ),
      const SizedBox(height: 12),
      ElevatedButton(
        onPressed: _loading ? null : _sendEmailCode,
        child: _loading
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : Text(l10n.sendCode),
      ),
      const SizedBox(height: 8),
      TextButton(
        onPressed: _loading ? null : () => setState(() => _showEmailForm = false),
        child: Text(l10n.useADifferentSignInMethod),
      ),
    ];
  }
}
