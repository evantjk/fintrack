import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';

class TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final Category? category;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.category,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final fmt = NumberFormat.currency(locale: 'en_MY', symbol: 'RM ');
    final dateFmt = DateFormat('dd MMM yyyy');

    return Dismissible(
      key: Key('tx_${transaction.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppTheme.expenseColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => onDelete?.call(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: ListTile(
          onTap: onTap,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Color(category?.colorValue ?? 0xFF9E9E9E).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                category?.icon ?? '📦',
                style: const TextStyle(fontSize: 22),
              ),
            ),
          ),
          title: Text(
            transaction.title,
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 15, color: AppTheme.textDark),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (category != null)
                Text(category!.name,
                    style: const TextStyle(
                        fontSize: 12, color: AppTheme.textMuted)),
              Text(dateFmt.format(transaction.date),
                  style:
                      const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            ],
          ),
          trailing: Text(
            '${isIncome ? '+' : '-'}${fmt.format(transaction.amount)}',
            style: TextStyle(
              color: isIncome ? AppTheme.incomeColor : AppTheme.expenseColor,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
