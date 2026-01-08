import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';
import '../services/supabase_database_service.dart';
import '../models/receipt_model.dart';
import '../core/app_theme.dart';
import '../services/report_service.dart';
import 'visual_report_screen.dart';
import 'upgrade_screen.dart';
import 'receipt_detail_screen.dart';
import '../utils/currency_formatter.dart';

class MonthDetailScreen extends StatelessWidget {
  final DateTime month;

  const MonthDetailScreen({super.key, required this.month});

  @override
  Widget build(BuildContext context) {
    final SupabaseDatabaseService databaseService = SupabaseDatabaseService();
    final formattedDate = DateFormat.yMMMM(Localizations.localeOf(context).toString()).format(month);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(formattedDate),
        backgroundColor: AppColors.headerBackground,
        foregroundColor: AppColors.headerText,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _showReportOptions(context, month),
          ),
        ],
      ),
      body: FutureBuilder<List<Receipt>>(
        future: databaseService.getMonthAnalysisData(month),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(AppLocalizations.of(context)!.errorPrefix(snapshot.error.toString())));
          }

          final receipts = snapshot.data ?? [];

          if (receipts.isEmpty) {
            return Center(child: Text(AppLocalizations.of(context)!.noData));
          }

          final totalSpending = receipts.fold(0.0, (sum, item) => sum + item.totalAmount);

          return Column(
            children: [
              // Özet Kartı
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.totalSpending,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      CurrencyFormatter.format(totalSpending),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Fiş Listesi
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: receipts.length,
                  itemBuilder: (context, index) {
                    final receipt = receipts[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: Icon(
                            receipt.isManual ? Icons.edit_note : Icons.receipt_long,
                            color: AppColors.primary,
                          ),
                        ),
                        title: Text(
                          receipt.merchantName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          DateFormat('dd MMM yyyy', Localizations.localeOf(context).toString()).format(receipt.date),
                        ),
                        trailing: Text(
                          CurrencyFormatter.format(receipt.totalAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.text,
                          ),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReceiptDetailScreen(receipt: receipt),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showReportOptions(BuildContext context, DateTime month) async {
    final SupabaseDatabaseService databaseService = SupabaseDatabaseService();
    final tier = await databaseService.getUserTierStream().first;
    final isPremium = tier != 'standart';

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppLocalizations.of(context)!.reports,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildReportOption(
              context,
              icon: Icons.bar_chart,
              title: "Görsel Rapor",
              subtitle: "Pasta ve Sütun Grafikleriyle Analiz",
              isPremium: isPremium,
            onTap: () {
                Navigator.pop(context);
                if (isPremium) {
                   Navigator.push(context, MaterialPageRoute(builder: (_) => VisualReportScreen(month: month)));
                } else {
                  _showUpgradeDialog(context);
                }
              },
            ),
            const SizedBox(height: 12),
            _buildReportOption(
              context,
              icon: Icons.picture_as_pdf,
              title: "PDF Raporu",
              subtitle: "Detaylı harcama dökümü indirin",
              isPremium: isPremium,
              onTap: () {
                Navigator.pop(context);
                if (isPremium) {
                   _generatePdf(context, month);
                } else {
                  _showUpgradeDialog(context);
                }
              },
            ),
            const SizedBox(height: 12),
            _buildReportOption(
              context,
              icon: Icons.table_chart,
              title: "Excel Raporu",
              subtitle: "Harcamalarınızı Excel olarak kaydedin",
              isPremium: isPremium,
              onTap: () {
                Navigator.pop(context);
                if (isPremium) {
                   _generateExcel(context, month);
                } else {
                  _showUpgradeDialog(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isPremium,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: isPremium 
        ? const Icon(Icons.arrow_forward_ios, size: 14) 
        : const Icon(Icons.lock, color: Colors.amber, size: 20),
      onTap: onTap,
    );
  }

  void _showUpgradeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Premium Özellik"),
        content: const Text("Detaylı raporlama sistemi (PDF, Excel ve Görsel Grafikler) sadece Premium ve Aile Ekonomisi paketlerinde mevcuttur."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Kapat")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const UpgradeScreen()));
            },
            child: const Text("Paketleri Gör"),
          ),
        ],
      ),
    );
  }

  void _generatePdf(BuildContext context, DateTime month) async {
    final databaseService = SupabaseDatabaseService();
    final receipts = await databaseService.getMonthAnalysisData(month);
    final start = DateTime(month.year, month.month, 1);
    final end = DateTime(month.year, month.month + 1, 0); // Last day of month
    
    await ReportService().generateAndSharePdfReport(receipts, start, end, title: AppLocalizations.of(context)!.expenseAnalysis);
  }

  void _generateExcel(BuildContext context, DateTime month) async {
    final databaseService = SupabaseDatabaseService();
    final receipts = await databaseService.getMonthAnalysisData(month);
    
    await ReportService().generateAndShareExcelReport(receipts);
  }
}
