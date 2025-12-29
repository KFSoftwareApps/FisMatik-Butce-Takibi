import 'package:flutter/material.dart';
import '../utils/currency_formatter.dart';
import '../services/profile_service.dart';

class CurrencyProvider with ChangeNotifier {
  String _currencyCode = 'TRY';
  
  String get currencyCode => _currencyCode;

  Future<void> init() async {
    try {
      final profile = await ProfileService().getMyProfileOnce();
      if (profile != null) {
        setCurrency(profile.currency, notify: false);
      }
    } catch (e) {
      debugPrint("Currency initialization error: $e");
    }
  }

  void setCurrency(String code, {bool notify = true}) {
    if (_currencyCode == code) return;
    _currencyCode = code;
    CurrencyFormatter.updateCurrency(code);
    if (notify) {
      notifyListeners();
    }
  }
}
