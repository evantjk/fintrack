import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fintrack/widgets/balance_card.dart';
import 'package:fintrack/providers/theme_provider.dart';
import 'package:fintrack/theme/app_theme.dart';

void main() {
  // Wraps the card in the providers + theme it needs at runtime. The embedded
  // ThemeMascot calls context.watch<ThemeProvider>(), and PixelColors.of(context)
  // reads the active theme's ThemeExtension, so both must be present.
  Widget wrap({
    required double balance,
    required double income,
    required double expense,
    PixelThemeType theme = PixelThemeType.original,
  }) {
    return ChangeNotifierProvider<ThemeProvider>(
      create: (_) => ThemeProvider()..setTheme(theme),
      child: MaterialApp(
        theme: AppTheme.themeFor(theme),
        home: Scaffold(
          body: BalanceCard(
            balance: balance,
            income: income,
            expense: expense,
          ),
        ),
      ),
    );
  }

  testWidgets('renders the balance and income/expense labels', (tester) async {
    await tester.pumpWidget(
      wrap(balance: 3000, income: 5000, expense: 2000),
    );
    await tester.pumpAndSettle();

    expect(find.text('TOTAL BALANCE'), findsOneWidget);
    expect(find.text('INCOME'), findsOneWidget);
    expect(find.text('EXPENSE'), findsOneWidget);
    // Currency is formatted as RM with en_MY grouping.
    expect(find.textContaining('3,000.00'), findsOneWidget);
    expect(find.textContaining('5,000.00'), findsOneWidget);
    expect(find.textContaining('2,000.00'), findsOneWidget);
  });

  testWidgets('computes the % saved pill from income and expense',
      (tester) async {
    // (5000 - 2000) / 5000 = 0.6 -> "60% saved"
    await tester.pumpWidget(
      wrap(balance: 3000, income: 5000, expense: 2000),
    );
    await tester.pumpAndSettle();

    expect(find.text('60% saved'), findsOneWidget);
  });

  testWidgets('hides the savings pill when there is no income',
      (tester) async {
    await tester.pumpWidget(
      wrap(balance: -800, income: 0, expense: 800),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('saved'), findsNothing);
  });

  testWidgets('renders under the Luxury (non-pixel) theme', (tester) async {
    await tester.pumpWidget(
      wrap(
        balance: 12500,
        income: 15000,
        expense: 2500,
        theme: PixelThemeType.luxury,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('TOTAL BALANCE'), findsOneWidget);
    expect(find.textContaining('12,500.00'), findsOneWidget);
  });
}
