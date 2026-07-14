import 'package:flutter/material.dart';

/// Google/Apple sign-in choice sheet, opened from the intro screen's "Dive in" button.
/// Both providers are UI-only stubs until the real OAuth backend lands.
class LoginSheet extends StatelessWidget {
  const LoginSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const LoginSheet(),
    );
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
              onPressed: () => _showComingSoon(context),
              icon: const Icon(Icons.g_mobiledata, size: 26),
              label: const Text('Continue with Google'),
            ),
            const SizedBox(height: 12),
            // Visible now, disabled until the app is registered in App Store Connect for Apple Sign-In.
            ElevatedButton.icon(
              onPressed: null,
              icon: const Icon(Icons.apple, size: 20),
              label: const Text('Continue with Apple (coming soon)'),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Coming soon')),
    );
  }
}
