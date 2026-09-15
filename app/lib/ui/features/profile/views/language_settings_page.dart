import 'package:flutter/material.dart';

import '../../../../data/services/locale_controller.dart';
import '../../../../l10n/app_localizations.dart';

/// Native names, deliberately never translated — a diver needs to recognize their own
/// language's name even when the current UI language isn't it. Keyed by locale code, unlike
/// [null]'s "System default" (see LocaleController's own doc comment on this convention),
/// which does follow the current UI language.
const _nativeLocaleNames = <String, String>{
  'en': 'English',
  'ru': 'Русский',
  'es': 'Español',
  'de': 'Deutsch',
  'da': 'Dansk',
  'sv': 'Svenska',
};

class LanguageSettingsPage extends StatelessWidget {
  const LanguageSettingsPage({super.key, required this.localeController});

  final LocaleController localeController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).languageSettingsTitle, style: Theme.of(context).textTheme.headlineSmall),
      ),
      body: ListenableBuilder(
        listenable: localeController,
        builder: (context, _) {
          final selected = localeController.value?.languageCode;
          return ListView(
            children: [
              _LanguageTile(
                label: AppLocalizations.of(context).systemDefault,
                selected: selected == null,
                onTap: () => localeController.setLocale(null),
              ),
              for (final locale in AppLocalizations.supportedLocales)
                _LanguageTile(
                  label: _nativeLocaleNames[locale.languageCode] ?? locale.languageCode,
                  selected: selected == locale.languageCode,
                  onTap: () => localeController.setLocale(locale),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      title: Text(label),
      trailing: selected ? Icon(Icons.check, color: theme.colorScheme.primary) : null,
      onTap: onTap,
    );
  }
}
