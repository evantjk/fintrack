// Smoke test: confirms the dashboard/home screen renders.
//
// The real app entry (FinTrackApp) now boots Firebase and shows an auth gate,
// which can't run in a plain widget test without mocking Firebase. So this test
// mounts HomeScreen directly inside the same provider + theme setup the app
// uses, with an in-memory repository standing in for Firestore.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:fintrack/providers/transaction_provider.dart';
import 'package:fintrack/providers/theme_provider.dart';
import 'package:fintrack/providers/auth_provider.dart';
import 'package:fintrack/screens/home_screen.dart';
import 'package:fintrack/services/in_memory_repository.dart';
import 'package:fintrack/theme/app_theme.dart';

void main() {
  testWidgets('home screen renders', (tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(
            create: (_) =>
                TransactionProvider(InMemoryRepository())..loadAll(),
          ),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: MaterialApp(
          theme: AppTheme.themeFor(PixelThemeType.original),
          home: const HomeScreen(),
        ),
      ),
    );
    // Pump a few bounded frames to let the async loadAll() settle. We avoid
    // pumpAndSettle() because the loading CircularProgressIndicator animates
    // continuously, which would otherwise never let the scheduler go idle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
