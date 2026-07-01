import '../models/category.dart';
import '../models/transaction.dart';

/// Storage contract for a single user's finance data (categories +
/// transactions). Implemented by [HttpRepository] (fintrack-api) in the app
/// and by an in-memory fake in tests, so the provider can be exercised
/// without a live backend.
///
/// Every implementation is scoped to one user: the data it returns belongs only
/// to that account, which is what keeps each signed-in user's data separate.
abstract class FinanceRepository {
  /// Creates the default categories the first time a user is seen. A no-op if
  /// the user already has categories.
  Future<void> ensureSeeded();

  Future<List<Category>> getCategories();
  Future<List<Transaction>> getTransactions();

  /// Returns the new document id.
  Future<String> addCategory(Category category);
  Future<void> updateCategory(Category category);
  Future<void> deleteCategory(String id);

  /// Returns the new document id.
  Future<String> addTransaction(Transaction tx);
  Future<void> updateTransaction(Transaction tx);
  Future<void> deleteTransaction(String id);
}

/// Shared ordering used by every repository: income categories before expense
/// (type descending), then alphabetically by name — matching the original
/// SQLite `ORDER BY type DESC, name ASC`.
int compareCategories(Category a, Category b) {
  final byType = b.type.compareTo(a.type);
  return byType != 0 ? byType : a.name.compareTo(b.name);
}
