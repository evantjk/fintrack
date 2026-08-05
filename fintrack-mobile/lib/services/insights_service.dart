import 'package:flutter/material.dart' show IconData, Icons;

enum InsightSentiment { positive, warning, neutral }

// Turns the backend's text tag into a sentiment value (good/watch/neutral).
InsightSentiment _sentimentFromJson(String value) {
  switch (value) {
    case 'positive':
      return InsightSentiment.positive;
    case 'warning':
      return InsightSentiment.warning;
    default:
      return InsightSentiment.neutral;
  }
}

const Map<String, IconData> _iconsByKey = {
  'warning': Icons.warning_amber_rounded,
  'savings': Icons.savings_outlined,
  'trending_up': Icons.trending_up_rounded,
  'trending_down': Icons.trending_down_rounded,
  'steady': Icons.horizontal_rule_rounded,
  'pie_chart': Icons.pie_chart_outline_rounded,
  'priority_high': Icons.priority_high_rounded,
  'calendar': Icons.calendar_today_outlined,
  'weekend': Icons.weekend_outlined,
  'check_circle': Icons.check_circle_outline_rounded,
  'query_stats': Icons.query_stats_rounded,
  'auto_awesome': Icons.auto_awesome_outlined,
};

/// One AI-analysis card returned by fintrack-api's `/insights` endpoint - all
/// the aggregation and (when a Gemini key is configured) the language
/// generation happens server-side; this is just the wire format.
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

  // Builds one insight card from the backend's JSON.
  factory Insight.fromJson(Map<String, dynamic> json) => Insight(
        icon: _iconsByKey[json['icon']] ?? Icons.auto_awesome_outlined,
        title: json['title'] as String,
        message: json['message'] as String,
        sentiment: _sentimentFromJson(json['sentiment'] as String),
      );
}

/// A single 0-100 "financial health" reading plus a short label, as computed
/// by the backend from the signed-in user's transactions.
class HealthScore {
  final int score;
  final String label;
  final InsightSentiment sentiment;

  const HealthScore(
      {required this.score, required this.label, required this.sentiment});

  // Builds the money health score from the backend's JSON.
  factory HealthScore.fromJson(Map<String, dynamic> json) => HealthScore(
        score: json['score'] as int,
        label: json['label'] as String,
        sentiment: _sentimentFromJson(json['sentiment'] as String),
      );
}

/// Full response from `GET /insights`: the headline score, the 14-day
/// spending trend, and a handful of plain-language observations - optionally
/// written by Gemini from the server-computed numbers, or a deterministic
/// rule-based fallback when no model is configured or the call fails.
class InsightsData {
  final HealthScore healthScore;
  final double totalIncome;
  final double totalExpense;
  final List<double> dailyExpenseSeries;
  final List<Insight> insights;
  final String? aiSummary;
  final bool aiGenerated;

  const InsightsData({
    required this.healthScore,
    required this.totalIncome,
    required this.totalExpense,
    required this.dailyExpenseSeries,
    required this.insights,
    required this.aiSummary,
    required this.aiGenerated,
  });

  // Builds the whole insights bundle (score, cards, summary) from JSON.
  factory InsightsData.fromJson(Map<String, dynamic> json) => InsightsData(
        healthScore:
            HealthScore.fromJson(json['health_score'] as Map<String, dynamic>),
        totalIncome: (json['total_income'] as num).toDouble(),
        totalExpense: (json['total_expense'] as num).toDouble(),
        dailyExpenseSeries: (json['daily_expense_series'] as List<dynamic>)
            .map((v) => (v as num).toDouble())
            .toList(),
        insights: (json['insights'] as List<dynamic>)
            .map((i) => Insight.fromJson(i as Map<String, dynamic>))
            .toList(),
        aiSummary: json['ai_summary'] as String?,
        aiGenerated: json['ai_generated'] as bool? ?? false,
      );
}
