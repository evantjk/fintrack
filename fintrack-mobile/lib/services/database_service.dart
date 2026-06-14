import 'package:sqflite/sqflite.dart' hide Transaction;
import 'package:path/path.dart';
import '../models/category.dart';
import '../models/transaction.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'fintrack.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color_value INTEGER NOT NULL,
        type TEXT NOT NULL
      )
    ''');
    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        type TEXT NOT NULL,
        note TEXT,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');
    await _seedCategories(db);
  }

  Future<void> _seedCategories(Database db) async {
    final defaultCategories = [
      {'name': 'Salary', 'icon': '💼', 'color_value': 0xFF4CAF50, 'type': 'income'},
      {'name': 'Freelance', 'icon': '💻', 'color_value': 0xFF2196F3, 'type': 'income'},
      {'name': 'Investment', 'icon': '📈', 'color_value': 0xFF9C27B0, 'type': 'income'},
      {'name': 'Gift', 'icon': '🎁', 'color_value': 0xFFFF9800, 'type': 'income'},
      {'name': 'Food', 'icon': '🍔', 'color_value': 0xFFF44336, 'type': 'expense'},
      {'name': 'Transport', 'icon': '🚗', 'color_value': 0xFF607D8B, 'type': 'expense'},
      {'name': 'Shopping', 'icon': '🛍️', 'color_value': 0xFFE91E63, 'type': 'expense'},
      {'name': 'Bills', 'icon': '📄', 'color_value': 0xFF795548, 'type': 'expense'},
      {'name': 'Health', 'icon': '💊', 'color_value': 0xFF00BCD4, 'type': 'expense'},
      {'name': 'Entertainment', 'icon': '🎬', 'color_value': 0xFFFF5722, 'type': 'expense'},
      {'name': 'Education', 'icon': '📚', 'color_value': 0xFF3F51B5, 'type': 'expense'},
      {'name': 'Other', 'icon': '📦', 'color_value': 0xFF9E9E9E, 'type': 'expense'},
    ];
    for (final cat in defaultCategories) {
      await db.insert('categories', cat);
    }
  }

  // ---------- Category CRUD ----------

  Future<List<Category>> getCategories() async {
    final db = await database;
    final maps = await db.query('categories', orderBy: 'type DESC, name ASC');
    return maps.map(Category.fromMap).toList();
  }

  Future<Category?> getCategoryById(int id) async {
    final db = await database;
    final maps = await db.query('categories', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Category.fromMap(maps.first);
  }

  Future<int> insertCategory(Category category) async {
    final db = await database;
    return await db.insert('categories', category.toMap());
  }

  Future<int> updateCategory(Category category) async {
    final db = await database;
    return await db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    );
  }

  Future<int> deleteCategory(int id) async {
    final db = await database;
    return await db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- Transaction CRUD ----------

  Future<List<Transaction>> getTransactions() async {
    final db = await database;
    final maps = await db.query('transactions', orderBy: 'date DESC');
    return maps.map(Transaction.fromMap).toList();
  }

  Future<int> insertTransaction(Transaction tx) async {
    final db = await database;
    return await db.insert('transactions', tx.toMap());
  }

  Future<int> updateTransaction(Transaction tx) async {
    final db = await database;
    return await db.update(
      'transactions',
      tx.toMap(),
      where: 'id = ?',
      whereArgs: [tx.id],
    );
  }

  Future<int> deleteTransaction(int id) async {
    final db = await database;
    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, double>> getSummary() async {
    final db = await database;
    final incomeRows = await db.rawQuery(
        "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = 'income'");
    final expenseRows = await db.rawQuery(
        "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = 'expense'");
    final income = (incomeRows.first['total'] as num).toDouble();
    final expense = (expenseRows.first['total'] as num).toDouble();
    return {'income': income, 'expense': expense};
  }

  Future<List<Map<String, dynamic>>> getExpenseByCategory() async {
    final db = await database;
    return await db.rawQuery('''
      SELECT c.name, c.icon, c.color_value, SUM(t.amount) as total
      FROM transactions t
      JOIN categories c ON t.category_id = c.id
      WHERE t.type = 'expense'
      GROUP BY t.category_id
      ORDER BY total DESC
    ''');
  }
}
