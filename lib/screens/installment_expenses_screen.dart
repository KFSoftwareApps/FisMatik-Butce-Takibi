import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';
import '../core/app_theme.dart';
import '../models/credit_model.dart';
import '../services/supabase_database_service.dart';

class InstallmentExpensesScreen extends StatefulWidget {
  const InstallmentExpensesScreen({super.key});

  @override
  State<InstallmentExpensesScreen> createState() => _InstallmentExpensesScreenState();
}

class _InstallmentExpensesScreenState extends State<InstallmentExpensesScreen> {
  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService();
  late Stream<List<Credit>> _creditsStream;

  @override
  void initState() {
    super.initState();
    _creditsStream = _databaseService.getCredits();
  }

  void _refreshData() {
    setState(() {
      _creditsStream = _databaseService.getCredits();
    });
  }

  Future<void> _showAddInstallmentDialog({Credit? credit}) async {
    final isEditing = credit != null;
    
    final titleController = TextEditingController(text: credit?.title);
    final totalAmountController = TextEditingController(text: credit?.totalAmount.toString());
    final installmentCountController = TextEditingController(text: credit?.totalInstallments.toString() ?? '3');
    final dayController = TextEditingController(text: credit?.paymentDay.toString() ?? '15');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? AppLocalizations.of(context)!.edit : AppLocalizations.of(context)!.addManualExpense),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.merchantTitle,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.label),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: totalAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.amountTitle,
                  suffixText: "TL",
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.money),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: installmentCountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.installmentCountLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.repeat),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dayController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.dayLabel,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.calendar_today),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty || totalAmountController.text.isEmpty) return;

              final total = double.tryParse(totalAmountController.text.replaceAll(',', '.')) ?? 0;
              final count = int.tryParse(installmentCountController.text) ?? 3;
              final day = int.tryParse(dayController.text) ?? 15;

              final newCredit = Credit(
                id: credit?.id ?? const Uuid().v4(),
                userId: '', // Service fills this
                title: titleController.text.startsWith('[') ? titleController.text : "[${AppLocalizations.of(context)!.installment}] ${titleController.text}",
                totalAmount: total,
                monthlyAmount: total / count,
                totalInstallments: count,
                paymentDay: day.clamp(1, 31),
                createdAt: credit?.createdAt ?? DateTime.now(),
              );

              if (isEditing) {
                await _databaseService.deleteCredit(newCredit.id);
              }
              await _databaseService.addCredit(newCredit);

              if (mounted) {
                Navigator.pop(ctx);
                _refreshData();
              }
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteInstallment(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteConfirmTitle),
        content: Text(AppLocalizations.of(context)!.deleteCreditMessage),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.cancel)),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true), 
            child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
    if (confirm == true) {
      await _databaseService.deleteCredit(id);
      if (mounted) _refreshData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.installmentExpensesTitle ?? "Taksitli Giderler", 
          style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: StreamBuilder<List<Credit>>(
        stream: _creditsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final credits = snapshot.data ?? [];
          double totalMonthly = credits.fold(0, (sum, item) => sum + item.monthlyAmount);

          return Column(
            children: [
              // Summary Header
              Container(
                width: double.infinity,
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Colors.blue, Colors.lightBlueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                  ],
                ),
                child: Column(
                  children: [
                    Text(AppLocalizations.of(context)!.monthlyPaymentAmount, style: const TextStyle(color: Colors.white70)),
                    Text("₺${totalMonthly.toStringAsFixed(2)}", 
                      style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(AppLocalizations.of(context)!.activeExpensesCount(credits.length), 
                      style: const TextStyle(color: Colors.white, fontSize: 14)),
                  ],
                ),
              ),

              // List
              Expanded(
                child: credits.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(AppLocalizations.of(context)!.noData, style: TextStyle(color: Colors.grey.shade500)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: credits.length,
                        itemBuilder: (context, index) {
                          final credit = credits[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blue.shade50,
                                child: Icon(
                                  credit.totalInstallments == 999 ? Icons.credit_card : Icons.calendar_month,
                                  color: Colors.blue
                                ),
                              ),
                              title: Text(credit.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: credit.totalInstallments == 999 
                                  ? Text(AppLocalizations.of(context)!.creditCardDetail(credit.paymentDay.toString()))
                                  : Text(
                                      "Ayın ${credit.paymentDay}. günü • ${credit.currentInstallment} / ${credit.totalInstallments} Taksit",
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                    ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text("₺${credit.monthlyAmount.toStringAsFixed(0)}", 
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(AppLocalizations.of(context)!.monthly, 
                                    style: TextStyle(color: Colors.grey.shade500, fontSize: 10)),
                                ],
                              ),
                              onTap: () => _showAddInstallmentDialog(credit: credit),
                              onLongPress: () => _deleteInstallment(credit.id),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddInstallmentDialog(),
        backgroundColor: Colors.blue,
        label: Text(AppLocalizations.of(context)!.addManualExpense, style: const TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
