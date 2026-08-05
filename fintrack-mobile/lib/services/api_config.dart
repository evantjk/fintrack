import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Base URL for fintrack-api, local-dev only (see proceeding_plan.md Stage 2 —
/// deployment is a separate, later decision).
///
/// The Android emulator can't reach the host machine via `localhost` — it has
/// to use the special `10.0.2.2` loopback alias instead. Every other target
/// (desktop, iOS simulator, web) reaches the host machine directly.
class ApiConfig {
  static String get baseUrl {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://localhost:8000';
  }
}
