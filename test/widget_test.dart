// Smoke test: boots the full app and confirms the home screen renders.
//
// FinTrackApp builds a TransactionProvider that calls loadAll(), which hits the
// sqflite database. initTestDatabase() points sqflite at the FFI backend so this
// runs in the Dart test environment rather than on a device.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fintrack/main.dart';
import 'package:fintrack/screens/home_screen.dart';

import 'helpers.dart';

void main() {
  setUpAll(() async {
    await initTestDatabase();
  });

  testWidgets('app boots and shows the home screen', (tester) async {
    await tester.pumpWidget(const FinTrackApp());
    // Pump a few bounded frames to let the async loadAll() settle. We avoid
    // pumpAndSettle() because the loading CircularProgressIndicator animates
    // continuously, which would otherwise never let the scheduler go idle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(FinTrackApp), findsOneWidget);
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
