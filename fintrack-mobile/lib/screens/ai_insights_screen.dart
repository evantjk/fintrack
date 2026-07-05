import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../services/insights_service.dart';
import '../theme/app_theme.dart';

/// A simple, on-device "AI analysis" of the user's spending — a handful of
/// rule-based observations (savings rate, top category, month-over-month
/// change, etc.) computed from their own transactions. No chat, no external
/// API calls, nothing billed — everything here is plain Dart aggregation,
/// same spirit as [TransactionProvider.getExpenseByCategory].
class AiInsightsScreen extends StatelessWidget {
  const AiInsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = PixelColors.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('AI INSIGHTS')),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final insights = InsightsService.generate(
            transactions: provider.transactions,
            categories: provider.categories,
          );
          return RefreshIndicator(
            onRefresh: () => provider.loadAll(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.auto_awesome, color: p.accent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Based on your ${provider.transactions.length} '
                          'recorded transaction'
                          '${provider.transactions.length == 1 ? '' : 's'}, '
                          'calculated on your device.',
                          style: TextStyle(
                              color: p.textMuted, fontSize: 8, height: 1.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (provider.transactions.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Icon(Icons.auto_awesome_outlined,
                                size: 64, color: p.textMuted),
                            const SizedBox(height: 16),
                            Text(
                              'Add some transactions to get your first '
                              'insights.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: p.textMuted, fontSize: 9, height: 1.6),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...insights.map((i) => _InsightCard(insight: i)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final Insight insight;

  const _InsightCard({required this.insight});

  Color _sentimentColor(PixelColors p) {
    switch (insight.sentiment) {
      case InsightSentiment.positive:
        return p.income;
      case InsightSentiment.warning:
        return p.expense;
      case InsightSentiment.neutral:
        return p.accent;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = PixelColors.of(context);
    final color = _sentimentColor(p);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: p.hardShadow ? BoxShape.rectangle : BoxShape.circle,
                border: Border.all(color: color, width: p.hardShadow ? 2 : 1.5),
              ),
              child: Icon(insight.icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(insight.title,
                      style: TextStyle(fontSize: 10, color: p.textDark)),
                  const SizedBox(height: 6),
                  Text(insight.message,
                      style: TextStyle(
                          fontSize: 9, color: p.textMuted, height: 1.5)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
