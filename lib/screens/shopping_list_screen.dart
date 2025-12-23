import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../models/shopping_item_model.dart';
import '../services/supabase_database_service.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';

class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService();
  final TextEditingController _itemController = TextEditingController();
  
  String? _lastPriceInfo;
  bool _isSearchingPrice = false;

  @override
  void initState() {
    super.initState();
    _itemController.addListener(_onSearchChanged);
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
    // Çok sık istek atmamak için burada bir debounce eklenebilir ama şimdilik basit tutuyoruz
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
            _lastPriceInfo = null; // "Daha önce alınmadı" demek yerine boş bırakalım
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.shoppingListTitle),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const BackButton(color: AppColors.textDark),
        ),
      ),
      body: Column(
        children: [
          // GİRİŞ ALANI
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _itemController,
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.shoppingHint,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          prefixIcon: const Icon(Icons.add_shopping_cart, color: Colors.grey),
                        ),
                        onSubmitted: (_) => _addItem(),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FloatingActionButton(
                      onPressed: _addItem,
                      backgroundColor: AppColors.primary,
                      mini: true,
                      elevation: 0,
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ],
                ),
                
                // FİYAT GEÇMİŞİ BİLGİSİ
                if (_isSearchingPrice)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, left: 12),
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
                    padding: const EdgeInsets.only(top: 8.0, left: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.history, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _lastPriceInfo!,
                            style: const TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // LİSTE
          Expanded(
            child: StreamBuilder<List<ShoppingItem>>(
              stream: _databaseService.getShoppingList(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          AppLocalizations.of(context)!.emptyShoppingList,
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }

                final items = snapshot.data!;

                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Dismissible(
                      key: Key(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red.shade100,
                        child: const Icon(Icons.delete, color: Colors.red),
                      ),
                      onDismissed: (_) {
                        _databaseService.deleteShoppingItem(item.id);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          leading: Checkbox(
                            value: item.isChecked,
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                            onChanged: (val) {
                              _databaseService.toggleShoppingItem(item.id, val ?? false);
                            },
                          ),
                          title: Text(
                            item.name,
                            style: TextStyle(
                              decoration: item.isChecked ? TextDecoration.lineThrough : null,
                              color: item.isChecked ? Colors.grey : AppColors.textDark,
                              fontWeight: item.isChecked ? FontWeight.normal : FontWeight.w600,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.close, size: 20, color: Colors.grey),
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
        ],
      ),
    );
  }
}
