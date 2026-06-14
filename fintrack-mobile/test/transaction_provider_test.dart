import 'package:flutter_test/flutter_test.dart';
import 'package:fintrack/models/transaction.dart';
import 'package:fintrack/models/category.dart';
import 'package:fintrack/providers/transaction_provider.dart';
import 'package:fintrack/services/database_service.dart';

import 'helpers.dart';

void main() {
  // Build a transaction with sensible defaults for the field under test.
  Transaction makeTx({
    required double amount,
    required int categoryId,
    required String type,
    String title = 'Test',
  }) =>
      Transaction(
        title: title,
        amount: amount,
        date: DateTime(2026, 6, 14),
        categoryId: categoryId,
        type: type,
      );

  setUpAll(() async {
    await initTestDatabase();
  });

  // Start every test from a clean transactions table (categories stay seeded).
  setUp(() async {
    final db = await DatabaseService().database;
    await db.delete('transactions');
  });

  Future<TransactionProvider> loadedProvider() async {
    final p = TransactionProvider();
    await p.loadAll();
    return p;
  }

  test('loadAll seeds categories and starts with a zero balance', () async {
    final p = await loadedProvider();
    expect(p.categories, isNotEmpty);
    expect(p.transactions, isEmpty);
    expect(p.totalIncome, 0);
    expect(p.totalExpense, 0);
    expect(p.balance, 0);
  });

  test('seeded categories are split correctly by type', () async {
    final p = await loadedProvider();
    expect(p.incomeCategories, isNotEmpty);
    expect(p.expenseCategories, isNotEmpty);
    expect(p.incomeCategories.every((c) => c.type == 'income'), isTrue);
    expect(p.expenseCategories.every((c) => c.type == 'expense'), isTrue);
  });

  test('adding income increases income total and balance', () async {
    final p = await loadedProvider();
    final cat = p.incomeCategories.first;

    await p.addTransaction(
        makeTx(amount: 5000, categoryId: cat.id!, type: 'income'));

    expect(p.transactions.length, 1);
    expect(p.totalIncome, 5000);
    expect(p.totalExpense, 0);
    expect(p.balance, 5000);
  });

  test('adding an expense reduces the balance', () async {
    final p = await loadedProvider();
    final cat = p.expenseCategories.first;

    await p.addTransaction(
        makeTx(amount: 1200, categoryId: cat.id!, type: 'expense'));

    expect(p.totalExpense, 1200);
    expect(p.balance, -1200);
  });

  test('balance equals income minus expense across multiple entries', () async {
    final p = await loadedProvider();
    final income = p.incomeCategories.first;
    final expense = p.expenseCategories.first;

    await p.addTransaction(
        makeTx(amount: 5000, categoryId: income.id!, type: 'income'));
    await p.addTransaction(
        makeTx(amount: 2000, categoryId: expense.id!, type: 'expense'));

    expect(p.totalIncome, 5000);
    expect(p.totalExpense, 2000);
    expect(p.balance, 3000);
    expect(p.transactions.length, 2);
  });

  test('deleting a transaction reverses its effect on totals', () async {
    final p = await loadedProvider();
    final cat = p.incomeCategories.first;
    await p.addTransaction(
        makeTx(amount: 800, categoryId: cat.id!, type: 'income'));

    final id = p.transactions.first.id!;
    await p.deleteTransaction(id);

    expect(p.transactions, isEmpty);
    expect(p.totalIncome, 0);
    expect(p.balance, 0);
  });

  test('updating a transaction amount adjusts the totals', () async {
    final p = await loadedProvider();
    final cat = p.incomeCategories.first;
    await p.addTransaction(
        makeTx(amount: 100, categoryId: cat.id!, type: 'income'));

    final inserted = p.transactions.first;
    await p.updateTransaction(inserted.copyWith(amount: 250));

    expect(p.totalIncome, 250);
    expect(p.balance, 250);
    expect(p.transactions.length, 1);
  });

  test('type filter returns only matching transactions', () async {
    final p = await loadedProvider();
    final income = p.incomeCategories.first;
    final expense = p.expenseCategories.first;
    await p.addTransaction(
        makeTx(amount: 500, categoryId: income.id!, type: 'income'));
    await p.addTransaction(
        makeTx(amount: 300, categoryId: expense.id!, type: 'expense'));

    p.setFilter('income');
    expect(p.transactions.length, 1);
    expect(p.transactions.every((t) => t.type == 'income'), isTrue);

    p.setFilter('expense');
    expect(p.transactions.every((t) => t.type == 'expense'), isTrue);

    p.setFilter('all');
    expect(p.transactions.length, 2);
  });

  test('getExpenseByCategory aggregates expense totals per category', () async {
    final p = await loadedProvider();
    final cat = p.expenseCategories.first;
    await p.addTransaction(
        makeTx(amount: 30, categoryId: cat.id!, type: 'expense'));
    await p.addTransaction(
        makeTx(amount: 20, categoryId: cat.id!, type: 'expense'));

    final byCategory = await p.getExpenseByCategory();
    final row = byCategory.firstWhere((e) => e['name'] == cat.name);

    expect((row['total'] as num).toDouble(), 50);
  });

  test('category CRUD: add, update and delete a category', () async {
    final p = await loadedProvider();
    final before = p.categories.length;

    await p.addCategory(Category(
        name: 'Pets', icon: '🐶', colorValue: 0xFF8BC34A, type: 'expense'));
    expect(p.categories.length, before + 1);

    final added = p.categories.firstWhere((c) => c.name == 'Pets');
    await p.updateCategory(added.copyWith(name: 'Pet Care'));
    expect(p.categories.any((c) => c.name == 'Pet Care'), isTrue);

    final updated = p.categories.firstWhere((c) => c.name == 'Pet Care');
    await p.deleteCategory(updated.id!);
    expect(p.categories.length, before);
    expect(p.categories.any((c) => c.name == 'Pet Care'), isFalse);
  });
}
