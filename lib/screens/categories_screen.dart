import 'package:flutter/material.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';
import 'package:uuid/uuid.dart';
import '../core/app_theme.dart';
import '../models/category_model.dart';
import '../models/membership_model.dart'; 
import '../services/supabase_database_service.dart';
import '../utils/currency_formatter.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';
import '../services/auth_service.dart'; 
import '../core/app_icons.dart'; 

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService();
  late Future<List<Category>> _categoriesFuture;
  Map<String, double> _categorySpending = {}; // Kategori harcamalarını tutacak map

  @override
  void initState() {
    super.initState();
    _refreshCategories();
    _loadCategorySpendings(); // Harcamaları da yükle
  }

  void _refreshCategories() {
    setState(() {
      _categoriesFuture = _databaseService.getCategoriesOnce();
    });
    _loadCategorySpendings(); // Kategoriler yenilendiğinde harcamaları da yenile
  }

  // Kategori harcamalarını yükleme metodu
  Future<void> _loadCategorySpendings() async {
    final spendings = await _databaseService.getCategorySpendingThisMonth();
    setState(() {
      _categorySpending = spendings;
    });
  }

  // Yeni Kategori Ekleme Penceresi (Sadece yetkili kullanıcılar için)
  void _showAddCategoryDialog(BuildContext context, bool canManage) {
    if (!canManage) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.categoryManagementUpgradePrompt)),
      );
      return;
    }

    final nameController = TextEditingController();
    final limitController = TextEditingController();
    int selectedColor = 0xFF2196F3; // Varsayılan Mavi
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.newCategory),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.categoryName,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.category),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: limitController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.monthlyBudgetLimitOptional,
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.attach_money),
                suffixText: CurrencyFormatter.currencySymbol,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final newCat = Category(
                  id: const Uuid().v4(),
                  name: nameController.text,
                  colorValue: selectedColor,
                  iconCode: 0xe5c3, // Varsayılan yıldız ikonu
                  budgetLimit: double.tryParse(limitController.text) ?? 0,
                );
                
                await _databaseService.addCategory(newCat);
                _refreshCategories(); // Listeyi güncelle
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: Text(AppLocalizations.of(context)!.add),
          ),
        ],
      ),
    );
  }

  // Limit Düzenleme Penceresi
  void _showEditLimitDialog(BuildContext context, Category category, List<Category> allCategories) {
    final limitController = TextEditingController(text: category.budgetLimit > 0 ? category.budgetLimit.toStringAsFixed(0) : '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("${category.name} ${AppLocalizations.of(context)!.limitLabel}"),
        content: TextField(
          controller: limitController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context)!.monthlyBudgetLimit,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.attach_money),
            suffixText: CurrencyFormatter.currencySymbol,
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () async {
              final newLimit = double.tryParse(limitController.text) ?? 0;
              
              // Kategoriyi güncelle
              final updatedCategories = allCategories.map((c) {
                if (c.id == category.id) {
                  return Category(
                    id: c.id, 
                    name: c.name, 
                    colorValue: c.colorValue, 
                    iconCode: c.iconCode,
                    budgetLimit: newLimit
                  );
                }
                return c;
              }).toList();

              await _databaseService.updateCategories(updatedCategories);
              _refreshCategories(); // Listeyi güncelle
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context.watch<CurrencyProvider>(); // Rebuilds when currency changes
    // 1. Kullanıcının üyelik yetkisini dinle
    return StreamBuilder<MembershipTier>(
      stream: _databaseService.getUserTierStream().map((tierId) => MembershipTier.Tiers[tierId] ?? MembershipTier.Tiers['standart']!), 
      builder: (context, membershipSnapshot) {
        final currentTier = membershipSnapshot.data ?? MembershipTier.Tiers['standart']!;
        final canManage = currentTier.canManageCategories;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(AppLocalizations.of(context)!.myCategories, style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold)),
            backgroundColor: Colors.white,
            elevation: 0,
            iconTheme: const IconThemeData(color: AppColors.textDark),
          ),
          body: FutureBuilder<List<Category>>(
            future: _categoriesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              
              final categories = snapshot.data ?? Category.defaultCategories;

              return ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  
                  // Standart kategoriler silinemez (defaultCategories içindeki id'ye bakarak)
                  final bool isDefaultCategory = Category.defaultCategories.any((defCat) => defCat.id == category.id);
                  final bool isCustomCategory = !isDefaultCategory; 
                  
                  final spending = _categorySpending[category.name] ?? 0.0;
                  final limit = category.budgetLimit;
                  final progress = limit > 0 ? (spending / limit).clamp(0.0, 1.0) : 0.0;
                  
                  Color progressColor = Color(category.colorValue);
                  if (limit > 0) {
                    if (spending >= limit) {
                      progressColor = Colors.red;
                    } else if (spending >= limit * 0.8) {
                      progressColor = Colors.orange;
                    }
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: InkWell(
                      onTap: () => _showEditLimitDialog(context, category, categories),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Color(category.colorValue).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(AppIcons.getIcon(category.iconCode), color: Color(category.colorValue)),
                              ),
                              title: Text(
                                _getLocalizedCategoryName(context, category.name),
                                style: const TextStyle(fontWeight: FontWeight.bold)
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (limit > 0)
                                    Text(
                                      AppLocalizations.of(context)!.spendingVsLimit(spending.toStringAsFixed(0), limit.toStringAsFixed(0), CurrencyFormatter.currencySymbol),
                                      style: TextStyle(
                                        fontSize: 12, 
                                        color: spending >= limit ? Colors.red : Colors.grey.shade700,
                                        fontWeight: spending >= limit ? FontWeight.bold : FontWeight.normal
                                      ),
                                    )
                                  else
                                    Text(AppLocalizations.of(context)!.noLimit, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                              trailing: canManage && isCustomCategory
                                  ? IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                      onPressed: () async {
                                        final updatedList = List<Category>.from(categories);
                                        updatedList.removeAt(index);
                                        await _databaseService.updateCategories(updatedList);
                                        _refreshCategories(); // Listeyi güncelle
                                      },
                                    )
                                  : const Icon(Icons.edit, size: 18, color: Colors.grey),
                            ),
                            if (limit > 0)
                              Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: LinearProgressIndicator(
                                  value: progress,
                                  backgroundColor: Colors.grey.shade200,
                                  color: progressColor,
                                  minHeight: 6,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          // 2. FAB BUTONU KONTROLÜ
          floatingActionButton: canManage 
              ? FloatingActionButton(
                  onPressed: () => _showAddCategoryDialog(context, canManage),
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.add, color: Colors.white),
                )
              : null, // Yetkisi yoksa FAB gösterme
        );
      },
    );
  }
  String _getLocalizedCategoryName(BuildContext context, String name) {
    final l10n = AppLocalizations.of(context)!;
    switch (name) {
      case 'Market': return l10n.categoryMarket;
      case 'Yeme-İçme': return l10n.categoryFood;
      case 'Akaryakıt': return l10n.categoryGas;
      case 'Giyim': return l10n.categoryClothing;
      case 'Teknoloji': return l10n.categoryTech;
      case 'Sağlık': return l10n.healthCategory;
      case 'Ev Eşyası': return l10n.categoryHome;
      case 'Diğer': return l10n.other;
      default: return name;
    }
  }
}
