import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../theme/app_theme.dart';
import '../utils/currency_formatter.dart';

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
    final p = PixelColors.of(context);
    final pix = p.hardShadow;
    final isIncome = transaction.type == 'income';
    final dateFmt = DateFormat('dd MMM yyyy');

    return Dismissible(
      key: Key('tx_${transaction.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: p.expense,
          borderRadius: p.radius == 0 ? null : BorderRadius.circular(16),
          border: p.box(p.outline, 2),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) => onDelete?.call(),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 8,
          ),
          leading: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: Color(
                category?.colorValue ?? 0xFF9E9E9E,
              ).withValues(alpha: 0.18),
              borderRadius: p.radius == 0 ? null : BorderRadius.circular(14),
              border: p.box(Color(category?.colorValue ?? 0xFF9E9E9E), 2),
            ),
            child: Center(
              child: Text(
                category?.icon ?? '📦',
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),
          title: Text(
            transaction.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: pix ? 11 : 15,
              height: 1.4,
              fontWeight: pix ? null : FontWeight.w600,
              color: p.textDark,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (category != null)
                  Text(
                    category!.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: pix ? 8 : 12,
                      color: p.textMuted,
                    ),
                  ),
                const SizedBox(height: 2),
                Text(
                  dateFmt.format(transaction.date),
                  style: TextStyle(fontSize: pix ? 8 : 12, color: p.textMuted),
                ),
              ],
            ),
          ),
          trailing: SizedBox(
            width: 105,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                '${isIncome ? '+' : '-'}${formatCurrency(transaction.amount)}',
                maxLines: 1,
                style: TextStyle(
                  color: isIncome ? p.income : p.expense,
                  fontWeight: pix ? null : FontWeight.bold,
                  fontSize: pix ? 9 : 15,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
