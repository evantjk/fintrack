import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/balance_card.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/theme_switcher.dart';
import '../widgets/mascots.dart';
import '../theme/app_theme.dart';
import '../routes/app_routes.dart';
import 'transactions_screen.dart';
import 'statistics_screen.dart';
import 'categories_screen.dart';
import 'ai_insights_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void _goToTab(int index) => setState(() => _currentIndex = index);

  @override
  Widget build(BuildContext context) {
    final p = PixelColors.of(context);
    // Built here (not a const field) so the dashboard can receive a callback
    // to switch tabs — e.g. its "SEE ALL" button jumps to the Transactions tab.
    final pages = [
      _DashboardTab(onSeeAll: () => _goToTab(1)),
      const TransactionsScreen(),
      const StatisticsScreen(),
      const CategoriesScreen(),
      const AiInsightsScreen(),
    ];
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: p.hardShadow ? p.outline : const Color(0xFFE3E7ED),
              width: p.hardShadow ? 2 : 1,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (i) => setState(() => _currentIndex = i),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home'),
            NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'Transactions'),
            NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: 'Statistics'),
            NavigationDestination(
                icon: Icon(Icons.category_outlined),
                selectedIcon: Icon(Icons.category),
                label: 'Categories'),
            NavigationDestination(
                icon: Icon(Icons.auto_awesome_outlined),
                selectedIcon: Icon(Icons.auto_awesome),
                label: 'Insights'),
          ],
        ),
      ),
      floatingActionButton: _currentIndex == 0 || _currentIndex == 1
          ? FloatingActionButton.extended(
              onPressed: () => _openAddTransaction(context),
              icon: const Icon(Icons.add),
              label: const Text('ADD'),
            )
          : null,
    );
  }

  void _openAddTransaction(BuildContext context) {
    Navigator.pushNamed(context, AppRoutes.transactionForm);
  }
}

class _DashboardTab extends StatelessWidget {
  /// Called when the user taps "SEE ALL" — jumps to the Transactions tab.
  final VoidCallback onSeeAll;

  const _DashboardTab({required this.onSeeAll});

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text('You can sign back in any time.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log out'),
          ),
        ],
      ),
    );
    if (shouldLogout == true && context.mounted) {
      // The auth gate listens to authStateChanges() and returns to login.
      await context.read<AuthProvider>().signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = PixelColors.of(context);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ThemeMascot(size: 26, outline: Colors.white),
            const SizedBox(width: 8),
            const Text('FINTRACK'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Switch theme',
            icon: const Icon(Icons.palette_outlined),
            onPressed: () => showThemeSwitcher(context),
          ),
          IconButton(
            tooltip: 'Log out',
            icon: const Icon(Icons.logout),
            onPressed: () => _confirmLogout(context),
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () => provider.loadAll(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BalanceCard(
                    balance: provider.balance,
                    income: provider.totalIncome,
                    expense: provider.totalExpense,
                  ),
                  const _QuickActions(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'RECENT',
                          style: TextStyle(fontSize: 11, color: p.textDark),
                        ),
                        TextButton(
                          onPressed: onSeeAll,
                          child: const Text('SEE ALL'),
                        ),
                      ],
                    ),
                  ),
                  if (provider.recentTransactions.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            ThemeMascot(size: 72, outline: p.outline),
                            const SizedBox(height: 16),
                            Text(
                              'No transactions yet.\nTap + to add your first one.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: p.textMuted,
                                  fontSize: 9,
                                  height: 1.6),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    ...provider.recentTransactions.map((tx) {
                      final cat = provider.getCategoryById(tx.categoryId);
                      return TransactionTile(
                        transaction: tx,
                        category: cat,
                        onTap: () => Navigator.pushNamed(
                          context,
                          AppRoutes.transactionForm,
                          arguments: TransactionArgs(transaction: tx),
                        ),
                        onDelete: () =>
                            provider.deleteTransaction(tx.id!),
                      );
                    }),
                  const SizedBox(height: 80),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final p = PixelColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              label: 'INCOME',
              icon: Icons.add_circle_outline,
              color: p.income,
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.transactionForm,
                arguments: const TransactionArgs(initialType: 'income'),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _ActionButton(
              label: 'EXPENSE',
              icon: Icons.remove_circle_outline,
              color: p.expense,
              onTap: () => Navigator.pushNamed(
                context,
                AppRoutes.transactionForm,
                arguments: const TransactionArgs(initialType: 'expense'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = PixelColors.of(context);
    final bool pixel = p.hardShadow;
    return InkWell(
      onTap: onTap,
      borderRadius: p.br,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          // Surface card (adapts per theme) instead of a flat colour wash.
          color: p.surface,
          borderRadius: p.br,
          border: p.box(pixel ? p.outline : const Color(0xFFE3E7ED),
              pixel ? 2 : 1),
          boxShadow: pixel
              ? [BoxShadow(color: p.outline, offset: const Offset(3, 3))]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Tinted icon chip — circular for soft themes, square for pixel.
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: pixel ? BoxShape.rectangle : BoxShape.circle,
                border: Border.all(color: color, width: pixel ? 2 : 1.5),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Text(label,
                style: TextStyle(
                    color: color,
                    fontSize: pixel ? 9 : 14,
                    fontWeight: pixel ? null : FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
