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
    final p = PixelColors.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('STATISTICS')),
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
                  Text(
                    'SPENDING BY CATEGORY',
                    style: TextStyle(fontSize: 11, color: p.textDark),
                  ),
                  const SizedBox(height: 12),
                  if (_expenseByCategory.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.bar_chart_outlined,
                                size: 64, color: p.textMuted),
                            const SizedBox(height: 16),
                            Text('No expense data yet.',
                                style: TextStyle(
                                    color: p.textMuted, fontSize: 9)),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    _SpendingDonut(
                        data: _expenseByCategory, total: total),
                    const SizedBox(height: 16),
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
                  ],
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
    final p = PixelColors.of(context);
    final fmt = NumberFormat.currency(locale: 'en_MY', symbol: 'RM ');
    return Row(
      children: [
        Expanded(
            child: _StatCard('Income', fmt.format(income), p.income,
                Icons.arrow_downward_rounded)),
        const SizedBox(width: 12),
        Expanded(
            child: _StatCard('Expense', fmt.format(expense), p.expense,
                Icons.arrow_upward_rounded)),
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
    final p = PixelColors.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(color: p.textMuted, fontSize: 8)),
              ],
            ),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(color: color, fontSize: 11),
              ),
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
    final p = PixelColors.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Expanded(
                    child: Text(name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 9, color: p.textDark))),
                Text(amount,
                    style: TextStyle(color: color, fontSize: 9)),
              ],
            ),
            const SizedBox(height: 10),
            Stack(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                      color: p.surfaceAlt,
                      borderRadius: p.radius == 0 ? null : BorderRadius.circular(5)),
                ),
                FractionallySizedBox(
                  widthFactor: percentage.clamp(0.0, 1.0),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(
                        color: color,
                        borderRadius:
                            p.radius == 0 ? null : BorderRadius.circular(5)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${(percentage * 100).toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 8, color: p.textMuted),
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
    final p = PixelColors.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TRANSACTION OVERVIEW',
                style: TextStyle(fontSize: 10, color: p.textDark)),
            Divider(height: 24, color: p.outline),
            _CountRow('Total Transactions', totalCount, p.textMuted),
            const SizedBox(height: 10),
            _CountRow('Income Entries', incomeCount, p.income),
            const SizedBox(height: 10),
            _CountRow('Expense Entries', expenseCount, p.expense),
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
    final p = PixelColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(label,
              style: TextStyle(color: p.textMuted, fontSize: 9, height: 1.4)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: p.radius == 0 ? null : BorderRadius.circular(20),
              border: Border.all(
                  color: color, width: p.hardShadow ? 1.5 : 0)),
          child: Text('$count',
              style: TextStyle(color: color, fontSize: 9)),
        ),
      ],
    );
  }
}

/// Donut chart of spending by category. Drawn with a CustomPainter so it needs
/// no extra chart dependency, and reads theme tokens for the track colour.
class _SpendingDonut extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final double total;

  const _SpendingDonut({required this.data, required this.total});

  @override
  Widget build(BuildContext context) {
    final p = PixelColors.of(context);
    final fmt = NumberFormat.currency(locale: 'en_MY', symbol: 'RM ');
    final segments = [
      for (final e in data)
        _DonutSeg((e['total'] as num).toDouble(), Color(e['color_value'] as int))
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            height: 180,
            width: 180,
            child: CustomPaint(
              painter: _DonutPainter(segments: segments, trackColor: p.surfaceAlt),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('TOTAL SPENT',
                        style: TextStyle(
                            fontSize: 8,
                            letterSpacing: 1,
                            color: p.textMuted)),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(fmt.format(total),
                          style: TextStyle(fontSize: 13, color: p.textDark)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DonutSeg {
  final double value;
  final Color color;
  const _DonutSeg(this.value, this.color);
}

class _DonutPainter extends CustomPainter {
  final List<_DonutSeg> segments;
  final Color trackColor;

  _DonutPainter({required this.segments, required this.trackColor});

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 24.0;
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - stroke) / 2,
    );
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = trackColor;
    canvas.drawArc(rect, 0, 6.2831853, false, track);

    final total = segments.fold<double>(0, (s, e) => s + e.value);
    if (total <= 0) return;

    const gap = 0.05; // small radial gap between slices
    double start = -1.5707963; // start at top (12 o'clock)
    for (final seg in segments) {
      final sweep = (seg.value / total) * 6.2831853;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = seg.color;
      final pad = sweep > gap ? gap / 2 : 0.0;
      canvas.drawArc(rect, start + pad, sweep - pad * 2, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.segments != segments || old.trackColor != trackColor;
}
