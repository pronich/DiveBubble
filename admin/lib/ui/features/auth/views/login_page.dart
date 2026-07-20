import 'package:flutter/material.dart';

import '../../../../data/repositories/auth_repository.dart';
import 'custom_google_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.authRepository, required this.onSignedIn});

  final AuthRepository authRepository;
  final Future<void> Function(bool isNewUser) onSignedIn;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _isGoogleReady = false;
  bool _isCompletingGoogleSignIn = false;
  String? _googleError;

  final _emailController = TextEditingController();
  bool _showEmailForm = false;
  bool _isSendingEmailLink = false;
  bool _emailLinkSent = false;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    widget.authRepository.listenForGoogleSignIn(onSignedIn: _onGoogleSignIn, onError: _onGoogleError);
    _initGoogle();
  }

  Future<void> _initGoogle() async {
    try {
      // Timeout, not just try/catch: Google Identity Services' own script load has been
      // observed to simply never resolve for some accounts/browser states — without this,
      // the Google button slot would spin forever. The email fallback below is never
      // gated on this at all, so a slow/broken Google init can't block it either way.
      await widget.authRepository.ensureGoogleReady().timeout(const Duration(seconds: 8));
      if (mounted) setState(() => _isGoogleReady = true);
    } catch (e) {
      if (mounted) setState(() => _googleError = 'Google sign-in is temporarily unavailable — try "Dive in with email" instead.');
    }
  }

  void _onGoogleSignIn(SignInResult result) {
    if (!mounted) return;
    setState(() => _isCompletingGoogleSignIn = false);
    widget.onSignedIn(result.isNewUser);
  }

  void _onGoogleError(Object error) {
    if (!mounted) return;
    setState(() {
      _isCompletingGoogleSignIn = false;
      _googleError = error.toString().replaceFirst('Exception: ', '');
    });
  }

  Future<void> _sendEmailLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _emailError = 'Enter your email');
      return;
    }

    setState(() {
      _isSendingEmailLink = true;
      _emailError = null;
    });
    try {
      await widget.authRepository.startEmailLogin(email);
      if (mounted) setState(() => _emailLinkSent = true);
    } catch (e) {
      if (mounted) setState(() => _emailError = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isSendingEmailLink = false);
    }
  }

  @override
  void dispose() {
    widget.authRepository.stopListeningForGoogleSignIn();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('DiveBubble Business', style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(
                  'Manage your dive center\'s trips and team.',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                if (_showEmailForm) ..._buildEmailForm(theme) else ..._buildProviderButtons(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildProviderButtons(ThemeData theme) {
    return [
      // This slot's own state (loading/ready/failed) is independent of the email button
      // below, which is *always* interactive immediately — a slow or broken Google init
      // must never block the one sign-in method that never touches Google at all.
      if (_googleError != null)
        const SizedBox.shrink()
      else if (!_isGoogleReady || _isCompletingGoogleSignIn)
        const SizedBox(height: 44, child: Center(child: CircularProgressIndicator()))
      else
        CustomGoogleButton(googleIdentity: widget.authRepository.googleIdentity),
      if (_googleError == null) const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        height: 44,
        child: FilledButton.tonalIcon(
          onPressed: () => setState(() => _showEmailForm = true),
          icon: const Icon(Icons.email_outlined, size: 20),
          label: const Text('Dive in with email'),
        ),
      ),
      if (_googleError != null) ...[
        const SizedBox(height: 12),
        Text(_googleError!, style: TextStyle(color: theme.colorScheme.error), textAlign: TextAlign.center),
      ],
    ];
  }

  List<Widget> _buildEmailForm(ThemeData theme) {
    if (_emailLinkSent) {
      return [
        Text(
          'Check your inbox — we sent a login link to ${_emailController.text.trim()}.',
          style: theme.textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ];
    }

    return [
      TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        decoration: const InputDecoration(labelText: 'Email'),
        onSubmitted: (_) => _sendEmailLink(),
      ),
      const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isSendingEmailLink ? null : _sendEmailLink,
          child: _isSendingEmailLink
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Send login link'),
        ),
      ),
      if (_emailError != null) ...[
        const SizedBox(height: 12),
        Text(_emailError!, style: TextStyle(color: theme.colorScheme.error), textAlign: TextAlign.center),
      ],
      const SizedBox(height: 8),
      TextButton(
        onPressed: _isSendingEmailLink ? null : () => setState(() => _showEmailForm = false),
        child: const Text('Use a different sign-in method'),
      ),
    ];
  }
}
