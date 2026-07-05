import 'package:flutter/material.dart' show IconData, Icons;
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/category.dart';

enum InsightSentiment { positive, warning, neutral }

/// One rule-based "AI analysis" card — no model calls involved, just a
/// human-readable observation derived from the user's own transactions.
class Insight {
  final IconData icon;
  final String title;
  final String message;
  final InsightSentiment sentiment;

  const Insight({
    required this.icon,
    required this.title,
    required this.message,
    this.sentiment = InsightSentiment.neutral,
  });
}

/// Generates a handful of plain-language observations from transaction
/// history using simple aggregation rules (totals, month-over-month deltas,
/// weekday grouping) — everything is computed on-device from data already
/// loaded by [TransactionProvider], so there is no network call and nothing
/// to pay for.
class InsightsService {
  InsightsService._();

  static final _money = NumberFormat.currency(locale: 'en_MY', symbol: 'RM ');

  static List<Insight> generate({
    required List<Transaction> transactions,
    required List<Category> categories,
  }) {
    if (transactions.length < 3) {
      return [
        const Insight(
          icon: Icons.auto_awesome_outlined,
          title: 'Not enough data yet',
          message:
              'Add a few more transactions and check back — insights get '
              'more useful the more history you have.',
        ),
      ];
    }

    final insights = <Insight>[];
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);

    final expenses = transactions.where((t) => t.type == 'expense').toList();
    final thisMonthTx =
        transactions.where((t) => !t.date.isBefore(thisMonthStart)).toList();
    final lastMonthTx = transactions
        .where((t) =>
            !t.date.isBefore(lastMonthStart) && t.date.isBefore(thisMonthStart))
        .toList();

    final totalIncome = _sum(transactions, 'income');
    final totalExpense = _sum(transactions, 'expense');
    final thisMonthExpense = _sum(thisMonthTx, 'expense');
    final lastMonthExpense = _sum(lastMonthTx, 'expense');

    _addSavingsRateInsight(insights, totalIncome, totalExpense);
    _addMonthOverMonthInsight(insights, thisMonthExpense, lastMonthExpense);
    _addTopCategoryInsight(insights, expenses, categories, totalExpense);
    _addBiggestExpenseInsight(insights, expenses, categories);
    _addWeekdayPatternInsight(insights, expenses);

    return insights;
  }

  static double _sum(List<Transaction> list, String type) =>
      list.where((t) => t.type == type).fold(0.0, (s, t) => s + t.amount);

  static String _pct(double fraction) => '${(fraction.abs() * 100).round()}%';

  static void _addSavingsRateInsight(
      List<Insight> insights, double totalIncome, double totalExpense) {
    if (totalIncome <= 0) return;
    final rate = (totalIncome - totalExpense) / totalIncome;
    if (rate < 0) {
      insights.add(Insight(
        icon: Icons.warning_amber_rounded,
        title: 'Spending more than you earn',
        message: 'Overall, your expenses are ${_pct(rate)} higher than your '
            'income. It may be worth reviewing your biggest spending '
            'categories below.',
        sentiment: InsightSentiment.warning,
      ));
    } else if (rate < 0.1) {
      insights.add(Insight(
        icon: Icons.savings_outlined,
        title: 'Thin savings margin',
        message: 'You are keeping ${_pct(rate)} of what you earn. A small '
            'cut to your top spending category could give you more of a '
            'buffer.',
        sentiment: InsightSentiment.warning,
      ));
    } else {
      insights.add(Insight(
        icon: Icons.trending_up_rounded,
        title: 'Healthy savings rate',
        message:
            'You are saving ${_pct(rate)} of your income overall. Keep it up.',
        sentiment: InsightSentiment.positive,
      ));
    }
  }

  static void _addMonthOverMonthInsight(
      List<Insight> insights, double thisMonth, double lastMonth) {
    if (lastMonth <= 0) return;
    final delta = (thisMonth - lastMonth) / lastMonth;
    if (delta.abs() < 0.05) {
      insights.add(Insight(
        icon: Icons.horizontal_rule_rounded,
        title: 'Spending is steady',
        message: 'This month\'s spending (${_money.format(thisMonth)}) is '
            'about the same as last month.',
      ));
    } else if (delta > 0) {
      insights.add(Insight(
        icon: Icons.trending_up_rounded,
        title: 'Spending is up this month',
        message: 'You have spent ${_pct(delta)} more than last month so far '
            '(${_money.format(thisMonth)} vs ${_money.format(lastMonth)}).',
        sentiment: InsightSentiment.warning,
      ));
    } else {
      insights.add(Insight(
        icon: Icons.trending_down_rounded,
        title: 'Spending is down this month',
        message: 'You have spent ${_pct(delta)} less than last month so far '
            '(${_money.format(thisMonth)} vs ${_money.format(lastMonth)}).',
        sentiment: InsightSentiment.positive,
      ));
    }
  }

  static void _addTopCategoryInsight(List<Insight> insights,
      List<Transaction> expenses, List<Category> categories, double total) {
    if (expenses.isEmpty || total <= 0) return;
    final totals = <String, double>{};
    for (final t in expenses) {
      totals[t.categoryId] = (totals[t.categoryId] ?? 0) + t.amount;
    }
    final topEntry =
        totals.entries.reduce((a, b) => a.value > b.value ? a : b);
    final cat = _findCategory(categories, topEntry.key);
    final share = topEntry.value / total;
    insights.add(Insight(
      icon: Icons.pie_chart_outline_rounded,
      title: 'Biggest spending category',
      message: '${cat?.name ?? 'Uncategorised'} makes up ${_pct(share)} of '
          'your total spending (${_money.format(topEntry.value)}).',
      sentiment: share > 0.4 ? InsightSentiment.warning : InsightSentiment.neutral,
    ));
  }

  static void _addBiggestExpenseInsight(List<Insight> insights,
      List<Transaction> expenses, List<Category> categories) {
    if (expenses.isEmpty) return;
    final biggest = expenses.reduce((a, b) => a.amount > b.amount ? a : b);
    final cat = _findCategory(categories, biggest.categoryId);
    final dateStr = DateFormat('d MMM').format(biggest.date);
    insights.add(Insight(
      icon: Icons.priority_high_rounded,
      title: 'Largest single expense',
      message: '${_money.format(biggest.amount)} on "${biggest.title}"'
          '${cat != null ? ' (${cat.name})' : ''} — $dateStr.',
    ));
  }

  static void _addWeekdayPatternInsight(
      List<Insight> insights, List<Transaction> expenses) {
    if (expenses.length < 5) return;
    final totalsByWeekday = <int, double>{};
    for (final t in expenses) {
      totalsByWeekday[t.date.weekday] =
          (totalsByWeekday[t.date.weekday] ?? 0) + t.amount;
    }
    final topDay =
        totalsByWeekday.entries.reduce((a, b) => a.value > b.value ? a : b);
    final dayName = DateFormat('EEEE').format(
        DateTime(2024, 1, 1).add(Duration(days: topDay.key - 1)));
    insights.add(Insight(
      icon: Icons.calendar_today_outlined,
      title: 'Spending pattern',
      message:
          'You tend to spend the most on ${dayName}s (${_money.format(topDay.value)} total).',
    ));
  }

  static Category? _findCategory(List<Category> categories, String id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }
}
