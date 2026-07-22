import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

  static const _termsUrl = 'https://divebubble.io/terms';
  static const _privacyUrl = 'https://divebubble.io/privacy';
  static const _supportEmail = 'support@divebubble.io';

  Future<void> _open(String url) => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Legal')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _open(_termsUrl),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _open(_privacyUrl),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Contact support'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _open('mailto:$_supportEmail'),
          ),
        ],
      ),
    );
  }
}
