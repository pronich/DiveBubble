import 'package:flutter/material.dart';

import '../../../../data/repositories/auth_repository.dart';
import '../../onboarding/views/login_sheet.dart';

// Placeholder until diver profile features land — for now, just a way in to sign in.
class ProfileView extends StatefulWidget {
  const ProfileView({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  bool _signedIn = false;

  // Re-checks on app resume too — the session may have expired/been revoked while backgrounded.
  late final _lifecycleListener = AppLifecycleListener(onResume: _refresh);

  @override
  void initState() {
    super.initState();
    widget.authRepository.addListener(_refresh);
    _refresh();
  }

  @override
  void dispose() {
    widget.authRepository.removeListener(_refresh);
    _lifecycleListener.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    final userId = await widget.authRepository.currentUserId();
    if (mounted) setState(() => _signedIn = userId != null);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Profile', style: Theme.of(context).textTheme.headlineSmall)),
      body: Center(
        child: _signedIn
            ? const Text('You\'re signed in')
            : ElevatedButton(
                onPressed: () => LoginSheet.show(context, authRepository: widget.authRepository),
                child: const Text('Login'),
              ),
      ),
    );
  }
}
