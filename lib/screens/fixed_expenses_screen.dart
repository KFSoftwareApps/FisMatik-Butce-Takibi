import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import 'package:fismatik/services/data_refresh_service.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';
import 'package:fismatik/utils/currency_formatter.dart';
import '../core/app_theme.dart';
import '../models/subscription_model.dart';
import '../services/supabase_database_service.dart';
import '../services/notification_service.dart';

class FixedExpensesScreen extends StatefulWidget {
  const FixedExpensesScreen({super.key});

  @override
  State<FixedExpensesScreen> createState() => _FixedExpensesScreenState();
}

class _FixedExpensesScreenState extends State<FixedExpensesScreen> {
  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService();
  final NotificationService _notificationService = NotificationService();
  
  late Stream<List<Subscription>> _subscriptionsStream;
  double _totalMonthlyCost = 0.0;
  final ScrollController _scrollController = ScrollController();
  StreamSubscription<void>? _refreshSubscription;

  @override
  void initState() {
    super.initState();
    _refreshData();
    
    // Listen for global refresh signals
    _refreshSubscription = DataRefreshService().onUpdate.listen((_) {
      if (mounted) _refreshData();
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _refreshSubscription?.cancel();
    super.dispose();
  }

  void _refreshData() {
    setState(() {
      _subscriptionsStream = _databaseService.getSubscriptions();
    });
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
                Expanded(
                  child: filteredExpenses.isEmpty
                      ? Center(child: Text(AppLocalizations.of(context)!.noResultsFound))
                      : ListView(
                          children: filteredExpenses.entries.expand((entry) {
                            return [
                              if (searchQuery.isNotEmpty) 
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
    final isEditing = subscription != null;
    final nameController = TextEditingController(text: subscription?.name ?? prefilledName);
    final priceController = TextEditingController(
      text: subscription != null ? CurrencyFormatter.formatDecimal(subscription.price) : \"\",
    );
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
      body: StreamBuilder<List<Subscription>>(
        stream: _subscriptionsStream,
        builder: (context, snapshot) {
          // Wrap logic to simplify
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final subscriptions = snapshot.data ?? [];
          final total = subscriptions.fold(0.0, (sum, item) => sum + item.price);

          return CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(
                child: Container(
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
                      Text(CurrencyFormatter.format(total), style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      const Icon(Icons.subscriptions_outlined, size: 20),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.subscriptionsOther, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),

              if (subscriptions.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Center(
                      child: Text(AppLocalizations.of(context)!.noSubscriptionsAdded, style: const TextStyle(color: Colors.grey))
                    ),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final sub = subscriptions[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade50,
                              child: Text(sub.name[0], style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                            ),
                            title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                             subtitle: Text(AppLocalizations.of(context)!.dayOfMonth(sub.renewalDay.toString())),
                            trailing: Text(CurrencyFormatter.format(sub.price), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            onTap: () => _addOrUpdateSubscription(subscription: sub),
                            onLongPress: () => _deleteSubscription(sub.id),
                          ),
                        ),
                      );
                    },
                    childCount: subscriptions.length,
                  ),
                ),
              
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          );
        },
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
