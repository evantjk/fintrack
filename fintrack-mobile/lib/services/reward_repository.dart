import 'dart:convert';

import 'package:http/http.dart' as http;

import '../theme/app_theme.dart';
import 'api_config.dart';
import 'auth_service.dart';

// The user's reward info: XP earned, check-in streak, and unlocked themes.
class RewardState {
  final int totalXp;
  final int spentXp;
  final int checkInCount;
  final int lastEarnedXp;
  final DateTime? lastCheckInDate;
  final Set<PixelThemeType> ownedThemes;
  final PixelThemeType activeTheme;

  const RewardState({
    required this.totalXp,
    required this.spentXp,
    required this.checkInCount,
    required this.lastEarnedXp,
    required this.lastCheckInDate,
    required this.ownedThemes,
    required this.activeTheme,
  });

  // Builds the reward info from the backend's JSON.
  factory RewardState.fromJson(Map<String, dynamic> json) {
    return RewardState(
      totalXp: json['total_xp'] as int,
      spentXp: json['spent_xp'] as int,
      checkInCount: json['check_in_count'] as int,
      lastEarnedXp: json['last_earned_xp'] as int,
      lastCheckInDate: json['last_check_in_date'] == null
          ? null
          : DateTime.parse(json['last_check_in_date'] as String),
      ownedThemes: (json['owned_themes'] as List<dynamic>)
          .map((id) => pixelThemeFromId(id as String))
          .toSet(),
      activeTheme: pixelThemeFromId(json['active_theme'] as String),
    );
  }
}

// The backend's reply after a daily check-in (XP gained and new totals).
class CheckInResponse {
  final String status;
  final RewardState profile;

  const CheckInResponse({
    required this.status,
    required this.profile,
  });

  // Builds the check-in reply from the backend's JSON.
  factory CheckInResponse.fromJson(Map<String, dynamic> json) {
    return CheckInResponse(
      status: json['status'] as String,
      profile: RewardState.fromJson(json['profile'] as Map<String, dynamic>),
    );
  }
}

// Talks to the backend's reward endpoints (XP, check-ins, theme unlocks).
class RewardRepository {
  final AuthService _authService;
  final http.Client _client;

  RewardRepository({AuthService? authService, http.Client? client})
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

  // Reads the reply, or throws if the backend returned an error.
  dynamic _decode(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return res.body.isEmpty ? null : jsonDecode(res.body);
    }
    throw Exception('Reward API error ${res.statusCode}: ${res.body}');
  }

  // Gets the user's current XP, streak and unlocked themes.
  Future<RewardState> getRewards() async {
    final res = await _client.get(
      _uri('/rewards'),
      headers: await _headers(),
    );
    return RewardState.fromJson(_decode(res) as Map<String, dynamic>);
  }

  // Does today's check-in to earn XP.
  Future<CheckInResponse> checkIn() async {
    final res = await _client.post(
      _uri('/rewards/check-in'),
      headers: await _headers(),
    );
    return CheckInResponse.fromJson(_decode(res) as Map<String, dynamic>);
  }

  // Spends XP to unlock a new theme.
  Future<RewardState> unlockTheme(PixelThemeType theme) async {
    final res = await _client.post(
      _uri('/rewards/unlock-theme'),
      headers: await _headers(),
      body: jsonEncode({'theme': theme.id}),
    );
    return RewardState.fromJson(_decode(res) as Map<String, dynamic>);
  }

  // Switches to an already-unlocked theme.
  Future<RewardState> applyTheme(PixelThemeType theme) async {
    final res = await _client.post(
      _uri('/rewards/apply-theme'),
      headers: await _headers(),
      body: jsonEncode({'theme': theme.id}),
    );
    return RewardState.fromJson(_decode(res) as Map<String, dynamic>);
  }
}

// Converts between a theme and the short text id the backend uses.
extension PixelThemeTypeId on PixelThemeType {
  String get id {
    switch (this) {
      case PixelThemeType.original:
        return 'original';
      case PixelThemeType.gundam:
        return 'gundam';
      case PixelThemeType.helloKitty:
        return 'helloKitty';
      case PixelThemeType.luxury:
        return 'luxury';
    }
  }
}

// Turns a backend text id back into a theme value.
PixelThemeType pixelThemeFromId(String id) {
  switch (id) {
    case 'gundam':
      return PixelThemeType.gundam;
    case 'helloKitty':
      return PixelThemeType.helloKitty;
    case 'luxury':
      return PixelThemeType.luxury;
    case 'original':
    default:
      return PixelThemeType.original;
  }
}