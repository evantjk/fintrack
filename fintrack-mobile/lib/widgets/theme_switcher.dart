import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import 'mascots.dart';

/// Opens a pixel-styled bottom sheet to pick between the Gundam and
/// Hello Kitty themes.
Future<void> showThemeSwitcher(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ThemeSwitcherSheet(),
  );
}

class _ThemeSwitcherSheet extends StatelessWidget {
  const _ThemeSwitcherSheet();

  @override
  Widget build(BuildContext context) {
    final p = PixelColors.of(context);
    final provider = context.watch<ThemeProvider>();

    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: p.radius == 0 ? null : BorderRadius.circular(20),
        border: p.box(p.outline, p.borderWidth == 0 ? 0 : 3),
        boxShadow: p.shadow(p.hardShadow ? p.outline : Colors.black, offset: 5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SELECT THEME',
              style: TextStyle(
                  fontSize: 12, color: p.textDark, letterSpacing: 1)),
          const SizedBox(height: 16),
          _ThemeOption(
            type: PixelThemeType.original,
            label: 'Original',
            swatches: const [
              Color(0xFF1565C0),
              Color(0xFF26C6DA),
              Color(0xFF4CAF50),
            ],
            selected: provider.current == PixelThemeType.original,
            onTap: () {
              provider.setTheme(PixelThemeType.original);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 12),
          _ThemeOption(
            type: PixelThemeType.gundam,
            label: 'Gundam',
            swatches: const [
              Color(0xFF2B4C9B),
              Color(0xFFE03A2F),
              Color(0xFFF2C14E),
            ],
            selected: provider.current == PixelThemeType.gundam,
            onTap: () {
              provider.setTheme(PixelThemeType.gundam);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 12),
          _ThemeOption(
            type: PixelThemeType.helloKitty,
            label: 'Hello Kitty',
            swatches: const [
              Color(0xFFFF7199),
              Color(0xFFFFBAD9),
              Color(0xFFFBF8E9),
            ],
            selected: provider.current == PixelThemeType.helloKitty,
            onTap: () {
              provider.setTheme(PixelThemeType.helloKitty);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 12),
          _ThemeOption(
            type: PixelThemeType.luxury,
            label: "Luxury — Evan's Preferred",
            swatches: const [
              Color(0xFF2C5C4F), // heritage green
              Color(0xFFB0894B), // antique gold
              Color(0xFFF1EBDD), // cream
            ],
            selected: provider.current == PixelThemeType.luxury,
            onTap: () {
              provider.setTheme(PixelThemeType.luxury);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final PixelThemeType type;
  final String label;
  final List<Color> swatches;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.type,
    required this.label,
    required this.swatches,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = PixelColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? p.accent.withValues(alpha: 0.12) : p.surface,
          borderRadius: p.radius == 0 ? null : BorderRadius.circular(14),
          border: Border.all(
            color: selected ? p.accent : (p.borderWidth == 0 ? const Color(0xFFE0E0E0) : p.outline),
            width: selected ? 3 : 2,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 38,
              height: 38,
              child: switch (type) {
                PixelThemeType.gundam => GundamMascot(size: 38, outline: p.outline),
                PixelThemeType.helloKitty =>
                  HelloKittyMascot(size: 38, outline: p.outline),
                PixelThemeType.original => Icon(
                    Icons.account_balance_wallet_rounded,
                    size: 32,
                    color: p.textDark),
                PixelThemeType.luxury =>
                  // Always antique gold so the crest reads as luxury regardless
                  // of the currently active theme.
                  const LuxuryMascot(size: 36, outline: Color(0xFFB0894B)),
              },
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(fontSize: 11, color: p.textDark)),
            ),
            Row(
              children: swatches
                  .map((c) => Container(
                        width: 16,
                        height: 16,
                        margin: const EdgeInsets.only(left: 4),
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius:
                              p.radius == 0 ? null : BorderRadius.circular(4),
                          border: Border.all(color: p.outline, width: 1.5),
                        ),
                      ))
                  .toList(),
            ),
            if (selected) ...[
              const SizedBox(width: 10),
              Icon(Icons.check_box, color: p.accent, size: 20),
            ],
          ],
        ),
      ),
    );
  }
}
