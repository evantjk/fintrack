// Firestore also exports a `Transaction` (its run-transaction type); hide it so
// our own transaction model name wins in this file.
import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import '../models/category.dart';
import '../models/transaction.dart';
import 'default_categories.dart';
import 'finance_repository.dart';

/// Cloud-backed store for one user's data, living under
/// `users/{uid}/categories` and `users/{uid}/transactions` in Firestore.
///
/// Because every collection path is namespaced by the signed-in user's [uid],
/// two different accounts can never see each other's data, and the data follows
/// the user across devices.
class FirestoreRepository implements FinanceRepository {
  final String uid;
  final FirebaseFirestore _fs;

  FirestoreRepository(this.uid, {FirebaseFirestore? firestore})
      : _fs = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _categories =>
      _fs.collection('users').doc(uid).collection('categories');

  CollectionReference<Map<String, dynamic>> get _transactions =>
      _fs.collection('users').doc(uid).collection('transactions');

  @override
  Future<void> ensureSeeded() async {
    final existing = await _categories.limit(1).get();
    if (existing.docs.isNotEmpty) return;
    final batch = _fs.batch();
    for (final cat in defaultCategories) {
      batch.set(_categories.doc(), cat);
    }
    await batch.commit();
  }

  @override
  Future<List<Category>> getCategories() async {
    final snap = await _categories.get();
    final list =
        snap.docs.map((d) => Category.fromMap(d.id, d.data())).toList();
    list.sort(compareCategories);
    return list;
  }

  @override
  Future<List<Transaction>> getTransactions() async {
    // Dates are stored as ISO-8601 strings, which sort chronologically as text.
    final snap = await _transactions.orderBy('date', descending: true).get();
    return snap.docs.map((d) => Transaction.fromMap(d.id, d.data())).toList();
  }

  @override
  Future<String> addCategory(Category category) async {
    final ref = await _categories.add(category.toMap());
    return ref.id;
  }

  @override
  Future<void> updateCategory(Category category) =>
      _categories.doc(category.id).update(category.toMap());

  @override
  Future<void> deleteCategory(String id) => _categories.doc(id).delete();

  @override
  Future<String> addTransaction(Transaction tx) async {
    final ref = await _transactions.add(tx.toMap());
    return ref.id;
  }

  @override
  Future<void> updateTransaction(Transaction tx) =>
      _transactions.doc(tx.id).update(tx.toMap());

  @override
  Future<void> deleteTransaction(String id) => _transactions.doc(id).delete();
}
