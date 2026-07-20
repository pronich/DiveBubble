import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

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
  bool _isReady = false;
  bool _isCompletingSignIn = false;
  String? _error;
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authSub;

  final _emailController = TextEditingController();
  bool _showEmailForm = false;
  bool _isSendingEmailLink = false;
  bool _emailLinkSent = false;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      // Timeout, not just try/catch: Google Identity Services' own initialize() has been
      // observed to simply never resolve for some accounts/browser states (a GIS-internal
      // FedCM promise rejecting with OperationError in an unrelated microtask, unrelated to
      // *our* awaited Future) — without this, the whole login screen (including the email
      // fallback, previously gated on the same _isReady flag) got stuck behind a Google
      // problem that had nothing to do with the diver's actual sign-in method.
      await widget.authRepository.ensureInitialized().timeout(const Duration(seconds: 8));
      _authSub = widget.authRepository.authenticationEvents.listen(
        _onAuthEvent,
        onError: (Object e) => setState(() => _error = e.toString()),
      );
      if (mounted) setState(() => _isReady = true);
    } catch (e) {
      if (mounted) setState(() => _error = 'Google sign-in is temporarily unavailable — try "Dive in with email" instead.');
    }
  }

  Future<void> _onAuthEvent(GoogleSignInAuthenticationEvent event) async {
    if (event is! GoogleSignInAuthenticationEventSignIn) return;

    setState(() {
      _isCompletingSignIn = true;
      _error = null;
    });
    try {
      final result = await widget.authRepository.completeSignIn(event.user);
      await widget.onSignedIn(result.isNewUser);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isCompletingSignIn = false);
    }
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
    _authSub?.cancel();
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
      if (_error != null)
        const SizedBox.shrink()
      else if (!_isReady || _isCompletingSignIn)
        const SizedBox(height: 44, child: Center(child: CircularProgressIndicator()))
      else
        // Looks like our own FilledButton.tonal — see CustomGoogleButton's own doc
        // comment for why the *real* click target underneath still has to be Google's own
        // widget.
        const CustomGoogleButton(),
      if (_error == null) const SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        height: 44,
        child: FilledButton.tonalIcon(
          onPressed: () => setState(() => _showEmailForm = true),
          icon: const Icon(Icons.email_outlined, size: 20),
          label: const Text('Dive in with email'),
        ),
      ),
      if (_error != null) ...[
        const SizedBox(height: 12),
        Text(_error!, style: TextStyle(color: theme.colorScheme.error), textAlign: TextAlign.center),
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
