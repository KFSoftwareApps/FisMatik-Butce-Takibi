import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';
import '../models/receipt_model.dart';
import '../services/supabase_database_service.dart';
import 'edit_receipt_screen.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> with SingleTickerProviderStateMixin {
  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService();
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  
  List<Receipt> _allReceipts = [];
  List<Receipt> _filteredReceipts = [];
  List<Map<String, dynamic>> _productResults = [];
  bool _isLoading = true;

  // Filtreler
  DateTime? _startDate;
  DateTime? _endDate;
  double? _minAmount;
  double? _maxAmount;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {}); // Tab değişince UI güncelle (Floating action button vs varsa)
      }
    });
    _loadReceipts();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReceipts() async {
    setState(() => _isLoading = true);
    final stream = _databaseService.getReceipts();
    stream.listen((receipts) {
      if (mounted) {
        setState(() {
          _allReceipts = receipts;
          _filterReceipts(); // İlk yüklemede filtrele
          _isLoading = false;
        });
      }
    });
  }

  void _filterReceipts() {
    final query = _searchController.text.toLowerCase();
    
    // 1. Fiş Filtreleme
    setState(() {
      _filteredReceipts = _allReceipts.where((receipt) {
        // ... (Mevcut filtreleme mantığı aynı kalacak)
        bool matchesText = receipt.merchantName.toLowerCase().contains(query);
        if (!matchesText) {
          matchesText = receipt.items.any((item) => item.name.toLowerCase().contains(query));
        }

        bool matchesDate = true;
        if (_startDate != null) {
          matchesDate = matchesDate && receipt.date.isAfter(_startDate!.subtract(const Duration(days: 1)));
        }
        if (_endDate != null) {
          matchesDate = matchesDate && receipt.date.isBefore(_endDate!.add(const Duration(days: 1)));
        }

        bool matchesAmount = true;
        if (_minAmount != null) {
          matchesAmount = matchesAmount && receipt.totalAmount >= _minAmount!;
        }
        if (_maxAmount != null) {
          matchesAmount = matchesAmount && receipt.totalAmount <= _maxAmount!;
        }

        bool matchesCategory = true;
        if (_selectedCategory != null) {
          matchesCategory = matchesCategory && receipt.category == _selectedCategory;
        }

        return matchesText && matchesDate && matchesAmount && matchesCategory;
      }).toList();
      
      _filteredReceipts.sort((a, b) => b.date.compareTo(a.date));
    });

    // 2. Ürün Arama (Eğer 2. tab aktifse veya genel arama yapılıyorsa)
    _searchProducts(query);
  }

  Future<void> _searchProducts(String query) async {
    if (query.length < 2) {
      if (mounted) setState(() => _productResults = []);
      return;
    }

    final results = await _databaseService.getProductsByPrice(query, sourceReceipts: _allReceipts);
    if (mounted) {
      setState(() {
        _productResults = results;
      });
    }
  }

  Future<void> _selectDateRange(BuildContext context) async {
     // ... (Mevcut mantık)
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _startDate != null && _endDate != null 
          ? DateTimeRange(start: _startDate!, end: _endDate!) 
          : null,
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _filterReceipts();
    }
  }

  void _showFilterSheet() {
      // ... (Mevcut mantık)
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.detailedFilter, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              // ... (Kalan filtre UI kodları aynı)
               ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.date_range, color: AppColors.primary),
                title: Text(_startDate == null 
                    ? AppLocalizations.of(context)!.selectDateRange 
                    : "${DateFormat('dd/MM/yyyy', Localizations.localeOf(context).toString()).format(_startDate!)} - ${DateFormat('dd/MM/yyyy', Localizations.localeOf(context).toString()).format(_endDate!)}"),
                onTap: () async {
                  await _selectDateRange(context);
                  setModalState(() {});
                },
              ),
              const Divider(),

              Text(AppLocalizations.of(context)!.amountRange, style: const TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: AppLocalizations.of(context)!.minAmountLabel),
                      onChanged: (val) {
                        _minAmount = double.tryParse(val);
                        _filterReceipts();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: AppLocalizations.of(context)!.maxAmountLabel),
                      onChanged: (val) {
                        _maxAmount = double.tryParse(val);
                        _filterReceipts();
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text(AppLocalizations.of(context)!.categoryLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
              StreamBuilder<List<dynamic>>(
                stream: _databaseService.getCategories(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const CircularProgressIndicator();
                  final categories = snapshot.data!;
                  return DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedCategory,
                    hint: Text(AppLocalizations.of(context)!.categorySelectHint),
                    items: categories.map<DropdownMenuItem<String>>((c) {
                      return DropdownMenuItem<String>(
                        value: c.name,
                        child: Text(c.name),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setModalState(() {
                        _selectedCategory = val;
                      });
                      _filterReceipts();
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
              
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _startDate = null;
                      _endDate = null;
                      _minAmount = null;
                      _maxAmount = null;
                      _selectedCategory = null;
                    });
                    _filterReceipts();
                    Navigator.pop(context);
                  },
                  child: Text(AppLocalizations.of(context)!.clearFilters, style: const TextStyle(color: Colors.red)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: TextField(
          controller: _searchController,
          // autofocus: true, // Klavye hemen açılmasın, tab seçilebilsin
          decoration: InputDecoration(
            hintText: _tabController.index == 0 
                ? AppLocalizations.of(context)!.searchHint 
                : AppLocalizations.of(context)!.searchProductHint,
            border: InputBorder.none,
            hintStyle: const TextStyle(color: Colors.grey),
          ),
          style: const TextStyle(color: AppColors.textDark),
          onChanged: (val) => _filterReceipts(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterSheet,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: AppLocalizations.of(context)!.tabReceipts),
            Tab(text: AppLocalizations.of(context)!.tabProducts),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildReceiptList(),
                _buildProductList(),
              ],
            ),
    );
  }

  Widget _buildReceiptList() {
    if (_filteredReceipts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text(AppLocalizations.of(context)!.noResultsFound, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _filteredReceipts.length,
      itemBuilder: (context, index) {
        final receipt = _filteredReceipts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.primary.withOpacity(0.1),
              child: const Icon(Icons.receipt, color: AppColors.primary),
            ),
            title: Text(receipt.merchantName, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(DateFormat('dd MMMM yyyy', Localizations.localeOf(context).toString()).format(receipt.date)),
            trailing: Text(
              "${receipt.totalAmount.toStringAsFixed(2)} ₺",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EditReceiptScreen(receipt: receipt)),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProductList() {
    if (_searchController.text.length < 2) {
       return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_basket_outlined, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text(AppLocalizations.of(context)!.searchProductHint, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    if (_productResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 60, color: Colors.grey.shade300),
            const SizedBox(height: 10),
            Text(AppLocalizations.of(context)!.noResultsFound, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _productResults.length,
      itemBuilder: (context, index) {
        final item = _productResults[index];
        final isCheapeast = index == 0; // Sıralı geldiği için ilki en ucuzdur

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isCheapeast ? const BorderSide(color: Colors.green, width: 2) : BorderSide.none,
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _showProductHistory(context, item['productName']),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        item['productName'],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCheapeast)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          AppLocalizations.of(context)!.cheapestAt(item['merchantName']),
                          style: const TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.store, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              item['merchantName'],
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd MMM yyyy', Localizations.localeOf(context).toString()).format(item['date']),
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    Text(
                      "${(item['price'] as double).toStringAsFixed(2)} ₺",
                      style: TextStyle(
                        fontWeight: FontWeight.bold, 
                        fontSize: 20,
                        color: isCheapeast ? Colors.green : AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

Future<void> _showProductHistory(BuildContext context, String productName) async {
  // Basit bir dialog ile geçmişi göster
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text("$productName ${AppLocalizations.of(context)!.history}"),
      content: FutureBuilder<Map<String, dynamic>?>(
        future: _databaseService.getPriceHistoryForProducts([productName]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
          }
          // Servis şu an Map<String, dynamic> dönüyor (tekil ürün için map içinde map olabilir veya direk map)
          // Servis tanımı: Future<Map<String, dynamic>?> getPriceHistoryForProducts(List<String> productNames)
          // Dönen yapı: {'süt': {'price': 20, 'date': ...}} -> Bu sadece SON fiyatı veriyordu galiba?
          // Kontrol etmem lazım. Eğer sadece son fiyatı veriyorsa history değildir.
          // ScanScreen için yazılan price history metodu aslında sadece "önceki fiyatı" buluyordu.
          // Tam bir liste dönmüyor.
          
          // O zaman burada basitçe o anki bulunan ürünler listesinden aynı isimli olanları süzüp gösterelim.
          // Zaten _allReceipts hafızamızda.
          
          final history = _allReceipts.expand((r) => r.items.map((i) => {
            'date': r.date,
            'price': i.price,
            'merchant': r.merchantName,
            'name': i.name
          })).where((i) => (i['name'] as String).toLowerCase() == productName.toLowerCase()).toList();
          
          history.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
          
          if (history.isEmpty) return Text(AppLocalizations.of(context)!.noResultsFound);

          return SizedBox(
            width: double.maxFinite,
            height: 300,
            child: ListView.builder(
              itemCount: history.length,
              itemBuilder: (context, index) {
                final h = history[index];
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(h['merchant'] as String),
                  subtitle: Text(DateFormat('dd MMM yyyy', Localizations.localeOf(context).toString()).format(h['date'] as DateTime)),
                  trailing: Text(
                    "${(h['price'] as double).toStringAsFixed(2)} ₺",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              },
            ),
          );
        },
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Tamam")),
      ],
    ),
  );
}
}
