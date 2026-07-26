import 'package:intl/intl.dart';

String formatCurrency(double amount) {
  if (!amount.isFinite) return 'RM --';
  if (amount.abs() >= 1e15) {
    return 'RM ${amount.toStringAsExponential(2)}';
  }
  if (amount.abs() >= 1e9) {
    return NumberFormat.compactCurrency(
      locale: 'en_MY',
      symbol: 'RM ',
      decimalDigits: 2,
    ).format(amount);
  }
  return NumberFormat.currency(
    locale: 'en_MY', symbol: 'RM ').format(amount);
}
