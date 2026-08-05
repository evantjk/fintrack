import 'package:flutter/foundation.dart';

import '../services/reward_repository.dart';
import '../theme/app_theme.dart';

// What happened when the user tapped check-in.
enum CheckInResult { success, alreadyCheckedIn }

// A theme the user can unlock by spending XP.
class RewardTheme {
  final PixelThemeType type;
  final String name;
  final String description;
  final int cost;

  const RewardTheme({
    required this.type,
    required this.name,
    required this.description,
    required this.cost,
  });
}

// Manages daily check-ins, XP, and which themes the user has unlocked.
class CheckInProvider extends ChangeNotifier {
  static const int baseDailyRewardXp = 10;
  static const int maxDailyRewardXp = 15;

  CheckInProvider({
    DateTime Function()? now,
    RewardRepository? repository,
  })  : _now = now ?? DateTime.now,
        _repo = repository ?? RewardRepository();

  final DateTime Function() _now;
  final RewardRepository _repo;

  String? _uid;
  bool _loading = false;
  int _totalXp = 0;
  int _spentXp = 0;
  int _checkInCount = 0;
  int _lastEarnedXp = 0;
  DateTime? _lastCheckInDate;
  final Set<PixelThemeType> _ownedThemes = {PixelThemeType.original};

  bool get loading => _loading;
  int get totalXp => _totalXp;
  int get spentXp => _spentXp;
  int get availableXp => _totalXp - _spentXp;
  int get checkInCount => _checkInCount;
  int get lastEarnedXp => _lastEarnedXp;
  int get nextRewardXp => _rewardForCheckInNumber(_checkInCount + 1);
  DateTime? get lastCheckInDate => _lastCheckInDate;
  int get rewardProgressXp => _totalXp;
  bool get checkedInToday =>
      _lastCheckInDate != null && _isSameDate(_lastCheckInDate!, _now());

  Set<PixelThemeType> get ownedThemes => Set.unmodifiable(_ownedThemes);

  static const List<RewardTheme> rewardThemes = [
    RewardTheme(
      type: PixelThemeType.original,
      name: 'Default Blue',
      description: 'The classic FinTrack professional theme.',
      cost: 0,
    ),
    RewardTheme(
      type: PixelThemeType.gundam,
      name: 'Midnight Dark',
      description: 'A bold high-contrast dashboard style.',
      cost: 30,
    ),
    RewardTheme(
      type: PixelThemeType.luxury,
      name: 'Ocean Breeze',
      description: 'Calming teal and refined soft surfaces.',
      cost: 60,
    ),
    RewardTheme(
      type: PixelThemeType.helloKitty,
      name: 'Sakura Petal',
      description: 'A warm pink theme for a softer dashboard.',
      cost: 90,
    ),
  ];

  // Loads this user's reward data on login, or resets it on logout.
  Future<void> setUser(String? uid) async {
    if (_uid == uid) return;
    _uid = uid;

    if (uid == null) {
      _applyState(
        const RewardState(
          totalXp: 0,
          spentXp: 0,
          checkInCount: 0,
          lastEarnedXp: 0,
          lastCheckInDate: null,
          ownedThemes: {PixelThemeType.original},
          activeTheme: PixelThemeType.original,
        ),
      );
      return;
    }

    _loading = true;
    notifyListeners();

    try {
      final state = await _repo.getRewards();
      _applyState(state);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // True if the user has already unlocked this theme.
  bool ownsTheme(PixelThemeType type) => _ownedThemes.contains(type);

  // True if the user has enough XP to unlock this theme.
  bool canAfford(RewardTheme theme) => availableXp >= theme.cost;

  // Does today's check-in and updates XP, or says it was already done.
  Future<CheckInResult> checkIn() async {
    final response = await _repo.checkIn();
    _applyState(response.profile);

    switch (response.status) {
      case 'success':
        return CheckInResult.success;
      case 'already_checked_in':
        return CheckInResult.alreadyCheckedIn;
      default:
        return CheckInResult.alreadyCheckedIn;
    }
  }

  // Spends XP to unlock a theme; returns false if it can't be done.
  Future<bool> unlockTheme(RewardTheme theme) async {
    if (ownsTheme(theme.type)) {
      final state = await _repo.applyTheme(theme.type);
      _applyState(state);
      return true;
    }

    if (!canAfford(theme)) return false;

    final state = await _repo.unlockTheme(theme.type);
    _applyState(state);
    return true;
  }

  // Copies the backend's reward data into this provider.
  void _applyState(RewardState state) {
    _totalXp = state.totalXp;
    _spentXp = state.spentXp;
    _checkInCount = state.checkInCount;
    _lastEarnedXp = state.lastEarnedXp;
    _lastCheckInDate = state.lastCheckInDate;
    _ownedThemes
      ..clear()
      ..addAll(state.ownedThemes);
    notifyListeners();
  }

  // True if two dates fall on the same day.
  bool _isSameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // Works out the XP for a check-in (more for a longer streak).
  int _rewardForCheckInNumber(int checkInNumber) {
    if (checkInNumber <= 0) return baseDailyRewardXp;
    final streakBonus = (checkInNumber - 1) ~/ 5;
    final reward = baseDailyRewardXp + streakBonus;
    return reward.clamp(baseDailyRewardXp, maxDailyRewardXp);
  }
}