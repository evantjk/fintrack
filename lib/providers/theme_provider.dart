import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Holds the active pixel theme and rebuilds the app when it changes.
class ThemeProvider extends ChangeNotifier {
  PixelThemeType _current = PixelThemeType.original;

  PixelThemeType get current => _current;

  ThemeData get themeData => AppTheme.themeFor(_current);

  void setTheme(PixelThemeType type) {
    if (_current == type) return;
    _current = type;
    notifyListeners();
  }

  /// Cycle to the next theme in declaration order.
  void toggle() {
    const values = PixelThemeType.values;
    setTheme(values[(_current.index + 1) % values.length]);
  }
}
