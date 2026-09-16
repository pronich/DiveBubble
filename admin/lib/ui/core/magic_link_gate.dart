import 'package:flutter/material.dart';

import '../../data/repositories/auth_repository.dart';

/// Sits above RootGate to consume `?token=&email=` from `Uri.base` (Flutter web has no router) before RootGate mounts, and threads the resulting `isNewUser` in via `childBuilder` so RootGate can route a freshly-invited staff member to PersonalInfoPage instead of the dashboard.
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
