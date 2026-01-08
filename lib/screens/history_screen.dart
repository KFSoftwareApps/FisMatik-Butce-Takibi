import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fismatik/l10n/generated/app_localizations.dart';
import '../services/supabase_database_service.dart';
import '../core/app_theme.dart';
import '../widgets/empty_state.dart';
import 'month_detail_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final SupabaseDatabaseService databaseService = SupabaseDatabaseService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.history),
        backgroundColor: AppColors.headerBackground,
        foregroundColor: AppColors.headerText,
      ),
      body: FutureBuilder<List<DateTime>>(
        future: databaseService.getAvailableMonths(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(AppLocalizations.of(context)!.errorPrefix(snapshot.error.toString())));
          }

          final months = snapshot.data ?? [];

          if (months.isEmpty) {
            return EmptyState(
              icon: Icons.history,
              title: AppLocalizations.of(context)!.noHistoryYet,
              description: AppLocalizations.of(context)!.noHistoryDescription,
              color: Colors.deepOrange,
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: months.length,
            itemBuilder: (context, index) {
              final date = months[index];
              final formattedDate = DateFormat.yMMMM(Localizations.localeOf(context).toString()).format(date);

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: const Icon(Icons.calendar_today, color: AppColors.primary),
                  ),
                  title: Text(
                    formattedDate,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MonthDetailScreen(month: date),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
