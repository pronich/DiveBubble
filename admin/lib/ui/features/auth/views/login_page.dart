import 'package:flutter/material.dart';

import '../../../../data/repositories/auth_repository.dart';

/// Google Sign-In is temporarily removed from this screen — see AuthRepository's own doc
/// comment for why. Email/passwordless is the only sign-in path for now.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, required this.authRepository, required this.onSignedIn});

  final AuthRepository authRepository;
  final Future<void> Function(bool isNewUser) onSignedIn;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  bool _isSendingEmailLink = false;
  bool _emailLinkSent = false;
  String? _emailError;

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
                    height: 44,
                    child: FilledButton.tonalIcon(
                      onPressed: _isSendingEmailLink ? null : _sendEmailLink,
                      icon: _isSendingEmailLink
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.email_outlined, size: 20),
                      label: Text(_isSendingEmailLink ? 'Sending…' : 'Dive in with email'),
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
