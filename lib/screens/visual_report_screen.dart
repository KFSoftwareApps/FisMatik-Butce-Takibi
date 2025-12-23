import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';
import '../models/receipt_model.dart';
import '../core/app_theme.dart';
import '../services/supabase_database_service.dart';

class VisualReportScreen extends StatelessWidget {
  final DateTime month;

  const VisualReportScreen({super.key, required this.month});

  @override
  Widget build(BuildContext context) {
    final SupabaseDatabaseService databaseService = SupabaseDatabaseService();
    final formattedDate = DateFormat.yMMMM(Localizations.localeOf(context).toString()).format(month);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("$formattedDate - Rapor"),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textDark,
        elevation: 0,
      ),
      body: FutureBuilder<List<Receipt>>(
        future: databaseService.getMonthAnalysisData(month),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.data ?? [];
          if (data.isEmpty) return const Center(child: Text("Veri bulunamadı"));

          final total = data.fold(0.0, (s, e) => s + e.totalAmount);
          final categories = _calculateCategoryData(data);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTotalCard(context, total),
                const SizedBox(height: 24),
                Text("Harcama Dağılımı", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildPieChart(context, categories),
                const SizedBox(height: 32),
                Text("Kategori Detayları", style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildCategoryList(context, categories, total),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTotalCard(BuildContext context, double total) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.primary, Color(0xFF6A11CB)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          const Text("Toplam Gider", style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(total),
            style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(BuildContext context, Map<String, double> categories) {
    final sorted = categories.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final colors = [AppColors.primary, Colors.orange, Colors.green, Colors.red, Colors.purple, Colors.cyan];

    return Container(
      height: 200,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 40,
          sections: sorted.asMap().entries.map((entry) {
            final index = entry.key;
            final val = entry.value;
            return PieChartSectionData(
              color: colors[index % colors.length],
              value: val.value,
              title: '',
              radius: 50,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildCategoryList(BuildContext context, Map<String, double> categories, double total) {
    final sorted = categories.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    return Column(
      children: sorted.map((e) {
        final percent = (e.value / total * 100).toStringAsFixed(1);
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("% $percent"),
            trailing: Text(
              NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(e.value),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
    );
  }

  Map<String, double> _calculateCategoryData(List<Receipt> receipts) {
    final Map<String, double> data = {};
    for (final r in receipts) {
      data[r.category] = (data[r.category] ?? 0) + r.totalAmount;
    }
    return data;
  }
}
