import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';
import 'mascots.dart';

class BalanceCard extends StatelessWidget {
  final double balance;
  final double income;
  final double expense;

  const BalanceCard({
    super.key,
    required this.balance,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    final p = PixelColors.of(context);
    final fmt = NumberFormat.currency(locale: 'en_MY', symbol: 'RM ');
    final bool square = p.radius == 0;
    final BorderRadius chipRadius =
        square ? BorderRadius.zero : BorderRadius.circular(12);

    // Real, computed metric (no fake "trend" data): the share of this period's
    // income that was kept rather than spent.
    final double savingsRate =
        income > 0 ? ((income - expense) / income).clamp(-1.0, 1.0) : 0.0;
    final bool positiveFlow = savingsRate >= 0;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [p.gradientStart, p.gradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: square ? BorderRadius.zero : BorderRadius.circular(24),
        border: p.box(p.outline, p.borderWidth == 0 ? 0 : 3),
        boxShadow: p.shadow(p.hardShadow ? p.outline : p.gradientEnd),
      ),
      child: Stack(
        children: [
          // Faint mascot watermark behind the content.
          Positioned(
            top: -6,
            right: -6,
            child: Opacity(
              opacity: 0.16,
              child: ThemeMascot(size: 96, outline: Colors.white),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'TOTAL BALANCE',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 9, letterSpacing: 1),
                  ),
                  const Spacer(),
                  if (income > 0)
                    _SavingsPill(
                      savingsRate: savingsRate,
                      positiveFlow: positiveFlow,
                      square: square,
                      pixel: p.hardShadow,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  fmt.format(balance),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    height: 1.3,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _SummaryChip(
                      label: 'INCOME',
                      amount: income,
                      icon: Icons.arrow_downward_rounded,
                      color: const Color(0xFF69F0AE),
                      radius: chipRadius,
                      pixel: p.hardShadow,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SummaryChip(
                      label: 'EXPENSE',
                      amount: expense,
                      icon: Icons.arrow_upward_rounded,
                      color: const Color(0xFFFF8A80),
                      radius: chipRadius,
                      pixel: p.hardShadow,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Computed "% saved" pill (income vs expense). Replaces Stitch's fake trend.
class _SavingsPill extends StatelessWidget {
  final double savingsRate;
  final bool positiveFlow;
  final bool square;
  final bool pixel;

  const _SavingsPill({
    required this.savingsRate,
    required this.positiveFlow,
    required this.square,
    required this.pixel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: square ? BorderRadius.zero : BorderRadius.circular(20),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.35),
            width: pixel ? 1.5 : 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            positiveFlow
                ? Icons.trending_up_rounded
                : Icons.trending_down_rounded,
            color: Colors.white,
            size: 12,
          ),
          const SizedBox(width: 4),
          Text(
            '${(savingsRate * 100).abs().toStringAsFixed(0)}% saved',
            style: const TextStyle(color: Colors.white, fontSize: 8),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  final Color color;
  final BorderRadius radius;
  final bool pixel;

  const _SummaryChip({
    required this.label,
    required this.amount,
    required this.icon,
    required this.color,
    required this.radius,
    required this.pixel,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat.currency(locale: 'en_MY', symbol: 'RM ');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: radius,
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.22),
            width: pixel ? 1.5 : 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.22),
              borderRadius: radius,
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 7)),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    fmt.format(amount),
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
