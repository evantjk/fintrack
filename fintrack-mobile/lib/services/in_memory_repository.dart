import '../models/category.dart';
import '../models/transaction.dart';
import 'default_categories.dart';
import 'finance_repository.dart';

/// A fake [FinanceRepository] that keeps everything in memory. Used by the unit
/// and widget tests so the provider can run without Firebase, mirroring the
/// Firestore implementation's seeding and ordering behaviour.
class InMemoryRepository implements FinanceRepository {
  final List<Category> _categories = [];
  final List<Transaction> _transactions = [];
  int _seq = 0;

  String _nextId() => 'id${++_seq}'; // makes a fresh fake id

  // Fills in the starter categories the first time, like the real backend.
  @override
  Future<void> ensureSeeded() async {
    if (_categories.isNotEmpty) return;
    for (final cat in defaultCategories) {
      _categories.add(Category.fromMap(_nextId(), cat));
    }
  }

  // Reads from the in-memory lists instead of the network.
  @override
  Future<List<Category>> getCategories() async {
    final list = [..._categories]..sort(compareCategories);
    return list;
  }

  @override
  Future<List<Transaction>> getTransactions() async {
    final list = [..._transactions]..sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  // Add / change / remove items directly in the in-memory lists below.
  @override
  Future<String> addCategory(Category category) async {
    final id = _nextId();
    _categories.add(category.copyWith(id: id));
    return id;
  }

  @override
  Future<void> updateCategory(Category category) async {
    final i = _categories.indexWhere((c) => c.id == category.id);
    if (i >= 0) _categories[i] = category;
  }

  @override
  Future<void> deleteCategory(String id) async {
    _categories.removeWhere((c) => c.id == id);
  }

  @override
  Future<String> addTransaction(Transaction tx) async {
    final id = _nextId();
    _transactions.add(tx.copyWith(id: id));
    return id;
  }

  @override
  Future<void> updateTransaction(Transaction tx) async {
    final i = _transactions.indexWhere((t) => t.id == tx.id);
    if (i >= 0) _transactions[i] = tx;
  }

  @override
  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((t) => t.id == id);
  }
}
