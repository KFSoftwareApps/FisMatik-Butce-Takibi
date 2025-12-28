import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';
import '../core/app_theme.dart';
import '../models/subscription_model.dart';
import '../models/credit_model.dart';
import '../services/supabase_database_service.dart';
import '../services/notification_service.dart';

class FixedExpensesScreen extends StatefulWidget {
  final bool openAddCreditDialogOnInit;

  const FixedExpensesScreen({super.key, this.openAddCreditDialogOnInit = false});

  @override
  State<FixedExpensesScreen> createState() => _FixedExpensesScreenState();
}

class _FixedExpensesScreenState extends State<FixedExpensesScreen> {
  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService();
  final NotificationService _notificationService = NotificationService();
  
  late Stream<List<Subscription>> _subscriptionsStream;
  late Stream<List<Credit>> _creditsStream;
  double _totalMonthlyCost = 0.0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _refreshData();
    
    if (widget.openAddCreditDialogOnInit) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        // Ufak bir gecikme ekleyerek sayfanın tam yüklenmesini ve çizilmesini bekleyelim
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          _showAddCreditDialog();
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _refreshData() {
    setState(() {
      _subscriptionsStream = _databaseService.getSubscriptions();
      _creditsStream = _databaseService.getCredits();
    });
  }

  // --- KREDİ EKLEME/DÜZENLEME ---
  Future<void> _showAddCreditDialog({Credit? credit}) async {
    final isEditing = credit != null;
    final isCreditCard = credit?.totalInstallments == 999;
    
    final titleController = TextEditingController(text: credit?.title);
    final totalAmountController = TextEditingController(text: credit?.totalAmount.toString());
    final monthlyAmountController = TextEditingController(text: credit?.monthlyAmount.toString());
    final totalInstallmentsController = TextEditingController(text: credit?.totalInstallments.toString());
    final remainingInstallmentsController = TextEditingController(text: credit?.remainingInstallments.toString());
    final dayController = TextEditingController(text: credit?.paymentDay.toString() ?? '15');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isCreditCard 
            ? AppLocalizations.of(context)!.editCreditCard 
            : (isEditing ? AppLocalizations.of(context)!.editCredit : AppLocalizations.of(context)!.addNewCredit)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.creditNameHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.label),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: totalAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: isCreditCard 
                      ? AppLocalizations.of(context)!.currentTotalDebt 
                      : AppLocalizations.of(context)!.totalCreditAmount,
                  suffixText: "TL",
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.money),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: monthlyAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: isCreditCard 
                      ? AppLocalizations.of(context)!.minimumPaymentAmount 
                      : AppLocalizations.of(context)!.monthlyInstallmentAmount,
                  suffixText: "TL",
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.calendar_view_day),
                ),
              ),
              const SizedBox(height: 12),
              if (!isCreditCard) ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: totalInstallmentsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.totalInstallmentsLabel,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: remainingInstallmentsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: AppLocalizations.of(context)!.remainingInstallmentsLabel,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: dayController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.paymentDayHint,
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
              if (titleController.text.isEmpty || monthlyAmountController.text.isEmpty) return;

              final total = double.tryParse(totalAmountController.text.replaceAll(',', '.')) ?? 0;
              final monthly = double.tryParse(monthlyAmountController.text.replaceAll(',', '.')) ?? 0;
              // If it's a credit card, force 999. If not, parse or default to 12.
              final totalInst = isCreditCard ? 999 : (int.tryParse(totalInstallmentsController.text) ?? 12);
              final remainingInst = isCreditCard ? 999 : (int.tryParse(remainingInstallmentsController.text) ?? totalInst);
              final day = int.tryParse(dayController.text) ?? 15;

              final newCredit = Credit(
                id: credit?.id ?? const Uuid().v4(),
                userId: '', // Service fills this
                title: titleController.text,
                totalAmount: total,
                monthlyAmount: monthly,
                totalInstallments: totalInst,
                remainingInstallments: remainingInst,
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

  // --- KREDİ KARTI EKLEME ---
  Future<void> _showAddCreditCardDialog() async {
    final bankController = TextEditingController();
    final limitController = TextEditingController();
    final debtController = TextEditingController();
    final dayController = TextEditingController(text: '1');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.addCreditCard),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: bankController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.bankNameHint,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.account_balance),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: limitController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.cardLimit,
                  suffixText: "TL",
                  helperText: AppLocalizations.of(context)!.cardLimitHelper,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.speed),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: debtController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.currentStatementDebt,
                  suffixText: "TL",
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.money_off),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dayController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.lastPaymentDayHint,
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
              if (bankController.text.isEmpty || debtController.text.isEmpty || limitController.text.isEmpty) return;

              final limit = double.tryParse(limitController.text.replaceAll(',', '.')) ?? 0;
              final debt = double.tryParse(debtController.text.replaceAll(',', '.')) ?? 0;
              final day = int.tryParse(dayController.text) ?? 1;

              // Asgari Tutar Hesabı
              // Limit > 20.000 ise %40, değilse %20
              final rate = limit > 20000 ? 0.40 : 0.20;
              final minPayment = debt * rate;

              final newCredit = Credit(
                id: const Uuid().v4(),
                userId: '', // Service fills this
                title: "${bankController.text} (${AppLocalizations.of(context)!.addCreditCard})",
                totalAmount: debt, // Toplam Borç
                monthlyAmount: minPayment, // Asgari Ödeme
                totalInstallments: 999, // Sürekli
                remainingInstallments: 999,
                paymentDay: day.clamp(1, 31),
                createdAt: DateTime.now(),
              );

              await _databaseService.addCredit(newCredit);

              if (mounted) {
                Navigator.pop(ctx);
                _refreshData();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.minPaymentCalculated(minPayment.toStringAsFixed(2))),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }



  // --- DELETE CONFIRMATION ---
  Future<void> _deleteCredit(String id) async {
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

  // --- SUBSCRIPTIONS LOGIC (Existing) ---
  // Predefined Expenses Data (Migrated from SubscriptionsScreen)
  final Map<String, List<Map<String, dynamic>>> _predefinedExpenses = {
    "Devlet & Vergi (TR)": [
      {"name": "Bağkur Primi (2025)", "price": 7735.98, "icon": "🇹🇷"},
      {"name": "SGK Primi", "price": 0.0, "icon": "🏥"},
      {"name": "KYK Kredi Ödemesi", "price": 0.0, "icon": "🎓"},
      {"name": "MTV (Motorlu Taşıtlar Vergisi)", "price": 0.0, "icon": "🚗"},
      {"name": "Emlak Vergisi", "price": 0.0, "icon": "🏠"},
      {"name": "Gelir Vergisi", "price": 0.0, "icon": "💰"},
      {"name": "KDV Ödemesi", "price": 0.0, "icon": "🧾"},
      {"name": "Muhtasar Beyanname", "price": 0.0, "icon": "📄"},
      {"name": "Trafik Cezası", "price": 0.0, "icon": "🚔"},
    ],
    "Dijital Abonelikler": [
      {"name": "Netflix", "price": 189.99, "icon": "🎬"},
      {"name": "Spotify", "price": 99.00, "icon": "🎵"},
      {"name": "YouTube Premium", "price": 79.99, "icon": "▶️"},
      {"name": "Disney+", "price": 164.90, "icon": "🏰"},
      {"name": "Amazon Prime", "price": 69.90, "icon": "📦"},
      {"name": "BluTV", "price": 199.90, "icon": "📺"},
      {"name": "Exxen", "price": 219.00, "icon": "⚽"},
      {"name": "Gain", "price": 249.00, "icon": "📱"},
      {"name": "Apple Music", "price": 59.99, "icon": "🍎"},
      {"name": "Tod TV", "price": 129.00, "icon": "⚽"},
    ],
    "Faturalar & Ev": [
      {"name": "Elektrik Faturası", "price": 0.0, "icon": "⚡"},
      {"name": "Su Faturası", "price": 0.0, "icon": "💧"},
      {"name": "Doğalgaz Faturası", "price": 0.0, "icon": "🔥"},
      {"name": "İnternet Faturası", "price": 450.00, "icon": "🌐"},
      {"name": "Cep Telefonu Faturası", "price": 350.00, "icon": "📱"},
      {"name": "Site Aidatı", "price": 0.0, "icon": "🏢"},
      {"name": "Kira", "price": 0.0, "icon": "🏠"},
    ],
    "Yapay Zeka & Teknoloji": [
      {"name": "ChatGPT Plus", "price": 499.99, "icon": "🤖"},
      {"name": "Gemini Advanced", "price": 719.00, "icon": "✨"},
      {"name": "Claude Pro", "price": 817.00, "icon": "🧠"},
      {"name": "GitHub Copilot", "price": 340.00, "icon": "💻"},
    ],
  };

  void _showExpenseSelectionSheet() {
    String searchQuery = "";
    bool isSearching = false;
    final textController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSheet) {
          // Filtering Logic
          final filteredExpenses = <String, List<Map<String, dynamic>>>{};
          
          if (searchQuery.isEmpty) {
            filteredExpenses.addAll(_predefinedExpenses);
          } else {
            _predefinedExpenses.forEach((category, items) {
              final matchingItems = items.where((item) {
                final name = (item['name'] as String).toLowerCase();
                return name.contains(searchQuery.toLowerCase());
              }).toList();
              
              if (matchingItems.isNotEmpty) {
                filteredExpenses[category] = matchingItems;
              }
            });
          }

          return Container(
            height: MediaQuery.of(context).size.height * 0.7,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Search Bar or Title
                      isSearching
                        ? Expanded(
                            child: TextField(
                              controller: textController,
                              autofocus: true,
                              decoration: InputDecoration(
                                hintText: AppLocalizations.of(context)!.searchExpenseHint,
                                border: InputBorder.none,
                              ),
                              onChanged: (value) {
                                setStateSheet(() {
                                  searchQuery = value;
                                });
                              },
                            ),
                          )
                        : Text(
                            AppLocalizations.of(context)!.selectExpense,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                      
                      // Action Icons
                      Row(
                        children: [
                          if (isSearching)
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setStateSheet(() {
                                   isSearching = false;
                                   searchQuery = "";
                                   textController.clear();
                                });
                              },
                            ),
                          if (!isSearching)
                             IconButton(
                                key: const ValueKey('search_btn'),
                                icon: const Icon(Icons.search, color: AppColors.primary),
                                onPressed: () {
                                  setStateSheet(() {
                                    isSearching = true;
                                  });
                                },
                             ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (!isSearching && searchQuery.isEmpty) ...[
                   ListTile(
                    leading: const Icon(Icons.credit_card, color: AppColors.primary, size: 32),
                    title: Text(AppLocalizations.of(context)!.addCreditInstallment, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(AppLocalizations.of(context)!.addCreditInstallmentSub),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(context);
                      _showAddCreditDialog();
                    },
                  ),
                   ListTile(
                    leading: const Icon(Icons.credit_score, color: Colors.orange, size: 32),
                    title: Text(AppLocalizations.of(context)!.addCreditCard, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(AppLocalizations.of(context)!.addCreditCardSub),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.pop(context);
                      _showAddCreditCardDialog();
                    },
                  ),
                  const Divider(),
                ],
                Expanded(
                  child: filteredExpenses.isEmpty
                      ? Center(child: Text(AppLocalizations.of(context)!.noResultsFound))
                      : ListView(
                          children: filteredExpenses.entries.expand((entry) {
                            // Show Header only if searching? Or always? Always is better context.
                            return [
                              if (searchQuery.isNotEmpty) // Optional: Show category header during search
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  child: Text(entry.key, style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
                                ),
                                
                              ...entry.value.map((item) {
                                return ListTile(
                                   leading: Text(item['icon'], style: const TextStyle(fontSize: 24)),
                                   title: Text(_getLocalizedExpenseName(context, item['name'])),
                                   trailing: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                                   onTap: () {
                                     Navigator.pop(context);
                                     _addOrUpdateSubscription(prefilledName: _getLocalizedExpenseName(context, item['name']));
                                   },
                                );
                              })
                            ];
                          }).toList(),
                        ),
                ),
                if (!isSearching)
                  ListTile(
                    leading: const Icon(Icons.edit, color: AppColors.primary),
                    title: Text(AppLocalizations.of(context)!.addCustomSubscription),
                    onTap: () {
                      Navigator.pop(context);
                      _addOrUpdateSubscription();
                    },
                  ),
                const SizedBox(height: 20),
              ],
            ),
          );
        }
      ),
    );
  }

  String _getLocalizedExpenseName(BuildContext context, String name) {
    final l10n = AppLocalizations.of(context)!;
    switch (name) {
      case 'Su Faturası': return l10n.waterBill;
      case 'Doğalgaz Faturası': return l10n.gasBill;
      case 'İnternet Faturası': return l10n.internetBill;
      case 'Cep Telefonu Faturası': return l10n.phoneBill;
      case 'Site Aidatı': return l10n.managementFee;
      case 'Kira': return l10n.rent;
      case 'Elektrik Faturası': return l10n.electricityBill;
      case 'Emlak Vergisi': return l10n.propertyTax;
      case 'Gelir Vergisi': return l10n.incomeTax;
      case 'KDV Ödemesi': return l10n.vatPayment;
      case 'Muhtasar Beyanname': return l10n.withholdingTax;
      case 'Trafik Cezası': return l10n.trafficFine;
      case 'SGK Primi': return l10n.socialSecurityPremium;
      case 'KYK Kredi Ödemesi': return l10n.studentLoan;
      case 'MTV (Motorlu Taşıtlar Vergisi)': return l10n.motorVehicleTax;
      default: return name;
    }
  }

  Future<void> _addOrUpdateSubscription({Subscription? subscription, String? prefilledName}) async {
    // Same logic as before
    final isEditing = subscription != null;
    final nameController = TextEditingController(text: subscription?.name ?? prefilledName);
    final priceController = TextEditingController(text: subscription?.price.toString());
    final dayController = TextEditingController(text: subscription?.renewalDay.toString() ?? '1');
    
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? AppLocalizations.of(context)!.editExpense : AppLocalizations.of(context)!.newFixedExpense),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             TextField(controller: nameController, decoration: InputDecoration(labelText: AppLocalizations.of(context)!.expenseNameLabel)),
             const SizedBox(height: 10),
             TextField(
               controller: priceController, 
               keyboardType: TextInputType.number,
               decoration: InputDecoration(labelText: AppLocalizations.of(context)!.amountLabel)
             ),
             const SizedBox(height: 10),
             TextField(
               controller: dayController, 
               keyboardType: TextInputType.number,
               decoration: InputDecoration(labelText: AppLocalizations.of(context)!.dayLabel)
             ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () async {
               final price = double.tryParse(priceController.text) ?? 0;
               final day = int.tryParse(dayController.text) ?? 1;
               final sub = Subscription(
                 id: subscription?.id ?? const Uuid().v4(),
                 name: nameController.text,
                 price: price,
                 renewalDay: day,
                 colorHex: 'FF2196F3', // Default blue
               );
               await _databaseService.addSubscription(sub);
               if (mounted) {
                 Navigator.pop(ctx);
                 _refreshData();
               }
            },
            child: Text(AppLocalizations.of(context)!.save),
          )
        ],
      )
    );
  }
  
  Future<void> _deleteSubscription(String id) async {
     await _databaseService.deleteSubscription(id);
     _refreshData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.fixedExpenses, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        padding: const EdgeInsets.only(bottom: 100),
        child: Column(
          children: [
            // --- HEADER SUMMARY ---
            // --- HEADER SUMMARY ---
            StreamBuilder<List<Subscription>>(
              stream: _subscriptionsStream,
              builder: (context, subSnapshot) {
                return StreamBuilder<List<Credit>>(
                  stream: _creditsStream,
                  builder: (context, creditSnapshot) {
                    double total = 0;
                    
                    if (subSnapshot.hasData) {
                      total += subSnapshot.data!.fold(0.0, (sum, item) => sum + item.price);
                    }
                    
                    if (creditSnapshot.hasData) {
                      total += creditSnapshot.data!.fold(0.0, (sum, item) => sum + item.monthlyAmount);
                    }

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(AppLocalizations.of(context)!.totalMonthlyFixedExpenses, style: const TextStyle(color: Colors.white70)),
                          Text("₺${total.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
             
             // --- KREDİLER SECTION ---
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
               child: Row(
                 children: [
                   const Icon(Icons.credit_card, size: 20),
                   const SizedBox(width: 8),
                   Text(AppLocalizations.of(context)!.myCredits, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                 ],
               ),
             ),
             StreamBuilder<List<Credit>>(
               stream: _creditsStream,
               builder: (context, snapshot) {
                 if (!snapshot.hasData || snapshot.data!.isEmpty) {
                   return Padding(
                     padding: const EdgeInsets.all(20.0),
                     child: Text(AppLocalizations.of(context)!.noCreditsAdded, style: const TextStyle(color: Colors.grey)),
                   );
                 }
                 return ListView.builder(
                   shrinkWrap: true,
                   physics: const NeverScrollableScrollPhysics(),
                   padding: const EdgeInsets.symmetric(horizontal: 20),
                   itemCount: snapshot.data!.length,
                   itemBuilder: (context, index) {
                     final credit = snapshot.data![index];
                     return Card(
                       margin: const EdgeInsets.only(bottom: 12),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                       child: ListTile(
                         leading: CircleAvatar(
                           backgroundColor: Colors.red.shade50,
                           child: Icon(
                              credit.totalInstallments == 999 ? Icons.credit_card : Icons.account_balance, 
                              color: Colors.red
                           ),
                         ),
                         title: Text(credit.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            credit.totalInstallments == 999 
                              ? AppLocalizations.of(context)!.creditCardDetail(credit.paymentDay.toString())
                                  : AppLocalizations.of(context)!.creditInstallmentDetail(credit.paymentDay.toString(), credit.remainingInstallments.toString(), credit.totalInstallments.toString())
                          ),
                         trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                               Text("₺${credit.monthlyAmount.toStringAsFixed(0)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(
                                  credit.totalInstallments == 999 ? AppLocalizations.of(context)!.estimatedMonthly : AppLocalizations.of(context)!.monthly, 
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 10)
                                ),
                            ],
                         ),
                         onTap: () => _showAddCreditDialog(credit: credit),
                         onLongPress: () => _deleteCredit(credit.id),
                       ),
                     );
                   },
                 );
               },
             ),
             
             const Divider(height: 40, thickness: 1),

             // --- ABONELİKLER SECTION ---
             Padding(
               padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
               child: Row(
                 children: [
                   const Icon(Icons.subscriptions_outlined, size: 20),
                   const SizedBox(width: 8),
                   Text(AppLocalizations.of(context)!.subscriptionsOther, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                 ],
               ),
             ),
             StreamBuilder<List<Subscription>>(
               stream: _subscriptionsStream,
               builder: (context, snapshot) {
                 if (!snapshot.hasData || snapshot.data!.isEmpty) {
                   return Padding(
                     padding: const EdgeInsets.all(20.0),
                     child: Text(AppLocalizations.of(context)!.noSubscriptionsAdded, style: const TextStyle(color: Colors.grey)),
                   );
                 }
                 return ListView.builder(
                   shrinkWrap: true,
                   physics: const NeverScrollableScrollPhysics(),
                   padding: const EdgeInsets.symmetric(horizontal: 20),
                   itemCount: snapshot.data!.length,
                   itemBuilder: (context, index) {
                     final sub = snapshot.data![index];
                     return Card(
                       margin: const EdgeInsets.only(bottom: 12),
                       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                       child: ListTile(
                         leading: CircleAvatar(
                           backgroundColor: Colors.blue.shade50,
                           child: Text(sub.name[0], style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                         ),
                         title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(AppLocalizations.of(context)!.dayOfMonth(sub.renewalDay.toString())),
                         trailing: Text("₺${sub.price.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                         onTap: () => _addOrUpdateSubscription(subscription: sub),
                         onLongPress: () => _deleteSubscription(sub.id),
                       ),
                     );
                   },
                 );
               },
             ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showExpenseSelectionSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(AppLocalizations.of(context)!.add, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
