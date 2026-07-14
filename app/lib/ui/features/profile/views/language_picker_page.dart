import 'package:flutter/material.dart';

import '../../../../domain/languages.dart';

/// Search + multi-select list of languages, replacing free-text entry (which we couldn't
/// reliably parse or compare later — "Russian" vs "russian" vs "Rus.").
class LanguagePickerPage extends StatefulWidget {
  const LanguagePickerPage({super.key, required this.initialSelection});

  final List<String> initialSelection;

  @override
  State<LanguagePickerPage> createState() => _LanguagePickerPageState();
}

class _LanguagePickerPageState extends State<LanguagePickerPage> {
  late final Set<String> _selected = widget.initialSelection.toSet();
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = kLanguages.where((l) => l.toLowerCase().contains(_query.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Languages'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(_selected.toList()),
            child: const Text('Done'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search languages',
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final language = filtered[index];
                return CheckboxListTile(
                  title: Text(language),
                  value: _selected.contains(language),
                  onChanged: (checked) {
                    setState(() {
                      if (checked ?? false) {
                        _selected.add(language);
                      } else {
                        _selected.remove(language);
                      }
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
