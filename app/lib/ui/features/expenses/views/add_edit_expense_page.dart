import 'package:flutter/material.dart';

import '../../../../domain/entities/expense.dart';
import '../../../../domain/entities/profile.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/widgets/calendar_picker_sheet.dart';
import '../utils/expense_format.dart';
import '../view_models/expense_view_model.dart';

/// One page for both create and edit — widget.existing is null for create. Any participant
/// may edit (per product decision); only the expense's own creator sees the delete action.
class AddEditExpensePage extends StatefulWidget {
  const AddEditExpensePage({super.key, required this.viewModel, this.existing});

  final ExpenseViewModel viewModel;
  final Expense? existing;

  bool get isEdit => existing != null;

  @override
  State<AddEditExpensePage> createState() => _AddEditExpensePageState();
}

class _AddEditExpensePageState extends State<AddEditExpensePage> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late String _payerUserId;
  late String _splitType;
  late DateTime _occurredAt;
  final Set<String> _selected = {};
  final Map<String, int> _shareCounts = {};
  final Map<String, TextEditingController> _exactControllers = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleController = TextEditingController(text: e?.title ?? '');
    _amountController = TextEditingController(
      text: e != null ? (e.amountMinor / 100).toStringAsFixed(2) : '',
    );
    _payerUserId = e?.payerUserId ?? widget.viewModel.currentUserId;
    _splitType = e?.splitType ?? 'equal';
    _occurredAt = e?.occurredAt ?? DateTime.now();

    for (final p in widget.viewModel.participants) {
      _exactControllers[p.id] = TextEditingController();
    }
    if (e != null) {
      for (final s in e.shares) {
        _selected.add(s.userId);
        _shareCounts[s.userId] = s.shares ?? 1;
        _exactControllers.putIfAbsent(s.userId, () => TextEditingController());
        _exactControllers[s.userId]!.text = (s.amountMinor / 100).toStringAsFixed(2);
      }
    } else {
      for (final p in widget.viewModel.participants) {
        _selected.add(p.id);
        _shareCounts[p.id] = 1;
      }
    }

    _amountController.addListener(_onFieldChanged);
    for (final c in _exactControllers.values) {
      c.addListener(_onFieldChanged);
    }
  }

  void _onFieldChanged() => setState(() {});

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    for (final c in _exactControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final amountMinor = parseExpenseAmountMinor(_amountController.text);
    final canDelete = widget.isEdit && widget.existing!.createdBy == widget.viewModel.currentUserId;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEdit ? l10n.editExpenseTitle : l10n.addExpenseTitle),
        actions: [
          if (canDelete)
            IconButton(icon: const Icon(Icons.delete_outline), onPressed: _confirmDelete),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            decoration: InputDecoration(labelText: l10n.titleFieldLabel),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(labelText: l10n.amountLabel, prefixText: '¤ '),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: InputDecoration(labelText: l10n.dateLabel),
              child: Text(formatShortDate(_occurredAt)),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _payerUserId,
            decoration: InputDecoration(labelText: l10n.paidByLabel),
            items: widget.viewModel.participants
                .map(
                  (p) => DropdownMenuItem(
                    value: p.id,
                    child: Text(widget.viewModel.displayName(p.id, youLabel: l10n.you, diverLabel: l10n.diver)),
                  ),
                )
                .toList(),
            onChanged: (v) => setState(() => _payerUserId = v!),
          ),
          const SizedBox(height: 16),
          SegmentedButton<String>(
            // The built-in checkmark on the selected segment eats into its width, which
            // wrapped a longer translation (e.g. Russian "По долям") onto a second line —
            // dropped so all three segments size consistently regardless of selection.
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: 'equal', label: Text(l10n.splitEqual)),
              ButtonSegment(value: 'shares', label: Text(l10n.splitShares)),
              ButtonSegment(value: 'exact', label: Text(l10n.splitExact)),
            ],
            selected: {_splitType},
            onSelectionChanged: (s) => setState(() => _splitType = s.first),
          ),
          const SizedBox(height: 16),
          Text(l10n.splitBetweenLabel, style: theme.textTheme.titleSmall),
          ...widget.viewModel.participants.map(_buildParticipantRow),
          if (_splitType == 'exact') ...[
            const SizedBox(height: 8),
            _buildRemainingBanner(context, amountMinor),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
          ],
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: widget.viewModel.isSubmitting ? null : _save,
            child: widget.viewModel.isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(widget.isEdit ? l10n.saveChanges : l10n.addExpenseTitle),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantRow(Profile p) {
    final l10n = AppLocalizations.of(context);
    final userId = p.id;
    final selected = _selected.contains(userId);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Checkbox(
            value: selected,
            onChanged: (v) => setState(() {
              if (v == true) {
                _selected.add(userId);
                _shareCounts.putIfAbsent(userId, () => 1);
              } else {
                _selected.remove(userId);
              }
            }),
          ),
          Expanded(child: Text(widget.viewModel.displayName(userId, youLabel: l10n.you, diverLabel: l10n.diver))),
          if (_splitType == 'shares' && selected) _buildShareStepper(userId),
          if (_splitType == 'exact' && selected)
            SizedBox(
              width: 96,
              child: TextField(
                controller: _exactControllers[userId],
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(isDense: true, prefixText: '¤ '),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildShareStepper(String userId) {
    final count = _shareCounts[userId] ?? 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: count > 1 ? () => setState(() => _shareCounts[userId] = count - 1) : null,
        ),
        SizedBox(width: 20, child: Text('$count', textAlign: TextAlign.center)),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => setState(() => _shareCounts[userId] = count + 1),
        ),
      ],
    );
  }

  Widget _buildRemainingBanner(BuildContext context, int? totalMinor) {
    if (totalMinor == null) return const SizedBox.shrink();
    var assigned = 0;
    for (final id in _selected) {
      assigned += parseExpenseAmountMinor(_exactControllers[id]?.text ?? '') ?? 0;
    }
    final remaining = totalMinor - assigned;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final ok = remaining == 0;
    return Text(
      ok ? l10n.fullyAssigned : l10n.remainingToAssign(formatExpenseAmount(remaining)),
      style: theme.textTheme.bodySmall?.copyWith(
        color: ok ? Colors.green : theme.colorScheme.error,
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showCalendarPicker(
      context,
      initialDate: _occurredAt,
      // No floor at "today" like trip creation's own use of this picker — an expense
      // routinely gets logged a day or two after it actually happened.
      minimumDate: DateTime(_occurredAt.year - 5),
    );
    if (picked != null) setState(() => _occurredAt = picked);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context);
    final title = _titleController.text.trim();
    final amountMinor = parseExpenseAmountMinor(_amountController.text);
    if (title.isEmpty || amountMinor == null || amountMinor <= 0 || _selected.isEmpty) {
      setState(() => _error = l10n.fillTitleAmountParticipant);
      return;
    }

    List<ExpenseShareInput> shares;
    switch (_splitType) {
      case 'shares':
        shares = _selected
            .map((id) => ExpenseShareInput(userId: id, shares: _shareCounts[id] ?? 1))
            .toList();
      case 'exact':
        final exactShares = <ExpenseShareInput>[];
        var sum = 0;
        for (final id in _selected) {
          final amt = parseExpenseAmountMinor(_exactControllers[id]?.text ?? '');
          if (amt == null) {
            setState(() => _error = l10n.enterExactAmountForEveryone);
            return;
          }
          sum += amt;
          exactShares.add(ExpenseShareInput(userId: id, amountMinor: amt));
        }
        if (sum != amountMinor) {
          setState(() => _error = l10n.exactAmountsMustAddUp);
          return;
        }
        shares = exactShares;
      default:
        shares = _selected.map((id) => ExpenseShareInput(userId: id)).toList();
    }

    setState(() => _error = null);
    final errorMsg = widget.isEdit
        ? await widget.viewModel.updateExpense(
            widget.existing!.id,
            payerUserId: _payerUserId,
            title: title,
            amountMinor: amountMinor,
            splitType: _splitType,
            occurredAt: _occurredAt,
            shares: shares,
          )
        : await widget.viewModel.createExpense(
            payerUserId: _payerUserId,
            title: title,
            amountMinor: amountMinor,
            splitType: _splitType,
            occurredAt: _occurredAt,
            shares: shares,
          );
    if (errorMsg != null) {
      setState(() => _error = errorMsg);
      return;
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _confirmDelete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteExpenseTitle),
        content: Text(l10n.deleteExpenseBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.delete, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final errorMsg = await widget.viewModel.deleteExpense(widget.existing!.id);
    if (!mounted) return;
    if (errorMsg != null) {
      setState(() => _error = errorMsg);
      return;
    }
    Navigator.of(context).pop();
  }
}
