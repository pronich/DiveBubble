import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_web/web_only.dart' as gsi_web;

import '../../../../data/repositories/auth_repository.dart';

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
      await widget.authRepository.ensureInitialized();
      _authSub = widget.authRepository.authenticationEvents.listen(
        _onAuthEvent,
        onError: (Object e) => setState(() => _error = e.toString()),
      );
      if (mounted) setState(() => _isReady = true);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
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
                if (!_isReady || _isCompletingSignIn)
                  const CircularProgressIndicator()
                else
                  // The rendered widget IS the click target — Google's own GIS button,
                  // not a Material button calling an imperative sign-in method (unsupported
                  // on web, see AuthRepository.ensureInitialized's doc comment).
                  gsi_web.renderButton(),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: TextStyle(color: theme.colorScheme.error), textAlign: TextAlign.center),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('or', style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ),
                    Expanded(child: Divider(color: theme.colorScheme.outlineVariant)),
                  ],
                ),
                const SizedBox(height: 24),
                if (_emailLinkSent)
                  Text(
                    'Check your inbox — we sent a login link to ${_emailController.text.trim()}.',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  )
                else ...[
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    onSubmitted: (_) => _sendEmailLink(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isSendingEmailLink ? null : _sendEmailLink,
                      child: _isSendingEmailLink
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Continue with email'),
                    ),
                  ),
                  if (_emailError != null) ...[
                    const SizedBox(height: 12),
                    Text(_emailError!, style: TextStyle(color: theme.colorScheme.error), textAlign: TextAlign.center),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
