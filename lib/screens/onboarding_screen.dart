import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/app_theme.dart';
import 'home_screen.dart';
import '../services/demo_data_service.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback? onComplete;

  const OnboardingScreen({
    super.key,
    this.onComplete,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _startWithDemoData = true; // Default to true for Apple review
  bool _isInserting = false;



  Future<void> _completeOnboarding() async {
    setState(() => _isInserting = true);
    
    if (_startWithDemoData) {
      try {
        await DemoDataService().insertDemoData();
      } catch (e) {
        debugPrint("Demo data insertion error: $e");
      }
    }

    if (widget.onComplete != null) {
      widget.onComplete!();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final user = Supabase.instance.client.auth.currentUser;
    
    // 1. Local Update
    final key = 'onboarding_completed_${user?.id ?? 'unknown'}';
    await prefs.setBool(key, true);

    // 2. Remote Update (Sync)
    if (user != null) {
      try {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(data: {'onboarding_completed': true}),
        );
      } catch (e) {
        debugPrint("Error syncing onboarding status: $e");
      }
    }
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: _skipOnboarding,
                  child: Text(
                    AppLocalizations.of(context)!.onboardingSkip,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),

            // PageView
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: 5,
                itemBuilder: (context, index) {
                  final pages = [
                    OnboardingPage(
                      title: AppLocalizations.of(context)!.onboardingTitle1,
                      description: AppLocalizations.of(context)!.onboardingDesc1,
                      icon: Icons.account_balance_wallet,
                      color: AppColors.primary,
                    ),
                    OnboardingPage(
                      title: AppLocalizations.of(context)!.onboardingTitle2,
                      description: AppLocalizations.of(context)!.onboardingDesc2,
                      icon: Icons.camera_alt,
                      color: Colors.blue,
                    ),
                    OnboardingPage(
                      title: AppLocalizations.of(context)!.onboardingTitle3,
                      description: AppLocalizations.of(context)!.onboardingDesc3,
                      icon: Icons.auto_awesome,
                      color: Colors.purple,
                    ),
                    OnboardingPage(
                      title: AppLocalizations.of(context)!.onboardingTitle4,
                      description: AppLocalizations.of(context)!.onboardingDesc4,
                      icon: Icons.shopping_bag_outlined,
                      color: Colors.orange,
                    ),
                    OnboardingPage(
                      title: AppLocalizations.of(context)!.onboardingTitle5,
                      description: AppLocalizations.of(context)!.onboardingDesc5,
                      icon: Icons.analytics,
                      color: Colors.green,
                    ),
                  ];
                  return _buildPage(pages[index]);
                },
              ),
            ),

            // Page Indicators
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => _buildIndicator(index == _currentPage, [
                    AppColors.primary,
                    Colors.blue,
                    Colors.purple,
                    Colors.orange,
                    Colors.green
                  ][index]),
                ),
              ),
            ),

            // Next/Start Button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isInserting ? null : _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: [
                      AppColors.primary,
                      Colors.blue,
                      Colors.purple,
                      Colors.orange,
                      Colors.green
                    ][_currentPage],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: _isInserting 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        _currentPage == 4 ? AppLocalizations.of(context)!.onboardingStart : AppLocalizations.of(context)!.onboardingNext,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 60,
              color: page.color,
            ),
          ),
          const SizedBox(height: 40),

          // Title
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: page.color,
            ),
          ),
          const SizedBox(height: 20),

          // Description
          Text(
            page.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.5,
            ),
          ),

          // Demo Data Choice (Only on last page)
          if (_currentPage == 4) ...[
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withOpacity(0.1)),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: _startWithDemoData,
                    onChanged: (v) => setState(() => _startWithDemoData = v ?? false),
                    activeColor: Colors.green,
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.onboardingDemoOption,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        Text(
                          AppLocalizations.of(context)!.onboardingDemoDetail,
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildIndicator(bool isActive, Color activeColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 24 : 8,
      decoration: BoxDecoration(
        color: isActive ? activeColor : Colors.grey.shade300,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
