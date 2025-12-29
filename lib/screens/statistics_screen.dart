import 'package:fl_chart/fl_chart.dart';
import 'package:lottie/lottie.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../models/receipt_model.dart';
import '../services/supabase_database_service.dart';
import '../services/report_service.dart';
import '../services/auth_service.dart';
import '../widgets/web_ad_banner.dart';
import 'package:flutter/foundation.dart';
import '../utils/currency_formatter.dart';

import 'package:shared_preferences/shared_preferences.dart';
import 'upgrade_screen.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';

enum DateFilterType { daily, monthly, yearly, custom, salaryDay }

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService();
  int _touchedIndex = -1;
  DateFilterType _selectedFilter = DateFilterType.monthly;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  late Stream<List<Receipt>> _receiptsStream;
  Stream<Map<String, dynamic>>? _userSettingsStream;
  final AuthService _authService = AuthService();
  String _currentTierId = 'standart';
  double _budgetLimit = 0.0;

  @override
  void initState() {
    super.initState();
    _receiptsStream = _databaseService.getUnifiedReceiptsStream();
    _userSettingsStream = _databaseService.getUserSettings();
    _checkInitialFilter();
  }

  Future<void> _checkInitialFilter() async {
    final prefs = await SharedPreferences.getInstance();
    final filter = prefs.getString('selected_filter');
    if (filter == "Maaş Günü") {
       if (mounted) setState(() => _selectedFilter = DateFilterType.salaryDay);
    }
    
    final tier = await _authService.getCurrentTier();
    final budgetLimit = await _databaseService.getMonthlyLimit();

    if (mounted) {
      setState(() {
        _currentTierId = tier.id;
        // Initial value handled by StreamBuilder or awaited if needed.
        // For now, let's just initialize it to 0 or handle it later.
        // Since it's a Stream, we can't sync get it.
        // We will relay on StreamBuilder.
        _budgetLimit = 0.0; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    context.watch<CurrencyProvider>(); // Rebuilds when currency changes
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.statistics),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        child: const BackButton(color: AppColors.textDark),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share, color: AppColors.textDark),
            onPressed: () => _showExportOptions(context),
            tooltip: AppLocalizations.of(context)!.getReportTooltip,
          ),
        ],
      ),
      body: StreamBuilder<List<Receipt>>(
        stream: _receiptsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          return StreamBuilder<Map<String, dynamic>>(
            stream: _userSettingsStream,
            builder: (context, settingsSnapshot) {
              final settings = settingsSnapshot.data ?? {'salary_day': 1};
              final int salaryDay = settings['salary_day'] as int? ?? 1;

              final allReceipts = snapshot.data!;
              final receipts = _filterReceiptsByDate(allReceipts, salaryDay);
          
          final categoryData = _calculateCategoryData(receipts);
          final monthlyData = _calculateMonthlyData(receipts);
          
          // Özet verileri hesapla
          final totalSpending = receipts.fold(0.0, (sum, item) => sum + item.totalAmount);
          final totalSavings = receipts.fold(0.0, (sum, item) => sum + item.discountAmount);
          
          // Vergi hesaplama: Eğer taxAmount varsa kullan, yoksa %10 KDV hesapla
          final totalTax = receipts.fold(0.0, (sum, item) {
            if (item.taxAmount > 0) {
              return sum + item.taxAmount;
            } else {
              // KDV dahil fiyattan KDV'yi hesapla: Toplam / 1.10 * 0.10
              return sum + (item.totalAmount / 1.10 * 0.10);
            }
          });
          
          final taxData = _calculateTaxData(receipts);

          final topCategoryEntry = categoryData.entries.isEmpty 
              ? null 
              : categoryData.entries.reduce((a, b) => a.value > b.value ? a : b);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Filtre Çubukları
                _buildFilterBar(),
                const SizedBox(height: 20),
                  // Özet Kartları Row 1
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        title: AppLocalizations.of(context)!.totalSpending,
                        value: CurrencyFormatter.format(totalSpending),
                        icon: Icons.account_balance_wallet,
                        color: Colors.blue,
                        backgroundColor: Colors.blue.shade50,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        title: AppLocalizations.of(context)!.totalSavings,
                        value: CurrencyFormatter.format(totalSavings),
                        icon: Icons.savings,
                        color: Colors.green,
                        backgroundColor: Colors.green.shade50,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                 // Özet Kartları Row 2
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard(
                        title: AppLocalizations.of(context)!.taxPaid,
                        value: CurrencyFormatter.format(totalTax),
                        icon: Icons.receipt,
                        color: Colors.red,
                        backgroundColor: Colors.red.shade50,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildSummaryCard(
                        title: AppLocalizations.of(context)!.mostSpentCategory,
                        value: topCategoryEntry?.key ?? "-",
                        icon: Icons.category,
                        color: Colors.orange,
                        backgroundColor: Colors.orange.shade50,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Kategori Dağılımı Kartı
                _buildChartCard(
                  title: AppLocalizations.of(context)!.categoryDistribution,
                  child: _buildPieChart(categoryData, receipts),
                ),
                
                const SizedBox(height: 24),
                
                // Aylık Harcamalar Kartı
                _buildChartCard(
                  title: AppLocalizations.of(context)!.last6Months,
                  child: _buildBarChart(monthlyData),
                ),

                const SizedBox(height: 24),
                
                // --- FORECAST CARD (Faz 2) ---
                if (_selectedFilter == DateFilterType.monthly)
                  _buildForecastCard(receipts),
                
                if (_selectedFilter == DateFilterType.monthly)
                  const SizedBox(height: 24),

                const SizedBox(height: 24),

                // Vergi Grafiği
                _buildChartCard(
                  title: AppLocalizations.of(context)!.monthlyTax,
                  child: _buildBarChart(taxData, color: Colors.redAccent),
                ),

                const SizedBox(height: 24),

                // VERGİ DETAYLARI BÖLÜMÜ
                Text(
                  AppLocalizations.of(context)!.taxSection,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 16),

                // Vergi Kartları
                Row(
                  children: [
                    Expanded(
                      child: _buildTaxCard(
                        title: AppLocalizations.of(context)!.dailyTax,
                        amount: _calculateDailyTax(receipts),
                        icon: Icons.today,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTaxCard(
                        title: AppLocalizations.of(context)!.monthlyTax,
                        amount: _calculateMonthlyTax(receipts),
                        icon: Icons.calendar_month,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildTaxCard(
                        title: AppLocalizations.of(context)!.yearlyTax,
                        amount: _calculateYearlyTax(receipts),
                        icon: Icons.calendar_today,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildTaxCard(
                        title: AppLocalizations.of(context)!.totalSavings,
                        amount: totalSavings,
                        icon: Icons.savings,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),

                if (kIsWeb && _currentTierId == 'standart')
                  const Center(
                    child: WebAdBanner(
                      adSlot: '7909719452',
                      width: 728,
                      height: 90,
                    ),
                  ),

                const SizedBox(height: 20),
              ],
            ),
          );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.asset(
            'assets/lottie/empty.json',
            width: 250,
            height: 250,
            errorBuilder: (context, error, stackTrace) {
               return Icon(Icons.bar_chart, size: 80, color: Colors.grey.shade300);
            },
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)!.noData,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color backgroundColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  // --- PASTA GRAFİK ---
  Widget _buildPieChart(Map<String, double> data, List<Receipt> receipts) {
    if (data.isEmpty || data.values.every((e) => e == 0)) {
      return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.pie_chart_outline, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.noDataForPeriod,
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    final List<Color> colors = [
      const Color(0xFF5C6BC0), // Indigo
      const Color(0xFFEF5350), // Red
      const Color(0xFF66BB6A), // Green
      const Color(0xFFFFA726), // Orange
      const Color(0xFFAB47BC), // Purple
      const Color(0xFF26A69A), // Teal
      const Color(0xFFEC407A), // Pink
      const Color(0xFF78909C), // Blue Grey
    ];

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PieChart(
            PieChartData(
              pieTouchData: PieTouchData(
                touchCallback: (FlTouchEvent event, pieTouchResponse) {
                  setState(() {
                    if (!event.isInterestedForInteractions ||
                        pieTouchResponse == null ||
                        pieTouchResponse.touchedSection == null) {
                      _touchedIndex = -1;
                      return;
                    }
                    _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                  });
                },
              ),
              borderData: FlBorderData(show: false),
              sectionsSpace: 2,
              centerSpaceRadius: 40,
              sections: List.generate(data.length, (i) {
                final isTouched = i == _touchedIndex;
                final fontSize = isTouched ? 20.0 : 14.0;
                final radius = isTouched ? 60.0 : 50.0;
                final entry = data.entries.elementAt(i);
                final color = colors[i % colors.length];
                final total = data.values.reduce((a, b) => a + b);
                final percentage = (entry.value / total * 100).toStringAsFixed(0);

                return PieChartSectionData(
                  color: color,
                  value: entry.value,
                  title: '$percentage%',
                  radius: radius,
                  titleStyle: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: const [Shadow(color: Colors.black26, blurRadius: 2)],
                  ),
                );
              }),
            ),
          ),
        ),
        if (_touchedIndex != -1) ...[
          const SizedBox(height: 24),
          _buildCategoryDetails(data.keys.elementAt(_touchedIndex), receipts),
        ],
      ],
    );
  }

  Widget _buildCategoryDetails(String categoryName, List<Receipt> receipts) {
    final categoryReceipts = receipts.where((r) => r.category == categoryName).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    // Using CurrencyFormatter

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$categoryName Detayları",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 12),
        ...categoryReceipts.take(5).map((r) => ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.receipt, size: 20, color: AppColors.primary),
          title: Text(r.merchantName),
          subtitle: Text(DateFormat('dd MMM yyyy', 'tr_TR').format(r.date)),
          trailing: Text(CurrencyFormatter.format(r.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
        )),
        if (categoryReceipts.length > 5)
          Center(
            child: TextButton(
              onPressed: () {
                // Navigate to search or history filtered by category
              },
              child: const Text("Tümünü Gör"),
            ),
          ),
      ],
    );
  }

  // --- ÇUBUK GRAFİK ---
  Widget _buildBarChart(Map<String, double> data, {Color color = AppColors.primary}) {
    if (data.isEmpty || data.values.every((e) => e == 0)) {
       return SizedBox(
        height: 200,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.bar_chart, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!.noDataForPeriod,
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    final keys = data.keys.toList();
    final values = data.values.toList();
    final maxY = values.isEmpty ? 100.0 : values.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY * 1.2,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.blueGrey,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${keys[group.x.toInt()]}\n',
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  children: [
                    TextSpan(
                      text: CurrencyFormatter.format(rod.toY),
                      style: const TextStyle(color: Colors.yellow, fontWeight: FontWeight.bold),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  if (value.toInt() >= 0 && value.toInt() < keys.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        keys[value.toInt()],
                        style: const TextStyle(
                          fontSize: 10, 
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  }
                  return const Text('');
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 0 ? maxY / 5 : 1,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.1),
                strokeWidth: 1,
              );
            },
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(data.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i],
                  color: color,
                  width: 12,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY * 1.2,
                    color: Colors.grey.withOpacity(0.05),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  // --- HESAPLAMALAR ---
  Map<String, double> _calculateCategoryData(List<Receipt> receipts) {
    final Map<String, double> data = {};
    for (var receipt in receipts) {
      data[receipt.category] = (data[receipt.category] ?? 0) + receipt.totalAmount;
    }
    return data;
  }

  Map<String, double> _calculateMonthlyData(List<Receipt> receipts) {
    final Map<String, double> data = {};
    final now = DateTime.now();
    
    // Son 6 ayı hazırla
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final key = DateFormat('MMM', 'tr_TR').format(date);
      data[key] = 0.0;
    }

    for (var receipt in receipts) {
      final diff = now.difference(receipt.date).inDays;
      if (diff < 180) {
        final key = DateFormat('MMM', 'tr_TR').format(receipt.date);
        if (data.containsKey(key)) {
          data[key] = data[key]! + receipt.totalAmount;
        }
      }
    }
    return data;
  }

  Map<String, double> _calculateTaxData(List<Receipt> receipts) {
    final Map<String, double> data = {};
    final now = DateTime.now();
    
    // Son 6 ayı hazırla
    for (int i = 5; i >= 0; i--) {
      final date = DateTime(now.year, now.month - i, 1);
      final key = DateFormat('MMM', 'tr_TR').format(date);
      data[key] = 0.0;
    }

    for (var receipt in receipts) {
      final diff = now.difference(receipt.date).inDays;
      if (diff < 180) {
        final key = DateFormat('MMM', 'tr_TR').format(receipt.date);
        if (data.containsKey(key)) {
          // Eğer taxAmount varsa kullan, yoksa %10 KDV hesapla
          final tax = receipt.taxAmount > 0 
              ? receipt.taxAmount 
              : (receipt.totalAmount / 1.10 * 0.10);
          data[key] = data[key]! + tax;
        }
      }
    }
    return data;
  }

  Widget _buildFilterBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip(
            label: AppLocalizations.of(context)!.daily,
            filterType: DateFilterType.daily,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: AppLocalizations.of(context)!.monthly,
            filterType: DateFilterType.monthly,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: AppLocalizations.of(context)!.yearly,
            filterType: DateFilterType.yearly,
          ),
          const SizedBox(width: 8),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: AppLocalizations.of(context)!.custom,
            filterType: DateFilterType.custom,
          ),
          const SizedBox(width: 8),
          _buildFilterChip(
            label: AppLocalizations.of(context)!.salaryDay,
            filterType: DateFilterType.salaryDay,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required DateFilterType filterType,
  }) {
    final isSelected = _selectedFilter == filterType;
    return GestureDetector(
      onTap: () async {
        if (filterType == DateFilterType.custom) {
          await _showCustomDatePicker();
        } else {
          setState(() {
            _selectedFilter = filterType;
            _customStartDate = null;
            _customEndDate = null;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade300,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.textDark,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Future<void> _showCustomDatePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _customStartDate != null && _customEndDate != null
          ? DateTimeRange(start: _customStartDate!, end: _customEndDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedFilter = DateFilterType.custom;
        _customStartDate = picked.start;
        _customEndDate = picked.end;
      });
    }
  }

  List<Receipt> _filterReceiptsByDate(List<Receipt> receipts, int salaryDay) {
    final now = DateTime.now();
    
    switch (_selectedFilter) {
      case DateFilterType.daily:
        final today = DateTime(now.year, now.month, now.day);
        return receipts.where((r) {
          final receiptDate = DateTime(r.date.year, r.date.month, r.date.day);
          return receiptDate.isAtSameMomentAs(today);
        }).toList();
        
      case DateFilterType.monthly:
        return receipts.where((r) {
          return r.date.year == now.year && r.date.month == now.month;
        }).toList();
        
      case DateFilterType.yearly:
        return receipts.where((r) {
          return r.date.year == now.year;
        }).toList();
        
      case DateFilterType.custom:
        if (_customStartDate == null || _customEndDate == null) {
          return receipts;
        }
        return receipts.where((r) {
          return r.date.isAfter(_customStartDate!.subtract(const Duration(days: 1))) &&
                 r.date.isBefore(_customEndDate!.add(const Duration(days: 1)));
        }).toList();

      case DateFilterType.salaryDay:
        DateTime startDate, endDate;
        if (now.day >= salaryDay) {
          startDate = DateTime(now.year, now.month, salaryDay);
          endDate = DateTime(now.year, now.month + 1, salaryDay).subtract(const Duration(seconds: 1));
        } else {
          startDate = DateTime(now.year, now.month - 1, salaryDay);
          endDate = DateTime(now.year, now.month, salaryDay).subtract(const Duration(seconds: 1));
        }
        return receipts.where((r) {
          return r.date.isAfter(startDate.subtract(const Duration(seconds: 1))) && 
                 r.date.isBefore(endDate.add(const Duration(seconds: 1)));
        }).toList();
    }
  }

  // --- VERGİ HESAPLAMA YÖNTEMLERİ ---
  double _calculateDailyTax(List<Receipt> receipts) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return receipts.where((r) {
      final receiptDate = DateTime(r.date.year, r.date.month, r.date.day);
      return receiptDate.isAtSameMomentAs(today);
    }).fold(0.0, (sum, r) {
    // Eğer taxAmount varsa kullan, yoksa %10 KDV hesapla
    final tax = r.taxAmount > 0 ? r.taxAmount : (r.totalAmount / 1.10 * 0.10);
    return sum + tax;
  });
  }

  double _calculateMonthlyTax(List<Receipt> receipts) {
    final now = DateTime.now();
    return receipts.where((r) {
      return r.date.year == now.year && r.date.month == now.month;
    }).fold(0.0, (sum, r) {
    // Eğer taxAmount varsa kullan, yoksa %10 KDV hesapla
    final tax = r.taxAmount > 0 ? r.taxAmount : (r.totalAmount / 1.10 * 0.10);
    return sum + tax;
  });
  }

  double _calculateYearlyTax(List<Receipt> receipts) {
    final now = DateTime.now();
    return receipts.where((r) {
      return r.date.year == now.year;
    }).fold(0.0, (sum, r) {
    // Eğer taxAmount varsa kullan, yoksa %10 KDV hesapla
    final tax = r.taxAmount > 0 ? r.taxAmount : (r.totalAmount / 1.10 * 0.10);
    return sum + tax;
  });
  }

  // --- VERGİ KARTI WİDGET ---
  Widget _buildTaxCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
              Icon(Icons.trending_up, color: color.withOpacity(0.5), size: 16),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            CurrencyFormatter.format(amount),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  void _showExportOptions(BuildContext context) {
    if (_currentTierId == 'standart') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const UpgradeScreen()),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.reports,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf, color: Colors.red),
                  title: Text(AppLocalizations.of(context)!.downloadPdfAndShare),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _generateReport(isPdf: true);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.table_chart, color: Colors.green),
                  title: Text(AppLocalizations.of(context)!.downloadExcelAndShare),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _generateReport(isPdf: false);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _generateReport({required bool isPdf}) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.preparingReport)),
      );

      // Mevcut filtreye göre verileri çek
      final allReceipts = await _databaseService.getMonthAnalysisData(DateTime.now());
      
      // Ayarları çek
      final settings = await _databaseService.getUserSettings().first;
      final int salaryDay = settings['salary_day'] as int? ?? 1;

      final filteredReceipts = _filterReceiptsByDate(allReceipts, salaryDay);

      if (filteredReceipts.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.noReportData)),
          );
        }
        return;
      }

      final reportService = ReportService();
      
      if (isPdf) {
        DateTime start = filteredReceipts.last.date;
        DateTime end = filteredReceipts.first.date;
        await reportService.generateAndSharePdfReport(filteredReceipts, start, end, title: AppLocalizations.of(context)!.statistics);
      } else {
        await reportService.generateAndShareExcelReport(filteredReceipts);
      }
    } catch (e) {
      debugPrint("Rapor hatası: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.errorPrefix(e.toString()))),
        );
      }
    }
  }

  // --- BÜTÇE TAHMİNİ (FORECAST) ---
  Widget _buildForecastCard(List<Receipt> receipts) {
    // Sadece mevcut ayı görüntülüyorsak çalışır (basitlik için şimdilik)
    final now = DateTime.now();
    final totalSpent = receipts.fold(0.0, (sum, item) => sum + item.totalAmount);
    
    // Basit projeksiyon: (Harcama / Geçen Gün) * Ayın Toplam Günü
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final currentDay = now.day;
    
    // Eğer ayın başındaysak (ilk gün) henüz tahmin yapmak zor, o anki harcamayı al
    double dailyAverage = currentDay > 0 ? totalSpent / currentDay : 0;
    double projectedTotal = dailyAverage * daysInMonth;

    // Bütçe aşımı kontrolü
    bool isOverBudget = _budgetLimit > 0 && projectedTotal > _budgetLimit;
    String message = AppLocalizations.of(context)!.budgetForecastMessage(
        CurrencyFormatter.format(projectedTotal));
        
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isOverBudget ? Colors.red.shade100 : Colors.green.shade100, width: 2),
        boxShadow: [
          BoxShadow(
            color: (isOverBudget ? Colors.red : Colors.green).withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isOverBudget ? Colors.red.shade50 : Colors.green.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.auto_graph, 
                  color: isOverBudget ? Colors.red : Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.budgetForecastTitle,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      isOverBudget 
                          ? AppLocalizations.of(context)!.overBudgetMessage 
                          : AppLocalizations.of(context)!.onTrackMessage,
                      style: TextStyle(
                        fontSize: 12, 
                        color: isOverBudget ? Colors.red : Colors.green,
                        fontWeight: FontWeight.w600
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: AppColors.textDark, fontSize: 14),
          ),
          const SizedBox(height: 12),
          // Progress bar
          Stack(
            children: [
              Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              if (_budgetLimit > 0)
                LayoutBuilder(
                  builder: (context, constraints) {
                    double percentage = (projectedTotal / _budgetLimit).clamp(0.0, 1.0);
                    return Container(
                      height: 8,
                      width: constraints.maxWidth * percentage,
                      decoration: BoxDecoration(
                        color: isOverBudget ? Colors.red : Colors.green,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  },
                ),
            ],
          ),
          if (_budgetLimit > 0)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "${AppLocalizations.of(context)!.totalSpending}: ${CurrencyFormatter.format(totalSpent)}",
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                  Text(
                    "${AppLocalizations.of(context)!.monthlyLimit}: ${CurrencyFormatter.format(_budgetLimit)}",
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
