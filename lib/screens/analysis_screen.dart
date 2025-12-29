import 'package:flutter/material.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';
import 'package:intl/intl.dart';
import '../utils/currency_formatter.dart';

import 'package:flutter/foundation.dart'; // For compute
import '../utils/product_merger.dart';
import '../core/app_theme.dart';
import 'package:fismatik/services/supabase_database_service.dart';
import '../models/receipt_model.dart';
import '../widgets/empty_state.dart';
import '../widgets/error_state.dart';
import 'receipt_detail_screen.dart';
import '../services/auth_service.dart';
import '../widgets/web_ad_banner.dart';
import 'package:fismatik/services/intelligence_service.dart';
import 'package:fismatik/models/subscription_model.dart';
import 'package:uuid/uuid.dart';
import 'package:fismatik/widgets/shimmer_loading.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/usage_guard.dart';
import 'package:fismatik/services/product_normalization_service.dart';
import '../models/membership_model.dart';
import 'upgrade_screen.dart';
import 'package:fismatik/services/profile_service.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';

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
  late Stream<Map<String, dynamic>> _roleStream;
  final IntelligenceService _intelligenceService = IntelligenceService();
  final AuthService _authService = AuthService();
  String _currentTierId = 'standart';
  String? _userCity;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _receiptsStream = _databaseService.getUnifiedReceiptsStream();
    _settingsStream = _databaseService.getUserSettings();
    _roleStream = _databaseService.getUserRoleDataStream();
    
    // Check for Salary Day preference on init
    _checkInitialData();
    _loadUserCity();
  }

  Future<void> _loadUserCity() async {
    try {
      final profile = await ProfileService().getMyProfileOnce();
      if (profile != null && mounted) {
        setState(() {
          _userCity = profile.city;
        });
      }
    } catch (e) {
      print("AnalysisScreen city load error: $e");
    }
  }

  Future<void> _checkInitialData() async {
    _checkSalaryDayPreference();
    final results = await Future.wait<dynamic>([
      _authService.getCurrentTier(),
      _databaseService.loadGlobalProductMappings(),
    ]);
    
    if (mounted) {
      setState(() {
        _currentTierId = (results[0] as MembershipTier).id;
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
    context.watch<CurrencyProvider>(); // Rebuilds when currency changes
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
                       setState(() {
                         _receiptsStream = _databaseService.getUnifiedReceiptsStream();
                       });
                    },
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                // Receipts loaded, now fetch role and settings
                return StreamBuilder<Map<String, dynamic>>(
                  stream: _roleStream,
                  builder: (context, roleSnapshot) {
                    final roleData = roleSnapshot.data ?? {};
                    _currentTierId = roleData['tier_id'] as String? ?? 'standart';

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
                  CurrencyFormatter.format(totalSpent),
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

          // --- AKILLI ANALİZ VE İPUÇLARI BÖLÜMÜ ---
          _buildIntelligenceSection(context),
          
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
                        CurrencyFormatter.format(categoryTotal),
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
                                CurrencyFormatter.format(receipt.totalAmount),
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
    final rawItems = receipts.expand((r) => r.items.map((i) {
      final mappingData = _databaseService.getNormalizedData(i.name);
      return <String, dynamic>{
        'name': mappingData.name,
        'quantity': i.quantity,
        'price': i.price,
        'category': mappingData.category ?? i.category ?? _databaseService.guessCategoryFromName(i.name),
      };
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
                         CurrencyFormatter.format(categoryTotals[index].value),
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
                       final hasLocationAccess = _currentTierId == 'limitless' || _currentTierId == 'limitless_family';
                       return FutureBuilder<Map<String, dynamic>?>(
                         future: _databaseService.getLocationPriceStats(stat.name, city: hasLocationAccess ? _userCity : null),
                         builder: (context, globalSnapshot) {
                           final globalData = globalSnapshot.data;
                           final myAvgPrice = stat.count > 0 ? stat.totalAmount / stat.count : 0.0;
                           
                           // Eğer toplulukta %10 veya daha ucuz bir fiyat varsa işaretle
                           final hasBetterDeal = globalData != null && 
                                               globalData['min_price'] < myAvgPrice * 0.9;

                           return ListTile(
                             dense: true,
                             contentPadding: const EdgeInsets.symmetric(
                                 horizontal: 16, vertical: 4),
                             title: Row(
                               children: [
                                 Expanded(child: Text(stat.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                                 if (hasBetterDeal)
                                   Container(
                                     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                     decoration: BoxDecoration(
                                       color: Colors.green.shade100,
                                       borderRadius: BorderRadius.circular(4),
                                     ),
                                     child: const Text(
                                       "🌍 Fırsat!",
                                       style: TextStyle(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold),
                                     ),
                                   ),
                               ],
                             ),
                             subtitle: Column(
                               crossAxisAlignment: CrossAxisAlignment.start,
                               children: [
                                 Text(
                                   AppLocalizations.of(context)!.timesBought(stat.count.toString()),
                                   style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                 ),
                                 if (globalData != null)
                                   Padding(
                                     padding: const EdgeInsets.only(top: 2),
                                     child: Text(
                                       _userCity != null 
                                         ? AppLocalizations.of(context)!.cheapestInCity(_userCity!) + ": ${CurrencyFormatter.format(globalData['min_price'])} (${globalData['cheapest_merchant']})"
                                         : AppLocalizations.of(context)!.cheapestInCommunity + ": ${CurrencyFormatter.format(globalData['min_price'])} (${globalData['cheapest_merchant']})",
                                       style: TextStyle(fontSize: 10, color: hasBetterDeal ? Colors.green : Colors.grey[500], fontWeight: hasBetterDeal ? FontWeight.bold : FontWeight.normal),
                                     ),
                                   ),
                               ],
                             ),
                            trailing: Text(
                              CurrencyFormatter.format(stat.totalAmount),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            onTap: hasBetterDeal ? () {
                              // Eğer kullanıcı daha ucuz fiyat bulursa "Fiyat Dedektifi" rozeti için sayacı artır
                              _intelligenceService.incrementPriceDiscoveries(); 
                              // Not: IntelligenceService üzerinden de çağrılabilir veya doğrudan GamificationService.
                              // Şimdilik sadece bilgilendirme yapalım.
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("${stat.name} için toplulukta daha ucuz bir fiyat keşfettiniz!"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } : null,
                          );
                        },
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

  // --- AKILLI ANALİZ VE İPUÇLARI BÖLÜMÜ ---
  Widget _buildIntelligenceSection(BuildContext context) {
    final bool isPro = _currentTierId == 'limitless' || _currentTierId == 'limitless_family';
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.deepPurple.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.deepPurple.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.psychology, color: Colors.deepPurple, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                AppLocalizations.of(context)!.intelligenceTitle,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              if (!isPro)
                Icon(Icons.lock_outline, color: Colors.grey.shade400, size: 18),
            ],
          ),
          const SizedBox(height: 16),
          
          if (!isPro)
            _buildLockedIntelligence(context)
          else
            _buildActiveIntelligence(context),
        ],
      ),
    );
  }

  Widget _buildLockedIntelligence(BuildContext context) {
    return Column(
      children: [
        Text(
          AppLocalizations.of(context)!.intelligenceProOnly,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UpgradeScreen()),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepPurple,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(AppLocalizations.of(context)!.unlockIntelligence),
        ),
      ],
    );
  }

  Widget _buildActiveIntelligence(BuildContext context) {
    return FutureBuilder<List<Object>>(
      future: Future.wait([
        _intelligenceService.getBudgetPrediction(),
        _intelligenceService.getPersonalizedSavingTips(),
        _intelligenceService.detectPotentialSubscriptions(),
      ]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: Padding(
            padding: EdgeInsets.all(10.0),
            child: CircularProgressIndicator(strokeWidth: 2),
          ));
        }
        
        if (snapshot.hasError) return const SizedBox();

        final prediction = snapshot.data![0] as Map<String, dynamic>;
        final tips = snapshot.data![1] as List<String>;
        final potentialSubs = snapshot.data![2] as List<Map<String, dynamic>>;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bütçe Tahmini
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (prediction['isExceeding'] as bool) ? Colors.red.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(
                    (prediction['isExceeding'] as bool) ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                    color: (prediction['isExceeding'] as bool) ? Colors.red : Colors.green,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.predictedEndOfMonth(
                            CurrencyFormatter.format((prediction['predictedTotal'] as double))
                          ),
                          style: TextStyle(
                            fontSize: 12, 
                            fontWeight: FontWeight.bold,
                            color: (prediction['isExceeding'] as bool) ? Colors.red.shade800 : Colors.green.shade800,
                          ),
                        ),
                        Text(
                          (prediction['isExceeding'] as bool) 
                            ? AppLocalizations.of(context)!.budgetDanger 
                            : AppLocalizations.of(context)!.budgetSafe,
                          style: TextStyle(fontSize: 11, color: (prediction['isExceeding'] as bool) ? Colors.red.shade700 : Colors.green.shade700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Tasarruf İpucu
            if (tips.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.lightbulb_outline, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tips.first,
                      style: const TextStyle(fontSize: 12, color: AppColors.textDark),
                    ),
                  ),
                ],
              ),

            if (potentialSubs.isNotEmpty) ...[
              const Divider(height: 24),
              Text(
                AppLocalizations.of(context)!.potentialSubsTitle,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              ...potentialSubs.map((sub) => _buildPotentialSubItem(context, sub)).toList(),
            ],
          ],
        );
      },
    );
  }

  Widget _buildPotentialSubItem(BuildContext context, Map<String, dynamic> sub) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sub['merchant'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                Text("${CurrencyFormatter.format(sub['price'])} • Her ayın ${sub['renewalDay']}. günü", style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _addAsSubscription(sub),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(AppLocalizations.of(context)!.addAsSubscriptionShort, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _addAsSubscription(Map<String, dynamic> subData) async {
    try {
      final subscription = Subscription(
        id: const Uuid().v4(),
        name: subData['merchant'],
        price: subData['price'],
        renewalDay: subData['renewalDay'],
        colorHex: 'FF673AB7', // Deep Purple default
      );
      
      await _databaseService.saveSubscription(subscription);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.subscriptionAdded)),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e")),
        );
      }
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
