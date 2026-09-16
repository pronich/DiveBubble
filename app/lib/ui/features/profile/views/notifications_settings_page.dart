import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../data/repositories/push_repository.dart';
import '../../../../data/services/push_preferences.dart';
import '../../../../l10n/app_localizations.dart';

/// Master on/off only for now — category toggles land here once there's more than one event worth distinguishing.
class NotificationsSettingsPage extends StatefulWidget {
  const NotificationsSettingsPage({super.key, required this.pushRepository});

  final PushRepository pushRepository;

  @override
  State<NotificationsSettingsPage> createState() => _NotificationsSettingsPageState();
}

class _NotificationsSettingsPageState extends State<NotificationsSettingsPage> {
  bool _loading = true;
  bool _enabled = true;
  // OS-level denial can't be reversed from inside the app, so this surfaces a disabled switch with an explanatory subtitle rather than silently failing on tap.
  bool _deniedAtOSLevel = false;
  // Unlike denied, requestPermission() can still show the OS prompt here, so the switch stays tappable instead of redirecting to system settings.
  bool _notDeterminedAtOSLevel = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final storedEnabled = await PushPreferences.isEnabled();
    final settings = await FirebaseMessaging.instance.getNotificationSettings();
    final denied = settings.authorizationStatus == AuthorizationStatus.denied;
    final notDetermined = settings.authorizationStatus == AuthorizationStatus.notDetermined;
    if (!mounted) return;
    setState(() {
      _deniedAtOSLevel = denied;
      _notDeterminedAtOSLevel = notDetermined;
      // Only genuinely "on" once the OS has actually authorized it, regardless of our stored preference.
      _enabled = storedEnabled && !denied && !notDetermined;
      _loading = false;
    });
  }

  Future<void> _onChanged(bool value) async {
    setState(() => _enabled = value);
    await PushPreferences.setEnabled(value);

    if (value) {
      final settings = await FirebaseMessaging.instance.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        if (mounted) {
          setState(() {
            _enabled = false;
            _deniedAtOSLevel = true;
            _notDeterminedAtOSLevel = false;
          });
        }
        return;
      }
      if (mounted) setState(() => _notDeterminedAtOSLevel = false);
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        try {
          await widget.pushRepository.registerToken(
            token: token,
            platform: defaultTargetPlatform == TargetPlatform.android ? 'android' : 'ios',
          );
        } catch (_) {
          // Best-effort — worst case this device just doesn't get pushes until the next retry.
        }
      }
    } else {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        try {
          await widget.pushRepository.unregisterToken(token);
        } catch (_) {
          // Best-effort — the local preference flag saved above is what actually stops main.dart from re-registering.
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.notificationsTitle)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              children: [
                SwitchListTile(
                  title: Text(l10n.pushNotificationsLabel),
                  subtitle: switch ((_deniedAtOSLevel, _notDeterminedAtOSLevel)) {
                    (true, _) => Text(l10n.pushDisabledInSystemSettings),
                    (_, true) => Text(l10n.tapToEnableNotifications),
                    _ => Text(l10n.newMessagesTripUpdatesEtc),
                  },
                  value: _enabled,
                  onChanged: _deniedAtOSLevel && !_enabled ? null : _onChanged,
                ),
              ],
            ),
    );
  }
}
