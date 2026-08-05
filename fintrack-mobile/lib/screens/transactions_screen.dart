import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../models/transaction.dart';
import '../widgets/transaction_tile.dart';
import '../theme/app_theme.dart';
import '../routes/app_routes.dart';

// The page that lists all transactions with search and filters.
class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  // Builds the search box, filter bar, and the grouped transaction list.
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
          final p = PixelColors.of(context);

          // Provider applies the type filter; we additionally apply the
          // local text search over title + category name.
          final q = _query.trim().toLowerCase();
          final items = provider.transactions.where((t) {
            if (q.isEmpty) return true;
            final cat = provider.getCategoryById(t.categoryId);
            return t.title.toLowerCase().contains(q) ||
                (cat?.name.toLowerCase().contains(q) ?? false);
          }).toList();

          return Column(
            children: [
              _SearchField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _query = v),
              ),
              _FilterBar(
                selected: provider.filterType,
                onChanged: provider.setFilter,
              ),
              Expanded(
                child: items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long_outlined,
                                size: 64, color: p.textMuted),
                            const SizedBox(height: 16),
                            Text(
                              q.isEmpty
                                  ? 'No transactions found.'
                                  : 'No matches for "$_query".',
                              style:
                                  TextStyle(color: p.textMuted, fontSize: 10),
                            ),
                          ],
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 80, top: 2),
                        children: _buildGrouped(context, provider, items),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Builds date-grouped rows (TODAY / YESTERDAY / dd MMM yyyy headers).
  List<Widget> _buildGrouped(
    BuildContext context,
    TransactionProvider provider,
    List<Transaction> items,
  ) {
    final p = PixelColors.of(context);
    final widgets = <Widget>[];
    String? lastBucket;
    for (final tx in items) {
      final bucket = _dateBucket(tx.date);
      if (bucket != lastBucket) {
        widgets.add(Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
          child: Text(
            bucket.toUpperCase(),
            style: TextStyle(
                fontSize: 9, letterSpacing: 1, color: p.textMuted),
          ),
        ));
        lastBucket = bucket;
      }
      final cat = provider.getCategoryById(tx.categoryId);
      widgets.add(TransactionTile(
        transaction: tx,
        category: cat,
        onTap: () => Navigator.pushNamed(
          context,
          AppRoutes.transactionForm,
          arguments: TransactionArgs(transaction: tx),
        ),
        onDelete: () => provider.deleteTransaction(tx.id!),
      ));
    }
    return widgets;
  }

  // Returns the group label for a date: Today, Yesterday, or the date.
  String _dateBucket(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final that = DateTime(d.year, d.month, d.day);
    final diff = today.difference(that).inDays;
    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('dd MMM yyyy').format(d);
  }
}

// The search box for filtering transactions by text.
class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchField({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final p = PixelColors.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(fontSize: p.hardShadow ? 10 : 14, color: p.textDark),
        decoration: const InputDecoration(
          hintText: 'Search transactions',
          prefixIcon: Icon(Icons.search, size: 20),
          isDense: true,
        ),
      ),
    );
  }
}

// The row of All / Income / Expense filter chips.
class _FilterBar extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _FilterBar({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final p = PixelColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _Chip('All', 'all', selected, onChanged, p.textMuted),
          const SizedBox(width: 8),
          _Chip('Income', 'income', selected, onChanged, p.income),
          const SizedBox(width: 8),
          _Chip('Expense', 'expense', selected, onChanged, p.expense),
        ],
      ),
    );
  }
}

// A single filter chip button used by the filter bar.
class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final String selected;
  final ValueChanged<String> onChanged;
  final Color color;

  const _Chip(this.label, this.value, this.selected, this.onChanged, this.color);

  @override
  Widget build(BuildContext context) {
    final p = PixelColors.of(context);
    final isSelected = value == selected;
    return FilterChip(
      label: Text(label, style: const TextStyle(fontSize: 8)),
      selected: isSelected,
      onSelected: (_) => onChanged(value),
      showCheckmark: false,
      backgroundColor: p.surface,
      selectedColor: color.withValues(alpha: 0.2),
      side: BorderSide(
          color: isSelected
              ? color
              : (p.hardShadow ? p.outline : const Color(0xFFCED4DA)),
          width: p.hardShadow ? 2 : 1),
      shape: RoundedRectangleBorder(
          borderRadius: p.radius == 0 ? BorderRadius.zero : BorderRadius.circular(20)),
      labelStyle: TextStyle(
        color: isSelected ? color : p.textMuted,
      ),
    );
  }
}
