import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../models/user_level.dart';
import '../models/achievement.dart';
import '../services/gamification_service.dart';
import '../widgets/xp_progress_bar.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';
import '../utils/l10n_helper.dart';

/// Gamification Dashboard Ekranı
class GamificationDashboard extends StatefulWidget {
  const GamificationDashboard({super.key});

  @override
  State<GamificationDashboard> createState() => _GamificationDashboardState();
}

class _GamificationDashboardState extends State<GamificationDashboard> {
  final GamificationService _gamificationService = GamificationService();
  UserLevel? _userLevel;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final level = await _gamificationService.getUserLevel();
    setState(() {
      _userLevel = level;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.myAchievements),
        backgroundColor: AppColors.headerBackground,
        foregroundColor: AppColors.headerText,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _userLevel == null
              ? Center(child: Text(AppLocalizations.of(context)!.dataLoadError))
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      // XP Progress Bar
                      XpProgressBar(userLevel: _userLevel!),

                      const SizedBox(height: 24),

                      // Günlük Streak
                      _buildStreakCard(),

                      const SizedBox(height: 24),

                      // Rozetler Başlık
                      Text(
                        AppLocalizations.of(context)!.myBadges,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Rozet İstatistikleri
                      _buildBadgeStats(),

                      const SizedBox(height: 16),

                      // Rozet Grid
                      _buildBadgeGrid(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildStreakCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange, Colors.deepOrange],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.dailyStreakLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.daysCount(_userLevel!.dailyStreak),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.keepGoing,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeStats() {
    final earnedCount = _userLevel!.badgesEarned.length;
    final totalCount = Achievements.all.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.emoji_events,
            label: AppLocalizations.of(context)!.earnedStat,
            value: '$earnedCount',
            color: Colors.amber,
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          _buildStatItem(
            icon: Icons.lock_outline,
            label: AppLocalizations.of(context)!.lockedStat,
            value: '${totalCount - earnedCount}',
            color: Colors.grey,
          ),
          Container(width: 1, height: 40, color: Colors.grey.shade300),
          _buildStatItem(
            icon: Icons.percent,
            label: AppLocalizations.of(context)!.completionStat,
            value: '${((earnedCount / totalCount) * 100).toInt()}%',
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildBadgeGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: Achievements.all.length,
      itemBuilder: (context, index) {
        final achievement = Achievements.all[index];
        final isEarned = _userLevel!.badgesEarned.contains(achievement.id);

        return _buildBadgeCard(achievement, isEarned);
      },
    );
  }

  Widget _buildBadgeCard(Achievement achievement, bool isEarned) {
    return GestureDetector(
      onTap: () => _showBadgeDetail(achievement, isEarned),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isEarned ? achievement.color.withOpacity(0.1) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isEarned ? achievement.color : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              achievement.icon,
              size: 40,
              color: isEarned ? achievement.color : Colors.grey.shade400,
            ),
            const SizedBox(height: 8),
            Text(
              L10nHelper.getBadgeName(context, achievement.id),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isEarned ? AppColors.textDark : Colors.grey,
              ),
            ),
            if (isEarned)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: achievement.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '✓',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showBadgeDetail(Achievement achievement, bool isEarned) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: achievement.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                achievement.icon,
                size: 60,
                color: achievement.color,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              L10nHelper.getBadgeName(context, achievement.id),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              L10nHelper.getBadgeDescription(context, achievement.id),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: achievement.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stars, color: achievement.color, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    AppLocalizations.of(context)!.xpReward(achievement.xpReward),
                    style: TextStyle(
                      color: achievement.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (isEarned)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.earned,
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock, color: Colors.grey, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.notEarnedYet,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }
}
