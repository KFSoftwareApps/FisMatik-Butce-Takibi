import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';
import '../core/app_theme.dart';
import '../models/credit_model.dart';
import '../services/supabase_database_service.dart';
import '../utils/currency_formatter.dart';

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

  Future<void> _showAddInstallmentDialog({Credit? credit, bool isExpense = false}) async {
    final isEditing = credit != null;
    
    final titleController = TextEditingController(text: credit?.title);
    final totalAmountController = TextEditingController(
      text: credit != null ? CurrencyFormatter.formatDecimal(credit.totalAmount) : '',
    );
    final monthlyAmountController = TextEditingController(
      text: credit != null ? CurrencyFormatter.formatDecimal(credit.monthlyAmount) : '',
    );
    final installmentCountController = TextEditingController(text: credit?.totalInstallments.toString() ?? '12');
    final remainingController = TextEditingController(text: credit?.remainingInstallments.toString() ?? '12');
    final dayController = TextEditingController(text: credit?.paymentDay.toString() ?? '15');

    // Auto-calculate monthly change listener
    void calculateMonthly() {
      final total = double.tryParse(totalAmountController.text.replaceAll(',', '.')) ?? 0;
      final count = int.tryParse(installmentCountController.text) ?? 1;
      if (count > 0 && total > 0) {
        monthlyAmountController.text = CurrencyFormatter.formatDecimal(total / count);
      }
    }

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.grey.shade50,
        title: Text(
          isEditing 
              ? AppLocalizations.of(context)!.edit 
              : (isExpense ? "Taksitli Gider Ekle" : "Kredi Ekle"),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title Field
              _buildRoundedField(
                controller: titleController,
                label: isExpense ? "Gider Adı" : "Kredi/Kart Adı", // Kredi/Kart Adı
                icon: Icons.credit_card,
              ),
              const SizedBox(height: 12),
              
              // Total Amount
              _buildRoundedField(
                controller: totalAmountController,
                label: "Toplam Tutar",
                suffix: "TL",
                icon: Icons.attach_money,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => calculateMonthly(),
              ),
              const SizedBox(height: 12),

              // Monthly Amount
              _buildRoundedField(
                controller: monthlyAmountController,
                label: "Aylık Taksit Tutarı",
                suffix: "TL",
                icon: Icons.payment,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 12),

              // Installments Row
              Row(
                children: [
                  Expanded(
                    child: _buildRoundedField(
                      controller: installmentCountController,
                      label: "Toplam Taksit",
                      keyboardType: TextInputType.number,
                      onChanged: (_) {
                         calculateMonthly();
                         // Auto update remaining if adding
                         if (!isEditing) {
                           remainingController.text = installmentCountController.text;
                         }
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildRoundedField(
                      controller: remainingController,
                      label: "Kalan Taksit", // Kalan Taksit
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Payment Day
              _buildRoundedField(
                controller: dayController,
                label: "Ödeme Günü",
                icon: Icons.calendar_today,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: Colors.grey),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            onPressed: () async {
              if (titleController.text.isEmpty || totalAmountController.text.isEmpty) return;

              final total = double.tryParse(totalAmountController.text.replaceAll(',', '.')) ?? 0;
              final monthly = double.tryParse(monthlyAmountController.text.replaceAll(',', '.')) ?? 0;
              final count = int.tryParse(installmentCountController.text) ?? 1;
              final remaining = int.tryParse(remainingController.text) ?? count;
              final day = int.tryParse(dayController.text) ?? 15;

              // Calculate createdAt based on remaining installments
              // If Total 12, Remaining 10, then 2 months passed.
              // CreatedAt should be 2 months ago.
              final completed = count - remaining;
              final now = DateTime.now();
              // Subtract completed months roughly
              // To be precise: If today is 28th Dec, and paid 2 months, start date approx 28th Oct.
              DateTime createdAt = now;
              if (completed > 0) {
                int targetMonth = now.month - completed;
                int targetYear = now.year;
                while (targetMonth < 1) {
                  targetMonth += 12;
                  targetYear -= 1;
                }
                createdAt = DateTime(targetYear, targetMonth, now.day > 28 ? 28 : now.day);
              } else if (completed < 0) {
                 // Forward date? Usually remaining <= total.
              }

              final newCredit = Credit(
                id: credit?.id ?? const Uuid().v4(),
                userId: '',
                title: isExpense && !titleController.text.startsWith('[') 
                    ? "[Gider] ${titleController.text}" 
                    : titleController.text,
                totalAmount: total,
                monthlyAmount: monthly > 0 ? monthly : (total / count),
                totalInstallments: count,
                paymentDay: day.clamp(1, 31),
                createdAt: createdAt,
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
            child: Text(AppLocalizations.of(context)!.save, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text("Taksitler", style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
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
          if (snapshot.hasError) {
             return Center(child: Text('Hata: ${snapshot.error}'));
          }

          final credits = snapshot.data ?? [];
          if (credits.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.credit_score, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                   Text(
                    "Henüz taksit eklenmemiş",
                    style: TextStyle(fontSize: 18, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                   Text(
                    "Başlamak için yeni ekleyin",
                    style: TextStyle(color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: credits.length,
            separatorBuilder: (ctx, i) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final credit = credits[index];
              return _buildCreditCard(credit);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSelectionSheet,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCreditCard(Credit credit) {
    final bool isFinished = credit.remainingInstallments <= 0;
    final bool isCreditCard = credit.totalInstallments == 999;
    final progress = credit.totalInstallments > 0 
        ? (credit.totalInstallments - credit.remainingInstallments) / credit.totalInstallments
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isCreditCard ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isCreditCard ? Icons.credit_card : Icons.calendar_today,
                  color: isCreditCard ? Colors.orange : Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      credit.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    if (!isCreditCard)
                      Text(
                        "${credit.remainingInstallments} taksit kaldı",
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20, color: Colors.grey),
                onPressed: () => _showAddInstallmentDialog(credit: credit, isExpense: credit.title.startsWith('[Gider]')),
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 20, color: Colors.redAccent),
                onPressed: () async {
                   final confirm = await showDialog<bool>(
                     context: context, 
                     builder: (ctx) => AlertDialog(
                       title: const Text("Sil"),
                       content: const Text("Bu taksidi silmek istediğinize emin misiniz?"),
                       actions: [
                         TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("İptal")),
                         ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Sil")),
                       ],
                     ),
                   );
                   if (confirm == true) {
                     await _databaseService.deleteCredit(credit.id);
                     _refreshData();
                   }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Aylık Tutar", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(
                    CurrencyFormatter.format(credit.monthlyAmount),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text("Toplam", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  Text(
                    CurrencyFormatter.format(credit.totalAmount),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ],
          ),
          if (!isCreditCard) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(isFinished ? Colors.green : AppColors.primary),
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRoundedField({
    required TextEditingController controller,
    required String label,
    IconData? icon,
    String? suffix,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            onChanged: onChanged,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              prefixIcon: icon != null ? Icon(icon, color: Colors.grey.shade600) : null,
              suffixText: suffix,
              suffixStyle: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }


  // Re-implementing _showAddCreditCardDialog just in case, or finding where it was.
  // Actually I replaced from line 31 to 414 using a single block.
  // I need to make sure I include _showAddCreditCardDialog and _showAddSelectionSheet.
  // I will just implement them here.
  
  Future<void> _showAddCreditCardDialog() async {
    final bankController = TextEditingController();
    final limitController = TextEditingController();
    final debtController = TextEditingController();
    final dayController = TextEditingController(text: '1');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(AppLocalizations.of(context)!.addCreditCard),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildRoundedField(controller: bankController, label: AppLocalizations.of(context)!.bankNameHint, icon: Icons.account_balance),
              const SizedBox(height: 12),
              _buildRoundedField(controller: limitController, label: AppLocalizations.of(context)!.cardLimit, suffix: "TL", icon: Icons.speed, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: 12),
              _buildRoundedField(controller: debtController, label: AppLocalizations.of(context)!.currentStatementDebt, suffix: "TL", icon: Icons.money_off, keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: 12),
              _buildRoundedField(controller: dayController, label: AppLocalizations.of(context)!.lastPaymentDayHint, icon: Icons.calendar_today, keyboardType: TextInputType.number),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () async {
              if (bankController.text.isEmpty || debtController.text.isEmpty) return;
              final limit = double.tryParse(limitController.text.replaceAll(',', '.')) ?? 0;
              final debt = double.tryParse(debtController.text.replaceAll(',', '.')) ?? 0;
              final day = int.tryParse(dayController.text) ?? 1;
              final rate = limit > 20000 ? 0.40 : 0.20;
              final minPayment = debt * rate;

              final newCredit = Credit(
                id: const Uuid().v4(),
                userId: '', 
                title: "${bankController.text} (${AppLocalizations.of(context)!.creditCard ?? 'Kredi Kartı'})",
                totalAmount: debt, 
                monthlyAmount: minPayment, 
                totalInstallments: 999, 
                paymentDay: day.clamp(1, 31),
                createdAt: DateTime.now(),
              );

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

  void _showAddSelectionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
              ),
              ListTile(
                leading: const Icon(Icons.calendar_month, color: Colors.blue, size: 28),
                title: Text(AppLocalizations.of(context)!.addCreditInstallment, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Kredi taksitlerini ekleyin"), // Kredi
                onTap: () {
                  Navigator.pop(context);
                  _showAddInstallmentDialog(isExpense: false);
                },
              ),
              const Divider(indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.shopping_bag, color: Colors.purple, size: 28),
                title: const Text("Taksitli Gider Ekle", style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text("Telefon, mobilya vb. taksitlerinizi ekleyin"),
                onTap: () {
                  Navigator.pop(context);
                  _showAddInstallmentDialog(isExpense: true);
                },
              ),
              const Divider(indent: 16, endIndent: 16),
              ListTile(
                leading: const Icon(Icons.credit_card, color: Colors.orange, size: 28),
                title: Text(AppLocalizations.of(context)!.addCreditCard, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(AppLocalizations.of(context)!.addCreditCardSub),
                onTap: () {
                  Navigator.pop(context);
                  _showAddCreditCardDialog();
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }
}
