import 'package:flutter/material.dart';

/// The themes the app can switch between.
enum PixelThemeType { original, gundam, helloKitty, luxury }

/// Theme-aware colors and style knobs used throughout the app.
///
/// Exposed as a [ThemeExtension] so every widget can read them via
/// `PixelColors.of(context)` and they swap when the active theme changes.
/// The style knobs ([radius], [borderWidth], [hardShadow], [fontFamily]) let
/// the same widgets render either the chunky pixel look or the soft "Original"
/// Material look.
@immutable
class PixelColors extends ThemeExtension<PixelColors> {
  final Color income;
  final Color expense;
  final Color textDark;
  final Color textMuted;
  final Color outline;
  final Color accent;

  /// Card / panel background (e.g. white for Original, cream for Luxury).
  final Color surface;
  final Color surfaceAlt;
  final Color gradientStart;
  final Color gradientEnd;

  /// Corner radius (0 = square pixel look).
  final double radius;

  /// Border thickness for boxes (0 = borderless / use elevation).
  final double borderWidth;

  /// Hard offset shadow (pixel) vs soft blurred shadow (original).
  final bool hardShadow;

  /// Null = default Material (Roboto); otherwise the pixel font.
  final String? fontFamily;

  /// Display metadata for the theme switcher.
  final String label;
  final String emoji;

  const PixelColors({
    required this.income,
    required this.expense,
    required this.textDark,
    required this.textMuted,
    required this.outline,
    required this.accent,
    required this.surface,
    required this.surfaceAlt,
    required this.gradientStart,
    required this.gradientEnd,
    required this.radius,
    required this.borderWidth,
    required this.hardShadow,
    required this.fontFamily,
    required this.label,
    required this.emoji,
  });

  static PixelColors of(BuildContext context) =>
      Theme.of(context).extension<PixelColors>()!;

  // ---- Style helpers -----------------------------------------------------
  BorderRadius get br => BorderRadius.circular(radius);

  /// Border for custom boxes, or null when borderless.
  Border? box([Color? color, double? width]) {
    final w = width ?? borderWidth;
    if (w <= 0) return null;
    return Border.all(color: color ?? outline, width: w);
  }

  /// Shadow for cards / hero containers given a base color.
  List<BoxShadow> shadow(Color base, {double offset = 6}) {
    if (hardShadow) {
      return [BoxShadow(color: base, blurRadius: 0, offset: Offset(offset, offset))];
    }
    return [
      BoxShadow(
        color: base.withValues(alpha: 0.30),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ];
  }

  @override
  PixelColors copyWith({
    Color? income,
    Color? expense,
    Color? textDark,
    Color? textMuted,
    Color? outline,
    Color? accent,
    Color? surface,
    Color? surfaceAlt,
    Color? gradientStart,
    Color? gradientEnd,
    double? radius,
    double? borderWidth,
    bool? hardShadow,
    String? fontFamily,
    String? label,
    String? emoji,
  }) {
    return PixelColors(
      income: income ?? this.income,
      expense: expense ?? this.expense,
      textDark: textDark ?? this.textDark,
      textMuted: textMuted ?? this.textMuted,
      outline: outline ?? this.outline,
      accent: accent ?? this.accent,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      radius: radius ?? this.radius,
      borderWidth: borderWidth ?? this.borderWidth,
      hardShadow: hardShadow ?? this.hardShadow,
      fontFamily: fontFamily ?? this.fontFamily,
      label: label ?? this.label,
      emoji: emoji ?? this.emoji,
    );
  }

  @override
  PixelColors lerp(ThemeExtension<PixelColors>? other, double t) {
    if (other is! PixelColors) return this;
    return PixelColors(
      income: Color.lerp(income, other.income, t)!,
      expense: Color.lerp(expense, other.expense, t)!,
      textDark: Color.lerp(textDark, other.textDark, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      outline: Color.lerp(outline, other.outline, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t)!,
      gradientEnd: Color.lerp(gradientEnd, other.gradientEnd, t)!,
      radius: t < 0.5 ? radius : other.radius,
      borderWidth: t < 0.5 ? borderWidth : other.borderWidth,
      hardShadow: t < 0.5 ? hardShadow : other.hardShadow,
      fontFamily: t < 0.5 ? fontFamily : other.fontFamily,
      label: t < 0.5 ? label : other.label,
      emoji: t < 0.5 ? emoji : other.emoji,
    );
  }
}

class AppTheme {
  AppTheme._();

  static const String pixelFont = 'PixelFont';

  /// Elegant serif used by the non-pixel Luxury ("old money") theme.
  static const String serifFont = 'EBGaramond';

  static ThemeData themeFor(PixelThemeType type) {
    switch (type) {
      case PixelThemeType.original:
        return _original;
      case PixelThemeType.gundam:
        return _gundam;
      case PixelThemeType.helloKitty:
        return _helloKitty;
      case PixelThemeType.luxury:
        return _luxury;
    }
  }

  // ---- Gundam: RX-78-2 federation blue / red / yellow on steel ----------
  static final ThemeData _gundam = _build(
    primary: const Color(0xFF2B4C9B),
    background: const Color(0xFFDDE3EC),
    colors: const PixelColors(
      income: Color(0xFF2E9E5B),
      expense: Color(0xFFE03A2F),
      textDark: Color(0xFF12223B),
      textMuted: Color(0xFF5B6B82),
      outline: Color(0xFF12223B),
      accent: Color(0xFFE03A2F),
      surface: Colors.white,
      surfaceAlt: Color(0xFFC7D0DE),
      gradientStart: Color(0xFF2B4C9B),
      gradientEnd: Color(0xFF1B2C5E),
      radius: 0,
      borderWidth: 2,
      hardShadow: true,
      fontFamily: pixelFont,
      label: 'Gundam',
      emoji: '🤖',
    ),
  );

  // ---- Hello Kitty: soft pastel (Milky / Lilas / Pink / Strawberry) ------
  static final ThemeData _helloKitty = _build(
    primary: const Color(0xFFFF7199), // strawberry
    background: const Color(0xFFFDE6EE),
    colors: const PixelColors(
      income: Color(0xFF5BB98C),
      expense: Color(0xFFF0537E),
      textDark: Color(0xFF6E2B43),
      textMuted: Color(0xFFC77E97),
      outline: Color(0xFF6E2B43),
      accent: Color(0xFFFF4D86),
      surface: Colors.white,
      surfaceAlt: Color(0xFFFFE2EA), // lilas
      gradientStart: Color(0xFFFF8FB3),
      gradientEnd: Color(0xFFF0537E),
      radius: 0,
      borderWidth: 2,
      hardShadow: true,
      fontFamily: pixelFont,
      label: 'Hello Kitty',
      emoji: '🎀',
    ),
  );

  // ---- Original: the classic Material look (rounded, soft, Roboto) -------
  static final ThemeData _original = _build(
    primary: const Color(0xFF1565C0),
    background: const Color(0xFFF5F7FA),
    colors: const PixelColors(
      income: Color(0xFF4CAF50),
      expense: Color(0xFFF44336),
      textDark: Color(0xFF1A1A2E),
      textMuted: Color(0xFF6B7280),
      outline: Color(0xFFE0E0E0),
      accent: Color(0xFF26C6DA),
      surface: Colors.white,
      surfaceAlt: Color(0xFFEDF1F6),
      gradientStart: Color(0xFF1565C0),
      gradientEnd: Color(0xFF1E88E5),
      radius: 16,
      borderWidth: 0,
      hardShadow: false,
      fontFamily: null,
      label: 'Original',
      emoji: '💳',
    ),
  );

  // ---- Luxury "Old Money": heritage green + cream + antique gold, elegant
  //      serif, soft rounded. NOT pixelated — the only theme with a serif font
  //      and no hard shadow/border. -----------------------------------------
  static final ThemeData _luxury = _build(
    primary: const Color(0xFF2C5C4F), // deep heritage green ("old money")
    background: const Color(0xFFF1EBDD), // warm cream / ivory
    colors: const PixelColors(
      income: Color(0xFF4F7B5B), // muted sage
      expense: Color(0xFF8A3B36), // oxblood / burgundy
      textDark: Color(0xFF2A2620), // warm near-black
      textMuted: Color(0xFF8C826C), // taupe
      outline: Color(0xFFC9BC9C), // soft taupe/gold hairline
      accent: Color(0xFFB0894B), // antique gold / brass
      surface: Color(0xFFFBF6EC), // soft off-white card
      surfaceAlt: Color(0xFFE8DFC9), // sand
      gradientStart: Color(0xFF34685A), // forest
      gradientEnd: Color(0xFF1E4034), // deep pine
      radius: 14,
      borderWidth: 0,
      hardShadow: false,
      fontFamily: serifFont,
      label: "Luxury — Evan's Preferred",
      emoji: '🥂',
    ),
  );

  /// Shared theme builder. Reads the style knobs off [colors] so it can emit
  /// both the chunky pixel look and the soft Material look.
  static ThemeData _build({
    required Color primary,
    required Color background,
    required PixelColors colors,
  }) {
    // "Pixel" styling (chunky fonts/sizes + pixel text theme) is driven by the
    // hard-shadow knob, not merely by having a custom font — so the Luxury
    // theme can use a serif font while still rendering the soft Material look.
    final bool pixel = colors.hardShadow;
    final double r = colors.radius;
    final double bw = colors.borderWidth;
    final double cardElevation = colors.hardShadow ? 0 : 2;
    final bool isDark = background.computeLuminance() < 0.35;

    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: isDark ? Brightness.dark : Brightness.light,
    ).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      secondary: colors.accent,
      surface: colors.surface,
      onSurface: colors.textDark,
      onSurfaceVariant: colors.textMuted,
      outline: colors.outline,
    );

    BorderSide side([Color? c, double? w]) =>
        bw <= 0 ? BorderSide.none : BorderSide(color: c ?? colors.outline, width: w ?? bw);
    RoundedRectangleBorder shape([double? w]) => RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(r),
          side: side(null, w),
        );

    TextStyle? font(double size, {Color? color, double spacing = 0}) => TextStyle(
          fontFamily: colors.fontFamily,
          fontSize: size,
          height: 1.4,
          letterSpacing: spacing,
          color: color,
        );

    return ThemeData(
      useMaterial3: true,
      fontFamily: colors.fontFamily,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      dividerColor: pixel ? colors.outline : const Color(0xFFE3E7ED),
      extensions: [colors],
      textTheme: pixel ? _pixelTextTheme(colors.textDark) : null,
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: font(pixel ? 14 : 20, color: Colors.white, spacing: 0.5),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        elevation: cardElevation,
        shadowColor: isDark ? colors.accent.withValues(alpha: 0.6) : null,
        margin: EdgeInsets.zero,
        shape: shape(),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: pixel ? 0 : 1,
          shape: shape(),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          textStyle: font(pixel ? 11 : 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: font(pixel ? 9 : 14),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: pixel ? 0 : 4,
        shape: shape(bw <= 0 ? null : bw + 0.5),
        extendedTextStyle: font(pixel ? 11 : 15),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: colors.surface,
        indicatorColor: primary.withValues(alpha: pixel ? 0.18 : 0.14),
        indicatorShape: pixel ? shape(1.5) : null,
        elevation: 0,
        labelTextStyle: WidgetStatePropertyAll(
          font(pixel ? 8 : 12, color: colors.textDark),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surface,
        shape: shape(bw <= 0 ? null : bw + 0.5),
        titleTextStyle: font(pixel ? 13 : 18, color: colors.textDark),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? colors.surfaceAlt : colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r == 0 ? 0 : 12),
          borderSide: BorderSide(
              color: pixel ? colors.outline : const Color(0xFFE0E0E0),
              width: pixel ? 2 : 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r == 0 ? 0 : 12),
          borderSide: BorderSide(
              color: pixel ? colors.outline : const Color(0xFFE0E0E0),
              width: pixel ? 2 : 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r == 0 ? 0 : 12),
          borderSide: BorderSide(color: colors.accent, width: pixel ? 2.5 : 2),
        ),
        labelStyle: font(pixel ? 10 : 14, color: colors.textMuted),
        hintStyle: font(pixel ? 10 : 14, color: colors.textMuted),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.textDark,
        contentTextStyle: font(pixel ? 9 : 13, color: Colors.white),
      ),
    );
  }

  /// Press Start 2P is large and wide, so the text scale is dialed down and
  /// given generous line-height for legibility.
  static TextTheme _pixelTextTheme(Color textDark) {
    TextStyle s(double size) => TextStyle(fontSize: size, height: 1.4, color: textDark);
    return TextTheme(
      displayLarge: s(26),
      displayMedium: s(22),
      displaySmall: s(18),
      headlineLarge: s(18),
      headlineMedium: s(16),
      headlineSmall: s(14),
      titleLarge: s(15),
      titleMedium: s(12),
      titleSmall: s(10),
      bodyLarge: s(11),
      bodyMedium: s(10),
      bodySmall: s(9),
      labelLarge: s(10),
      labelMedium: s(9),
      labelSmall: s(8),
    ).apply(fontFamily: pixelFont);
  }
}
