import 'package:flutter/material.dart';

import '../../../../domain/entities/expense.dart';
import '../../../core/formatting/date_format.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../utils/expense_format.dart';
import '../view_models/expense_view_model.dart';
import 'add_edit_expense_page.dart';

class ExpenseView extends StatefulWidget {
  const ExpenseView({super.key, required this.viewModel, required this.isCancelled});

  final ExpenseViewModel viewModel;
  final bool isCancelled;

  @override
  State<ExpenseView> createState() => _ExpenseViewState();
}

class _ExpenseViewState extends State<ExpenseView> {
  @override
  void initState() {
    super.initState();
    // Same "each tab loads itself on mount" pattern as TransportView/BuddyView — TabBarView
    // builds every tab eagerly, so this fires once the Bubble opens, not on first visit.
    widget.viewModel.load();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = widget.viewModel;
    final isCancelled = widget.isCancelled;
    return ListenableBuilder(
      listenable: viewModel,
      builder: (context, _) {
        if (viewModel.isLoading && viewModel.expenses.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        final error = viewModel.error;
        if (error != null) {
          return Center(child: Text('Error: $error'));
        }

        final expenses = viewModel.expenses;
        return Scaffold(
          body: Column(
            children: [
              _BalanceCard(viewModel: viewModel),
              Expanded(
                child: expenses.isEmpty
                    ? EmptyStateView(
                        icon: Icons.receipt_long_outlined,
                        title: 'No expenses yet',
                        subtitle: isCancelled
                            ? 'This trip has been cancelled.'
                            : 'Log a shared cost so everyone knows what they owe.',
                        ctaLabel: isCancelled ? null : 'Add expense',
                        onCtaPressed: isCancelled ? null : () => _openAdd(context),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: expenses.length,
                        separatorBuilder: (_, _) => const Divider(height: 1, indent: 16),
                        itemBuilder: (context, index) => _ExpenseRow(
                          viewModel: viewModel,
                          expense: expenses[index],
                          onTap: () => _openEdit(context, expenses[index]),
                        ),
                      ),
              ),
            ],
          ),
          floatingActionButton: isCancelled
              ? null
              : FloatingActionButton(
                  onPressed: () => _openAdd(context),
                  child: const Icon(Icons.add),
                ),
        );
      },
    );
  }

  void _openAdd(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => AddEditExpensePage(viewModel: widget.viewModel)));
  }

  void _openEdit(BuildContext context, Expense expense) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddEditExpensePage(viewModel: widget.viewModel, existing: expense),
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.viewModel});

  final ExpenseViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final myBalance = viewModel.myBalanceMinor;
    final settled = myBalance == 0;
    final owedToMe = myBalance > 0;
    final label = settled
        ? 'All settled up'
        : owedToMe
        ? 'You are owed ${formatExpenseAmount(myBalance)}'
        : 'You owe ${formatExpenseAmount(-myBalance)}';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: settled ? null : () => showExpenseBalanceSheet(context, viewModel),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: settled
              ? theme.colorScheme.surfaceContainerHighest
              : owedToMe
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            if (!settled) const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _ExpenseRow extends StatelessWidget {
  const _ExpenseRow({required this.viewModel, required this.expense, required this.onTap});

  final ExpenseViewModel viewModel;
  final Expense expense;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(expense.title),
      subtitle: Text(
        'Paid by ${viewModel.displayName(expense.payerUserId)} · ${formatShortDate(expense.occurredAt)}',
      ),
      trailing: Text(
        formatExpenseAmount(expense.amountMinor),
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

void showExpenseBalanceSheet(BuildContext context, ExpenseViewModel viewModel) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) => _ExpenseBalanceSheet(viewModel: viewModel),
  );
}

class _ExpenseBalanceSheet extends StatefulWidget {
  const _ExpenseBalanceSheet({required this.viewModel});

  final ExpenseViewModel viewModel;

  @override
  State<_ExpenseBalanceSheet> createState() => _ExpenseBalanceSheetState();
}

class _ExpenseBalanceSheetState extends State<_ExpenseBalanceSheet> {
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    widget.viewModel.addListener(_onViewModelChanged);
  }

  @override
  void dispose() {
    widget.viewModel.removeListener(_onViewModelChanged);
    super.dispose();
  }

  // Settling the last debt from a "Mark settled" tap inside this very sheet would otherwise
  // leave it sitting open showing "All settled up." with nothing left to do — auto-close
  // shortly after instead of making the diver swipe it away themselves.
  void _onViewModelChanged() {
    if (_closing || widget.viewModel.mySettlements.isNotEmpty) return;
    _closing = true;
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.viewModel,
      builder: (context, _) {
        final settlements = widget.viewModel.mySettlements;
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            // Column shrink-wraps to its widest child's intrinsic width by default (only
            // mainAxisSize governs the vertical axis) — without forcing full width here, the
            // sheet's own Material surface shrinks right along with it, which is exactly the
            // "squished horizontally" card the empty/settled state (just an icon + one line)
            // was rendering as.
            child: SizedBox(
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Balance', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  if (settlements.isEmpty)
                    // A short, empty-looking sheet reads as a rendering glitch rather than a
                    // deliberate "you're done here" state — this fills the same footprint a
                    // settlement row would, so it never flashes as a squashed sliver on its
                    // way to auto-closing (see _onViewModelChanged).
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            size: 40,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(height: 12),
                          const Text('All settled up.'),
                        ],
                      ),
                    )
                  else
                    ...settlements.map(
                      (s) => _SettlementRow(viewModel: widget.viewModel, settlement: s),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SettlementRow extends StatelessWidget {
  const _SettlementRow({required this.viewModel, required this.settlement});

  final ExpenseViewModel viewModel;
  final ExpenseSettlement settlement;

  @override
  Widget build(BuildContext context) {
    final iOwe = settlement.fromUserId == viewModel.currentUserId;
    final otherUserId = iOwe ? settlement.toUserId : settlement.fromUserId;
    final label = iOwe
        ? 'You owe ${viewModel.displayName(otherUserId)}'
        : '${viewModel.displayName(otherUserId)} owes you';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(formatExpenseAmount(settlement.amountMinor)),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () async {
              final error = await viewModel.settle(settlement);
              if (error != null && context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Could not settle: $error')));
              }
            },
            child: const Text('Mark settled'),
          ),
        ],
      ),
    );
  }
}
