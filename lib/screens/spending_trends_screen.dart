import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../models/receipt_model.dart';
import '../services/supabase_database_service.dart';
import '../utils/currency_formatter.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';

/// Harcama Trendleri Ekranı
/// Son 7 gün, 30 gün ve 12 ay için grafik gösterir
class SpendingTrendsScreen extends StatefulWidget {
  const SpendingTrendsScreen({super.key});

  @override
  State<SpendingTrendsScreen> createState() => _SpendingTrendsScreenState();
}

class _SpendingTrendsScreenState extends State<SpendingTrendsScreen> {
  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService();
  String _selectedPeriod = '7_days'; // '7_days', '30_days', '12_months'

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.spendingTrends),
        backgroundColor: AppColors.headerBackground,
        foregroundColor: AppColors.headerText,
      ),
      body: Column(
        children: [
          // Period Selector
          _buildPeriodSelector(),
          
          // Graph
          Expanded(
            child: StreamBuilder<List<Receipt>>(
              stream: _databaseService.getReceipts(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(AppLocalizations.of(context)!.noData),
                  );
                }

                final receipts = snapshot.data!;
                return _buildGraph(receipts);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          _buildPeriodButton('7_days', AppLocalizations.of(context)!.last7Days),
          _buildPeriodButton('30_days', AppLocalizations.of(context)!.last30Days),
          _buildPeriodButton('12_months', AppLocalizations.of(context)!.last12Months),
        ],
      ),
    );
  }

  Widget _buildPeriodButton(String period, String label) {
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedPeriod = period),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGraph(List<Receipt> receipts) {
    if (_selectedPeriod == '7_days') {
      return _build7DaysGraph(receipts);
    } else if (_selectedPeriod == '30_days') {
      return _build30DaysGraph(receipts);
    } else {
      return _build12MonthsGraph(receipts);
    }
  }

  Widget _build7DaysGraph(List<Receipt> receipts) {
    final now = DateTime.now();
    final data = <String, double>{};

    // Son 7 günü hazırla
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final key = DateFormat('dd/MM').format(date);
      data[key] = 0.0;
    }

    // Fişleri grupla
    for (var receipt in receipts) {
      final diff = now.difference(receipt.date).inDays;
      if (diff >= 0 && diff < 7) {
        final key = DateFormat('dd/MM').format(receipt.date);
        data[key] = (data[key] ?? 0) + receipt.totalAmount;
      }
    }

    return _buildLineChart(data, AppLocalizations.of(context)!.dailySpendingChart);
  }

  Widget _build30DaysGraph(List<Receipt> receipts) {
    final now = DateTime.now();
    final data = <String, double>{};

    // Son 30 günü 5'er günlük gruplara böl
    for (int i = 5; i >= 0; i--) {
      final startDate = now.subtract(Duration(days: (i + 1) * 5));
      final endDate = now.subtract(Duration(days: i * 5));
      final key = '${DateFormat('dd/MM').format(startDate)}-${DateFormat('dd/MM').format(endDate)}';
      data[key] = 0.0;
    }

    // Fişleri grupla
    for (var receipt in receipts) {
      final diff = now.difference(receipt.date).inDays;
      if (diff >= 0 && diff < 30) {
        final groupIndex = diff ~/ 5;
        final startDate = now.subtract(Duration(days: (groupIndex + 1) * 5));
        final endDate = now.subtract(Duration(days: groupIndex * 5));
        final key = '${DateFormat('dd/MM').format(startDate)}-${DateFormat('dd/MM').format(endDate)}';
        data[key] = (data[key] ?? 0) + receipt.totalAmount;
      }
    }

    return _buildBarChart(data, AppLocalizations.of(context)!.fiveDaySpendingChart);
  }

  Widget _build12MonthsGraph(List<Receipt> receipts) {
    final now = DateTime.now();
    final data = <String, double>{};

    // Son 12 ayı hazırla
    for (int i = 11; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final key = DateFormat('MMM', 'tr_TR').format(date);
      data[key] = 0.0;
    }

    // Fişleri grupla
    for (var receipt in receipts) {
      final diff = (now.year - receipt.date.year) * 12 + (now.month - receipt.date.month);
      if (diff >= 0 && diff < 12) {
        final key = DateFormat('MMM', 'tr_TR').format(receipt.date);
        data[key] = (data[key] ?? 0) + receipt.totalAmount;
      }
    }

    return _buildBarChart(data, AppLocalizations.of(context)!.monthlySpendingChart);
  }

  Widget _buildLineChart(Map<String, double> data, String title) {
    final spots = <FlSpot>[];
    final labels = data.keys.toList();
    
    for (int i = 0; i < labels.length; i++) {
      spots.add(FlSpot(i.toDouble(), data[labels[i]]!));
    }

    final maxY = data.values.isEmpty ? 100.0 : data.values.reduce((a, b) => a > b ? a : b) * 1.2;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          CurrencyFormatter.format(value),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              labels[index],
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: (labels.length - 1).toDouble(),
                minY: 0,
                maxY: maxY,
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.primary,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        return LineTooltipItem(
                          CurrencyFormatter.format(spot.y),
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: AppColors.primary,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.primary.withOpacity(0.1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(Map<String, double> data, String title) {
    final labels = data.keys.toList();
    final maxY = data.values.isEmpty ? 100.0 : data.values.reduce((a, b) => a > b ? a : b) * 1.2;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.primary,
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        CurrencyFormatter.format(rod.toY),
                        const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          CurrencyFormatter.format(value),
                          style: const TextStyle(fontSize: 10),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < labels.length) {
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              labels[index],
                              style: const TextStyle(fontSize: 9),
                              maxLines: 2,
                              textAlign: TextAlign.center,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY / 5,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(
                  labels.length,
                  (index) => BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: data[labels[index]]!,
                        color: AppColors.primary,
                        width: 16,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(6),
                          topRight: Radius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
