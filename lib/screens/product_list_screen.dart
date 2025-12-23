import 'package:flutter/material.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';
import '../core/app_theme.dart';
import '../models/receipt_model.dart';
import 'profile_screen.dart';

class ProductListScreen extends StatefulWidget {
  final List<String> allProducts;
  final List<Receipt> receipts;

  const ProductListScreen({
    required this.allProducts,
    required this.receipts,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'Tümü';

  List<String> get _filteredProducts {
    var products = widget.allProducts;
    
    if (_searchQuery.isNotEmpty) {
      products = products
          .where((p) => p.toLowerCase().contains(_searchQuery.toLowerCase()))
          .toList();
    }
    
    if (_selectedCategory != 'Tümü') {
      products = products.where((p) => _getCategoryForProduct(p) == _selectedCategory).toList();
    }
    
    return products;
  }

  String _getCategoryForProduct(String productName) {
    final lower = productName.toLowerCase();
    if (lower.contains('süt') || lower.contains('ayran') || lower.contains('yoğurt') || lower.contains('peynir')) {
      return 'Süt Ürünleri';
    } else if (lower.contains('ekmek') || lower.contains('poğaça') || lower.contains('simit')) {
      return 'Fırın';
    } else if (lower.contains('su') || lower.contains('kola') || lower.contains('meyve suyu') || lower.contains('çay')) {
      return 'İçecekler';
    } else if (lower.contains('deterjan') || lower.contains('sabun') || lower.contains('şampuan')) {
      return 'Temizlik';
    } else if (lower.contains('çikolata') || lower.contains('gofret') || lower.contains('bisküvi')) {
      return 'Atıştırmalık';
    }
    return 'Diğer';
  }

  List<String> get _categories {
    final cats = {'Tümü'};
    for (var product in widget.allProducts) {
      cats.add(_getCategoryForProduct(product));
    }
    return cats.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.smartPriceTrackerTitle),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: widget.allProducts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.insights, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.noProductHistory,
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // Search Bar
                Container(
                  color: AppColors.primary,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    decoration: InputDecoration(
                      hintText: 'Ürün ara...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                
                // Category Filters
                Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = category == _selectedCategory;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() => _selectedCategory = category);
                          },
                          backgroundColor: Colors.white,
                          selectedColor: AppColors.primary.withOpacity(0.2),
                          checkmarkColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSelected ? AppColors.primary : Colors.grey[700],
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                // Product List
                Expanded(
                  child: _filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'Ürün bulunamadı',
                                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = _filteredProducts[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _buildEnhancedProductCard(context, product),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildEnhancedProductCard(BuildContext context, String productName) {
    final category = _getCategoryForProduct(productName);
    final categoryIcon = _getCategoryIcon(category);
    
    return Container(
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate back and trigger the product history dialog
            Navigator.pop(context, productName);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(categoryIcon, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        productName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Süt Ürünleri':
        return Icons.local_drink;
      case 'Fırın':
        return Icons.bakery_dining;
      case 'İçecekler':
        return Icons.local_cafe;
      case 'Temizlik':
        return Icons.cleaning_services;
      case 'Atıştırmalık':
        return Icons.cookie;
      default:
        return Icons.shopping_bag;
    }
  }
}
