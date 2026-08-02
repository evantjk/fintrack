import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_service.dart';
import 'http_repository.dart' show ApiException;
import 'insights_service.dart';

/// Fetches the AI insights payload from fintrack-api's `/insights` endpoint.
/// A standalone client rather than a [FinanceRepository] method: insights are
/// derived, read-only data, not part of the transaction/category storage
/// contract those repositories implement.
// Talks to the backend's insights endpoint to get spending insights.
class InsightsApi {
  final AuthService _authService;
  final http.Client _client;

  InsightsApi({AuthService? authService, http.Client? client})
      : _authService = authService ?? AuthService(),
        _client = client ?? http.Client();

  // Calls the backend and returns the AI insights for the current user.
  Future<InsightsData> fetch() async {
    final token = await _authService.getIdToken();
    final res = await _client.get(
      Uri.parse('${ApiConfig.baseUrl}/insights'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
    if (res.statusCode < 200 || res.statusCode >= 300) {
      throw ApiException(res.statusCode, res.body);
    }
    return InsightsData.fromJson(jsonDecode(res.body) as Map<String, dynamic>);
  }
}
