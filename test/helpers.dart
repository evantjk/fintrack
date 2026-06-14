import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Initialises the FFI SQLite backend so the app's sqflite-based code (the
/// `DatabaseService`) runs inside the Dart test environment, and deletes any
/// existing test database so each run starts from the seeded default state.
///
/// Call this once per test file from `setUpAll`.
Future<void> initTestDatabase() async {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  final path = join(await databaseFactory.getDatabasesPath(), 'fintrack.db');
  try {
    await databaseFactory.deleteDatabase(path);
  } catch (_) {
    // No existing database to remove — fine.
  }
}
