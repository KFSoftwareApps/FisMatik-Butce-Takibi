import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import '../utils/currency_formatter.dart';

class WidgetService {
  static const String _groupId = 'group.fismatik.widget';
  static const String _widgetName = 'FismatikWidget';

  static Future<void> updateWidget({
    required double totalSpending,
    required double remainingBudget,
  }) async {
    try {
      if (kDebugMode) {
        print('WidgetService: Updating with spending: $totalSpending, remaining: $remainingBudget');
      }

      await HomeWidget.saveWidgetData<String>(
        'total_spending',
        CurrencyFormatter.format(totalSpending),
      );
      await HomeWidget.saveWidgetData<String>(
        'remaining_budget',
        CurrencyFormatter.format(remainingBudget),
      );
      
      double limit = totalSpending + remainingBudget;
      if (limit <= 0) limit = 1;
      int percent = ((totalSpending / limit) * 100).toInt().clamp(0, 100);

      await HomeWidget.saveWidgetData<int>('usage_percent', percent);
      
      final now = DateFormat('d MMMM, EEEE', 'tr_TR').format(DateTime.now());
      await HomeWidget.saveWidgetData<String>('current_date', now);
      await HomeWidget.saveWidgetData<String>('scan_uri', 'fismatik://scan');
      
      final result = await HomeWidget.updateWidget(
        name: _widgetName,
        iOSName: _widgetName,
        androidName: _widgetName,
        qualifiedAndroidName: 'com.fismatik.app.FismatikWidget',
      );

      if (kDebugMode) {
        print('WidgetService: Update result: $result');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error updating widget: $e');
      }
    }
  }
}
