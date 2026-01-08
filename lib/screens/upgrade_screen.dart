// lib/screens/upgrade_screen.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/membership_model.dart';
import '../services/supabase_database_service.dart';
import '../services/payment_service.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';
import '../utils/l10n_helper.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class UpgradeScreen extends StatefulWidget {
  const UpgradeScreen({super.key});

  @override
  State<UpgradeScreen> createState() => _UpgradeScreenState();
}

class _UpgradeScreenState extends State<UpgradeScreen> {
  final PaymentService _paymentService = PaymentService();
  bool _isLoading = false;
  int _selectedTierIndex = 1; // Default to Standart (premium)

  @override
  void initState() {
    super.initState();

    // Ödeme servisini başlat
    if (!kIsWeb) {
      _paymentService.init();
    }

    // Satın alma sonuçlarını dinle
    _paymentService.onPurchaseCompleted = (message, isSuccess) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isSuccess ? AppColors.success : Colors.red,
        ),
      );

      if (isSuccess) {
        Navigator.pop(context);
      }
    };
  }

  @override
  void dispose() {
    _paymentService.onPurchaseCompleted = null;
    super.dispose();
  }

  Future<void> _handleUpgrade(String tierId) async {
    setState(() => _isLoading = true);
    
    if (kIsWeb) {
      await _paymentService.openWebPaymentLink(tierId);
      setState(() => _isLoading = false);
    } else {
      await _paymentService.buyProduct(tierId);
      
      // 45 saniyelik zaman aşımı - Eğer mağazadan yanıt gelmezse sonsuz döngüyü kır
      Future.delayed(const Duration(seconds: 45), () {
        if (mounted && _isLoading) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text("İşlem mağaza tarafından henüz tamamlanmadı. Lütfen aboneliklerinizi kontrol edin.")),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MembershipTier>(
      stream: SupabaseDatabaseService()
          .getUserTierStream()
          .map(
            (tierId) =>
                MembershipTier.Tiers[tierId] ??
                MembershipTier.Tiers['standart']!,
          ),
      builder: (context, snapshot) {
        final currentTier = snapshot.data ?? MembershipTier.Tiers['standart']!;
        
        final tiers = [
          MembershipTier.Tiers['standart']!,
          MembershipTier.Tiers['premium']!,
          MembershipTier.Tiers['limitless']!,
          MembershipTier.Tiers['limitless_family']!,
        ];

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            leading: IconButton(
              icon: Icon(Icons.adaptive.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(AppLocalizations.of(context)!.membershipUpgradeTitle),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            actions: [
              if (!kIsWeb)
                TextButton(
                  onPressed: () => _paymentService.restorePurchases(),
                  child: Text(
                    AppLocalizations.of(context)!.restorePurchases,
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
            ],
          ),
          body: Column(
            children: [
              // Current Membership Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.workspace_premium, color: Colors.white, size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppLocalizations.of(context)!.currentMembershipStatus(
                          L10nHelper.getTierName(context, currentTier.id),
                        ),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Tier Selection Tabs
              Container(
                margin: const EdgeInsets.all(20),
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
                child: Row(
                  children: List.generate(tiers.length, (index) {
                    final tier = tiers[index];
                    final isSelected = _selectedTierIndex == index;
                    final isCurrent = tier.id == currentTier.id;
                    
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedTierIndex = index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            children: [
                              if (isCurrent)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  margin: const EdgeInsets.only(bottom: 4),
                                  decoration: BoxDecoration(
                                    color: isSelected ? Colors.white : AppColors.primary,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'MEVCUT',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? AppColors.primary : Colors.white,
                                    ),
                                  ),
                                ),
                              Text(
                                L10nHelper.getTierName(context, tier.id),
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.white : AppColors.textDark,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                tier.price,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white70 : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),

              // Feature Comparison Table
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _buildComparisonTable(context, tiers, currentTier),
                ),
              ),

              // Subscription Summary (Apple Compliance - iOS/MacOS Only)
              if (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.macOS)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blueGrey.withOpacity(0.1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.subscriptionTermsSummaryTitle,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalizations.of(context)!.subscriptionTermsSummaryBody,
                        style: TextStyle(fontSize: 10, color: Colors.grey[700], height: 1.3),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => _paymentService.manageSubscriptions(),
                            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                            child: Text(
                              AppLocalizations.of(context)!.manageSubscription,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Row(
                            children: [
                              TextButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TermsOfServiceScreen())),
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                child: Text(AppLocalizations.of(context)!.termsOfService, style: const TextStyle(fontSize: 10)),
                              ),
                              Text(" • ", style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                              TextButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen())),
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                child: Text(AppLocalizations.of(context)!.privacyPolicy, style: const TextStyle(fontSize: 10)),
                              ),
                              Text(" • ", style: TextStyle(color: Colors.grey[400], fontSize: 10)),
                              TextButton(
                                onPressed: () => launchUrl(Uri.parse('https://www.apple.com/legal/internet-services/itunes/dev/stdeula/')),
                                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                child: const Text("EULA", style: TextStyle(fontSize: 10)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              // Purchase Button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: (tiers[_selectedTierIndex].id == currentTier.id || 
                                  tiers[_selectedTierIndex].id == 'standart' || 
                                  _isLoading)
                          ? null
                          : () => _handleUpgrade(tiers[_selectedTierIndex].id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              tiers[_selectedTierIndex].id == currentTier.id
                                  ? AppLocalizations.of(context)!.currentMembership
                                  : tiers[_selectedTierIndex].id == 'standart'
                                      ? AppLocalizations.of(context)!.tier_free_name
                                      : AppLocalizations.of(context)!.buyNow,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildComparisonTable(BuildContext context, List<MembershipTier> tiers, MembershipTier currentTier) {
    final l10n = AppLocalizations.of(context)!;
    
    // Define all features with their availability per tier
    final features = [
      _FeatureRow(
        name: l10n.featureDailyScans,
        icon: Icons.camera_alt,
        values: [
          '1 fiş/gün',
          '10 fiş/gün',
          '25 fiş/gün',
          '35 fiş/gün',
        ],
      ),
      _FeatureRow(
        name: l10n.featureMonthlyManual,
        icon: Icons.edit_note,
        values: [
          '20 giriş/ay',
          '50 giriş/ay',
          '100 giriş/ay',
          '200 giriş/ay',
        ],
      ),
      _FeatureRow(
        name: l10n.featureUnlimitedSubscriptions,
        icon: Icons.repeat,
        values: [true, true, true, true],
      ),
      _FeatureRow(
        name: l10n.featureAdFree,
        icon: Icons.block,
        values: [false, true, true, true],
      ),
      _FeatureRow(
        name: l10n.featureCategoryManagement,
        icon: Icons.category,
        values: [false, true, true, true],
      ),
      _FeatureRow(
        name: l10n.featureBudgetForecasting,
        icon: Icons.trending_up,
        values: [false, false, true, true],
      ),
      _FeatureRow(
        name: l10n.featureSmartRefund,
        icon: Icons.replay_circle_filled,
        values: [false, false, true, true],
      ),
      _FeatureRow(
        name: l10n.featureExcelReports,
        icon: Icons.table_chart,
        values: [false, true, true, true],
      ),
      _FeatureRow(
        name: l10n.featurePdfReports,
        icon: Icons.picture_as_pdf,
        values: [false, true, true, true],
      ),
      _FeatureRow(
        name: l10n.featureTaxReports,
        icon: Icons.receipt_long,
        values: [false, true, true, true],
      ),
      _FeatureRow(
        name: l10n.featurePriceHistory,
        icon: Icons.history,
        values: [false, true, true, true],
      ),
      _FeatureRow(
        name: l10n.featureCheapestStore,
        icon: Icons.shopping_bag,
        values: [false, true, true, true],
      ),
      _FeatureRow(
        name: l10n.featurePriceAlerts,
        icon: Icons.notifications_active,
        values: [false, true, true, true],
      ),
      _FeatureRow(
        name: l10n.featureFamilySharing,
        icon: Icons.family_restroom,
        values: [false, false, false, true],
      ),
      _FeatureRow(
        name: l10n.featureSharedDashboard,
        icon: Icons.dashboard,
        values: [false, false, false, true],
      ),
    ];

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
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 40),
                Expanded(
                  child: Text(
                    l10n.compareFeatures,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Feature Rows
          ...features.asMap().entries.map((entry) {
            final index = entry.key;
            final feature = entry.value;
            final isEven = index % 2 == 0;

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isEven ? Colors.grey[50] : Colors.white,
              ),
              child: Row(
                children: [
                  Icon(
                    feature.icon,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      feature.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _buildFeatureValue(feature.values[_selectedTierIndex]),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildFeatureValue(dynamic value) {
    if (value is bool) {
      return Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: value ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          value ? Icons.check : Icons.close,
          size: 18,
          color: value ? Colors.green : Colors.red,
        ),
      );
    } else if (value is String) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _FeatureRow {
  final String name;
  final IconData icon;
  final List<dynamic> values; // bool, String, or int

  _FeatureRow({
    required this.name,
    required this.icon,
    required this.values,
  });
}
