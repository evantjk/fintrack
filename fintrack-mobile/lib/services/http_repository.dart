import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/category.dart';
import '../models/transaction.dart';
import 'api_config.dart';
import 'auth_service.dart';
import 'finance_repository.dart';

/// Thrown by [HttpRepository] when fintrack-api returns a non-2xx response.
class ApiException implements Exception {
  final int statusCode;
  final String body;
  const ApiException(this.statusCode, this.body);

  @override
  String toString() => 'ApiException($statusCode): $body';
}

/// fintrack-api-backed implementation of [FinanceRepository], replacing
/// direct Firestore access. The backend derives the signed-in user's uid
/// from the verified Bearer token, not from any value passed by this class —
/// that's what makes the per-user isolation server-enforced instead of
/// client-trusted (see proceeding_plan.md Stage 2/3).
class HttpRepository implements FinanceRepository {
  final AuthService _authService;
  final http.Client _client;

  HttpRepository({AuthService? authService, http.Client? client})
      : _authService = authService ?? AuthService(),
        _client = client ?? http.Client();

  // Builds the full web address for a backend path.
  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  // Adds the login token so the backend knows which user is asking.
  Future<Map<String, String>> _headers() async {
    final token = await _authService.getIdToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Returns the decoded JSON body, or null for an empty (e.g. 204) response.
  /// Throws [ApiException] for any non-2xx status.
  dynamic _decode(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.body.isEmpty ? null : jsonDecode(res.body);
    }
    throw ApiException(res.statusCode, res.body);
  }

  // Asks the backend to create the starter categories on first use.
  @override
  Future<void> ensureSeeded() async {
    final res =
        await _client.post(_uri('/categories/seed'), headers: await _headers());
    _decode(res);
  }

  // Gets all categories for the signed-in user from the backend.
  @override
  Future<List<Category>> getCategories() async {
    final res = await _client.get(_uri('/categories'), headers: await _headers());
    final list = _decode(res) as List<dynamic>;
    return list
        .map((m) => Category.fromMap(
            (m as Map<String, dynamic>)['id'] as String, m))
        .toList();
  }

  // Gets all transactions for the signed-in user from the backend.
  @override
  Future<List<Transaction>> getTransactions() async {
    final res =
        await _client.get(_uri('/transactions'), headers: await _headers());
    final list = _decode(res) as List<dynamic>;
    return list
        .map((m) => Transaction.fromMap(
            (m as Map<String, dynamic>)['id'] as String, m))
        .toList();
  }

  // Saves a new category and returns its id.
  @override
  Future<String> addCategory(Category category) async {
    final res = await _client.post(
      _uri('/categories'),
      headers: await _headers(),
      body: jsonEncode(category.toMap()),
    );
    final json = _decode(res) as Map<String, dynamic>;
    return json['id'] as String;
  }

  // Saves changes to an existing category.
  @override
  Future<void> updateCategory(Category category) async {
    final res = await _client.put(
      _uri('/categories/${category.id}'),
      headers: await _headers(),
      body: jsonEncode(category.toMap()),
    );
    _decode(res);
  }

  // Removes a category by its id.
  @override
  Future<void> deleteCategory(String id) async {
    final res =
        await _client.delete(_uri('/categories/$id'), headers: await _headers());
    _decode(res);
  }

  // Saves a new transaction and returns its id.
  @override
  Future<String> addTransaction(Transaction tx) async {
    final res = await _client.post(
      _uri('/transactions'),
      headers: await _headers(),
      body: jsonEncode(tx.toMap()),
    );
    final json = _decode(res) as Map<String, dynamic>;
    return json['id'] as String;
  }

  // Saves changes to an existing transaction.
  @override
  Future<void> updateTransaction(Transaction tx) async {
    final res = await _client.put(
      _uri('/transactions/${tx.id}'),
      headers: await _headers(),
      body: jsonEncode(tx.toMap()),
    );
    _decode(res);
  }

  // Removes a transaction by its id.
  @override
  Future<void> deleteTransaction(String id) async {
    final res = await _client.delete(_uri('/transactions/$id'),
        headers: await _headers());
    _decode(res);
  }
}
