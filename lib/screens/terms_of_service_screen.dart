import 'package:flutter/material.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';
import '../core/app_theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)!.termsOfServiceTitle,
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              AppLocalizations.of(context)!.lastUpdated,
              AppLocalizations.of(context)!.termsLastUpdated,
            ),
            const SizedBox(height: 20),
            _buildSection(
              AppLocalizations.of(context)!.termsSection1Title,
              AppLocalizations.of(context)!.termsSection1Content,
            ),
            _buildSection(
              AppLocalizations.of(context)!.termsSection2Title,
              AppLocalizations.of(context)!.termsSection2Content,
            ),
            _buildSection(
              AppLocalizations.of(context)!.termsSection3Title,
              AppLocalizations.of(context)!.termsSection3Content,
            ),
            _buildSection(
              AppLocalizations.of(context)!.termsSection4Title,
              AppLocalizations.of(context)!.termsSection4Content,
            ),
            _buildSection(
              AppLocalizations.of(context)!.termsSection5Title,
              AppLocalizations.of(context)!.termsSection5Content,
            ),
            _buildSection(
              AppLocalizations.of(context)!.termsSection6Title,
              AppLocalizations.of(context)!.termsSection6Content,
            ),
            _buildSection(
              AppLocalizations.of(context)!.termsSection7Title,
              AppLocalizations.of(context)!.termsSection7Content,
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                AppLocalizations.of(context)!.termsFooter,
                style: const TextStyle(
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textDark,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textLight,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
