import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_theme.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  List<Map<String, dynamic>> _expenseByCategory = [];
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final provider =
        Provider.of<TransactionProvider>(context, listen: false);
    final data = await provider.getExpenseByCategory();
    if (mounted) setState(() { _expenseByCategory = data; _loaded = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Statistics')),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          if (!_loaded) {
            return const Center(child: CircularProgressIndicator());
          }
          final fmt = NumberFormat.currency(locale: 'en_MY', symbol: 'RM ');
          final total = _expenseByCategory.fold<double>(
              0, (sum, e) => sum + (e['total'] as num).toDouble());

          return RefreshIndicator(
            onRefresh: () async {
              setState(() => _loaded = false);
              await _loadStats();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SummaryRow(
                    income: provider.totalIncome,
                    expense: provider.totalExpense,
                    balance: provider.balance,
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Spending by Category',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textDark),
                  ),
                  const SizedBox(height: 12),
                  if (_expenseByCategory.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.bar_chart_outlined,
                                size: 64, color: AppTheme.textMuted),
                            SizedBox(height: 16),
                            Text('No expense data yet.',
                                style: TextStyle(color: AppTheme.textMuted)),
                          ],
                        ),
                      ),
                    )
                  else
                    ..._expenseByCategory.map((e) {
                      final amount = (e['total'] as num).toDouble();
                      final pct = total > 0 ? amount / total : 0.0;
                      final color = Color(e['color_value'] as int);
                      return _CategoryBar(
                        icon: e['icon'] as String,
                        name: e['name'] as String,
                        amount: fmt.format(amount),
                        percentage: pct,
                        color: color,
                      );
                    }),
                  const SizedBox(height: 24),
                  _TransactionCountCard(
                    totalCount: provider.transactions.length,
                    incomeCount: provider.transactions
                        .where((t) => t.type == 'income')
                        .length,
                    expenseCount: provider.transactions
                        .where((t) => t.type == 'expense')
                        .length,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final double income;
  final double expense;
  final double balance;

  const _SummaryRow(
      {required this.income, required this.expense, required this.balance});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_MY', symbol: 'RM ');
    return Row(
      children: [
        Expanded(
            child: _StatCard('Income', fmt.format(income), AppTheme.incomeColor,
                Icons.arrow_downward_rounded)),
        const SizedBox(width: 12),
        Expanded(
            child: _StatCard('Expense', fmt.format(expense),
                AppTheme.expenseColor, Icons.arrow_upward_rounded)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard(this.label, this.value, this.color, this.icon);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 6),
                Text(label,
                    style: const TextStyle(
                        color: AppTheme.textMuted, fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final String icon;
  final String name;
  final String amount;
  final double percentage;
  final Color color;

  const _CategoryBar({
    required this.icon,
    required this.name,
    required this.amount,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark))),
                Text(amount,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
              ],
            ),
            const SizedBox(height: 8),
            Stack(
              children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4)),
                ),
                FractionallySizedBox(
                  widthFactor: percentage.clamp(0.0, 1.0),
                  child: Container(
                    height: 6,
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${(percentage * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                    fontSize: 11, color: AppTheme.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionCountCard extends StatelessWidget {
  final int totalCount;
  final int incomeCount;
  final int expenseCount;

  const _TransactionCountCard({
    required this.totalCount,
    required this.incomeCount,
    required this.expenseCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Transaction Overview',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppTheme.textDark)),
            const Divider(height: 24),
            _CountRow('Total Transactions', totalCount, Colors.blueGrey),
            const SizedBox(height: 8),
            _CountRow('Income Entries', incomeCount, AppTheme.incomeColor),
            const SizedBox(height: 8),
            _CountRow('Expense Entries', expenseCount, AppTheme.expenseColor),
          ],
        ),
      ),
    );
  }
}

class _CountRow extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _CountRow(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textMuted)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20)),
          child: Text('$count',
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ),
      ],
    );
  }
}
