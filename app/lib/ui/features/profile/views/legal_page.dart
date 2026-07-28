import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class LegalPage extends StatelessWidget {
  const LegalPage({super.key});

  static const _termsUrl = 'https://divebubble.io/terms';
  static const _privacyUrl = 'https://divebubble.io/privacy';
  static const _supportEmail = 'support@divebubble.io';

  Future<void> _open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  // Android already shows its own app chooser for an implicit mailto intent when more than
  // one mail app is installed, so only iOS (which always jumps straight to Mail.app with no
  // chooser) needs this picker.
  Future<void> _contactSupport(BuildContext context) async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      await _open('mailto:$_supportEmail');
      return;
    }
    final hasGmail = await canLaunchUrl(
      Uri.parse('googlegmail://co?to=$_supportEmail'),
    );
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text('Mail'),
              onTap: () {
                Navigator.pop(sheetContext);
                _open('mailto:$_supportEmail');
              },
            ),
            if (hasGmail)
              ListTile(
                leading: const Icon(Icons.email_outlined),
                title: const Text('Gmail'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _open('googlegmail://co?to=$_supportEmail');
                },
              ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Copy email address'),
              onTap: () async {
                Navigator.pop(sheetContext);
                await Clipboard.setData(
                  const ClipboardData(text: _supportEmail),
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Email address copied')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

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
            onTap: () => _contactSupport(context),
          ),
        ],
      ),
    );
  }
}
