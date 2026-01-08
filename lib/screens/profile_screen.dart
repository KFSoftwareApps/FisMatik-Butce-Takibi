import 'package:flutter/foundation.dart'; // [NEW]
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supa;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/currency_provider.dart';
import '../utils/currency_formatter.dart';
import '../services/network_time_service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_theme.dart';
import '../services/supabase_database_service.dart';
import '../services/auth_service.dart';
import '../services/family_service.dart';
import '../services/notification_service.dart';
import '../services/export_service.dart';
import '../services/report_service.dart';
import '../models/membership_model.dart';
import '../models/receipt_model.dart';
import '../models/subscription_model.dart';
import '../models/credit_model.dart';
import 'package:fismatik/services/product_normalization_service.dart';

import 'login_screen.dart';
import 'about_screen.dart';
import 'edit_profile_screen.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';
import 'upgrade_screen.dart';
import 'history_screen.dart';
import 'family_plan_screen.dart';
import 'history_screen.dart';
import 'subscriptions_screen.dart';
import 'fixed_expenses_screen.dart';
import 'installment_expenses_screen.dart';
import 'categories_screen.dart';
import 'upgrade_screen.dart';
import 'edit_profile_screen.dart';
import 'admin_screen.dart';
import 'family_plan_screen.dart'; // Changed from family_screen.dart
import 'badges_screen.dart';
import 'spending_trends_screen.dart';
import 'notification_settings_screen.dart';
import 'gamification_dashboard.dart';
import 'scan_screen.dart';
import 'search_screen.dart';
import 'product_list_screen.dart';
import 'shopping_list_screen.dart';
import 'package:fismatik/main.dart'; // languageNotifier için
import 'package:fismatik/services/sms_service.dart';
import 'package:fismatik/services/profile_service.dart';
import 'package:fismatik/models/user_profile_model.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService();
  final supa.SupabaseClient _client = supa.Supabase.instance.client;
  bool _isLoadingDelete = false;
  bool _smsTrackingEnabled = false;
  String? _city;
  String? _district;


  late Stream<Map<String, dynamic>> _userRoleStream;
  late Stream<List<Receipt>> _receiptsStream;


  @override
  void initState() {
    super.initState();
    _initStreams();
    _checkExpiration();
    _loadGlobalProductMappings();
    _loadSmsPreference();
    _loadUserProfile();
  }

  void _initStreams() {
    _userRoleStream = _databaseService.getUserRoleDataStream();
    _receiptsStream = _databaseService.getReceipts();
  }
  
  void _checkExpiration() async {
    try {
      await _databaseService.checkAndDowngradeIfExpired();
    } catch (e) {
      if (mounted) {
         // Error handling
      }
    }
  }

  void _loadGlobalProductMappings() {
     _databaseService.loadGlobalProductMappings();
  }

  // ... (keeping other init methods)

  @override
  Widget build(BuildContext context) {
    context.watch<CurrencyProvider>();
    return StreamBuilder<Map<String, dynamic>>(
      stream: _userRoleStream,
      builder: (context, roleSnapshot) {
        if (roleSnapshot.hasError) {
          debugPrint("Role stream error: ${roleSnapshot.error}");
          // Fallback to empty map or proceed
        }
        
        if (roleSnapshot.connectionState == ConnectionState.waiting && !roleSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final roleData = roleSnapshot.data ?? {};
        

        final tierId = roleData['tier_id'] as String? ?? 'standart';
        final expiresAtStr = roleData['expires_at'] as String?;
        final expiresAt = expiresAtStr != null ? DateTime.tryParse(expiresAtStr) : null;

        final currentTier = MembershipTier.Tiers[tierId] ?? MembershipTier.Tiers['standart']!;
        final user = supa.Supabase.instance.client.auth.currentUser;
        final String email = user?.email ?? "Misafir Kullanıcı";
        final String displayName = user?.userMetadata?['full_name'] ?? email.split('@')[0];

        return StreamBuilder<List<Receipt>>(
          stream: _receiptsStream,
          builder: (context, receiptsSnapshot) {
            // Show loading or use empty list if waiting but allow building structure
            final bool isReceiptsLoading = receiptsSnapshot.connectionState == ConnectionState.waiting && !receiptsSnapshot.hasData;
            final receipts = receiptsSnapshot.data ?? [];
            final now = DateTime.now();

            // İstatistikler
            final monthlyReceipts = receipts.where((r) =>
              r.date.year == now.year && r.date.month == now.month
            ).toList();

            final monthlySpent = monthlyReceipts.fold<double>(
              0, (sum, r) => sum + r.totalAmount
            );

            final avgPerReceipt = receipts.isEmpty
              ? 0.0
              : receipts.fold<double>(0, (sum, r) => sum + r.totalAmount) / receipts.length;

            if (isReceiptsLoading) {
               return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            return Scaffold(
              backgroundColor: AppColors.background,
              body: SafeArea(
                child: RefreshIndicator(
                  onRefresh: () async {
                    await _databaseService.checkAndDowngradeIfExpired();
                    setState(() {});
                  },
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        _buildProfileHeader(displayName, email),
                        const SizedBox(height: 24),
                        _buildStatsCards(monthlySpent, receipts.length, avgPerReceipt),
                        const SizedBox(height: 20),
                        const SizedBox(height: 20),
                        _buildMembershipCard(currentTier, expiresAt),
                        const SizedBox(height: 20),
                        if (tierId == 'limitless' || tierId == 'limitless_family' || tierId == 'premium') ...[
                          _buildSmartPriceTracker(context, receipts),
                          const SizedBox(height: 20),
                        ],
                        // Budget Progress Removed
                        // _buildMonthlyProgress(totalBudgetSpent, monthlyLimit), 
                        
                const SizedBox(height: 20),
                // Admin Paneli Kontrolü
                FutureBuilder<bool>(
                  future: supa.Supabase.instance.client
                      .from('user_roles')
                      .select('is_admin')
                      .eq('user_id', user?.id ?? '')
                      .maybeSingle()
                      .then((val) => val?['is_admin'] == true)
                      .catchError((_) => false),
                  builder: (context, adminSnapshot) {
                    if (adminSnapshot.data == true) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 20),
                        child: _buildSettingsTile(
                          context,
                          icon: Icons.admin_panel_settings,
                          title: "Admin Paneli",
                          subtitle: AppLocalizations.of(context)!.adminSubtitle,
                          color: Colors.deepPurple,
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.deepPurple),
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen())),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                            const SizedBox(height: 20),
                            _buildSectionTitle(AppLocalizations.of(context)!.accountSection),
                            if (tierId == 'limitless_family')
                              _buildSettingsTile(
                                context,
                                icon: Icons.family_restroom,
                                title: AppLocalizations.of(context)!.familyPlan,
                                color: Colors.pink,
                                trailing: FutureBuilder<List<Map<String, dynamic>>>(
                                  future: FamilyService().getPendingInvitations(),
                                  builder: (context, snapshot) {
                                    if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                                      return Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                        child: Text("${snapshot.data!.length}", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                      );
                                    }
                                    return const Icon(Icons.arrow_forward_ios, size: 16);
                                  },
                                ),
                                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FamilyPlanScreen())),
                              ),
                            if (tierId == 'limitless' || tierId == 'limitless_family' || tierId == 'premium')
                            _buildSettingsTile(
                              context,
                              icon: Icons.shopping_basket_outlined,
                              title: AppLocalizations.of(context)!.shoppingListTitle,
                              color: Colors.green, // Choose a nice color
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShoppingListScreen())),
                            ),
                            _buildSettingsTile(
                              context,
                              icon: Icons.account_balance_wallet_outlined,
                              title: AppLocalizations.of(context)!.fixedExpenses,
                              color: Colors.purple,
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FixedExpensesScreen())),
                            ),
                            _buildSettingsTile(
                              context,
                              icon: Icons.receipt_long_outlined,
                              title: AppLocalizations.of(context)!.installmentExpensesTitle ?? "Taksitli Giderler",
                              color: Colors.blue,
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InstallmentExpensesScreen())),
                            ),
                            _buildSettingsTile(
                              context,
                              icon: Icons.history,
                              title: AppLocalizations.of(context)!.history,
                              color: Colors.deepOrange,
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HistoryScreen())),
                            ),
                            _buildSettingsTile(
                              context,
                              icon: Icons.trending_up,
                              title: AppLocalizations.of(context)!.spendingTrends,
                              subtitle: AppLocalizations.of(context)!.spendingTrendsSubtitle,
                              color: Colors.orange,
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SpendingTrendsScreen())),
                            ),
                            _buildSettingsTile(
                              context,
                              icon: Icons.category_outlined,
                              title: AppLocalizations.of(context)!.myCategories,
                              color: Colors.teal,
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoriesScreen())),
                            ),
                            _buildSettingsTile(
                              context,
                              icon: Icons.emoji_events,
                              title: AppLocalizations.of(context)!.myAchievements,
                              subtitle: AppLocalizations.of(context)!.achievementsSubtitle,
                              color: Colors.amber,
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GamificationDashboard())),
                            ),
                            const SizedBox(height: 20),
                            _buildSectionTitle(AppLocalizations.of(context)!.settingsSection),

                            _buildSettingsTile(
                              context,
                              icon: Icons.notifications_outlined,
                              title: AppLocalizations.of(context)!.notificationSettings,
                              subtitle: AppLocalizations.of(context)!.notificationSettingsSubtitle,
                              color: Colors.deepOrange,
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationSettingsScreen())),
                            ),
                            const SizedBox(height: 12),
                            if (defaultTargetPlatform == TargetPlatform.android)
                              _buildSettingsTile(
                                context,
                                icon: Icons.sms_outlined,
                                title: AppLocalizations.of(context)!.smsTrackingTitle,
                                subtitle: AppLocalizations.of(context)!.smsTrackingDesc,
                                color: Colors.blue,
                                trailing: Switch.adaptive(
                                  value: _smsTrackingEnabled,
                                  onChanged: _toggleSmsTracking,
                                  activeColor: AppColors.primary,
                                ),
                              ),
                            const SizedBox(height: 20),
                            _buildSectionTitle(AppLocalizations.of(context)!.otherSection),
                            _buildSettingsTile(
                              context,
                              icon: Icons.table_chart_outlined,
                              title: AppLocalizations.of(context)!.exportExcel,
                              color: Colors.green.shade700,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (tierId == 'standart')
                                    const Icon(Icons.lock, size: 14, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.download, size: 16),
                                ],
                              ),
                              onTap: () async {
                                if (tierId == 'standart') {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const UpgradeScreen()));
                                  return;
                                }
                                final databaseService = SupabaseDatabaseService();
                                final now = DateTime.now();
                                final receipts = await databaseService.getMonthAnalysisData(now);
                                if (context.mounted) {
                                  await ReportService().generateAndShareExcelReport(receipts);
                                }
                              },
                            ),
                            _buildSettingsTile(
                              context,
                              icon: Icons.receipt_long,
                              title: AppLocalizations.of(context)!.exportTaxReport,
                              color: Colors.redAccent,
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (tierId == 'standart')
                                    const Icon(Icons.lock, size: 14, color: Colors.amber),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.download, size: 16),
                                ],
                              ),
                              onTap: () async {
                                if (tierId == 'standart') {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const UpgradeScreen()));
                                  return;
                                }
                                // Vergi raporu için de yeni PDF sistemini veya özelleştirilmiş raporu kullanabiliriz.
                                // Şimdilik mevcut Excel sistemini yeni verilerle çağırıyoruz.
                                final databaseService = SupabaseDatabaseService();
                                final now = DateTime.now();
                                final receipts = await databaseService.getMonthAnalysisData(now);
                                if (context.mounted) {
                                  final start = DateTime(now.year, now.month, 1);
                                  await ReportService().generateAndSharePdfReport(receipts, start, now, isTaxReport: true);
                                }
                              },
                            ),
                            _buildSettingsTile(
                              context,
                              icon: Icons.language,
                              title: AppLocalizations.of(context)!.language,
                              color: Colors.cyan,
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: _showLanguageDialog,
                            ),
                            _buildSettingsTile(
                              context,
                              icon: Icons.info_outline,
                              title: AppLocalizations.of(context)!.aboutUs,
                              color: Colors.blueGrey,
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen())),
                            ),

                            _buildSettingsTile(
                              context,
                              icon: Icons.gavel,
                              title: "EULA (Apple Standard)",
                              color: Colors.blueGrey,
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () => launchUrl(Uri.parse('https://www.apple.com/legal/internet-services/itunes/dev/stdeula/')),
                            ),
                            const SizedBox(height: 10),
                            _buildSettingsTile(
                              context,
                              icon: Icons.delete_forever,
                              title: AppLocalizations.of(context)!.deleteAccountTitle,
                              color: Colors.red.shade700,
                              onTap: _handleDeleteAccount,
                            ),
                            const SizedBox(height: 10),
                            _buildSettingsTile(
                              context,
                              icon: Icons.logout,
                              title: AppLocalizations.of(context)!.logout,
                              color: Colors.redAccent,
                              onTap: () => _showLogoutDialog(context),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                );

          },
        );
      },
    );
  }

  Future<void> _launchSubscriptionManagement() async {
    Uri url;
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      url = Uri.parse('https://apps.apple.com/account/subscriptions');
    } else {
      url = Uri.parse('https://play.google.com/store/account/subscriptions');
    }

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.subscriptionPageLoadError)),
        );
      }
    }
  }

  Widget _buildProfileHeader(String displayName, String email) {
    final user = supa.Supabase.instance.client.auth.currentUser;
    final avatarUrl = user?.userMetadata?['avatar_url'];

    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                    )
                  ],
                  color: avatarUrl != null ? null : AppColors.primary.withOpacity(0.1),
                  image: avatarUrl != null
                      ? DecorationImage(
                          image: NetworkImage(avatarUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: avatarUrl == null
                    ? Center(
                        child: Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : "?",
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          Text(
            email,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSmartPriceTracker(BuildContext context, List<Receipt> receipts) {
    // Sadece tüm ürün isimlerini topla (Detay ekranı için lazım)
    final List<String> allRawNames = receipts.expand((r) => r.items.map((i) => i.name)).toList();

    return GestureDetector(
      onTap: () => _showAllProductsScreen(context, allRawNames, receipts),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.08),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: AppColors.primary.withOpacity(0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.orange, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.smartPriceTrackerTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.smartPriceTrackerSubTitle,
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
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyTrackerCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Icon(Icons.insights, color: Colors.grey.shade400, size: 32),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)!.noProductHistory,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildProductTag(BuildContext context, String productName, List<Receipt> allReceipts) {
    return ActionChip(
      avatar: const Icon(Icons.shopping_bag_outlined, size: 16, color: AppColors.primary),
      label: Text(productName),
      onPressed: () => _showDetailedProductHistory(context, productName, allReceipts),
      backgroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withOpacity(0.2)),
      ),
    );
  }

  Future<void> _showDetailedProductHistory(BuildContext context, String productName, List<Receipt> allReceipts) async {
    final targetName = productName.trim().toLowerCase();
    
    final history = allReceipts.expand((r) => r.items.map((i) => {
      'date': r.date,
      'price': i.price,
      'merchant': r.merchantName,
      'name': i.name,
      'normalized_name': _databaseService.normalizeProductName(i.name).trim().toLowerCase()
    })).where((i) {
      final iName = (i['name'] as String).trim().toLowerCase();
      final iNormalized = (i['normalized_name'] as String);
      return iNormalized == targetName || iName == targetName;
    }).toList();
    
    history.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));

    // Market Önerisi Hesapla (Son 3 aydaki en ucuz market)
    String? bestMarket;
    double minPrice = double.infinity;
    if (history.isNotEmpty) {
      for (var h in history) {
        final price = (h['price'] as num).toDouble();
        if (price < minPrice) {
          minPrice = price;
          bestMarket = h['merchant'] as String?;
        }
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    productName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
              ],
            ),
            if (bestMarket != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars, color: Colors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppLocalizations.of(context)!.marketRecommendation(bestMarket!),
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                          Text(
                            AppLocalizations.of(context)!.bestPriceRecently,
                            style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 24),
            Text(AppLocalizations.of(context)!.viewHistory, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                itemCount: history.length,
                separatorBuilder: (c, i) => const Divider(),
                itemBuilder: (c, i) {
                  final h = history[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(h['merchant'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text(DateFormat('dd MMMM yyyy').format(h['date'] as DateTime)),
                    trailing: Text(
                      CurrencyFormatter.format(h['price'] as double),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }


  void _showAllProductsScreen(BuildContext context, List<String> allRawNames, List<Receipt> receipts) async {
    final selectedProduct = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => ProductListScreen(allProducts: allRawNames, receipts: receipts),
      ),
    );
    
    if (selectedProduct != null && mounted) {
      _showDetailedProductHistory(context, selectedProduct, receipts);
    }
  }


  Widget _buildStatsCards(double monthlySpent, int totalReceipts, double avgPerReceipt) {
    // Using CurrencyFormatter

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            title: AppLocalizations.of(context)!.statsThisMonth,
            value: CurrencyFormatter.format(monthlySpent),
            icon: Icons.calendar_today,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: AppLocalizations.of(context)!.statsTotalReceipts,
            value: totalReceipts.toString(),
            icon: Icons.receipt,
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            title: AppLocalizations.of(context)!.statsAverage,
            value: CurrencyFormatter.format(avgPerReceipt),
            icon: Icons.trending_up,
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildMembershipCard(MembershipTier tier, DateTime? expiresAt) {
    final tierColors = {
      'standart': [const Color(0xFF6C757D), const Color(0xFF495057)],
      'premium': [const Color(0xFF6A11CB), const Color(0xFF2575FC)],
      'limitless': [const Color(0xFFFFD700), const Color(0xFFFFA500)],
      'limitless_family': [const Color(0xFF1A237E), const Color(0xFF00796B)],
    };

    final tierIcons = {
      'standart': Icons.person,
      'premium': Icons.star,
      'limitless': Icons.workspace_premium,
      'limitless_family': Icons.family_restroom,
    };

    final colors = tierColors[tier.id] ?? tierColors['standart']!;
    final icon = tierIcons[tier.id] ?? Icons.person;


    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors[1].withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.membershipTierLabel(tier.name),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (expiresAt != null && tier.id != 'standart') ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.timer_outlined, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              'Bitiş: ${_timeRemaining(expiresAt)}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          if (tier.id == 'premium' || tier.id == 'limitless') ...[
             const SizedBox(height: 20),
             SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _launchSubscriptionManagement,
                icon: const Icon(Icons.open_in_new, size: 18),
                label: Text(AppLocalizations.of(context)!.manageCancelSubscription),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
             ),
          ],

          if (tier.id == 'limitless_family') ...[
             const SizedBox(height: 20),
             SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FamilyPlanScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.settings, size: 18),
                label: Text(AppLocalizations.of(context)!.familySettings),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
             ),
             const SizedBox(height: 10),
             SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _launchSubscriptionManagement,
                icon: const Icon(Icons.open_in_new, size: 18, color: Colors.white70),
                label: Text(AppLocalizations.of(context)!.manageCancelSubscription, style: const TextStyle(color: Colors.white70)),
              ),
             ),
          ] else if (tier.id == 'standart') ...[

             const SizedBox(height: 20),
             SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                   Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const UpgradeScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.star, size: 18),
                label: Text(AppLocalizations.of(context)!.upgradeMembership),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
             ),
          ]
        ],
      ),
    );
  }



  Widget _buildRecentActivity(List<Receipt> recentReceipts) {

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.recentActivity,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const HistoryScreen(),
                    ),
                  );
                },
                child: Text(AppLocalizations.of(context)!.seeAll),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (recentReceipts.isEmpty)
             Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  AppLocalizations.of(context)!.noReceiptsYet,
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
            )
          else
            ...recentReceipts.map((receipt) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.receipt, size: 20, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          receipt.merchantName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          _timeAgoSync(receipt.date),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(receipt.totalAmount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )).toList(),
        ],
      ),
    );
  }

  void _showLanguageDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.language),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text("Türkçe"),
                leading: const Text("🇹🇷"),
                onTap: () async {
                  languageNotifier.value = const Locale('tr');
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('selected_language', 'tr');
                  if (context.mounted) Navigator.pop(context);
                },
                trailing: languageNotifier.value.languageCode == 'tr'
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
              ),
              ListTile(
                title: const Text("English"),
                leading: const Text("🇬🇧"),
                onTap: () async {
                  languageNotifier.value = const Locale('en');
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('selected_language', 'en');
                  if (context.mounted) Navigator.pop(context);
                },
                trailing: languageNotifier.value.languageCode == 'en'
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmLogoutTitle),
        content: Text(AppLocalizations.of(context)!.confirmLogoutMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await AuthService().signOut();
            },
            child: Text(AppLocalizations.of(context)!.loginLogout),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }



  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Color color = AppColors.textDark,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: const TextStyle(fontSize: 12),
              )
            : null,
        trailing: trailing,
      ),
    );
  }
  Future<void> _loadUserProfile() async {
    final user = _client.auth.currentUser;
    if (user != null) {
      final profileService = ProfileService();
      final profile = await profileService.getUserProfile(user.id);
      if (mounted) {
        setState(() {
          _city = profile?.city;
          _district = profile?.district;
        });
      }
    }
  }

  Future<void> _loadSmsPreference() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _smsTrackingEnabled = prefs.getBool('sms_tracking_enabled') ?? false;
      });
    }
  }

  Future<void> _toggleSmsTracking(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('sms_tracking_enabled', value);
    if (mounted) {
      setState(() {
        _smsTrackingEnabled = value;
      });
    }
  }

  void _handleDeleteAccount() {
    final List<String> reasons = [
      "Uygulamayı yeterli bulmadım",
      "Başka bir hesap açacağım",
      "Çok fazla bildirim geliyor",
      "Kullanımı zor geldi",
      "Diğer"
    ];
    String selectedReason = reasons[0];
    final TextEditingController otherReasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                AppLocalizations.of(context)!.deleteAccount,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Hesabınızı ve tüm verilerinizi silmek üzeresiniz. Bu işlem geri alınamaz."),
                    const SizedBox(height: 20),
                    const Text(
                      "Silme Nedeni:",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedReason,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: reasons.map((reason) {
                        return DropdownMenuItem(
                          value: reason,
                          child: Text(reason, style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (val) {
                        setDialogState(() {
                          selectedReason = val!;
                        });
                      },
                    ),
                    if (selectedReason == "Diğer") ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: otherReasonController,
                        decoration: const InputDecoration(
                          labelText: "Lütfen sebep belirtiniz",
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text("Vazgeç"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () {
                     String finalReason = selectedReason;
                     if (selectedReason == "Diğer") {
                       final customText = otherReasonController.text.trim();
                       if (customText.isNotEmpty) {
                         finalReason = "Diğer: $customText";
                       }
                     }
                     Navigator.pop(ctx);
                     // Direkt silme fonksiyonunu çağır (Confirmation dialog'u atla, zaten burası confirmation)
                     _performAccountDeletion(finalReason);
                  },
                  child: const Text("Hesabı Sil", style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _performAccountDeletion(String reason) async {
     try {
       // Loading göster
       showDialog(
         context: context, 
         barrierDismissible: false,
         builder: (_) => const Center(child: CircularProgressIndicator())
       );

       await _databaseService.deleteAccount(reason);
       
       // Loading kapat (ÖNCE bunu yapmalıyız, aksi takdirde çıkış yapılınca context kaybolur)
       if (mounted && Navigator.canPop(context)) Navigator.pop(context);

       // Başarılı mesajı
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text("Hesap silme talebi alındı. Çıkış yapılıyor...")),
         );
       }
       
       // ŞİMDİ çıkış yap
       await AuthService().signOut();

       // Zaten AuthWrapper bunu yakalayıp Login ekranına atacak.
     } catch (e) {
       // Loading kapat
       if (mounted && Navigator.canPop(context)) Navigator.pop(context);
       
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(content: Text("Hata: $e")),
         );
       }
     }
  }

  void _showFinalDeletionConfirmation(String reason) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteAccount),
        content: Text("Hesabınızı silmek istediğinize emin misiniz? Bu işlem geri alınamaz.\n\nSebep: $reason"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(context);
              setState(() => _isLoadingDelete = true);
              try {
                await _databaseService.deleteAccount(reason);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Hesap silme talebi gönderildi.")),
                  );
                  // Çıkış yap ve login ekranına dön
                  await AuthService().signOut();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Hata: $e")),
                  );
                }
              } finally {
                if (mounted) {
                  setState(() => _isLoadingDelete = false);
                }
              }
            },
            child: Text(AppLocalizations.of(context)!.delete),
          ),
        ],
      ),
    );
  }

  String _timeRemaining(DateTime? date) {
    if (date == null) return '';
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.isNegative) return "Süresi doldu";

    if (difference.inDays > 0) {
      return "${difference.inDays} gün";
    } else if (difference.inHours > 0) {
      return "${difference.inHours} saat";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes} dk";
    } else {
      return "Az kaldı";
    }
  }

  String _timeAgo(DateTime? date) { // Keep _timeAgo for recent activity if needed, or update usage
    if (date == null) return '';
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return "${(difference.inDays / 365).floor()}y";
    } else if (difference.inDays > 30) {
      return "${(difference.inDays / 30).floor()}ay";
    } else if (difference.inDays > 0) {
      return "${difference.inDays}g";
    } else if (difference.inHours > 0) {
      return "${difference.inHours}s";
    } else if (difference.inMinutes > 0) {
      return "${difference.inMinutes}dk";
    } else {
      return "Şimdi";
    }
  }

  String _timeAgoSync(DateTime? date) {
    return _timeAgo(date);
  }
}
