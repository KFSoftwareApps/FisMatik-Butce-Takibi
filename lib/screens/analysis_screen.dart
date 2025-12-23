import 'package:flutter/material.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';

import 'package:flutter/foundation.dart'; // For compute
import '../utils/product_merger.dart';
import '../core/app_theme.dart';
import '../services/supabase_database_service.dart';
import '../models/receipt_model.dart';
import '../widgets/empty_state.dart';
import 'receipt_detail_screen.dart';
import '../services/auth_service.dart';
import '../widgets/web_ad_banner.dart';
import '../services/ai_service.dart';
import '../widgets/shimmer_loading.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart'; // [NEW]
import '../services/usage_guard.dart'; // [NEW]

class AnalysisScreen extends StatefulWidget {
  const AnalysisScreen({super.key});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen>
    with SingleTickerProviderStateMixin {
  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService();
  late TabController _tabController;

  late List<String> _timeFilters;
  String _selectedTimeFilter = ''; // Initialized to empty, will be set in initState or build
  bool _isFirstLoad = true;

  late Stream<List<Receipt>> _receiptsStream;
  late Stream<Map<String, dynamic>> _settingsStream;
  final AuthService _authService = AuthService();
  String _currentTierId = 'standart';
  
  // Cache for the session to prevent flicker
  final Map<String, String> _adviceMemoryCache = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _receiptsStream = _databaseService.getUnifiedReceiptsStream();
    _settingsStream = _databaseService.getUserSettings();
    
    // Check for Salary Day preference on init
    _checkInitialData();
  }

  Future<void> _checkInitialData() async {
    _checkSalaryDayPreference();
    final tier = await _authService.getCurrentTier();
    if (mounted) {
      setState(() {
        _currentTierId = tier.id;
      });
    }
  }

  Future<void> _checkSalaryDayPreference() async {
     try {
       final settings = await _databaseService.getUserSettings().first;
       final salaryDay = settings['salary_day'] as int? ?? 1;
       
       if (salaryDay > 1 && mounted) {
          setState(() {
             _selectedTimeFilter = "Maaş Günü"; 
          });
       }
     } catch (e) {
       print("Error checking salary day pref: $e");
     }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _timeFilters = [
      AppLocalizations.of(context)!.thisWeek,
      AppLocalizations.of(context)!.thisMonth,
      AppLocalizations.of(context)!.salaryDay, 
      AppLocalizations.of(context)!.thisYear,
      AppLocalizations.of(context)!.all,
    ];

    // Only set default if it's NOT already set to a special value like "Maaş Günü"
    // and if the current value is invalid
    if (!_timeFilters.contains(_selectedTimeFilter)) {
       // If "Salary Day" was set but not in list yet (race condition), it stays.
       // But if it's completely invalid, revert to This Month.
       if (_selectedTimeFilter != AppLocalizations.of(context)!.salaryDay) {
          _selectedTimeFilter = AppLocalizations.of(context)!.thisMonth;
       }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.expenseAnalysis,
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        child: SafeArea(
          child: TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            tabs: [
              Tab(text: AppLocalizations.of(context)!.categories),
              Tab(text: AppLocalizations.of(context)!.products),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          _buildTimeFilters(),
          Expanded(
            child: StreamBuilder<List<Receipt>>(
              stream: _receiptsStream, // Use cached stream
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                // Receipts loaded, now fetch settings
                return StreamBuilder<Map<String, dynamic>>(
                  stream: _settingsStream, // Use cached stream
                  builder: (context, settingsSnapshot) {
                    final settings = settingsSnapshot.data ?? {'salary_day': 1};
                    final int salaryDay = settings['salary_day'] as int;

                    final filteredReceipts = _filterReceiptsByDate(snapshot.data!, salaryDay);

                    if (filteredReceipts.isEmpty) {
                      return Center(
                        child: Text(AppLocalizations.of(context)!.noReceiptsFoundInRange),
                      );
                    }

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        _buildCategoryTab(filteredReceipts),
                        _buildProductTab(filteredReceipts),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          if (kIsWeb && _currentTierId == 'standart')
            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildResponsiveAd(),
            ),
        ],
      ),
    );
  }

  Widget _buildResponsiveAd() {
    final double screenWidth = MediaQuery.of(context).size.width;
    
    // Mobil genişlik (< 728px) için 320x100, masaüstü için 728x90
    if (screenWidth < 728) {
      return const WebAdBanner(
        adSlot: '7909719452',
        width: 320,
        height: 100,
      );
    } else {
      return const WebAdBanner(
        adSlot: '7909719452',
        width: 728,
        height: 90,
      );
    }
  }

  Widget _buildTimeFilters() {
    // didChangeDependencies çalışmadan build gelirse diye min-güvence
    final filters = (_timeFilters.isNotEmpty) ? _timeFilters : <String>[];

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: filters.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final label = filters[index];
            final selected = label == _selectedTimeFilter;

            return ChoiceChip(
              label: Text(label),
              selected: selected,
              selectedColor: AppColors.primary.withOpacity(0.15),
              labelStyle: TextStyle(
                color: selected ? AppColors.primary : Colors.black87,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
              onSelected: (_) {
                setState(() => _selectedTimeFilter = label);
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
                side: BorderSide(
                  color: selected ? AppColors.primary : Colors.grey.shade300,
                ),
              ),
              backgroundColor: Colors.white,
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryTab(List<Receipt> receipts) {
    final currencyFormat = NumberFormat.currency(locale: 'tr_TR', symbol: '₺');

    final categoryData = _calculateCategoryData(receipts);
    final totalSpent =
        receipts.fold<double>(0, (sum, r) => sum + r.totalAmount);

    if (totalSpent <= 0 || categoryData.isEmpty) {
      return Center(child: Text(AppLocalizations.of(context)!.noCategoryData));
    }

    // Kategorileri en fazla harcamadan aza sırala
    final sortedEntries = categoryData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2575FC).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.totalSpendingLabel,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                Text(
                  currencyFormat.format(totalSpent),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // --- AI FİNANS KOÇU TAVSİYESİ ---
          // Sadece Pro ve Aile paketlerinde göster
          if (['limitless', 'limitless_family'].contains(_currentTierId))
            _buildAiAdviceCard(totalSpent, categoryData),
          
          const SizedBox(height: 20),

          // Kategori kartları
          ...sortedEntries.map((entry) {
            final categoryName = entry.key;
            final categoryTotal = entry.value;
            final percentage =
                (categoryTotal / totalSpent * 100).toStringAsFixed(1);

            final categoryReceipts =
                receipts.where((r) => r.category == categoryName).toList()
                  ..sort((a, b) => b.date.compareTo(a.date));

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  )
                ],
              ),
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getCategoryIcon(categoryName),
                      color: AppColors.primary,
                    ),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          categoryName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        currencyFormat.format(categoryTotal),
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: (categoryTotal / totalSpent).clamp(0, 1),
                              backgroundColor: Colors.grey[200],
                              valueColor:
                                  const AlwaysStoppedAnimation<Color>(
                                      AppColors.primary),
                              minHeight: 6,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '%$percentage',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(),
                    ),
                    if (categoryReceipts.isEmpty)
                       Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(AppLocalizations.of(context)!.noTransactionInCategory),
                      )
                    else
                      ...categoryReceipts.map((receipt) {
                        return ListTile(
                          dense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.receipt_long,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ),
                          title: Text(
                            receipt.merchantName,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            DateFormat('dd.MM.yyyy HH:mm').format(receipt.date),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                currencyFormat.format(receipt.totalAmount),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.chevron_right,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ],
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ReceiptDetailScreen(receipt: receipt),
                              ),
                            );
                          },
                        );
                      }).toList(),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildProductTab(List<Receipt> receipts) {
    // 1. Prepare raw items for Isolate (Run on main thread, O(N))
    // We guess categories here to pass simple strings to the isolate
    final rawItems = receipts.expand((r) => r.items.map((i) => <String, dynamic>{
      'name': i.name,
      'quantity': i.quantity,
      'price': i.price,
      'category': i.category ?? _guessCategoryFromName(i.name),
    })).toList();

    // 2. Run merging logic in background
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: compute(ProductMerger.calculateStats, rawItems),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
           return const Center(child: CircularProgressIndicator());
        }
        
        if (snapshot.hasError) {
           return Center(child: Text("${AppLocalizations.of(context)!.generalError}: ${snapshot.error}"));
        }
        
        // 3. Convert back to objects
        final statsMaps = snapshot.data ?? [];
        if (statsMaps.isEmpty) {
           return Center(
             child: Text(AppLocalizations.of(context)!.noProductsToShow),
           );
        }

        final productStats = statsMaps.map((m) => _ProductStat(
           name: m['name'],
           count: (m['count'] as num).toInt(),
           totalAmount: (m['totalAmount'] as num).toDouble(),
           category: m['category'] ?? 'Diğer',
        )).toList();
        
        // --- EXISTING UI BUILDING LOGIC ---
        
        // Kategorilere göre grupla
        final Map<String, List<_ProductStat>> groupedStats = {};
        for (final stat in productStats) {
          groupedStats.putIfAbsent(stat.category, () => []);
          groupedStats[stat.category]!.add(stat);
        }
    
        // Kategori toplamlarını hesapla ve sırala
        final categoryTotals = groupedStats.entries.map((entry) {
          final total =
              entry.value.fold<double>(0, (sum, item) => sum + item.totalAmount);
          return MapEntry(entry.key, total);
        }).toList()
          ..sort((a, b) => b.value.compareTo(a.value));
          
        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: categoryTotals.length,
          itemBuilder: (context, index) {
            final categoryName = categoryTotals[index].key;
            // ... (rest uses categoryTotals[index]) ...
            final items = groupedStats[categoryName]!
              ..sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                  )
                ],
              ),
              child: Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  tilePadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _getCategoryIcon(categoryName),
                      color: AppColors.primary,
                    ),
                  ),
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          categoryName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                         // Need to access formatted total here or calculate it
                         NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(categoryTotals[index].value),
                         style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(),
                    ),
                    ...items.map((stat) {
                      return ListTile(
                        dense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        title: Text(
                          stat.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          AppLocalizations.of(context)!.timesBought(stat.count.toString()),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        trailing: Text(
                          NumberFormat.currency(locale: 'tr_TR', symbol: '₺').format(stat.totalAmount),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }).toList(),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      }
    );
  }



  // _levenshteinDistance ve _findSimilarProduct metodları PERFORMANS SORUNU (ANR) NEDENİYLE KALDIRILDI.
  // Gerekirse ileride Isolate içinde tekrar eklenebilir.



  String _guessCategoryFromName(String name) {
    final lowerName = name.toLowerCase().trim();

    // Hariç Tutulacaklar (Kategori olarak sayılmayacaklar)
    if (lowerName.contains('indirim') ||
        lowerName.contains('kdv') ||
        lowerName.contains('vergi') ||
        lowerName.contains('iskonto') ||
        lowerName.contains('toplam') ||
        lowerName.contains('ara toplam')) {
      return 'Diğer'; 
    }

    // --- EV EŞYASI & ZÜCCACİYE ---
    if (lowerName.contains('sürahi') ||
        lowerName.contains('cam') ||
        lowerName.contains('bardak') ||
        lowerName.contains('tabak') ||
        lowerName.contains('kaşık') ||
        lowerName.contains('çatal') ||
        lowerName.contains('bıçak') ||
        lowerName.contains('tencere') ||
        lowerName.contains('tava') ||
        lowerName.contains('kase') ||
        lowerName.contains('fincan') ||
        lowerName.contains('kavanoz') ||
        lowerName.contains('plastik') ||
        lowerName.contains('mutfak') ||
        lowerName.contains('züccaciye')) {
      return 'Ev Eşyası';
    }

    // --- MARKET & GIDA ---
    
    // Temel Gıda & Kahvaltılık
    if (lowerName.contains('ekmek') ||
        lowerName.contains('yumurta') ||
        lowerName.contains('peynir') ||
        lowerName.contains('kasar') || lowerName.contains('kaşar') ||
        lowerName.contains('labne') ||
        lowerName.contains('yogurt') || lowerName.contains('yoğurt') ||
        lowerName.contains('süt') || // "süt" kelimesi dikkatli kullanılmalı
        lowerName.contains('kaymak') ||
        lowerName.contains('tereyag') || lowerName.contains('tereyağ') ||
        lowerName.contains('margarin') ||
        lowerName.contains('zeytin') ||
        lowerName.contains('reçel') || lowerName.contains('recel') ||
        lowerName.contains('bal') ||
        lowerName.contains('helva') ||
        lowerName.contains('un') ||
        lowerName.contains('seker') || lowerName.contains('şeker') ||
        lowerName.contains('tuz') ||
        lowerName.contains('makarna') ||
        lowerName.contains('pirinç') || lowerName.contains('pirinc') ||
        lowerName.contains('bulgur') ||
        lowerName.contains('mercimek') ||
        lowerName.contains('nohut') ||
        lowerName.contains('fasulye') ||
        lowerName.contains('salça') || lowerName.contains('salca') ||
        lowerName.contains('yağ') || lowerName.contains('yağ')) { // ayçiçek yağı vb
      return 'Market';
    }

    // Et & Balık
    if (lowerName.contains('kıyma') || lowerName.contains('kiyma') ||
        lowerName.contains('kuşbaşı') || lowerName.contains('kusbasi') ||
        lowerName.contains('biftek') ||
        lowerName.contains('antrikot') ||
        lowerName.contains('bonfile') ||
        lowerName.contains('köfte') || lowerName.contains('kofte') ||
        lowerName.contains('tavuk') ||
        lowerName.contains('piliç') || lowerName.contains('pilic') ||
        lowerName.contains('kanat') ||
        lowerName.contains('baget') ||
        lowerName.contains('bütün tavuk') ||
        lowerName.contains('balık') || lowerName.contains('balik') ||
        lowerName.contains('hamsi') ||
        lowerName.contains('somon') ||
        lowerName.contains('ton balığı') ||
        lowerName.contains('sucuk') ||
        lowerName.contains('salam') ||
        lowerName.contains('sosis') ||
        lowerName.contains('pastırma')) {
      return 'Market'; 
    }

    // Sebze & Meyve
    if (lowerName.contains('domates') ||
        lowerName.contains('biber') ||
        lowerName.contains('patlıcan') ||
        lowerName.contains('salatalık') ||
        lowerName.contains('kabak') ||
        lowerName.contains('soğan') || lowerName.contains('sogan') ||
        lowerName.contains('patates') ||
        lowerName.contains('havuç') ||
        lowerName.contains('marul') ||
        lowerName.contains('maydanoz') ||
        lowerName.contains('dereotu') ||
        lowerName.contains('elma') ||
        lowerName.contains('muz') ||
        lowerName.contains('portakal') ||
        lowerName.contains('mandalina') ||
        lowerName.contains('limon') ||
        lowerName.contains('karpuz') ||
        lowerName.contains('kavun') ||
        lowerName.contains('çilek') ||
        lowerName.contains('üzüm')) {
      return 'Market';
    }

    // İçecekler (Market Altında Olarak da Düşünülebilir ama Ayrı İstenirse Değiştirilebilir)
    if (lowerName.contains('su ') || lowerName == 'su' ||
        lowerName.contains('maden suyu') ||
        lowerName.contains('soda') ||
        lowerName.contains('kola') ||
        lowerName.contains('cola') ||
        lowerName.contains('pepsi') ||
        lowerName.contains('fanta') ||
        lowerName.contains('sprite') ||
        lowerName.contains('gazoz') ||
        lowerName.contains('soğuk çay') || lowerName.contains('ice tea') ||
        lowerName.contains('limonata') ||
        lowerName.contains('meyve suyu') ||
        lowerName.contains('ayran') ||
        lowerName.contains('kefir') ||
        lowerName.contains('bira') ||
        lowerName.contains('rakı') ||
        lowerName.contains('şarap') ||
        lowerName.contains('votka') ||
        lowerName.contains('viski') || 
        lowerName.contains('kahve') ||
        lowerName.contains('çay') || lowerName.contains('cay') ||
        lowerName.contains('sahlep')) {
      return 'Market'; 
    }

    // Abur Cubur / Atıştırmalık
    if (lowerName.contains('çikolata') || lowerName.contains('cikolata') ||
        lowerName.contains('gofret') ||
        lowerName.contains('bisküvi') || lowerName.contains('biskuvi') ||
        lowerName.contains('kraker') ||
        lowerName.contains('cips') ||
        lowerName.contains('kuruyemiş') ||
        lowerName.contains('fıstık') ||
        lowerName.contains('fındık') ||
        lowerName.contains('ceviz') ||
        lowerName.contains('sakız') ||
        lowerName.contains('dondurma') ||
        lowerName.contains('kek') ||
        lowerName.contains('kraker')) {
      return 'Atıştırmalık';
    }



    // Sigara & Tütün Ürünleri
    if (lowerName.contains('sigara') ||
        lowerName.contains('marlboro') ||
        lowerName.contains('parliament') ||
        lowerName.contains('winston') ||
        lowerName.contains('camel') ||
        lowerName.contains('kent') ||
        lowerName.contains('muratti') ||
        lowerName.contains('davidoff') ||
        lowerName.contains('chesterfield') ||
        lowerName.contains('lark') ||
        lowerName.contains('l&m') || lowerName.contains('lm ') ||
        lowerName.contains('pall mall') ||
        lowerName.contains('lucky strike') ||
        lowerName.contains('rothmans') ||
        lowerName.contains('monte carlo') ||
        lowerName.contains('west') ||
        lowerName.contains('violet') ||
        lowerName.contains('samsun') ||
        lowerName.contains('maltepe') ||
        lowerName.contains('2000') ||
        lowerName.contains('tekel') ||
        lowerName.contains('tütün') ||
        lowerName.contains('makaron') ||
        lowerName.contains('filtre')) {
      return 'Sigara';
    }

    return 'Diğer';
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Market':
        return Icons.shopping_cart;
      case 'Akaryakıt':
        return Icons.local_gas_station;
      case 'Yeme-İçme':
        return Icons.restaurant;
      case 'Sigara':
        return Icons.smoking_rooms;
      case 'Giyim':
        return Icons.checkroom;
      case 'Teknoloji':
      case 'Elektronik':
        return Icons.computer;
      case 'Sigara':
        return Icons.smoking_rooms;
      case 'Alkol':
        return Icons.local_bar;
      case 'Gıda':
        return Icons.fastfood;
      case 'Et & Tavuk':
        return Icons.set_meal;
      case 'İçecek':
        return Icons.local_cafe;
      case 'Baharat & Çeşni':
        return Icons.grass;
      case 'Meyve & Sebze':
        return Icons.eco;
      case 'Atıştırmalık':
        return Icons.cookie;
      case 'Temizlik & Bakım':
        return Icons.cleaning_services;
      case 'Kişisel Bakım':
        return Icons.face;
      case 'Ev Eşyası':
        return Icons.home;
      case 'Hizmet':
        return Icons.build;
      case 'Diğer':
      case 'Diğer Ürünler':
        return Icons.category;
      case 'Sabit Gider':
        return Icons.autorenew;
      default:
        return Icons.category;
    }
  }

  Widget _buildEmptyState() {
    return const EmptyState(
      icon: Icons.analytics_outlined,
      title: 'Henüz Analiz Yok',
      description: 'Fiş tarayarak harcama analizlerinizi görüntüleyin',
      color: AppColors.primary,
    );
  }

  Map<String, double> _calculateCategoryData(List<Receipt> receipts) {
    final Map<String, double> data = {};
    for (final receipt in receipts) {
      final category = receipt.category;
      data[category] = (data[category] ?? 0) + receipt.totalAmount;
    }
    return data;
  }

  List<Receipt> _filterReceiptsByDate(List<Receipt> receipts, int salaryDay) {
    final now = DateTime.now();
    final localizations = AppLocalizations.of(context)!;
    
    // "Tümü" seçiliyse filtreleme yapma
    if (_selectedTimeFilter == localizations.all) {
      return receipts;
    }

    return receipts.where((receipt) {
      if (_selectedTimeFilter == "Maaş Günü") {
        // Maaş Günü Mantığı
        DateTime startDate, endDate;
        
        if (now.day >= salaryDay) {
          // Maaş bu ay yatmış (örn: Maaş 15'i, Bugün 20'si -> 15'inden 14'üne)
          startDate = DateTime(now.year, now.month, salaryDay);
          endDate = DateTime(now.year, now.month + 1, salaryDay).subtract(const Duration(seconds: 1));
        } else {
          // Maaş henüz yatmamış, önceki aydan say (örn: Maaş 15'i, Bugün 10'u -> Geçen ay 15 - Bu ay 14)
          startDate = DateTime(now.year, now.month - 1, salaryDay);
          endDate = DateTime(now.year, now.month, salaryDay).subtract(const Duration(seconds: 1));
        }
        
        return receipt.date.isAfter(startDate.subtract(const Duration(seconds: 1))) && 
               receipt.date.isBefore(endDate.add(const Duration(seconds: 1)));
               
      } else if (_selectedTimeFilter == localizations.thisWeek) {
        // Bu Hafta (Pazartesi'den Pazar'a)
        final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
        
        final receiptDate = DateTime(receipt.date.year, receipt.date.month, receipt.date.day);
        final start = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
        final end = DateTime(endOfWeek.year, endOfWeek.month, endOfWeek.day, 23, 59, 59);
        
        return receiptDate.isAfter(start.subtract(const Duration(seconds: 1))) &&
               receiptDate.isBefore(end.add(const Duration(seconds: 1)));
               
      } else if (_selectedTimeFilter == localizations.thisMonth) {
         // Bu Ay (Takvim ayı: 1 - 30/31)
         return receipt.date.year == now.year && receipt.date.month == now.month;
         
      } else if (_selectedTimeFilter == localizations.thisYear) {
         // Bu Yıl
         return receipt.date.year == now.year;
      }
      
      return true;
    }).toList();
  }

  Widget _buildAiAdviceCard(double totalSpent, Map<String, double> categoryData) {
    return FutureBuilder<String?>(
      future: _getFinancialAdviceSafe(totalSpent, categoryData),
      builder: (context, snapshot) {
        final advice = snapshot.data;
        final isLoading = snapshot.connectionState == ConnectionState.waiting;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: advice == null && isLoading 
            ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
            : advice == null 
               ? const SizedBox.shrink() // Limit dolduysa veya hata varsa gizle
               : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "AI Finans Koçu",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.textDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (isLoading)
                CardShimmer(height: 60, margin: EdgeInsets.zero)
              else
                Text(
                  advice!, // Safe because of outer check
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade700,
                    height: 1.5,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Future<String?> _getFinancialAdviceSafe(double totalSpent, Map<String, double> categoryData) async {
    // 1. Tier Check (Extra güvenlik)
    if (!['limitless', 'limitless_family'].contains(_currentTierId)) {
      return null;
    }

    final userId = _authService.currentUser?.id;
    if (userId == null) return null;

    // 2. Memory Cache Check
    final now = DateTime.now();
    final todayStr = DateFormat('yyyyMMdd').format(now);
    // Filtreye göre key oluştur
    final filterKey = _selectedTimeFilter.replaceAll(' ', '_'); 
    final cacheKey = '${userId}_${todayStr}_$filterKey';
    
    if (_adviceMemoryCache.containsKey(cacheKey)) {
      return _adviceMemoryCache[cacheKey];
    }

    // 3. Disk Cache Check (SharedPreferences)
    final prefs = await SharedPreferences.getInstance();
    final diskCacheKey = 'fismatik_advice_$cacheKey';
    final diskCached = prefs.getString(diskCacheKey);
    if (diskCached != null) {
      _adviceMemoryCache[cacheKey] = diskCached;
      return diskCached;
    }

    // 4. Usage Guard Check
    // Kullanıcının hakkı var mı?
    final guard = await UsageGuard.checkAndConsume(UsageFeature.aiCoach);
    if (!guard.isAllowed) {
      // Limit dolduysa veya hata varsa null dön (UI gizler)
      return null;
    }

    // 5. Fetch from AI
    try {
      final advice = await AiService().getFinancialAdvice(totalSpent, categoryData);
      if (advice != null) {
        if (!advice.contains('Hata')) {
           _adviceMemoryCache[cacheKey] = advice;
           await prefs.setString(diskCacheKey, advice);
        }
        return advice;
      } else {
        // null döndüyse hak iadesi yap
        await UsageGuard.refund(UsageFeature.aiCoach);
        return null;
      }
    } catch (e) {
      await UsageGuard.refund(UsageFeature.aiCoach);
      return null;
    }
  }
}

class _ProductStat {
  final String name;
  int count;
  double totalAmount;
  final String category;

  _ProductStat({
    required this.name,
    required this.count,
    required this.totalAmount,
    required this.category,
  });
}
