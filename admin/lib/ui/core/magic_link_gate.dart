import 'package:flutter/material.dart';

import '../../data/repositories/auth_repository.dart';

/// Sits above RootGate at the app's root. A magic-link email points back at this app's own
/// root URL with ?token=&email= query params (see AuthApiService.startEmailLogin) — Flutter
/// web has no router configured (MaterialApp.home is a fixed widget), so `Uri.base` is the
/// only way to see those params on a fresh page load. If they're present, this consumes them
/// against the backend *before* RootGate ever mounts, so RootGate's own currentUserId check
/// already finds a valid session by the time it runs. `childBuilder` (not a plain `child`)
/// so the freshly-learned `isNewUser` can be threaded into RootGate's construction — a magic
/// link is exactly how an invited staff member's very first sign-in happens, and RootGate
/// needs to know that to route them through PersonalInfoPage instead of straight to the
/// dashboard (see RootGate's own doc comment).
class MagicLinkGate extends StatefulWidget {
  const MagicLinkGate({super.key, required this.authRepository, required this.childBuilder});

  final AuthRepository authRepository;
  final Widget Function(bool isNewUser) childBuilder;

  @override
  State<MagicLinkGate> createState() => _MagicLinkGateState();
}

class _MagicLinkGateState extends State<MagicLinkGate> {
  bool _isProcessing = true;
  bool _isNewUser = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _consumeIfPresent();
  }

  Future<void> _consumeIfPresent() async {
    final params = Uri.base.queryParameters;
    final token = params['token'];
    final email = params['email'];
    if (token == null || email == null) {
      setState(() => _isProcessing = false);
      return;
    }
    try {
      final result = await widget.authRepository.completeEmailLogin(email, token);
      _isNewUser = result.isNewUser;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isProcessing) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_error != null) {
      final theme = Theme.of(context);
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_error!, style: TextStyle(color: theme.colorScheme.error), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(onPressed: () => setState(() => _error = null), child: const Text('Continue')),
              ],
            ),
          ),
        ),
      );
    }
    return widget.childBuilder(_isNewUser);
  }
}
