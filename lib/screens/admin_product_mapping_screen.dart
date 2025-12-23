import 'package:flutter/material.dart';
import 'package:fismatik/services/supabase_database_service.dart';
import 'package:fismatik/services/product_normalization_service.dart';
import '../core/app_theme.dart';
import '../models/category_model.dart';

class AdminProductMappingScreen extends StatefulWidget {
  const AdminProductMappingScreen({super.key});

  @override
  State<AdminProductMappingScreen> createState() => _AdminProductMappingScreenState();
}

class _AdminProductMappingScreenState extends State<AdminProductMappingScreen> with SingleTickerProviderStateMixin {
  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService();
  late TabController _tabController;
  
  List<Map<String, dynamic>> _unmappedProducts = [];
  List<Map<String, dynamic>> _existingMappings = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final unmapped = await _databaseService.getUnmappedProductNames();
      final existing = await _databaseService.getGlobalProductMappings();
      
      setState(() {
        _unmappedProducts = unmapped;
        _existingMappings = existing;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Hata: $e");
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showMappingDialog(String rawName, {String? initialNormalized, String? initialCategory}) async {
    final nameController = TextEditingController(text: initialNormalized ?? _databaseService.normalizeProductName(rawName));
    String? selectedCategory = initialCategory ?? _databaseService.guessCategoryFromName(rawName);
    
    // Ensure selectedCategory is "Diğer" if it's not in the list or is null
    if (selectedCategory == null || !Category.defaultCategories.any((element) => element.name == selectedCategory)) {
      selectedCategory = "Diğer";
    }

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text("Ürün Düzenle"),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Orijinal: $rawName", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: "Düzenlenmiş İsim",
                      border: OutlineInputBorder(),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: "Kategori",
                      border: OutlineInputBorder(),
                    ),
                    items: Category.defaultCategories.map((c) => DropdownMenuItem(
                      value: c.name,
                      child: Text(c.name),
                    )).toList(),
                    onChanged: (val) {
                      setState(() => selectedCategory = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, {
                  'name': nameController.text.trim(),
                  'category': selectedCategory!
                }),
                child: const Text("Kaydet"),
              ),
            ],
          );
        }
      ),
    );

    if (result != null && result['name']!.isNotEmpty) {
      try {
        await _databaseService.upsertProductMapping(
          rawName: rawName,
          normalizedName: result['name']!,
          category: result['category'],
        );
        // Refresh cache
        await _databaseService.loadGlobalProductMappings();
        _loadData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Eşleştirme kaydedildi")));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Hata: $e")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ürün İsimlerini Düzenle"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Yeni Ürünler"),
            Tab(text: "Eşleşenler"),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: const InputDecoration(
                hintText: "Ürün ara...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUnmappedList(),
                    _buildMappingList(),
                  ],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnmappedList() {
    final filtered = _unmappedProducts.where((p) => p['name'].toString().toLowerCase().contains(_searchQuery)).toList();
    
    if (filtered.isEmpty) {
      return const Center(child: Text("Düzenlenecek yeni ürün bulunamadı"));
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        final name = item['name'] as String;
        final count = item['count'] as int;
        final guessedCat = _databaseService.guessCategoryFromName(name);

        return ListTile(
          title: Text(name),
          subtitle: Text("$count kez okutuldu • Tahmin: $guessedCat"),
          trailing: const Icon(Icons.edit_note),
          onTap: () => _showMappingDialog(name),
        );
      },
    );
  }

  Widget _buildMappingList() {
    final filtered = _existingMappings.where((m) => 
      m['raw_name'].toString().toLowerCase().contains(_searchQuery) ||
      m['normalized_name'].toString().toLowerCase().contains(_searchQuery)
    ).toList();

    if (filtered.isEmpty) {
      return const Center(child: Text("Eşleşme bulunamadı"));
    }

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final mapping = filtered[index];
        final category = mapping['category'] ?? "Diğer";
        return ListTile(
          title: Text(mapping['raw_name']),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("-> ${mapping['normalized_name']}", style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              Text("Kategori: $category", style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Eşleşmeyi Sil"),
                  content: const Text("Bu eşleşmeyi silmek istediğinize emin misiniz?"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("İptal")),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Sil")),
                  ],
                ),
              );

              if (confirm == true) {
                await _databaseService.deleteProductMapping(mapping['id']);
                await _databaseService.loadGlobalProductMappings();
                _loadData();
              }
            },
          ),
          onTap: () => _showMappingDialog(
            mapping['raw_name'], 
            initialNormalized: mapping['normalized_name'],
            initialCategory: mapping['category'],
          ),
        );
      },
    );
  }
}
