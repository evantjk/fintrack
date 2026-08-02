import 'package:intl/intl.dart';

// Shows a number as Malaysian Ringgit (e.g. RM 1,250.00).
// Uses short form for very big numbers so the text still fits.
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
