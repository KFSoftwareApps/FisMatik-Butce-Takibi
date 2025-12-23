import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';
import '../core/app_theme.dart';
import '../models/subscription_model.dart';
import '../services/supabase_database_service.dart';
import '../services/notification_service.dart';
import 'fixed_expenses_screen.dart';

class SubscriptionsScreen extends StatefulWidget {
  const SubscriptionsScreen({super.key});

  @override
  State<SubscriptionsScreen> createState() => _SubscriptionsScreenState();
}

class _SubscriptionsScreenState extends State<SubscriptionsScreen> {
  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService();
  final NotificationService _notificationService = NotificationService();
  
  late Stream<List<Subscription>> _subscriptionsStream;
  double _totalMonthlyCost = 0.0;

  // Predefined Expenses Data
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

  @override
  void initState() {
    super.initState();
    _refreshSubscriptions();
  }

  void _refreshSubscriptions() {
    setState(() {
      _subscriptionsStream = _databaseService.getSubscriptions();
    });
  }

  // Gider Seçme Ekranı (Bottom Sheet)
  void _showExpenseSelectionSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F7), // iOS tarzı gri arka plan
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    ),
                    child: Text(AppLocalizations.of(context)!.close, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                  Text(
                    AppLocalizations.of(context)!.selectExpense,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 80), // Dengelemek için boşluk
                ],
              ),
            ),
            
            // List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                children: [
                  // Konut Kredisi / Taksit Ekle Seçeneği (En başa ekliyoruz)
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.credit_card, color: AppColors.primary, size: 24),
                      ),
                      title: Text(AppLocalizations.of(context)!.addCreditInstallment, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(AppLocalizations.of(context)!.creditInstallmentDesc),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () {
                        // FixedExpensesScreen üzerindeki dialog fonksiyonunu çağıramayız çünkü burası SubscriptionsScreen.
                        // Ancak kullanıcıyı FixedExpensesScreen'e yönlendirebiliriz veya burada da dialog açabiliriz.
                        // Tutarlı olması için FixedExpensesScreen'e yönlendirelim, orada zaten açık.
                        Navigator.pop(context);
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (context) => FixedExpensesScreen(openAddCreditDialogOnInit: true)), // Yönlendir ve diyaloğu aç
                        );
                        // VEYA: Buraya da _showAddCreditDialog kopyalamak yerine,
                        // Doğrudan FixedExpensesScreen'i açıp parametre ile dialogu tetikleyebiliriz?
                        // Şimdilik basit çözüm: Kullanıcı buradaysa yanlış yerdedir, ama yine de buton koyduk.
                        // En iyisi: FixedExpensesScreen.openAddCreditDialog(context) gibi statik bir metod olmalıydı.
                        // Pratik Çözüm: Buradan FixedExpensesScreen açıp kullanıcıya bırakmak.
                        // FAKAT: Kullanıcı zaten "Sabit Giderler -> Ekle" diyerek buraya geldi.
                        // O yüzden bu ekranın FixedExpensesScreen olması GEREKİRDİ.
                        // Eğer burası SubscriptionsScreen ise, muhtemelen FixedExpensesScreen yerine yanlışlıkla burası açılıyor.
                      },
                    ),
                  ),
                  
                  ..._predefinedExpenses.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 12, bottom: 8, top: 16),
                          child: Text(
                            entry.key,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: entry.value.asMap().entries.map((itemEntry) {
                              final index = itemEntry.key;
                              final item = itemEntry.value;
                              final isLast = index == entry.value.length - 1;
                              
                              return Column(
                                children: [
                                  ListTile(
                                    leading: Text(
                                      item['icon'],
                                      style: const TextStyle(fontSize: 24),
                                    ),
                                    title: Text(
                                      item['name'],
                                      style: const TextStyle(fontWeight: FontWeight.w600),
                                    ),
                                    subtitle: item['price'] > 0 
                                        ? Text("Ort. ${item['price'].toStringAsFixed(2)} TL", style: TextStyle(color: Colors.grey[500], fontSize: 12))
                                        : null,
                                    trailing: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                                    onTap: () {
                                      Navigator.pop(context); // Sheet'i kapat
                                      _addOrUpdateSubscription(
                                        prefilledName: item['name'],
                                        prefilledPrice: null, // Kullanıcı isteği: Tutar boş gelsin
                                      );
                                    },
                                  ),
                                  if (!isLast)
                                    const Divider(height: 1, indent: 50, endIndent: 16, color: Color(0xFFE5E5EA)),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    );
                  }),
                  // Özel Ekleme Seçeneği
                  const SizedBox(height: 20),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.edit_note, color: AppColors.primary, size: 28),
                      title: Text(AppLocalizations.of(context)!.addCustomExpense, style: const TextStyle(fontWeight: FontWeight.bold)),
                      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
                      onTap: () {
                        Navigator.pop(context);
                        _addOrUpdateSubscription();
                      },
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addOrUpdateSubscription({Subscription? subscription, String? prefilledName, double? prefilledPrice}) async {
    final isEditing = subscription != null;
    final nameController = TextEditingController(text: subscription?.name ?? prefilledName);
    final priceController = TextEditingController(text: subscription?.price.toString() ?? prefilledPrice?.toString());
    final dayController = TextEditingController(text: subscription?.renewalDay.toString() ?? '1');
    
    // Basit renk seçimi için varsayılanlar
    int selectedColor = int.parse(subscription?.colorHex ?? 'FF2196F3', radix: 16);

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? AppLocalizations.of(context)!.editExpense : AppLocalizations.of(context)!.newFixedExpense),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.expenseNameLabel,
                  prefixIcon: const Icon(Icons.label_outline),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.amountLabel,
                  suffixText: "TL",
                  prefixIcon: const Icon(Icons.attach_money),
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dayController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.dayLabel,
                  prefixIcon: const Icon(Icons.calendar_today),
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty || priceController.text.isEmpty) return;

              final price = double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0.0;
              final day = int.tryParse(dayController.text) ?? 1;

              final newSub = Subscription(
                id: subscription?.id ?? const Uuid().v4(),
                name: nameController.text,
                price: price,
                renewalDay: day.clamp(1, 31),
                colorHex: selectedColor.toRadixString(16).toUpperCase(),
              );

              if (isEditing) {
                await _databaseService.addSubscription(newSub); // upsert
              } else {
                await _databaseService.addSubscription(newSub);
              }

              // Bildirim planla
              if (mounted) {
                await _notificationService.scheduleSubscriptionReminder(context, newSub);
              }

              if (mounted) {
                Navigator.pop(ctx);
                _refreshSubscriptions(); // Listeyi yenile
              }
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSubscription(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.areYouSure),
        content: Text(AppLocalizations.of(context)!.expenseWillBeDeleted),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await _databaseService.deleteSubscription(id);
      if (mounted) {
        _refreshSubscriptions(); // Listeyi yenile
      }
    }
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final subscriptions = snapshot.data ?? [];
          
          // Toplam maliyeti hesapla
          _totalMonthlyCost = subscriptions.fold(0.0, (sum, item) => sum + item.price);

          return Column(
            children: [
              // Özet Kartı
              Container(
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
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      AppLocalizations.of(context)!.monthlyFixedExpense,
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "₺${_totalMonthlyCost.toStringAsFixed(2)}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.of(context)!.activeExpensesCount(subscriptions.length.toString()),
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),

              // Liste
              Expanded(
                child: subscriptions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.account_balance_wallet_outlined, size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              AppLocalizations.of(context)!.noFixedExpensesYet,
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: subscriptions.length,
                        itemBuilder: (context, index) {
                          final sub = subscriptions[index];
                          final color = Color(int.parse(sub.colorHex, radix: 16));
                          
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 2,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              leading: Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    sub.name.substring(0, 1).toUpperCase(),
                                    style: TextStyle(
                                      color: color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                sub.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                                subtitle: Text(
                                  AppLocalizations.of(context)!.renewsOnDay(sub.renewalDay.toString()),
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "₺${sub.price.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.textDark,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                    onPressed: () => _deleteSubscription(sub.id),
                                  ),
                                ],
                              ),
                              onTap: () => _addOrUpdateSubscription(subscription: sub),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showExpenseSelectionSheet, // Yeni seçim ekranını aç
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
