import 'package:universal_io/io.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' hide Category;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';

import '../core/app_theme.dart';
import '../models/receipt_model.dart';
import '../models/category_model.dart';
import '../models/credit_model.dart';
import '../models/user_level.dart';
import '../services/supabase_database_service.dart';
import '../services/auth_service.dart';
import '../services/ad_service.dart';
import '../services/notification_service.dart';
import '../services/location_service.dart';
import '../services/gamification_service.dart';
import 'upgrade_screen.dart';

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualItemEntry {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  
  void dispose() {
    nameController.dispose();
    priceController.dispose();
  }
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  final _merchantController = TextEditingController();
  final _amountController = TextEditingController();
  final _taxController = TextEditingController();
  final _noteController = TextEditingController();
  
  // Ürün listesi
  final List<_ManualItemEntry> _itemEntries = [];

  DateTime _selectedDate = DateTime.now();
  String? _selectedCategoryName;

  bool _isSaving = false;

  // Kota bilgisi için state
  int _usedManualEntries = 0;
  int? _manualLimit;
  bool _quotaLoaded = false;
  
  // Taksitli Gider State
  bool _isInstallment = false;
  int _installmentCount = 3;

  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService();
  final AuthService _authService = AuthService();
  final AdService _adService = AdService();
  
  String _currentTierId = 'standart';

  @override
  void initState() {
    super.initState();
    _loadManualQuota();
    _adService.loadAd(); // Load ad
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _amountController.dispose();
    _taxController.dispose();
    _noteController.dispose();
    for (var entry in _itemEntries) {
      entry.dispose();
    }
    super.dispose();
  }

  void _addNewItem() {
    setState(() {
      final entry = _ManualItemEntry();
      // Fiyat değişince toplamı güncelle
      entry.priceController.addListener(_updateTotalAmount);
      _itemEntries.add(entry);
    });
  }

  void _removeItem(int index) {
    setState(() {
      _itemEntries[index].dispose();
      _itemEntries.removeAt(index);
      _updateTotalAmount();
    });
  }

  void _updateTotalAmount() {
    double total = 0;
    for (var entry in _itemEntries) {
      final priceText = entry.priceController.text.replaceAll(',', '.').trim();
      final price = double.tryParse(priceText) ?? 0;
      total += price;
    }
    
    if (total > 0) {
      _amountController.text = total.toStringAsFixed(2);
      // Toplam değişince KDV'yi de %10 olarak güncelle (Eğer boşsa veya kullanıcı henüz elle girmemişse?)
      // Şimdilik sadece toplamı güncelleyelim, KDV'yi kullanıcıya bırakalım veya kaydederken fallback yapalım.
      _taxController.text = (total / 11).toStringAsFixed(2);
    } else if (_itemEntries.isEmpty) {
      // Liste boşaldıysa manuel girişe izin ver, elle silinmediyse
    }
  }

  Future<void> _loadManualQuota() async {
    try {
      final tier = await _authService.getCurrentTier();
      final currentCount =
          await _databaseService.getCurrentManualEntryCount();

      if (!mounted) return;

      setState(() {
        _usedManualEntries = currentCount;
        _manualLimit = tier.manualEntryLimit;
        _currentTierId = tier.id;
        _quotaLoaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _quotaLoaded = true;
        _manualLimit = null;
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<bool> _checkManualLimit() async {
    try {
      final currentCount =
          await _databaseService.getCurrentManualEntryCount();
      final tier = await _authService.getCurrentTier();
      final canAdd = await _authService.canAddManualEntries(currentCount);

      if (mounted) {
        setState(() {
          _usedManualEntries = currentCount;
          _manualLimit = tier.manualEntryLimit;
          _quotaLoaded = true;
        });
      }

      if (!canAdd) {
        if (!mounted) return false;

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.manualEntryLimitTitle),
            content: Text(
              AppLocalizations.of(context)!.manualEntryLimitContent(tier.manualEntryLimit),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppLocalizations.of(context)!.close),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (c) => const UpgradeScreen()),
                  );
                },
                child: Text(
                  AppLocalizations.of(context)!.upgradeMembership,
                  style: const TextStyle(color: AppColors.primary),
                ),
              ),
            ],
          ),
        );

        return false;
      }

      return true;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text(AppLocalizations.of(context)!.manualEntryLimitError(e.toString())),
          ),
        );
      }
      return true;
    }
  }

  Future<void> _submit() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final merchant = _merchantController.text.trim();
    final note = _noteController.text.trim();
    final amountText = _amountController.text.replaceAll(',', '.').trim();

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.enterValidAmount)),
      );
      return;
    }

    final taxText = _taxController.text.replaceAll(',', '.').trim();
    double taxAmount = double.tryParse(taxText) ?? (amount / 1.10 * 0.10);

    if (!await _checkManualLimit()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final categoryName = _selectedCategoryName ?? AppLocalizations.of(context)!.other;

      if (_isInstallment) {
        // Taksitli harcama olarak kaydet (user_credits tablosuna)
        final credit = Credit(
          id: const Uuid().v4(),
          userId: '', // Servis dolduracak
          title: "[${AppLocalizations.of(context)!.installment}] ${merchant.isNotEmpty ? merchant : AppLocalizations.of(context)!.manualExpense}",
          totalAmount: amount,
          monthlyAmount: amount / _installmentCount,
          totalInstallments: _installmentCount,
          remainingInstallments: _installmentCount,
          paymentDay: _selectedDate.day,
          createdAt: _selectedDate,
        );

        await _databaseService.addCredit(credit);
      } else {
        // Normal makbuz olarak kaydet
        List<ReceiptItem> items = [];
        if (_itemEntries.isNotEmpty) {
          for (var entry in _itemEntries) {
            final name = entry.nameController.text.trim();
            final priceText = entry.priceController.text.replaceAll(',', '.').trim();
            final price = double.tryParse(priceText) ?? 0;
            
            if (name.isNotEmpty && price > 0) {
              items.add(ReceiptItem(name: name, price: price));
            }
          }
        } else {
          final itemName = note.isNotEmpty ? note : AppLocalizations.of(context)!.manualExpense;
          items.add(ReceiptItem(name: itemName, price: amount));
        }

        await _databaseService.saveManualReceipt(
          merchantName: merchant.isNotEmpty ? merchant : AppLocalizations.of(context)!.manualExpense,
          date: _selectedDate,
          totalAmount: amount,
          taxAmount: taxAmount,
          category: categoryName,
          items: items,
        );
      }

      // Bütçe Kontrolü
      try {
        final categories = await _databaseService.getCategoriesOnce();
        final category = categories.firstWhere(
          (c) => c.name == categoryName, 
          orElse: () => Category(id: '', name: categoryName, colorValue: 0, iconCode: 0, budgetLimit: 0)
        );

        if (category.budgetLimit > 0) {
          final spendingMap = await _databaseService.getCategorySpendingThisMonth();
          final currentSpending = spendingMap[categoryName] ?? 0.0;
          
          // Bildirim servisini çağır
          await NotificationService().checkCategoryBudgetAndNotify(
            context,
            categoryName, 
            currentSpending, 
            category.budgetLimit
          );
        }
      } catch (e) {
        debugPrint("Bütçe kontrol hatası: $e");
      }

      // Gamification & Rozet Kontrolü
      if (mounted) {
        try {
          final gamificationService = GamificationService();
          
          // 1. XP Ekle
          await gamificationService.addXp(XpActivity.manualEntry);
          
          // 2. İstatistikleri al
          final count = await _databaseService.getCurrentReceiptCount();
          final totalSpending = await _databaseService.getTotalSpending();
          final joinDate = await _authService.getJoinDate();
          
          // 3. Tüm başarımları kontrol et
          await gamificationService.checkAllAchievements(
            totalReceipts: count,
            totalSpending: totalSpending,
            transactionDate: DateTime.now(),
            joinDate: joinDate,
          );

        } catch (e) {
          debugPrint("Gamification hatası: $e");
        }
      }

      // Reklam Kontrolü (SADECE STANDART ÜYELER İÇİN - Her 3 manuel eklemede 1)
      if (_currentTierId == 'standart') {
        try {
          final prefs = await SharedPreferences.getInstance();
          int manualAdCounter = (prefs.getInt('manual_ad_counter') ?? 0) + 1;
          
          if (manualAdCounter >= 3) {
            // 3 oldu, reklam göster ve sıfırla
            await prefs.setInt('manual_ad_counter', 0);
            if (mounted) {
              _adService.showInterstitialAd(context: context);
            }
          } else {
            // Henüz 3 olmadı, sayacı kaydet
            await prefs.setInt('manual_ad_counter', manualAdCounter);
          }
        } catch (e) {
          debugPrint("Reklam sayacı hatası: $e");
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.manualExpenseSaved),
          backgroundColor: AppColors.success,
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.saveError(e.toString())),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.addManualExpense)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // İş yeri / açıklama
              TextFormField(
                controller: _merchantController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.merchantTitle,
                  hintText: AppLocalizations.of(context)!.merchantHint,
                ),
              ),
              const SizedBox(height: 16),

              // Tutar
              TextFormField(
                controller: _amountController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.amountTitle,
                  hintText: AppLocalizations.of(context)!.amountHint,
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  LengthLimitingTextInputFormatter(11),
                ],
                validator: (value) {
                  final v = value?.replaceAll(',', '.').trim() ?? '';
                  final parsed = double.tryParse(v);
                  if (parsed == null || parsed <= 0) {
                    return AppLocalizations.of(context)!.enterValidAmount;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // KDV
              TextFormField(
                controller: _taxController,
                decoration: InputDecoration(
                  labelText: "KDV (Opsiyonel)",
                  hintText: "Vergi tutarı (Boşsa %10 hesaplanır)",
                  prefixText: "₺",
                  border: const OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),

              // Tarih seçimi
              InkWell(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.date,
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "${_selectedDate.day.toString().padLeft(2, '0')}"
                        ".${_selectedDate.month.toString().padLeft(2, '0')}"
                        ".${_selectedDate.year}",
                      ),
                      const Icon(Icons.calendar_today, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Kategori
              StreamBuilder<List<Category>>(
                stream: _databaseService.getCategories(),
                builder: (context, snapshot) {
                  final categories =
                      snapshot.data ?? Category.defaultCategories;

                  if (categories.isEmpty) {
                    _selectedCategoryName = null;
                  } else {
                    if (_selectedCategoryName == null ||
                        !categories
                            .any((c) => c.name == _selectedCategoryName)) {
                      _selectedCategoryName = categories.first.name;
                    }
                  }

                  return DropdownButtonFormField<String>(
                    value: _selectedCategoryName,
                    items: categories
                        .map(
                          (c) => DropdownMenuItem<String>(
                            value: c.name,
                            child: Text(c.name),
                          ),
                        )
                        .toList(),
                    onChanged: categories.isEmpty
                        ? null
                        : (val) {
                            setState(() {
                              _selectedCategoryName = val;
                            });
                          },
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.category,
                      border: OutlineInputBorder(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),

              // TAKSİTLİ HARCAMA SEÇENEĞİ
              Container(
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(
                        AppLocalizations.of(context)!.installmentExpenseTitle ?? "Taksitli Harcama mı?",
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                      subtitle: Text(AppLocalizations.of(context)!.installmentExpenseSub ?? "Bu harcama ay ay gider olarak yansıtılsın."),
                      value: _isInstallment,
                      onChanged: (val) => setState(() => _isInstallment = val),
                      secondary: const Icon(Icons.calendar_month, color: Colors.blue),
                    ),
                    if (_isInstallment)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(AppLocalizations.of(context)!.installmentCountLabel ?? "Taksit Sayısı:"),
                                Text(
                                  "$_installmentCount",
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue),
                                ),
                              ],
                            ),
                            Slider(
                              value: _installmentCount.toDouble(),
                              min: 2,
                              max: 24,
                              divisions: 22,
                              label: _installmentCount.toString(),
                              onChanged: (val) => setState(() => _installmentCount = val.toInt()),
                            ),
                            Text(
                              "${AppLocalizations.of(context)!.monthlyPaymentAmount ?? 'Aylık Tutar'}: ₺${((double.tryParse(_amountController.text.replaceAll(',', '.')) ?? 0) / _installmentCount).toStringAsFixed(2)}",
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontStyle: FontStyle.italic),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // ÜRÜN EKLEME BÖLÜMÜ
              Text(
                AppLocalizations.of(context)!.productsOptional,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _itemEntries.length,
                itemBuilder: (context, index) {
                  final entry = _itemEntries[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            controller: entry.nameController,
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.productName,
                              isDense: true,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            controller: entry.priceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: AppLocalizations.of(context)!.unitPrice,
                              isDense: true,
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                          onPressed: () => _removeItem(index),
                        ),
                      ],
                    ),
                  );
                },
              ),

              ElevatedButton.icon(
                onPressed: _addNewItem,
                icon: const Icon(Icons.add),
                label: Text(AppLocalizations.of(context)!.addProduct),
              ),
              
              const SizedBox(height: 16),

              // Not / açıklama
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.noteTitle,
                  hintText: AppLocalizations.of(context)!.noteHint,
                ),
                maxLines: 2,
              ),

              const SizedBox(height: 16),

              if (_quotaLoaded)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    _manualLimit == null
                        ? AppLocalizations.of(context)!.manualQuotaError
                        : (_manualLimit! >= 999999
                            ? AppLocalizations.of(context)!.manualQuotaStatusInfinite(_usedManualEntries)
                            : AppLocalizations.of(context)!.manualQuotaStatus(_usedManualEntries, _manualLimit!)),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    foregroundColor: Colors.white,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(AppLocalizations.of(context)!.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
