import 'package:flutter/foundation.dart' hide Category;
import '../models/transaction.dart';
import '../models/category.dart';
import '../services/finance_repository.dart';
import '../services/http_repository.dart';

/// Holds the signed-in user's transactions and categories in memory and keeps
/// them in sync with a per-user [FinanceRepository] (fintrack-api in the app).
///
/// Call [setUser] whenever the signed-in user changes: it rebinds the provider
/// to that user's data so each account sees only its own transactions. Pass a
/// repository to the constructor in tests to avoid Firebase.
class TransactionProvider extends ChangeNotifier {
  /// Repository injected for tests. When set, it is reused for every user.
  final FinanceRepository? _injected;
  FinanceRepository? _repo;
  String? _uid;

  TransactionProvider([FinanceRepository? repository])
      : _injected = repository,
        _repo = repository;

  List<Transaction> _transactions = [];
  List<Category> _categories = [];
  double _totalIncome = 0;
  double _totalExpense = 0;
  bool _isLoading = false;
  String _filterType = 'all'; // 'all', 'income', 'expense'

  List<Transaction> get transactions {
    if (_filterType == 'all') return _transactions;
    return _transactions.where((t) => t.type == _filterType).toList();
  }

  /// All loaded transactions, ignoring [filterType]. Screens that compute
  /// whole-history aggregates (e.g. AI insights) should use this rather than
  /// [transactions], which is scoped to whatever filter is active on the
  /// transactions list screen.
  List<Transaction> get allTransactions => _transactions;

  List<Category> get categories => _categories;
  List<Category> get incomeCategories =>
      _categories.where((c) => c.type == 'income').toList();
  List<Category> get expenseCategories =>
      _categories.where((c) => c.type == 'expense').toList();

  double get totalIncome => _totalIncome;
  double get totalExpense => _totalExpense;
  double get balance => _totalIncome - _totalExpense;
  bool get isLoading => _isLoading;
  String get filterType => _filterType;

  List<Transaction> get recentTransactions => _transactions.take(5).toList();

  /// Points the provider at a specific user's data (or clears it on sign-out).
  /// Guards against re-binding to the same user so it is safe to call on every
  /// auth-state rebuild.
  Future<void> setUser(String? uid) async {
    if (uid == _uid) return;
    _uid = uid;
    if (uid == null) {
      _repo = _injected;
      _transactions = [];
      _categories = [];
      _totalIncome = 0;
      _totalExpense = 0;
      _isLoading = false;
      notifyListeners();
      return;
    }
    _repo = _injected ?? HttpRepository();
    await loadAll();
  }

  Future<void> loadAll() async {
    final repo = _repo;
    if (repo == null) return;
    _isLoading = true;
    notifyListeners();
    await repo.ensureSeeded();
    _transactions = await repo.getTransactions();
    _categories = await repo.getCategories();
    _recomputeTotals();
    _isLoading = false;
    notifyListeners();
  }

  void _recomputeTotals() {
    _totalIncome = _transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (sum, t) => sum + t.amount);
    _totalExpense = _transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  Future<void> addTransaction(Transaction tx) async {
    final repo = _repo;
    if (repo == null) return;
    final id = await repo.addTransaction(tx);
    _transactions.insert(0, tx.copyWith(id: id));
    if (tx.type == 'income') {
      _totalIncome += tx.amount;
    } else {
      _totalExpense += tx.amount;
    }
    notifyListeners();
  }

  Future<void> updateTransaction(Transaction tx) async {
    final repo = _repo;
    if (repo == null) return;
    final old = _transactions.firstWhere((t) => t.id == tx.id);
    // Reverse old effect
    if (old.type == 'income') {
      _totalIncome -= old.amount;
    } else {
      _totalExpense -= old.amount;
    }
    await repo.updateTransaction(tx);
    final idx = _transactions.indexWhere((t) => t.id == tx.id);
    _transactions[idx] = tx;
    // Apply new effect
    if (tx.type == 'income') {
      _totalIncome += tx.amount;
    } else {
      _totalExpense += tx.amount;
    }
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    final repo = _repo;
    if (repo == null) return;
    final tx = _transactions.firstWhere((t) => t.id == id);
    await repo.deleteTransaction(id);
    _transactions.removeWhere((t) => t.id == id);
    if (tx.type == 'income') {
      _totalIncome -= tx.amount;
    } else {
      _totalExpense -= tx.amount;
    }
    notifyListeners();
  }

  Future<void> addCategory(Category cat) async {
    final repo = _repo;
    if (repo == null) return;
    final id = await repo.addCategory(cat);
    _categories.add(cat.copyWith(id: id));
    notifyListeners();
  }

  Future<void> updateCategory(Category cat) async {
    final repo = _repo;
    if (repo == null) return;
    await repo.updateCategory(cat);
    final idx = _categories.indexWhere((c) => c.id == cat.id);
    _categories[idx] = cat;
    notifyListeners();
  }

  Future<void> deleteCategory(String id) async {
    final repo = _repo;
    if (repo == null) return;
    await repo.deleteCategory(id);
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  /// Aggregates expense totals per category, in the shape the statistics screen
  /// expects (`name`, `icon`, `color_value`, `total`), sorted high to low.
  /// Computed in Dart since Firestore has no SQL-style JOIN/GROUP BY.
  Future<List<Map<String, dynamic>>> getExpenseByCategory() async {
    final totals = <String, double>{};
    for (final t in _transactions.where((t) => t.type == 'expense')) {
      totals[t.categoryId] = (totals[t.categoryId] ?? 0) + t.amount;
    }
    final rows = <Map<String, dynamic>>[];
    totals.forEach((catId, total) {
      final cat = getCategoryById(catId);
      if (cat == null) return;
      rows.add({
        'name': cat.name,
        'icon': cat.icon,
        'color_value': cat.colorValue,
        'total': total,
      });
    });
    rows.sort((a, b) => (b['total'] as double).compareTo(a['total'] as double));
    return rows;
  }

  Category? getCategoryById(String id) {
    try {
      return _categories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  void setFilter(String type) {
    _filterType = type;
    notifyListeners();
  }
}
