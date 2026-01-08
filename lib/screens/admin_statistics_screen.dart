import 'package:flutter/material.dart';
import '../services/supabase_database_service.dart';
import '../core/app_theme.dart';
import '../models/receipt_model.dart';
import 'package:intl/intl.dart';

class AdminStatisticsScreen extends StatefulWidget {
  const AdminStatisticsScreen({super.key});

  @override
  State<AdminStatisticsScreen> createState() => _AdminStatisticsScreenState();
}

class _AdminStatisticsScreenState extends State<AdminStatisticsScreen> {
  final SupabaseDatabaseService _databaseService = SupabaseDatabaseService();
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<Map<String, dynamic>> _recentUsers = [];
  List<Receipt> _recentReceipts = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final results = await Future.wait([
        _databaseService.getAdminStats(),
        _databaseService.getAllUsersForAdmin(),
        _databaseService.getRecentReceiptsForAdmin(5),
      ]);

      if (mounted) {
        setState(() {
          _stats = results[0] as Map<String, dynamic>;
          
          // Get last 5 users
          final allUsers = results[1] as List<Map<String, dynamic>>;
          // Sort by join_date descending if not already sorted
          allUsers.sort((a, b) {
            final dateA = DateTime.tryParse(a['join_date'] ?? '') ?? DateTime(2000);
            final dateB = DateTime.tryParse(b['join_date'] ?? '') ?? DateTime(2000);
            return dateB.compareTo(dateA);
          });
          _recentUsers = allUsers.take(5).toList();

          _recentReceipts = results[2] as List<Receipt>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "İstatistikler yüklenirken hata oluştu: $e";
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Detaylı İstatistikler"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTierBreakdownSection(),
                      const SizedBox(height: 24),
                      _buildOtherStatsSection(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildTierBreakdownSection() {
    final tiers = _stats['tier_breakdown'] as Map<String, dynamic>? ?? {};
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Üyelik Dağılımı",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildTierRow("Ücretsiz", tiers['standart'] ?? 0, Colors.grey),
                const Divider(),
                _buildTierRow("Standart", tiers['premium'] ?? 0, Colors.blue),
                const Divider(),
                _buildTierRow("Pro", tiers['limitless'] ?? 0, Colors.orange),
                const Divider(),
                _buildTierRow("Aile", tiers['limitless_family'] ?? 0, Colors.purple),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOtherStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Diğer Bilgiler",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.info_outline, color: Colors.blue),
                  title: const Text("Veritabanı Durumu"),
                  subtitle: const Text("Aktif"),
                  trailing: const Icon(Icons.check_circle, color: Colors.green),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.update, color: Colors.orange),
                  title: const Text("Son Güncelleme"),
                  subtitle: Text(DateTime.now().toString().substring(0, 16)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTierRow(String label, int count, Color color) {
    final total = (_stats['total_users'] as int?) ?? 1;
    final percentage = (count / (total == 0 ? 1 : total) * 100).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            "$count ($percentage%)",
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
