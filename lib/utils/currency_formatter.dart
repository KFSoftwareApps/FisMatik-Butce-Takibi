import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String _currentCurrency = 'TRY';
  static String _currentLocale = 'tr_TR';
  static String _currentSymbol = '₺';

  static void updateCurrency(String code) {
    _currentCurrency = code;
    switch (code) {
      case 'USD':
        _currentLocale = 'en_US';
        _currentSymbol = '\$';
        break;
      case 'EUR':
        _currentLocale = 'de_DE';
        _currentSymbol = '€';
        break;
      case 'GBP':
        _currentLocale = 'en_GB';
        _currentSymbol = '£';
        break;
      case 'TRY':
      default:
        _currentLocale = 'tr_TR';
        _currentSymbol = '₺';
    }
    _updateFormatters();
  }

  static NumberFormat _currencyFormat = NumberFormat.currency(
    locale: _currentLocale,
    symbol: _currentSymbol,
    decimalDigits: 2,
  );

  static NumberFormat _decimalFormat = NumberFormat.decimalPattern(_currentLocale)
    ..maximumFractionDigits = 2
    ..minimumFractionDigits = 2;

  static void _updateFormatters() {
    _currencyFormat = NumberFormat.currency(
      locale: _currentLocale,
      symbol: _currentSymbol,
      decimalDigits: 2,
    );

    _decimalFormat = NumberFormat.decimalPattern(_currentLocale)
      ..maximumFractionDigits = 2
      ..minimumFractionDigits = 2;
  }

  /// Formats a double to a currency string (e.g., 1.250,50 ₺ or $1,250.50)
  static String format(double amount) {
    return _currencyFormat.format(amount);
  }

  /// Formats a double to a string with exactly 2 decimal places using active locale
  static String formatDecimal(double value) {
    return _decimalFormat.format(value);
  }

  static String get currencySymbol => _currentSymbol;
  static String get currencyCode => _currentCurrency;
}
