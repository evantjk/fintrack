import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/transaction_tile.dart';
import '../theme/app_theme.dart';
import 'add_edit_transaction_screen.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              _FilterBar(
                selected: provider.filterType,
                onChanged: provider.setFilter,
              ),
              Expanded(
                child: provider.transactions.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 64, color: AppTheme.textMuted),
                            SizedBox(height: 16),
                            Text(
                              'No transactions found.',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 16),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.only(bottom: 80, top: 4),
                        itemCount: provider.transactions.length,
                        itemBuilder: (context, i) {
                          final tx = provider.transactions[i];
                          final cat = provider.getCategoryById(tx.categoryId);
                          return TransactionTile(
                            transaction: tx,
                            category: cat,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    AddEditTransactionScreen(transaction: tx),
                              ),
                            ),
                            onDelete: () =>
                                provider.deleteTransaction(tx.id!),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _FilterBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _Chip('All', 'all', selected, onChanged, Colors.blueGrey),
          const SizedBox(width: 8),
          _Chip('Income', 'income', selected, onChanged, AppTheme.incomeColor),
          const SizedBox(width: 8),
          _Chip('Expense', 'expense', selected, onChanged, AppTheme.expenseColor),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onChanged;
  final Color color;

  const _Chip(this.label, this.value, this.selected, this.onChanged, this.color);

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onChanged(value),
      selectedColor: color.withValues(alpha: 0.2),
      checkmarkColor: color,
      labelStyle: TextStyle(
        color: isSelected ? color : AppTheme.textMuted,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }
}
