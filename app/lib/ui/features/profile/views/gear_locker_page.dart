import 'package:flutter/material.dart';

import '../../../../domain/gear_item.dart';
import '../../../../ui/core/theme/app_colors.dart';
import '../view_models/profile_view_model.dart';

class GearLockerPage extends StatelessWidget {
  const GearLockerPage({super.key, required this.viewModel});

  final ProfileViewModel viewModel;

  static final Set<String> _essentialKeys = kEssentialGearItems.map((i) => i.key).toSet();

  GearStatus _nextStatus(GearStatus current) {
    switch (current) {
      case GearStatus.missing:
        return GearStatus.owned;
      case GearStatus.owned:
        return GearStatus.rents;
      case GearStatus.rents:
        return GearStatus.missing;
    }
  }

  void _openAddItemSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddGearItemSheet(viewModel: viewModel),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gear locker')),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          final statusByKey = {for (final g in viewModel.gear) g.itemKey: g.status};
          final additionalItems = viewModel.gear.where((g) => !_essentialKeys.contains(g.itemKey)).toList();

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SectionLabel('ESSENTIAL'),
              _GearGroup(
                children: [
                  for (var i = 0; i < kEssentialGearItems.length; i++) ...[
                    _GearRow(
                      label: kEssentialGearItems[i].label,
                      status: GearStatus.fromValue(
                        statusByKey[kEssentialGearItems[i].key] ?? GearStatus.missing.value,
                      ),
                      onTap: () => viewModel.setGearStatus(
                        itemKey: kEssentialGearItems[i].key,
                        status: _nextStatus(
                          GearStatus.fromValue(statusByKey[kEssentialGearItems[i].key] ?? GearStatus.missing.value),
                        ).value,
                      ),
                    ),
                    if (i < kEssentialGearItems.length - 1) const Divider(height: 1),
                  ],
                ],
              ),
              const SizedBox(height: 24),
              _SectionLabel('ADDITIONAL'),
              if (additionalItems.isNotEmpty)
                _GearGroup(
                  children: [
                    for (var i = 0; i < additionalItems.length; i++) ...[
                      _GearRow(
                        label: additionalItems[i].itemKey,
                        status: GearStatus.fromValue(additionalItems[i].status),
                        onTap: () => viewModel.setGearStatus(
                          itemKey: additionalItems[i].itemKey,
                          status: _nextStatus(GearStatus.fromValue(additionalItems[i].status)).value,
                        ),
                        onRemove: () => viewModel.removeGear(additionalItems[i].itemKey),
                      ),
                      if (i < additionalItems.length - 1) const Divider(height: 1),
                    ],
                  ],
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _openAddItemSheet(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add item'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant, letterSpacing: 0.5),
      ),
    );
  }
}

class _GearGroup extends StatelessWidget {
  const _GearGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    // Material (not Container+BoxDecoration) so the ListTiles inside have a proper ink
    // surface to paint splashes on — a plain colored DecoratedBox hides them and Flutter
    // throws a runtime assertion for it.
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _GearRow extends StatelessWidget {
  const _GearRow({required this.label, required this.status, required this.onTap, this.onRemove});

  final String label;
  final GearStatus status;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusPill(status: status),
          if (onRemove != null) ...[
            const SizedBox(width: 4),
            InkWell(
              onTap: onRemove,
              borderRadius: BorderRadius.circular(12),
              child: Icon(Icons.close, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ],
      ),
      onTap: onTap,
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final GearStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, icon, fg, bg) = switch (status) {
      GearStatus.owned => ('Owned', Icons.check_circle_outline, AppColors.onSuccessContainer, AppColors.successContainer),
      GearStatus.missing => ('Missing', Icons.remove_circle_outline, AppColors.onErrorContainer, AppColors.errorContainer),
      GearStatus.rents => ('Usually rent', Icons.radio_button_unchecked, AppColors.onWarningContainer, AppColors.warningContainer),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: fg, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _AddGearItemSheet extends StatefulWidget {
  const _AddGearItemSheet({required this.viewModel});

  final ProfileViewModel viewModel;

  @override
  State<_AddGearItemSheet> createState() => _AddGearItemSheetState();
}

class _AddGearItemSheetState extends State<_AddGearItemSheet> {
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final label = _controller.text.trim();
    if (label.isEmpty) return;
    setState(() => _submitting = true);
    final ok = await widget.viewModel.setGearStatus(itemKey: label, status: GearStatus.owned.value);
    if (ok && mounted) Navigator.of(context).pop();
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add item', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'For anything beyond the essentials — torch, action camera, buoy...',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Item name'),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: const Text('Add'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
