import 'package:fintrack/models/category.dart';
import 'package:fintrack/models/transaction.dart';
import 'package:fintrack/theme/app_theme.dart';
import 'package:fintrack/widgets/transaction_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('fits a large amount on a narrow mobile screen', (tester) async {
    tester.view.physicalSize = const Size(330, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final transaction = Transaction(
      id: 'transaction-1',
      title: 'Monthly salary payment',
      amount: 999999999.99,
      date: DateTime(2026, 7, 25),
      categoryId: 'category-1',
      type: 'income',
    );
    final category = Category(
      id: 'category-1',
      name: 'Employment income',
      icon: 'work',
      colorValue: 0xFF2196F3,
      type: 'income',
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.themeFor(PixelThemeType.original),
        home: Scaffold(
          body: TransactionTile(transaction: transaction, category: category),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    expect(find.textContaining('999,999,999.99'), findsOneWidget);
  });
}
