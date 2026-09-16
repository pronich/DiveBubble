import 'package:flutter/material.dart';

import '../../../../data/services/locale_controller.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/formatting/locale_display.dart';

/// Picking a row applies immediately, same as the Profile > Language settings page; Continue just moves on, it doesn't itself persist anything.
class LanguageOnboardingPage extends StatelessWidget {
  const LanguageOnboardingPage({super.key, required this.localeController, required this.onDone});

  final LocaleController localeController;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              Icon(Icons.language, size: 56, color: theme.colorScheme.primary),
              const SizedBox(height: 24),
              Text(l10n.chooseYourLanguageTitle, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              Text(
                l10n.chooseYourLanguageBody,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListenableBuilder(
                  listenable: localeController,
                  builder: (context, _) {
                    final selected = localeController.value?.languageCode;
                    return ListView(
                      children: [
                        _LanguageTile(
                          label: l10n.systemDefaultWithLanguage(nativeNameFor(resolvedSystemLocale())),
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
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: ElevatedButton(onPressed: onDone, child: Text(l10n.continueLabel)),
              ),
            ],
          ),
        ),
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
