import 'package:flutter_test/flutter_test.dart';
import 'package:fintrack/models/transaction.dart';
import 'package:fintrack/models/category.dart';

void main() {
  group('Transaction model', () {
    test('toMap / fromMap round-trips all fields', () {
      final tx = Transaction(
        id: 7,
        title: 'Lunch',
        amount: 12.50,
        date: DateTime(2026, 6, 14, 13, 30),
        categoryId: 5,
        type: 'expense',
        note: 'Nasi lemak',
      );

      final restored = Transaction.fromMap(tx.toMap());

      expect(restored.id, 7);
      expect(restored.title, 'Lunch');
      expect(restored.amount, 12.50);
      expect(restored.date, DateTime(2026, 6, 14, 13, 30));
      expect(restored.categoryId, 5);
      expect(restored.type, 'expense');
      expect(restored.note, 'Nasi lemak');
    });

    test('toMap omits a null id (so SQLite can auto-increment)', () {
      final tx = Transaction(
        title: 'Coffee',
        amount: 5,
        date: DateTime(2026, 1, 1),
        categoryId: 1,
        type: 'expense',
      );
      expect(tx.toMap().containsKey('id'), isFalse);
    });

    test('copyWith overrides only the given fields', () {
      final tx = Transaction(
        id: 1,
        title: 'Salary',
        amount: 5000,
        date: DateTime(2026, 6, 1),
        categoryId: 2,
        type: 'income',
      );

      final edited = tx.copyWith(amount: 5500, note: 'Bonus included');

      expect(edited.amount, 5500);
      expect(edited.note, 'Bonus included');
      // Unchanged fields are preserved.
      expect(edited.title, 'Salary');
      expect(edited.type, 'income');
      expect(edited.categoryId, 2);
    });
  });

  group('Category model', () {
    test('toMap / fromMap round-trips all fields', () {
      final cat = Category(
        id: 3,
        name: 'Food',
        icon: '🍔',
        colorValue: 0xFFF44336,
        type: 'expense',
      );

      final restored = Category.fromMap(cat.toMap());

      expect(restored.id, 3);
      expect(restored.name, 'Food');
      expect(restored.icon, '🍔');
      expect(restored.colorValue, 0xFFF44336);
      expect(restored.type, 'expense');
    });

    test('copyWith overrides only the given fields', () {
      final cat = Category(
        id: 1,
        name: 'Transport',
        icon: '🚗',
        colorValue: 0xFF607D8B,
        type: 'expense',
      );

      final edited = cat.copyWith(name: 'Travel');

      expect(edited.name, 'Travel');
      expect(edited.icon, '🚗');
      expect(edited.type, 'expense');
    });
  });
}
