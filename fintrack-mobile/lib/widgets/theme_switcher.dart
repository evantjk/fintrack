import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/check_in_provider.dart';
import '../providers/theme_provider.dart';
import '../theme/app_theme.dart';
import 'mascots.dart';

/// Opens a pixel-styled bottom sheet to pick between the Gundam and
/// Hello Kitty themes.
Future<void> showThemeSwitcher(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => const _ThemeSwitcherSheet(),
  );
}

class _ThemeSwitcherSheet extends StatelessWidget {
  const _ThemeSwitcherSheet();

  @override
  Widget build(BuildContext context) {
    final p = PixelColors.of(context);
    final themeProvider = context.watch<ThemeProvider>();
    final rewards = context.watch<CheckInProvider>();

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
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: p.outline,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Theme Gallery',
                  style: TextStyle(
                    fontSize: p.hardShadow ? 12 : 18,
                    color: p.textDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: p.br,
                ),
                child: Text(
                  '${rewards.availableXp} XP Available',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Close',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: p.br,
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_outlined,
                  color: Theme.of(context).colorScheme.primary,
                  size: 18,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Earn more XP by checking in daily, then exchange it for premium themes.',
                    style: TextStyle(color: p.textDark, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...CheckInProvider.rewardThemes.map(
            (theme) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ThemeOption(
                rewardTheme: theme,
                selected: themeProvider.current == theme.type,
                owned: rewards.ownsTheme(theme.type),
                canAfford: rewards.canAfford(theme),
                onTap: () => _selectTheme(context, theme),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _selectTheme(BuildContext context, RewardTheme theme) async {
    final rewards = context.read<CheckInProvider>();
    final themeProvider = context.read<ThemeProvider>();

    if (rewards.ownsTheme(theme.type)) {
      await rewards.unlockTheme(theme);
      themeProvider.setTheme(theme.type);
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('${theme.name} Theme Applied.')));
      return;
    }

    if (!rewards.canAfford(theme)) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: const Icon(Icons.error_outline, size: 36),
          title: const Text('Not Enough XP', textAlign: TextAlign.center),
          content: const Text(
            'Complete more daily check-ins to unlock this theme.',
            textAlign: TextAlign.center,
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('OK'),
              ),
            ),
          ],
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ThemeDialogIcon(theme: theme),
            const SizedBox(height: 18),
            Text(
              'Unlock ${theme.name} Theme?',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: PixelColors.of(context).textDark,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(theme.description, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            _CostRow(label: 'Theme Cost', value: '${theme.cost} XP'),
            const SizedBox(height: 8),
            _CostRow(
              label: 'Available Balance',
              value: '${rewards.availableXp} XP',
              outlined: true,
            ),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Unlock Theme'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;
    if (await rewards.unlockTheme(theme)) {
      themeProvider.setTheme(theme.type);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${theme.name} Theme Unlocked and Applied.')),
      );
    }
  }
}

class _ThemeOption extends StatelessWidget {
  final RewardTheme rewardTheme;
  final bool selected;
  final bool owned;
  final bool canAfford;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.rewardTheme,
    required this.selected,
    required this.owned,
    required this.canAfford,
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
            color: selected
                ? p.accent
                : (p.borderWidth == 0 ? const Color(0xFFE0E0E0) : p.outline),
            width: selected ? 3 : 2,
          ),
        ),
        child: Row(
          children: [
            _ThemeIcon(type: rewardTheme.type, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rewardTheme.name,
                    style: TextStyle(
                      fontSize: p.hardShadow ? 10 : 14,
                      color: p.textDark,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    rewardTheme.description,
                    style: TextStyle(
                      fontSize: p.hardShadow ? 8 : 11,
                      color: p.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: selected
                    ? p.accent.withValues(alpha: 0.16)
                    : p.surfaceAlt,
                borderRadius: p.br,
              ),
              child: Text(
                selected
                    ? 'Active'
                    : owned
                    ? 'Apply'
                    : canAfford
                    ? '${rewardTheme.cost} XP'
                    : 'Locked',
                style: TextStyle(
                  color: selected
                      ? p.accent
                      : owned || canAfford
                      ? p.textDark
                      : p.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
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

class _ThemeIcon extends StatelessWidget {
  final PixelThemeType type;
  final double size;

  const _ThemeIcon({required this.type, required this.size});

  @override
  Widget build(BuildContext context) {
    final p = PixelColors.of(context);
    return SizedBox(
      width: size,
      height: size,
      child: switch (type) {
        PixelThemeType.gundam => GundamMascot(size: size, outline: p.outline),
        PixelThemeType.helloKitty => HelloKittyMascot(
          size: size,
          outline: p.outline,
        ),
        PixelThemeType.original => Icon(
          Icons.account_balance_wallet_rounded,
          size: size * 0.84,
          color: p.textDark,
        ),
        PixelThemeType.luxury => Icon(
          Icons.waves_rounded,
          size: size * 0.82,
          color: const Color(0xFF2C7A7B),
        ),
      },
    );
  }
}

class _CostRow extends StatelessWidget {
  final String label;
  final String value;
  final bool outlined;

  const _CostRow({
    required this.label,
    required this.value,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = PixelColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: outlined ? p.surface : p.surfaceAlt,
        borderRadius: p.br,
        border: outlined
            ? Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.18),
              )
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: p.textMuted,
                fontSize: p.hardShadow ? 8 : 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: p.textDark,
                fontWeight: FontWeight.w800,
                fontSize: p.hardShadow ? 8 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemeDialogIcon extends StatelessWidget {
  final RewardTheme theme;

  const _ThemeDialogIcon({required this.theme});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: primary.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Center(child: _ThemeIcon(type: theme.type, size: 38)),
    );
  }
}