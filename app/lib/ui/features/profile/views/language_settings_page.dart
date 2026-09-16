import 'package:flutter/material.dart';

import '../../../../data/services/locale_controller.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/formatting/locale_display.dart';

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
                label: AppLocalizations.of(context).systemDefaultWithLanguage(nativeNameFor(resolvedSystemLocale())),
                selected: selected == null,
                onTap: () => localeController.setLocale(null),
              ),
              for (final locale in AppLocalizations.supportedLocales)
                _LanguageTile(
                  label: nativeNameFor(locale),
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
