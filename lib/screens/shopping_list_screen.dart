import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fismatik/core/app_theme.dart';
import 'package:fismatik/models/shopping_item_model.dart';
import 'package:fismatik/services/supabase_database_service.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';
import '../widgets/error_state.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService();
  final TextEditingController _itemController = TextEditingController();
  
  bool _isSearchingPrice = false;
  String? _lastPriceInfo; 
  List<String> _suggestions = [];
  String _currentTierId = 'standart';

  @override
  void initState() {
    super.initState();
    _itemController.addListener(_onSearchChanged);
    _loadSuggestions();
    _loadUserTier();
  }

  Future<void> _loadUserTier() async {
    final tier = await _databaseService.getCurrentTier();
    if (mounted) {
      setState(() {
        _currentTierId = tier.id;
      });
    }
  }

  Future<void> _loadSuggestions() async {
    final products = await _databaseService.getFrequentlyBoughtProducts();
    if (mounted) {
      setState(() {
        _suggestions = products;
      });
    }
  }

  @override
  void dispose() {
    _itemController.removeListener(_onSearchChanged);
    _itemController.dispose();
    super.dispose();
  }

  // Debounce benzeri basit bir yapı
  void _onSearchChanged() {
    if (_itemController.text.length > 2) {
      _checkPriceHistory(_itemController.text);
    } else {
      setState(() {
        _lastPriceInfo = null;
      });
    }
  }

  Future<void> _checkPriceHistory(String query) async {
    setState(() => _isSearchingPrice = true);
    
    try {
      final result = await _databaseService.getLastPriceForProduct(query);
      if (mounted) {
        setState(() {
          if (result != null) {
            final price = result['price'];
            final date = result['date'] as DateTime;
            final merchant = result['merchant'];
            final locale = Localizations.localeOf(context).toString();
            final formattedDate = DateFormat('d MMM', locale).format(date);
            
            _lastPriceInfo = AppLocalizations.of(context)!.lastPriceInfo(merchant, formattedDate, price.toString());
          } else {
            _lastPriceInfo = null; 
          }
        });
      }
    } finally {
      if (mounted) setState(() => _isSearchingPrice = false);
    }
  }

  Future<void> _addItem() async {
    if (_itemController.text.trim().isEmpty) return;

    try {
      await _databaseService.addShoppingItem(_itemController.text.trim());
      _itemController.clear();
      setState(() {
        _lastPriceInfo = null;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hata: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.shoppingListTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: AppColors.textDark),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
            tooltip: AppLocalizations.of(context)!.clearChecked,
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: Text(AppLocalizations.of(context)!.deleteAllTitle ?? "Hepsini Sil"),
                  content: Text(AppLocalizations.of(context)!.deleteAllConfirm ?? "Listedeki tüm ürünler silinecektir. Emin misiniz?"),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(AppLocalizations.of(context)!.cancel)),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(AppLocalizations.of(context)!.delete, style: const TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (confirm == true) {
                await _databaseService.deleteAllShoppingItems();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // LİSTE
          Expanded(
            child: StreamBuilder<List<ShoppingItem>>(
              stream: _databaseService.getShoppingList(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  final error = snapshot.error.toString();
                  final isNetworkError = error.contains('SocketException') || error.contains('NetworkImage') || error.contains('ClientException');
                  return ErrorState(
                    title: isNetworkError ? (AppLocalizations.of(context)!.noInternet ?? "Bağlantı Hatası") : (AppLocalizations.of(context)!.generalError ?? "Bir Hata Oluştu"),
                    description: isNetworkError 
                        ? (AppLocalizations.of(context)!.networkError ?? "İnternet bağlantınızı kontrol edip tekrar deneyin.")
                        : error,
                    icon: isNetworkError ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                    onRetry: () {
                      setState(() {});
                    },
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 10)),
                            ],
                          ),
                          child: Icon(Icons.shopping_cart_outlined, size: 60, color: Colors.grey.shade300),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          AppLocalizations.of(context)!.emptyShoppingList,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "İhtiyaçlarınızı ekleyerek başlayın",
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                final items = snapshot.data!;

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Dismissible(
                      key: Key(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delete_outline, color: Colors.red),
                      ),
                      onDismissed: (_) {
                        _databaseService.deleteShoppingItem(item.id);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: item.isChecked ? Colors.transparent : Colors.grey.shade200,
                            width: 1,
                          ),
                          boxShadow: item.isChecked ? [] : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          leading: GestureDetector(
                            onTap: () {
                               _databaseService.toggleShoppingItem(item.id, !item.isChecked);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: item.isChecked ? AppColors.primary : Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: item.isChecked ? AppColors.primary : Colors.grey.shade400,
                                  width: 2,
                                ),
                              ),
                              child: item.isChecked 
                                  ? const Icon(Icons.check, size: 16, color: Colors.white) 
                                  : null,
                            ),
                          ),
                          title: Text(
                            item.name,
                            style: TextStyle(
                              decoration: item.isChecked ? TextDecoration.lineThrough : null,
                              decorationColor: Colors.grey,
                              color: item.isChecked ? Colors.grey : AppColors.textDark,
                              fontSize: 16,
                              fontWeight: item.isChecked ? FontWeight.normal : FontWeight.w600,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.close, size: 18, color: Colors.grey.shade400),
                            onPressed: () => _databaseService.deleteShoppingItem(item.id),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          
          // GİRİŞ ALANI (Alt kısımda sabit)
          Container(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + MediaQuery.of(context).padding.bottom),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // FİYAT GEÇMİŞİ ve ÖNERİLER KISMI
                 if (_isSearchingPrice)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, left: 4),
                    child: Row(
                      children: [
                        const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
                        const SizedBox(width: 8),
                        Text(AppLocalizations.of(context)!.checkingPriceHistory, style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                      ],
                    ),
                  )
                else if (_lastPriceInfo != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12, left: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: Colors.green.shade50, shape: BoxShape.circle),
                          child: const Icon(Icons.history, size: 14, color: Colors.green),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _lastPriceInfo!,
                            style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_suggestions.isNotEmpty && (_currentTierId == 'limitless' || _currentTierId == 'limitless_family')) ...[
                  SizedBox(
                    height: 32,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _suggestions.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final product = _suggestions[index];
                        return ActionChip(
                          label: Text(product, style: const TextStyle(fontSize: 12)),
                          backgroundColor: Colors.grey.shade50,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          side: BorderSide(color: Colors.grey.shade200),
                          onPressed: () {
                            _itemController.text = product;
                            _addItem();
                          },
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: _itemController,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            hintText: AppLocalizations.of(context)!.shoppingHint,
                            hintStyle: TextStyle(color: Colors.grey.shade500),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            prefixIcon: const Icon(Icons.add_circle_outline, color: Colors.grey),
                          ),
                          onSubmitted: (_) => _addItem(),
                          textInputAction: TextInputAction.done,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _addItem,
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.arrow_upward_rounded, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
