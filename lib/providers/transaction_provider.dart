import 'package:flutter/foundation.dart' hide Category;
import '../models/transaction.dart';
import '../models/category.dart';
import '../services/database_service.dart';

class TransactionProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();

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

  Future<void> loadAll() async {
    _isLoading = true;
    notifyListeners();
    _transactions = await _db.getTransactions();
    _categories = await _db.getCategories();
    final summary = await _db.getSummary();
    _totalIncome = summary['income'] ?? 0;
    _totalExpense = summary['expense'] ?? 0;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> addTransaction(Transaction tx) async {
    final id = await _db.insertTransaction(tx);
    final saved = tx.copyWith(id: id);
    _transactions.insert(0, saved);
    if (tx.type == 'income') {
      _totalIncome += tx.amount;
    } else {
      _totalExpense += tx.amount;
    }
    notifyListeners();
  }

  Future<void> updateTransaction(Transaction tx) async {
    final old = _transactions.firstWhere((t) => t.id == tx.id);
    // Reverse old effect
    if (old.type == 'income') {
      _totalIncome -= old.amount;
    } else {
      _totalExpense -= old.amount;
    }
    await _db.updateTransaction(tx);
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

  Future<void> deleteTransaction(int id) async {
    final tx = _transactions.firstWhere((t) => t.id == id);
    await _db.deleteTransaction(id);
    _transactions.removeWhere((t) => t.id == id);
    if (tx.type == 'income') {
      _totalIncome -= tx.amount;
    } else {
      _totalExpense -= tx.amount;
    }
    notifyListeners();
  }

  Future<void> addCategory(Category cat) async {
    final id = await _db.insertCategory(cat);
    _categories.add(cat.copyWith(id: id));
    notifyListeners();
  }

  Future<void> updateCategory(Category cat) async {
    await _db.updateCategory(cat);
    final idx = _categories.indexWhere((c) => c.id == cat.id);
    _categories[idx] = cat;
    notifyListeners();
  }

  Future<void> deleteCategory(int id) async {
    await _db.deleteCategory(id);
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getExpenseByCategory() async {
    return await _db.getExpenseByCategory();
  }

  Category? getCategoryById(int id) {
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
