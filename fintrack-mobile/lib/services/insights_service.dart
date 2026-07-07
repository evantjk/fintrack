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

/// A single 0-100 "financial health" reading plus a short label, computed
/// from the same real numbers shown elsewhere in the app (savings rate,
/// month-over-month trend) — no separate data source, just a blended view
/// of them for the headline card.
class HealthScore {
  final int score;
  final String label;
  final InsightSentiment sentiment;

  const HealthScore(
      {required this.score, required this.label, required this.sentiment});
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
    _addProjectedMonthEndInsight(
        insights, thisMonthExpense, lastMonthExpense, now);
    _addTopCategoryInsight(insights, expenses, categories, totalExpense);
    _addBiggestExpenseInsight(insights, expenses, categories);
    _addWeekdayPatternInsight(insights, expenses);
    _addWeekendVsWeekdayInsight(insights, expenses);
    _addNoSpendStreakInsight(insights, expenses, now);

    return insights;
  }

  /// Blends the savings rate with the month-over-month spending trend into a
  /// single 0-100 reading for the headline card. Both inputs are numbers
  /// already surfaced elsewhere in the app — this just weights and combines
  /// them, it does not invent new data.
  static HealthScore computeHealthScore({
    required List<Transaction> transactions,
  }) {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);

    final totalIncome = _sum(transactions, 'income');
    final totalExpense = _sum(transactions, 'expense');
    final thisMonthExpense = _sum(
        transactions.where((t) => !t.date.isBefore(thisMonthStart)).toList(),
        'expense');
    final lastMonthExpense = _sum(
        transactions
            .where((t) =>
                !t.date.isBefore(lastMonthStart) &&
                t.date.isBefore(thisMonthStart))
            .toList(),
        'expense');

    final savingsRate =
        totalIncome > 0 ? (totalIncome - totalExpense) / totalIncome : 0.0;
    // rate -0.5 -> 0, 0 -> 50, 0.5+ -> 100
    final savingsScore =
        (((savingsRate.clamp(-0.5, 0.5) + 0.5)) * 100).round();

    int score;
    if (lastMonthExpense > 0) {
      final delta = (thisMonthExpense - lastMonthExpense) / lastMonthExpense;
      // delta -0.5 (spend down 50%) -> 100, 0 -> 50, +0.5 -> 0
      final trendScore = (((-delta).clamp(-0.5, 0.5) + 0.5) * 100).round();
      score = (savingsScore * 0.6 + trendScore * 0.4).round();
    } else {
      score = savingsScore;
    }
    score = score.clamp(0, 100);

    final String label;
    final InsightSentiment sentiment;
    if (score >= 80) {
      label = 'Excellent';
      sentiment = InsightSentiment.positive;
    } else if (score >= 60) {
      label = 'Good';
      sentiment = InsightSentiment.positive;
    } else if (score >= 40) {
      label = 'Fair';
      sentiment = InsightSentiment.neutral;
    } else {
      label = 'Needs attention';
      sentiment = InsightSentiment.warning;
    }
    return HealthScore(score: score, label: label, sentiment: sentiment);
  }

  /// Total expense per calendar day for the trailing [days] days (oldest
  /// first), for the sparkline on the insights header.
  static List<double> dailyExpenseSeries({
    required List<Transaction> transactions,
    int days = 14,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final totals = List<double>.filled(days, 0);
    for (final t in transactions) {
      if (t.type != 'expense') continue;
      final d = DateTime(t.date.year, t.date.month, t.date.day);
      final diff = today.difference(d).inDays;
      if (diff >= 0 && diff < days) {
        totals[days - 1 - diff] += t.amount;
      }
    }
    return totals;
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

  /// Projects this month's total spend from the pace set so far, compared
  /// against what was actually spent last month.
  static void _addProjectedMonthEndInsight(List<Insight> insights,
      double thisMonth, double lastMonth, DateTime now) {
    if (lastMonth <= 0 || thisMonth <= 0) return;
    final dayOfMonth = now.day;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    if (dayOfMonth < 3) return; // too early in the month to project
    final projected = thisMonth / dayOfMonth * daysInMonth;
    final delta = (projected - lastMonth) / lastMonth;
    if (delta.abs() < 0.08) return; // roughly on par, skip a redundant card
    insights.add(Insight(
      icon: Icons.query_stats_rounded,
      title: delta > 0 ? 'On track to overspend' : 'On track to spend less',
      message: 'At your current pace, this month could end around '
          '${_money.format(projected)}, ${_pct(delta)} '
          '${delta > 0 ? 'more' : 'less'} than last month\'s '
          '${_money.format(lastMonth)}.',
      sentiment:
          delta > 0 ? InsightSentiment.warning : InsightSentiment.positive,
    ));
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

  /// Compares average daily spend on weekends (Sat/Sun) vs weekdays.
  static void _addWeekendVsWeekdayInsight(
      List<Insight> insights, List<Transaction> expenses) {
    if (expenses.length < 6) return;
    double weekendTotal = 0, weekdayTotal = 0;
    final weekendDays = <String>{}, weekdayDays = <String>{};
    for (final t in expenses) {
      final key = '${t.date.year}-${t.date.month}-${t.date.day}';
      if (t.date.weekday >= DateTime.saturday) {
        weekendTotal += t.amount;
        weekendDays.add(key);
      } else {
        weekdayTotal += t.amount;
        weekdayDays.add(key);
      }
    }
    if (weekendDays.isEmpty || weekdayDays.isEmpty) return;
    final weekendAvg = weekendTotal / weekendDays.length;
    final weekdayAvg = weekdayTotal / weekdayDays.length;
    if (weekdayAvg <= 0) return;
    final delta = (weekendAvg - weekdayAvg) / weekdayAvg;
    if (delta.abs() < 0.15) return; // not a meaningful enough gap
    insights.add(Insight(
      icon: Icons.weekend_outlined,
      title: delta > 0 ? 'Weekends cost more' : 'Weekdays cost more',
      message: 'You spend ${_money.format(delta > 0 ? weekendAvg : weekdayAvg)} '
          'a day on average ${delta > 0 ? 'on weekends' : 'on weekdays'}, '
          '${_pct(delta)} more than ${delta > 0 ? 'weekdays' : 'weekends'} '
          '(${_money.format(delta > 0 ? weekdayAvg : weekendAvg)}).',
    ));
  }

  /// Counts no-spend days in the trailing week — a quick, positive signal
  /// when present, and silently skipped when there is nothing to report.
  static void _addNoSpendStreakInsight(
      List<Insight> insights, List<Transaction> expenses, DateTime now) {
    const window = 7;
    final today = DateTime(now.year, now.month, now.day);
    final spentDays = <String>{};
    for (final t in expenses) {
      final d = DateTime(t.date.year, t.date.month, t.date.day);
      final diff = today.difference(d).inDays;
      if (diff >= 0 && diff < window) {
        spentDays.add('${d.year}-${d.month}-${d.day}');
      }
    }
    final noSpendDays = window - spentDays.length;
    if (noSpendDays <= 0) return;
    insights.add(Insight(
      icon: Icons.check_circle_outline_rounded,
      title: noSpendDays == window
          ? 'No spending in the past week'
          : 'No-spend days this week',
      message: noSpendDays == window
          ? 'You have not logged a single expense in the last $window days.'
          : 'You had $noSpendDays no-spend day${noSpendDays == 1 ? '' : 's'} '
              'out of the last $window.',
      sentiment: noSpendDays >= 4
          ? InsightSentiment.positive
          : InsightSentiment.neutral,
    ));
  }

  static Category? _findCategory(List<Category> categories, String id) {
    for (final c in categories) {
      if (c.id == id) return c;
    }
    return null;
  }
}
