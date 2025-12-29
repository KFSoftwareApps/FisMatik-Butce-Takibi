import 'package:flutter/material.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../models/receipt_model.dart';
import '../utils/currency_formatter.dart';
import 'package:fismatik/services/product_normalization_service.dart';
import 'package:fismatik/services/supabase_database_service.dart';
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
  String _viewMode = 'generic'; // 'brand' or 'generic'
  bool _isLoadingPreference = true;
  final _dbService = SupabaseDatabaseService();
  // Using CurrencyFormatter

  List<Map<String, dynamic>> _allGenericData = [];
  List<String> _allBrandData = [];

  @override
  void initState() {
    super.initState();
    _loadUserPreference();
  }

  void _preCalculateData() {
    // 1. Brand Data (Simple unique list)
    _allBrandData = widget.allProducts.toSet().toList()..sort();

    // 2. Generic Data (Optimized O(N) grouping and stats)
    final stats = <String, Map<String, dynamic>>{};
    
    // Group names first
    for (final product in widget.allProducts) {
      final normalized = _dbService.normalizeProductName(product);
      if (!stats.containsKey(normalized)) {
        stats[normalized] = {
          'normalized_name': normalized,
          'variants': <String>{},
          'prices': <double>[],
        };
      }
      stats[normalized]!['variants'].add(product);
    }

    // Single pass over receipts to collect prices
    for (final receipt in widget.receipts) {
      for (final item in receipt.items) {
        final itemNormalized = _dbService.normalizeProductName(item.name);
        if (stats.containsKey(itemNormalized)) {
          stats[itemNormalized]!['prices'].add(item.price.toDouble());
        }
      }
    }

    // Convert to final format
    _allGenericData = stats.values.map((s) {
      final prices = s['prices'] as List<double>;
      return {
        'normalized_name': s['normalized_name'],
        'brand_count': (s['variants'] as Set<String>).length,
        'min_price': prices.isEmpty ? 0.0 : prices.reduce((a, b) => a < b ? a : b),
        'max_price': prices.isEmpty ? 0.0 : prices.reduce((a, b) => a > b ? a : b),
        'brand_variants': (s['variants'] as Set<String>).toList(),
      };
    }).toList();
  }

  Future<void> _loadUserPreference() async {
    try {
      await Future.wait([
        _dbService.getUserPriceComparisonMode(),
        _dbService.loadGlobalProductMappings(),
      ]).then((results) {
        if (mounted) {
          _preCalculateData(); // Pre-calculate after mappings are loaded
          setState(() {
            _viewMode = results[0] as String;
            _isLoadingPreference = false;
          });
        }
      });
    } catch (e) {
      if (mounted) {
        _preCalculateData();
        setState(() {
          _viewMode = 'generic';
          _isLoadingPreference = false;
        });
      }
    }
  }

  Future<void> _toggleViewMode() async {
    final newMode = _viewMode == 'brand' ? 'generic' : 'brand';
    try {
      await _dbService.setUserPriceComparisonMode(newMode);
      if (mounted) {
        setState(() => _viewMode = newMode);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newMode == 'generic'
                  ? AppLocalizations.of(context)!.switchToGeneric
                  : AppLocalizations.of(context)!.switchToBrand,
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e')),
        );
      }
    }
  }

  List<dynamic> get _filteredProducts {
    final query = _searchQuery.toLowerCase();
    
    if (_viewMode == 'brand') {
      return _allBrandData.where((p) {
        final matchesQuery = query.isEmpty || p.toLowerCase().contains(query);
        final matchesCategory = _selectedCategory == 'Tümü' || _getCategoryForProduct(p) == _selectedCategory;
        return matchesQuery && matchesCategory;
      }).toList();
    } else {
      return _allGenericData.where((p) {
        final name = (p['normalized_name'] as String).toLowerCase();
        final matchesQuery = query.isEmpty || name.contains(query);
        final matchesCategory = _selectedCategory == 'Tümü' || _getCategoryForProduct(p['normalized_name']) == _selectedCategory;
        return matchesQuery && matchesCategory;
      }).toList();
    }
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
        actions: [
          if (!_isLoadingPreference)
            IconButton(
              icon: Icon(
                _viewMode == 'brand' ? Icons.label : Icons.category,
                color: Colors.white,
              ),
              tooltip: _viewMode == 'brand'
                  ? AppLocalizations.of(context)!.switchToGeneric
                  : AppLocalizations.of(context)!.switchToBrand,
              onPressed: _toggleViewMode,
            ),
        ],
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
                          selectedColor: AppColors.primary.withValues(alpha: 0.2),
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
                            if (_viewMode == 'brand') {
                              final product = _filteredProducts[index] as String;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildBrandProductCard(context, product),
                              );
                            } else {
                              final productData = _filteredProducts[index] as Map<String, dynamic>;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildGenericProductCard(context, productData),
                              );
                            }
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildBrandProductCard(BuildContext context, String productName) {
    final category = _getCategoryForProduct(productName);
    final categoryIcon = _getCategoryIcon(category);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pop(context, productName),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
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

  Widget _buildGenericProductCard(BuildContext context, Map<String, dynamic> productData) {
    final normalizedName = productData['normalized_name'] as String;
    final brandCount = productData['brand_count'] as int;
    final minPrice = productData['min_price'] as double;
    final maxPrice = productData['max_price'] as double;
    final category = _getCategoryForProduct(normalizedName);
    final categoryIcon = _getCategoryIcon(category);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pop(context, normalizedName),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(categoryIcon, color: Colors.orange, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        normalizedName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$brandCount farklı marka',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (minPrice > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${CurrencyFormatter.format(minPrice)} - ${CurrencyFormatter.format(maxPrice)}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
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

  String _getCategoryForProduct(String productName) {
    final mapping = _dbService.getNormalizedData(productName);
    if (mapping.category != null) return mapping.category!;
    return _dbService.guessCategoryFromName(productName);
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Market':
        return Icons.shopping_cart;
      case 'Akaryakıt':
        return Icons.local_gas_station;
      case 'Yeme-İçme':
        return Icons.restaurant;
      case 'Giyim':
        return Icons.checkroom;
      case 'Teknoloji':
        return Icons.computer;
      case 'Sağlık':
        return Icons.local_hospital;
      case 'Ev Eşyası':
        return Icons.kitchen;
      case 'Atıştırmalık':
        return Icons.cookie;
      default:
        return Icons.shopping_bag;
    }
  }
}
