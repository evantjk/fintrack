import '../models/transaction.dart';

/// Centralised route names for the app.
///
/// Keeping the route names in one place (instead of scattering raw strings
/// across `Navigator.pushNamed` calls) is the "centralise the routing code"
/// idea from the Navigation & Routing lecture — screens are referenced by a
/// stable alias, so a screen can be renamed or rebuilt without hunting through
/// every caller.
class AppRoutes {
  AppRoutes._(); // no instances — this is just a namespace for the constants.

  static const String login = '/login';
  static const String signup = '/signup';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';

  /// The shared add / edit transaction screen. Receives a [TransactionArgs] via
  /// the route's `arguments` parameter.
  static const String transactionForm = '/transaction-form';
}

/// Wraps the data passed to the add / edit transaction route.
///
/// The lecture's recommended way to pass more than one value to a named route
/// is to bundle the values in a single object and send it through `arguments`,
/// rather than passing several loose values — that is exactly what this does
/// ([transaction] when editing, [initialType] when pre-selecting income/expense
/// for a brand-new entry).
class TransactionArgs {
  /// The transaction being edited, or `null` when adding a new one.
  final Transaction? transaction;

  /// Pre-selected type ('income' / 'expense') for a new transaction.
  final String? initialType;

  const TransactionArgs({this.transaction, this.initialType});
}
