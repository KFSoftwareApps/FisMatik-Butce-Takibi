import 'package:flutter/material.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';

class L10nHelper {
  static String getBadgeName(BuildContext context, String id) {
    final l10n = AppLocalizations.of(context)!;
    switch (id) {
      case 'first_receipt': return l10n.badge_first_receipt_name;
      case 'receipt_5': return l10n.badge_receipt_5_name;
      case 'receipt_10': return l10n.badge_receipt_10_name;
      case 'receipt_50': return l10n.badge_receipt_50_name;
      case 'receipt_100': return l10n.badge_receipt_100_name;
      case 'receipt_500': return l10n.badge_receipt_500_name;
      case 'receipt_1000': return l10n.badge_receipt_1000_name;
      case 'streak_7': return l10n.badge_streak_7_name;
      case 'streak_30': return l10n.badge_streak_30_name;
      case 'streak_365': return l10n.badge_streak_365_name;
      case 'saver': return l10n.badge_saver_name;
      case 'saver_master': return l10n.badge_saver_master_name;
      case 'big_spender': return l10n.badge_big_spender_name;
      case 'budget_master': return l10n.badge_budget_master_name;
      case 'night_owl': return l10n.badge_night_owl_name;
      case 'early_bird': return l10n.badge_early_bird_name;
      case 'weekend_shopper': return l10n.badge_weekend_shopper_name;
      case 'loyal_user': return l10n.badge_loyal_user_name;
      case 'category_master': return l10n.badge_category_master_name;
      case 'ultimate_master': return l10n.badge_ultimate_master_name;
      case 'goal_hunter': return l10n.badge_goal_hunter_name;
      case 'market_master': return l10n.badge_market_master_name;
      case 'fuel_tracker': return l10n.badge_fuel_tracker_name;
      case 'gourmet': return l10n.badge_gourmet_name;
      default: return id;
    }
  }

  static String getBadgeDescription(BuildContext context, String id) {
    final l10n = AppLocalizations.of(context)!;
    switch (id) {
      case 'first_receipt': return l10n.badge_first_receipt_desc;
      case 'receipt_5': return l10n.badge_receipt_5_desc;
      case 'receipt_10': return l10n.badge_receipt_10_desc;
      case 'receipt_50': return l10n.badge_receipt_50_desc;
      case 'receipt_100': return l10n.badge_receipt_100_desc;
      case 'receipt_500': return l10n.badge_receipt_500_desc;
      case 'receipt_1000': return l10n.badge_receipt_1000_desc;
      case 'streak_7': return l10n.badge_streak_7_desc;
      case 'streak_30': return l10n.badge_streak_30_desc;
      case 'streak_365': return l10n.badge_streak_365_desc;
      case 'saver': return l10n.badge_saver_desc;
      case 'saver_master': return l10n.badge_saver_master_desc;
      case 'big_spender': return l10n.badge_big_spender_desc;
      case 'budget_master': return l10n.badge_budget_master_desc;
      case 'night_owl': return l10n.badge_night_owl_desc;
      case 'early_bird': return l10n.badge_early_bird_desc;
      case 'weekend_shopper': return l10n.badge_weekend_shopper_desc;
      case 'loyal_user': return l10n.badge_loyal_user_desc;
      case 'category_master': return l10n.badge_category_master_desc;
      case 'ultimate_master': return l10n.badge_ultimate_master_desc;
      case 'goal_hunter': return l10n.badge_goal_hunter_desc;
      case 'market_master': return l10n.badge_market_master_desc;
      case 'fuel_tracker': return l10n.badge_fuel_tracker_desc;
      case 'gourmet': return l10n.badge_gourmet_desc;
      default: return "";
    }
  }

  static String getBadgeMessage(BuildContext context, String id, {String? fallback}) {
    final l10n = AppLocalizations.of(context)!;
    switch (id) {
      case 'first_receipt': return l10n.badge_first_receipt_msg;
      case 'receipt_5': return l10n.badge_receipt_5_msg;
      case 'receipt_10': return l10n.badge_receipt_10_msg;
      case 'receipt_50': return l10n.badge_receipt_50_msg;
      case 'saver': return l10n.badge_saver_msg;
      case 'big_spender': return l10n.badge_big_spender_msg;
      case 'budget_master': return l10n.badge_budget_master_msg;
      case 'night_owl': return l10n.badge_night_owl_msg;
      case 'early_bird': return l10n.badge_early_bird_msg;
      case 'weekend_shopper': return l10n.badge_weekend_shopper_msg;
      case 'loyal_user': return l10n.badge_loyal_user_msg;
      case 'category_master': return l10n.badge_category_master_msg;
      case 'ultimate_master': return l10n.badge_ultimate_master_msg;
      default: return fallback ?? "";
    }
  }

  static String getLevelName(BuildContext context, int level) {
    final l10n = AppLocalizations.of(context)!;
    switch (level) {
      case 1: return l10n.level_1_name;
      case 2: return l10n.level_2_name;
      case 3: return l10n.level_3_name;
      case 4: return l10n.level_4_name;
      case 5: return l10n.level_5_name;
      case 6: return l10n.level_6_name;
      case 7: return l10n.level_7_name;
      case 8: return l10n.level_8_name;
      case 9: return l10n.level_9_name;
      case 10: return l10n.level_10_name;
      default: return l10n.unknown;
    }
  }

  static String getTierName(BuildContext context, String tierId) {
    final l10n = AppLocalizations.of(context)!;
    switch (tierId) {
      case 'standart': return l10n.tier_free_name;
      case 'premium': return l10n.tier_standart_name;
      case 'limitless': return l10n.tier_premium_name;
      case 'limitless_family': return l10n.tier_limitless_family_name;
      default: return tierId;
    }
  }
}
