import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart';
import '../utils/currency_formatter.dart';

class WidgetService {
  static const String _groupId = 'group.fismatik.widget';
  static const String _widgetName = 'FismatikWidget';

  static Future<void> updateWidget({
    required double totalSpending,
    required double remainingBudget,
  }) async {
    // Using CurrencyFormatter

    try {
      await HomeWidget.saveWidgetData<String>(
        'total_spending',
        CurrencyFormatter.format(totalSpending),
      );
      await HomeWidget.saveWidgetData<String>(
        'remaining_budget',
        CurrencyFormatter.format(remainingBudget),
      );
      
      double limit = totalSpending + remainingBudget;
      if (limit <= 0) limit = 1; // Divide by zero guard
      int percent = ((totalSpending / limit) * 100).toInt().clamp(0, 100);

      await HomeWidget.saveWidgetData<int>('usage_percent', percent);
      
      final now = DateFormat('d MMMM, EEEE', 'tr_TR').format(DateTime.now());
      await HomeWidget.saveWidgetData<String>('current_date', now);
      
      // Phase 8: Deep links for quick actions
      // Bu veriler native (XML/Kotlin) tarafında PendingIntent için kullanılacak
      await HomeWidget.saveWidgetData<String>('scan_uri', 'fismatik://scan');
      
      await HomeWidget.updateWidget(
        name: _widgetName,
        androidName: _widgetName,
        iOSName: _widgetName,
        qualifiedAndroidName: 'com.fismatik.app.FismatikWidget',
      );
    } catch (e) {
      print('Error updating widget: $e');
    }
  }
}
